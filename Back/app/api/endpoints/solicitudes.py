import os
import re
import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Query, status
from sqlalchemy.orm import Session

from app.api.dependencies import get_db
from app.models.models import SolicitudEstablecimiento, EstadoSolicitud, Usuario, RolUsuario, Establecimiento
from app.schemas.schemas import (
    SolicitudEstablecimientoCreate,
    SolicitudEstablecimientoResponse,
    SolicitudEstablecimientoUpdateEstado,
    UploadDocumentoResponse
)

router = APIRouter()

# Directorio para almacenamiento seguro de documentos probatorios de identidad
UPLOAD_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "static", "uploads", "documentos")
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
    slug = re.sub(r'[^\w\s-]', '', slug)
    slug = re.sub(r'[\s_-]+', '-', slug)
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
# TAREA 1000: Desarrollar API para carga segura de documentos probatorios
# ===========================================================================
@router.post("/upload-documento", response_model=UploadDocumentoResponse, status_code=status.HTTP_201_CREATED)
async def upload_documento_probatorio(
    file: UploadFile = File(...),
    tipo_documento: str = Form("INE", description="Tipo de documento de identidad: INE o PASAPORTE")
):
    """
    Carga de manera segura un documento oficial de identidad (INE o Pasaporte) en formato PDF, JPG o PNG.
    - Valida tipo de documento (INE, PASAPORTE).
    - Valida extensión permitida (.pdf, .png, .jpg, .jpeg).
    - Valida tamaño máximo (10 MB) y cabeceras del archivo (magic bytes).
    - Sanitiza y renombra con UUID para prevenir Path Traversal o sobreescrituras.
    """
    tipo_clean = tipo_documento.strip().upper()
    if tipo_clean not in ALLOWED_TIPOS_DOCUMENTO:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Tipo de documento inválido ('{tipo_documento}'). Debe ser INE o PASAPORTE."
        )

    _, ext = os.path.splitext(file.filename or "")
    ext = ext.lower()

    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Extensión de archivo no permitida. Formatos válidos: {', '.join(ALLOWED_EXTENSIONS)}"
        )

    try:
        content = await file.read()
        file_size = len(content)

        if file_size == 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="El archivo subido está vacío."
            )

        if file_size > MAX_FILE_SIZE:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail="El documento excede el límite máximo permitido de 10 MB."
            )

        if not validate_magic_bytes(content, ext):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="El contenido binario del archivo no coincide con un PDF o imagen auténtica."
            )

        # Generar nombre único con prefijo del tipo de identificación (INE / PASAPORTE)
        safe_filename = f"{tipo_clean.lower()}_{uuid.uuid4().hex}{ext}"
        file_path = os.path.join(UPLOAD_DIR, safe_filename)

        with open(file_path, "wb") as buffer:
            buffer.write(content)

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al almacenar el documento probatorio: {str(e)}"
        )
    finally:
        await file.close()

    public_url = f"/static/uploads/documentos/{safe_filename}"
    return UploadDocumentoResponse(
        url=public_url,
        filename=safe_filename,
        tipo_documento=tipo_clean,
        tamano_bytes=file_size,
        mensaje=f"Documento de identidad ({tipo_clean}) verificado y almacenado de forma segura."
    )


# ============================================================================
# CREAR Y CONSULTAR SOLICITUDES DE VERIFICACIÓN Y ALTA DE SUCURSAL
# ============================================================================
@router.post("/", response_model=SolicitudEstablecimientoResponse, status_code=status.HTTP_201_CREATED)
def crear_solicitud(
    solicitud_in: SolicitudEstablecimientoCreate,
    db: Session = Depends(get_db)
):
    """
    Registra una nueva solicitud de verificación de identidad y alta de sucursal en estado PENDIENTE.
    Requiere que previamente se haya cargado el documento de identidad (INE o Pasaporte).
    """
    usuario = db.query(Usuario).filter(Usuario.id == solicitud_in.usuario_id).first()
    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="El usuario solicitante especificado no existe."
        )

    if not solicitud_in.documentos_url or not solicitud_in.documentos_url.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Es obligatorio adjuntar el documento de verificación de identidad (INE o Pasaporte) antes de solicitar el alta de la sucursal."
        )

    solicitud = SolicitudEstablecimiento(
        usuario_id=solicitud_in.usuario_id,
        nombre_negocio=solicitud_in.nombre_negocio.strip(),
        documentos_url=solicitud_in.documentos_url.strip(),
        estado=EstadoSolicitud.PENDIENTE
    )
    db.add(solicitud)
    db.commit()
    db.refresh(solicitud)
    return solicitud


@router.get("/", response_model=List[SolicitudEstablecimientoResponse])
def listar_solicitudes(
    usuario_id: Optional[str] = Query(None, description="Filtrar por ID de usuario solicitante"),
    estado: Optional[str] = Query(None, description="Filtrar por estado: PENDIENTE, APROBADA, RECHAZADA"),
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db)
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
            query = query.filter(SolicitudEstablecimiento.estado == EstadoSolicitud[estado_upper])

    return query.order_by(SolicitudEstablecimiento.fecha_solicitud.desc()).offset(skip).limit(limit).all()


@router.get("/{solicitud_id}", response_model=SolicitudEstablecimientoResponse)
def obtener_solicitud(solicitud_id: str, db: Session = Depends(get_db)):
    """
    Obtiene el detalle de una solicitud de establecimiento por su ID.
    """
    solicitud = db.query(SolicitudEstablecimiento).filter(SolicitudEstablecimiento.id == solicitud_id).first()
    if not solicitud:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Solicitud no encontrada."
        )
    return solicitud


# ============================================================================
# TAREA 980: Desarrollar API para la Máquina de estados (Pendiente, Aprobado, Rechazado)
# ============================================================================
@router.patch("/{solicitud_id}/estado", response_model=SolicitudEstablecimientoResponse)
def actualizar_estado_solicitud(
    solicitud_id: str,
    payload: SolicitudEstablecimientoUpdateEstado,
    db: Session = Depends(get_db)
):
    """
    API para la Máquina de estados de una solicitud (PENDIENTE, APROBADA, RECHAZADA).
    Gestiona y valida las transiciones permitidas entre los estados de la solicitud:
      - Estado inicial: PENDIENTE
      - Estados finales: APROBADA, RECHAZADA
    (La validación manual del local y alta administrativa corresponde a otro endpoint).
    """
    solicitud = db.query(SolicitudEstablecimiento).filter(SolicitudEstablecimiento.id == solicitud_id).first()
    if not solicitud:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Solicitud no encontrada."
        )

    # Normalizar entrada (acepta APROBADO/APROBADA, RECHAZADO/RECHAZADA, PENDIENTE)
    raw_estado = payload.estado.strip().upper()
    mapa_estados = {
        "PENDIENTE": "PENDIENTE",
        "APROBADA": "APROBADA",
        "APROBADO": "APROBADA",
        "RECHAZADA": "RECHAZADA",
        "RECHAZADO": "RECHAZADA",
    }

    if raw_estado not in mapa_estados:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Estado inválido. Estados permitidos: PENDIENTE, APROBADA, RECHAZADA."
        )

    nuevo_estado = EstadoSolicitud[mapa_estados[raw_estado]]
    estado_actual = solicitud.estado

    # Reglas de transición de la Máquina de Estados
    if estado_actual == nuevo_estado:
        return solicitud

    # Bloquear transiciones directas entre estados terminales (APROBADA <-> RECHAZADA)
    if estado_actual in (EstadoSolicitud.APROBADA, EstadoSolicitud.RECHAZADA) and nuevo_estado != EstadoSolicitud.PENDIENTE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Transición inválida en la máquina de estados: No se puede pasar directamente de '{estado_actual.value}' a '{nuevo_estado.value}'."
        )

    # Actualizar estado en la máquina de estados
    solicitud.estado = nuevo_estado

    # Si pasa a APROBADA, promovemos al usuario a propietario y creamos su establecimiento si no existe
    if nuevo_estado == EstadoSolicitud.APROBADA:
        usuario = db.query(Usuario).filter(Usuario.id == solicitud.usuario_id).first()
        if usuario and usuario.rol == RolUsuario.CLIENTE:
            usuario.rol = RolUsuario.PROPIETARIO

        existente = db.query(Establecimiento).filter(
            Establecimiento.propietario_id == solicitud.usuario_id,
            Establecimiento.nombre == solicitud.nombre_negocio
        ).first()

        if not existente:
            base_slug = slugify(solicitud.nombre_negocio)
            slug_candidato = base_slug
            contador = 1
            while db.query(Establecimiento).filter(Establecimiento.slug == slug_candidato).first():
                slug_candidato = f"{base_slug}-{contador}"
                contador += 1

            nuevo_establecimiento = Establecimiento(
                propietario_id=solicitud.usuario_id,
                nombre=solicitud.nombre_negocio,
                slug=slug_candidato,
                activo=True
            )
            db.add(nuevo_establecimiento)

    db.commit()
    db.refresh(solicitud)
    return solicitud
