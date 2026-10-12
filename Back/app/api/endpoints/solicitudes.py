import os
import re
import uuid
import shutil
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Query, status
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

# Directorio para almacenamiento seguro de documentos probatorios
UPLOAD_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "static", "uploads", "documentos")
os.makedirs(UPLOAD_DIR, exist_ok=True)

ALLOWED_EXTENSIONS = {".pdf", ".png", ".jpg", ".jpeg"}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB


def slugify(text: str) -> str:
    slug = text.lower().strip()
    slug = re.sub(r'[^\w\s-]', '', slug)
    slug = re.sub(r'[\s_-]+', '-', slug)
    return slug


# ===========================================================================
# Carga segura de documentos probatorios
# ===========================================================================
@router.post("/upload-documento", response_model=UploadDocumentoResponse, status_code=status.HTTP_201_CREATED)
async def upload_documento_probatorio(file: UploadFile = File(...)):
    """
    Carga de manera segura un documento probatorio (PDF, JPG, PNG).
    Valida extensión y genera un nombre seguro no predecible.
    """
    _, ext = os.path.splitext(file.filename or "")
    ext = ext.lower()

    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Tipo de archivo no permitido. Extensiones válidas: {', '.join(ALLOWED_EXTENSIONS)}"
        )

    # Generar nombre único para evitar colisiones e inyecciones de ruta
    safe_filename = f"{uuid.uuid4().hex}{ext}"
    file_path = os.path.join(UPLOAD_DIR, safe_filename)

    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al almacenar el archivo: {str(e)}"
        )
    finally:
        await file.close()

    public_url = f"/static/uploads/documentos/{safe_filename}"
    return UploadDocumentoResponse(url=public_url, filename=safe_filename)


# ============================================================================
# CREAR Y CONSULTAR SOLICITUDES DE ESTABLECIMIENTOS
# ============================================================================
@router.post("/", response_model=SolicitudEstablecimientoResponse, status_code=status.HTTP_201_CREATED)
def crear_solicitud(
    solicitud_in: SolicitudEstablecimientoCreate,
    db: Session = Depends(get_db)
):
    """
    Registra una nueva solicitud de verificación de establecimiento en estado PENDIENTE.
    """
    usuario = db.query(Usuario).filter(Usuario.id == solicitud_in.usuario_id).first()
    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="El usuario especificado no existe."
        )

    solicitud = SolicitudEstablecimiento(
        usuario_id=solicitud_in.usuario_id,
        nombre_negocio=solicitud_in.nombre_negocio,
        documentos_url=solicitud_in.documentos_url,
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
    Lista las solicitudes de verificación registradas, con soporte de filtrado.
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
# TAREA 980: Máquina de estados (PENDIENTE -> APROBADA / RECHAZADA)
# ============================================================================
@router.patch("/{solicitud_id}/estado", response_model=SolicitudEstablecimientoResponse)
def actualizar_estado_solicitud(
    solicitud_id: str,
    payload: SolicitudEstablecimientoUpdateEstado,
    db: Session = Depends(get_db)
):
    """
    Máquina de estados para solicitudes de verificación.
    Transiciones válidas:
      - PENDIENTE -> APROBADA: Aprueba la solicitud, promueve el rol del usuario a 'propietario'
                               y genera automáticamente el Establecimiento inicial.
      - PENDIENTE -> RECHAZADA: Rechaza la solicitud con registro en base de datos.
    """
    solicitud = db.query(SolicitudEstablecimiento).filter(SolicitudEstablecimiento.id == solicitud_id).first()
    if not solicitud:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Solicitud no encontrada."
        )

    nuevo_estado_str = payload.estado.upper()
    if nuevo_estado_str not in EstadoSolicitud.__members__:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Estado inválido. Opciones permitidas: {[e.value for e in EstadoSolicitud]}"
        )

    nuevo_estado = EstadoSolicitud[nuevo_estado_str]
    estado_actual = solicitud.estado

    # Reglas de transición de la máquina de estados
    if estado_actual == nuevo_estado:
        return solicitud  # Sin cambios

    if estado_actual in [EstadoSolicitud.APROBADA, EstadoSolicitud.RECHAZADA] and nuevo_estado_str not in ["PENDIENTE"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Transición no permitida: La solicitud ya se encuentra en estado final '{estado_actual.value}'."
        )

    # Actualizar estado de la solicitud
    solicitud.estado = nuevo_estado

    # Efectos colaterales de la transición a APROBADA
    if nuevo_estado == EstadoSolicitud.APROBADA:
        usuario = db.query(Usuario).filter(Usuario.id == solicitud.usuario_id).first()
        if usuario and usuario.rol != RolUsuario.PROPIETARIO and usuario.rol != RolUsuario.ADMIN:
            usuario.rol = RolUsuario.PROPIETARIO

        # Crear el establecimiento automáticamente si aún no existe
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
