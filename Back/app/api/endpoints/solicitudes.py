import os
import re
import uuid
from typing import List, Optional
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

# Directorio para almacenamiento seguro de documentos probatorios
UPLOAD_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(__file__))),
    "static",
    "uploads",
    "documentos",
)
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
}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB


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
# TAREA 1000 (FG): Desarrollar API para carga segura de documentos probatorios
# ===========================================================================
@router.post(
    "/upload-documento",
    response_model=UploadDocumentoResponse,
    status_code=status.HTTP_201_CREATED,
)
async def upload_documento_probatorio(
    file: UploadFile = File(...),
    tipo_documento: str = Form("INE", description="Tipo de documento probatorio: INE, PASAPORTE, COMPROBANTE_DOMICILIO, DOCUMENTO_LOCAL"),
):
    """
    Carga de manera segura un documento oficial probatorio (INE, Pasaporte, Comprobante de domicilio, Documento del local)
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
        mensaje=f"Documento probatorio ({tipo_clean}) verificado y almacenado de forma segura.",
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
    Registra una nueva solicitud de verificación de identidad y alta de sucursal en estado PENDIENTE.
    Si el usuario ya tenía una solicitud pendiente o rechazada, actualiza sus datos y documentos.
    """
    usuario = db.query(Usuario).filter(Usuario.id == solicitud_in.usuario_id).first()
    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="El usuario solicitante especificado no existe.",
        )

    if not solicitud_in.documentos_url or not solicitud_in.documentos_url.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Es obligatorio adjuntar los documentos probatorios de verificación de identidad antes de solicitar el alta de la sucursal.",
        )

    solicitud_existente = (
        db.query(SolicitudEstablecimiento)
        .filter(
            SolicitudEstablecimiento.usuario_id == solicitud_in.usuario_id,
            SolicitudEstablecimiento.estado == EstadoSolicitud.PENDIENTE.value,
        )
        .first()
    )

    if solicitud_existente:
        solicitud_existente.nombre_negocio = solicitud_in.nombre_negocio.strip()
        solicitud_existente.documentos_url = solicitud_in.documentos_url.strip()
        db.commit()
        db.refresh(solicitud_existente)
        return solicitud_existente

    solicitud = SolicitudEstablecimiento(
        id=str(uuid.uuid4()),
        usuario_id=solicitud_in.usuario_id,
        nombre_negocio=solicitud_in.nombre_negocio.strip(),
        documentos_url=solicitud_in.documentos_url.strip(),
        estado=EstadoSolicitud.PENDIENTE.value,
    )
    db.add(solicitud)
    db.commit()
    db.refresh(solicitud)
    return solicitud


@router.get("/", response_model=List[SolicitudResponse])
def listar_solicitudes(
    usuario_id: Optional[str] = Query(None, description="Filtrar por ID de usuario solicitante"),
    estado: Optional[str] = Query(None, description="Filtrar por estado: PENDIENTE, APROBADA, RECHAZADA"),
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
):
    """
    Lista las solicitudes de verificación y alta de sucursal registradas.
    """
    query = db.query(SolicitudEstablecimiento)

    if usuario_id:
        query = query.filter(SolicitudEstablecimiento.usuario_id == usuario_id)

    if estado:
        estado_upper = estado.upper()
        if estado_upper in EstadoSolicitud.__members__:
            query = query.filter(SolicitudEstablecimiento.estado == EstadoSolicitud[estado_upper].value)

    return query.order_by(SolicitudEstablecimiento.fecha_solicitud.desc()).offset(skip).limit(limit).all()


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
    return solicitud


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
    Gestiona y valida las transiciones permitidas entre los estados de la solicitud:
      - PENDIENTE -> APROBADA: Aprueba la solicitud, actualiza el rol del usuario a 'propietario'
                               y genera Establecimiento, Cuponera base y Diseño inicial si no existen.
      - PENDIENTE -> RECHAZADA: Rechaza la solicitud de alta.
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
    estado_actual_str = (
        solicitud.estado.value if hasattr(solicitud.estado, "value") else str(solicitud.estado)
    ).lower()

    if estado_actual_str == nuevo_estado_enum.value:
        return solicitud

    # Bloquear transiciones directas entre estados terminales (aprobada <-> rechazada)
    if estado_actual_str in ("aprobada", "rechazada") and nuevo_estado_enum != EstadoSolicitud.PENDIENTE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Transición inválida en la máquina de estados: No se puede pasar directamente de '{estado_actual_str}' a '{nuevo_estado_enum.value}'.",
        )

    solicitud.estado = nuevo_estado_enum.value

    # Efecto de transición a APROBADA: promover usuario a propietario y crear Establecimiento + Cuponera + DisenoCuponera
    if nuevo_estado_enum == EstadoSolicitud.APROBADA:
        usuario = db.query(Usuario).filter(Usuario.id == solicitud.usuario_id).first()
        if usuario and usuario.rol != RolUsuario.ADMIN.value:
            usuario.rol = RolUsuario.PROPIETARIO.value

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

    db.commit()
    db.refresh(solicitud)
    return solicitud
