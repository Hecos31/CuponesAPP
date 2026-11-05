import json
import os
import re
import uuid
from datetime import datetime
from typing import Dict, Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Query, status
from sqlalchemy.orm import Session

from app.api.dependencies import get_db
from app.models.models import (
    SolicitudEstablecimiento,
    EstadoSolicitud,
    Usuario,
    RolUsuario,
    Establecimiento,
    Cuponera,
    DisenoCuponera,
)
from app.schemas.schemas import (
    CrearSolicitudRequest,
    SolicitudResponse,
    SolicitudEstablecimientoUpdateEstado,
    UploadDocumentoResponse,
)

router = APIRouter()

# Directorio para almacenamiento seguro de documentos probatorios y logos
STATIC_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(__file__))),
    "static",
)
UPLOAD_DIR = os.path.join(STATIC_DIR, "uploads", "documentos")
METADATA_FILE = os.path.join(STATIC_DIR, "solicitudes_metadata.json")
os.makedirs(UPLOAD_DIR, exist_ok=True)

ALLOWED_EXTENSIONS = {".pdf", ".png", ".jpg", ".jpeg"}
ALLOWED_TIPOS_DOCUMENTO = {
    "INE",
    "PASAPORTE",
    "IDENTIFICACION_OFICIAL",
    "COMPROBANTE_DOMICILIO",
    "DOCUMENTO_LOCAL",
    "ACTA_CONSTITUTIVA",
    "RFC",
    "LOGO_SUCURSAL",
    "CAMBIO_NOMBRE",
}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB


def cargar_metadata_solicitudes() -> Dict[str, Dict[str, Any]]:
    if not os.path.exists(METADATA_FILE):
        return {}
    try:
        with open(METADATA_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
            return data if isinstance(data, dict) else {}
    except Exception:
        return {}


def guardar_metadata_solicitudes(data: Dict[str, Dict[str, Any]]) -> None:
    try:
        with open(METADATA_FILE, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
    except Exception:
        pass


def actualizar_metadata_solicitud(
    solicitud_id: str,
    *,
    direccion: Optional[str] = None,
    nombre_solicitante: Optional[str] = None,
    comentarios_evaluacion: Optional[str] = None,
    fecha_evaluacion: Optional[str] = None,
    tipo_solicitud: Optional[str] = None,
    establecimiento_id: Optional[str] = None,
    nombre_anterior: Optional[str] = None,
) -> Dict[str, Any]:
    meta_all = cargar_metadata_solicitudes()
    actual = meta_all.get(solicitud_id, {})
    if direccion is not None:
        actual["direccion"] = direccion
    if nombre_solicitante is not None:
        actual["nombre_solicitante"] = nombre_solicitante
    if comentarios_evaluacion is not None:
        actual["comentarios_evaluacion"] = comentarios_evaluacion
    if fecha_evaluacion is not None:
        actual["fecha_evaluacion"] = fecha_evaluacion
    if tipo_solicitud is not None:
        actual["tipo_solicitud"] = tipo_solicitud
    if establecimiento_id is not None:
        actual["establecimiento_id"] = establecimiento_id
    if nombre_anterior is not None:
        actual["nombre_anterior"] = nombre_anterior
    meta_all[solicitud_id] = actual
    guardar_metadata_solicitudes(meta_all)
    return actual


def construir_solicitud_response(
    solicitud: SolicitudEstablecimiento,
    db: Session,
    meta_all: Optional[Dict[str, Dict[str, Any]]] = None,
) -> SolicitudResponse:
    if meta_all is None:
        meta_all = cargar_metadata_solicitudes()
    meta = meta_all.get(solicitud.id, {})

    usuario = db.query(Usuario).filter(Usuario.id == solicitud.usuario_id).first()
    estado_str = (
        solicitud.estado.value if hasattr(solicitud.estado, "value") else str(solicitud.estado)
    )

    return SolicitudResponse(
        id=solicitud.id,
        usuario_id=solicitud.usuario_id,
        nombre_negocio=solicitud.nombre_negocio,
        documentos_url=solicitud.documentos_url,
        estado=estado_str,
        fecha_solicitud=solicitud.fecha_solicitud,
        usuario_email=usuario.email if usuario else None,
        direccion=meta.get("direccion"),
        nombre_solicitante=meta.get("nombre_solicitante"),
        comentarios_evaluacion=meta.get("comentarios_evaluacion"),
        fecha_evaluacion=meta.get("fecha_evaluacion"),
        tipo_solicitud=meta.get("tipo_solicitud") or "ALTA_SUCURSAL",
        establecimiento_id=meta.get("establecimiento_id"),
        nombre_anterior=meta.get("nombre_anterior"),
    )


def slugify(text: str) -> str:
    slug = text.lower().strip()
    slug = re.sub(r"[^\w\s-]", "", slug)
    slug = re.sub(r"[\s_-]+", "-", slug)
    return slug or "sucursal"


def validate_magic_bytes(content: bytes, ext: str) -> bool:
    """
    Verifica que los primeros bytes del archivo (magic numbers) correspondan
    con una imagen válida (PNG, JPG/JPEG) o un documento PDF para evitar archivos maliciosos.
    """
    if len(content) < 4:
        return False
    if ext == ".pdf":
        return content.startswith(b"%PDF")
    if ext == ".png":
        return content.startswith(b"\x89PNG")
    if ext in {".jpg", ".jpeg"}:
        return content.startswith(b"\xff\xd8\xff")
    return True


# ===========================================================================
# TAREA 1000 (FG): Desarrollar API para carga segura de documentos probatorios y logos
# ===========================================================================
@router.post(
    "/upload-documento",
    response_model=UploadDocumentoResponse,
    status_code=status.HTTP_201_CREATED,
)
async def upload_documento_probatorio(
    file: UploadFile = File(...),
    tipo_documento: str = Form("INE", description="Tipo de documento probatorio: INE, PASAPORTE, COMPROBANTE_DOMICILIO, DOCUMENTO_LOCAL, LOGO_SUCURSAL"),
):
    """
    Carga de manera segura un documento oficial probatorio o logotipo de sucursal
    en formato PDF, JPG o PNG:
    - Valida el tipo de documento.
    - Valida extensión permitida (.pdf, .png, .jpg, .jpeg).
    - Valida tamaño máximo (10 MB) y cabeceras binarias del archivo (magic bytes).
    - Sanitiza y renombra con UUID para prevenir Path Traversal o sobreescrituras.
    """
    tipo_clean = tipo_documento.strip().upper()
    if tipo_clean not in ALLOWED_TIPOS_DOCUMENTO:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Tipo de documento inválido ('{tipo_documento}'). Tipos válidos: {', '.join(sorted(ALLOWED_TIPOS_DOCUMENTO))}",
        )

    _, ext = os.path.splitext(file.filename or "")
    ext = ext.lower()

    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Extensión de archivo no permitida. Formatos válidos: {', '.join(sorted(ALLOWED_EXTENSIONS))}",
        )

    try:
        content = await file.read()
        file_size = len(content)

        if file_size == 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="El archivo subido está vacío.",
            )

        if file_size > MAX_FILE_SIZE:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail="El documento excede el límite máximo permitido de 10 MB.",
            )

        if not validate_magic_bytes(content, ext):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="El contenido binario del archivo no coincide con un PDF o imagen auténtica.",
            )

        safe_filename = f"{tipo_clean.lower()}_{uuid.uuid4().hex}{ext}"
        file_path = os.path.join(UPLOAD_DIR, safe_filename)

        with open(file_path, "wb") as buffer:
            buffer.write(content)

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al almacenar el documento probatorio: {str(e)}",
        )
    finally:
        await file.close()

    public_url = f"/static/uploads/documentos/{safe_filename}"
    return UploadDocumentoResponse(
        url=public_url,
        filename=safe_filename,
        tipo_documento=tipo_clean,
        tamano_bytes=file_size,
        mensaje=f"Archivo ({tipo_clean}) verificado y almacenado de forma segura.",
    )


# ============================================================================
# CREAR Y CONSULTAR SOLICITUDES DE VERIFICACIÓN Y ALTA DE SUCURSAL
# ============================================================================
@router.post("/", response_model=SolicitudResponse, status_code=status.HTTP_201_CREATED)
def crear_solicitud(
    solicitud_in: CrearSolicitudRequest,
    db: Session = Depends(get_db),
):
    """
    Registra una nueva solicitud de verificación de identidad y alta de sucursal (o cambio de nombre) en estado PENDIENTE.
    Si el usuario ya tenía esa misma solicitud pendiente o rechazada para el mismo negocio, la reactiva/actualiza.
    Si es una nueva sucursal en una cuenta que ya tiene otra sucursal previa, crea un nuevo registro PENDIENTE de revisión.
    """
    usuario = db.query(Usuario).filter(Usuario.id == solicitud_in.usuario_id).first()
    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="El usuario solicitante especificado no existe.",
        )

    tipo_sol = (solicitud_in.tipo_solicitud or "ALTA_SUCURSAL").strip().upper()

    if tipo_sol == "ALTA_SUCURSAL" and (not solicitud_in.documentos_url or not solicitud_in.documentos_url.strip()):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Es obligatorio adjuntar los documentos probatorios de verificación de identidad antes de solicitar el alta de la sucursal.",
        )

    nombre_clean = solicitud_in.nombre_negocio.strip()

    # Buscamos si ya existe una solicitud PENDIENTE o RECHAZADA para este mismo nombre de negocio (o establecimiento)
    solicitud_existente = (
        db.query(SolicitudEstablecimiento)
        .filter(
            SolicitudEstablecimiento.usuario_id == solicitud_in.usuario_id,
            SolicitudEstablecimiento.nombre_negocio == nombre_clean,
            SolicitudEstablecimiento.estado.in_([
                EstadoSolicitud.PENDIENTE.value,
                EstadoSolicitud.RECHAZADA.value,
            ]),
        )
        .order_by(SolicitudEstablecimiento.fecha_solicitud.desc())
        .first()
    )

    if solicitud_existente:
        solicitud_existente.nombre_negocio = nombre_clean
        if solicitud_in.documentos_url:
            solicitud_existente.documentos_url = solicitud_in.documentos_url.strip()
        solicitud_existente.estado = EstadoSolicitud.PENDIENTE.value
        solicitud_existente.fecha_solicitud = datetime.utcnow()
        db.commit()
        db.refresh(solicitud_existente)
        actualizar_metadata_solicitud(
            solicitud_existente.id,
            direccion=solicitud_in.direccion,
            nombre_solicitante=solicitud_in.nombre_solicitante,
            comentarios_evaluacion="",
            fecha_evaluacion="",
            tipo_solicitud=tipo_sol,
            establecimiento_id=solicitud_in.establecimiento_id,
            nombre_anterior=solicitud_in.nombre_anterior,
        )
        return construir_solicitud_response(solicitud_existente, db)

    solicitud = SolicitudEstablecimiento(
        id=str(uuid.uuid4()),
        usuario_id=solicitud_in.usuario_id,
        nombre_negocio=nombre_clean,
        documentos_url=(solicitud_in.documentos_url or "").strip(),
        estado=EstadoSolicitud.PENDIENTE.value,
    )
    db.add(solicitud)
    db.commit()
    db.refresh(solicitud)

    actualizar_metadata_solicitud(
        solicitud.id,
        direccion=solicitud_in.direccion,
        nombre_solicitante=solicitud_in.nombre_solicitante,
        tipo_solicitud=tipo_sol,
        establecimiento_id=solicitud_in.establecimiento_id,
        nombre_anterior=solicitud_in.nombre_anterior,
    )
    return construir_solicitud_response(solicitud, db)


@router.get("/", response_model=List[SolicitudResponse])
def listar_solicitudes(
    usuario_id: Optional[str] = Query(None, description="Filtrar por ID de usuario solicitante"),
    estado: Optional[str] = Query(None, description="Filtrar por estado: PENDIENTE, APROBADA, RECHAZADA"),
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
):
    """
    Lista las solicitudes de verificación, alta de sucursal y cambio de nombre registradas.
    """
    query = db.query(SolicitudEstablecimiento)

    if usuario_id:
        query = query.filter(SolicitudEstablecimiento.usuario_id == usuario_id)

    if estado:
        estado_upper = estado.upper()
        mapa_filtro = {
            "PENDIENTE": EstadoSolicitud.PENDIENTE.value,
            "APROBADA": EstadoSolicitud.APROBADA.value,
            "APROBADO": EstadoSolicitud.APROBADA.value,
            "RECHAZADA": EstadoSolicitud.RECHAZADA.value,
            "RECHAZADO": EstadoSolicitud.RECHAZADA.value,
        }
        if estado_upper in mapa_filtro:
            query = query.filter(SolicitudEstablecimiento.estado == mapa_filtro[estado_upper])

    items = query.order_by(SolicitudEstablecimiento.fecha_solicitud.desc()).offset(skip).limit(limit).all()
    meta_all = cargar_metadata_solicitudes()
    return [construir_solicitud_response(item, db, meta_all) for item in items]


@router.get("/{solicitud_id}", response_model=SolicitudResponse)
def obtener_solicitud(solicitud_id: str, db: Session = Depends(get_db)):
    """
    Obtiene el detalle de una solicitud de establecimiento por su ID.
    """
    solicitud = db.query(SolicitudEstablecimiento).filter(SolicitudEstablecimiento.id == solicitud_id).first()
    if not solicitud:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Solicitud no encontrada.",
        )
    return construir_solicitud_response(solicitud, db)


# ============================================================================
# TAREA 980 (FG): Desarrollar API para la Máquina de estados (Pendiente, Aprobado, Rechazado)
# ============================================================================
@router.patch("/{solicitud_id}/estado", response_model=SolicitudResponse)
def actualizar_estado_solicitud(
    solicitud_id: str,
    payload: SolicitudEstablecimientoUpdateEstado,
    db: Session = Depends(get_db),
):
    """
    API para la Máquina de estados de una solicitud (PENDIENTE, APROBADA, RECHAZADA).
    Permite al administrador evaluar manualmente la solicitud (ya sea un alta de nueva sucursal
    o un cambio de nombre de sucursal existente), registrar comentarios o correcciones
    para el solicitante, y aprobar o rechazar la solicitud.
    """
    solicitud = db.query(SolicitudEstablecimiento).filter(SolicitudEstablecimiento.id == solicitud_id).first()
    if not solicitud:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Solicitud no encontrada.",
        )

    raw_estado = payload.estado.strip().upper()
    mapa_estados = {
        "PENDIENTE": EstadoSolicitud.PENDIENTE,
        "APROBADA": EstadoSolicitud.APROBADA,
        "APROBADO": EstadoSolicitud.APROBADA,
        "RECHAZADA": EstadoSolicitud.RECHAZADA,
        "RECHAZADO": EstadoSolicitud.RECHAZADA,
    }

    if raw_estado not in mapa_estados:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Estado inválido. Estados permitidos: PENDIENTE, APROBADA, RECHAZADA.",
        )

    nuevo_estado_enum = mapa_estados[raw_estado]
    solicitud.estado = nuevo_estado_enum.value

    # Guardamos los comentarios o correcciones realizados por el administrador
    meta = actualizar_metadata_solicitud(
        solicitud.id,
        comentarios_evaluacion=(payload.comentarios_evaluacion or "").strip(),
        fecha_evaluacion=datetime.utcnow().isoformat(),
    )

    tipo_solicitud = (meta.get("tipo_solicitud") or "ALTA_SUCURSAL").upper()
    establecimiento_id_meta = meta.get("establecimiento_id")

    if nuevo_estado_enum == EstadoSolicitud.APROBADA:
        usuario = db.query(Usuario).filter(Usuario.id == solicitud.usuario_id).first()
        if usuario and usuario.rol != RolUsuario.ADMIN.value:
            usuario.rol = RolUsuario.PROPIETARIO.value

        # Caso 1: Solicitud de Cambio de Nombre para una sucursal existente
        if tipo_solicitud == "CAMBIO_NOMBRE" and establecimiento_id_meta:
            sucursal_existente = (
                db.query(Establecimiento)
                .filter(Establecimiento.id == establecimiento_id_meta)
                .first()
            )
            if sucursal_existente:
                nuevo_nombre = solicitud.nombre_negocio.strip()
                sucursal_existente.nombre = nuevo_nombre
                base_slug = slugify(nuevo_nombre)
                sucursal_existente.slug = f"{base_slug}-{str(uuid.uuid4())[:4]}"

                cuponera_asociada = (
                    db.query(Cuponera)
                    .filter(Cuponera.establecimiento_id == sucursal_existente.id)
                    .first()
                )
                if cuponera_asociada:
                    cuponera_asociada.titulo = f"Cuponera de Fidelidad - {nuevo_nombre}"
        else:
            # Caso 2: Solicitud de Alta de Sucursal Nueva
            existente = (
                db.query(Establecimiento)
                .filter(
                    Establecimiento.propietario_id == solicitud.usuario_id,
                    Establecimiento.nombre == solicitud.nombre_negocio,
                )
                .first()
            )

            if not existente:
                base_slug = slugify(solicitud.nombre_negocio)
                slug_candidato = f"{base_slug}-{str(uuid.uuid4())[:4]}"

                nuevo_establecimiento = Establecimiento(
                    id=str(uuid.uuid4()),
                    propietario_id=solicitud.usuario_id,
                    nombre=solicitud.nombre_negocio,
                    slug=slug_candidato,
                    activo=True,
                )
                db.add(nuevo_establecimiento)
                db.flush()

                nueva_cuponera = Cuponera(
                    id=str(uuid.uuid4()),
                    establecimiento_id=nuevo_establecimiento.id,
                    titulo=f"Cuponera de Fidelidad - {nuevo_establecimiento.nombre}",
                    descripcion_premio="Premio por definir por el comercio",
                    total_sellos_requeridos=6,
                    activa=True,
                )
                db.add(nueva_cuponera)
                db.flush()

                nuevo_diseno = DisenoCuponera(
                    id=str(uuid.uuid4()),
                    cuponera_id=nueva_cuponera.id,
                    configuracion_ui={},
                )
                db.add(nuevo_diseno)
            else:
                existente.activo = True

    db.commit()
    db.refresh(solicitud)
    return construir_solicitud_response(solicitud, db)
