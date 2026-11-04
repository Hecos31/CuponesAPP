import re
import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.api.dependencies import get_db
from app.models.models import (
    Establecimiento,
    Usuario,
    RolUsuario,
    Cuponera,
    DisenoCuponera,
    SolicitudEstablecimiento,
    EstadoSolicitud,
)
from app.schemas.schemas import (
    EstablecimientoCreate,
    EstablecimientoUpdate,
    EstablecimientoResponse,
    EstadoSucursalResponse,
    CrearSolicitudRequest,
    MensajeResponse,
)

router = APIRouter()


def slugify(text: str) -> str:
    slug = text.lower().strip()
    slug = re.sub(r"[^\w\s-]", "", slug)
    slug = re.sub(r"[\s_-]+", "-", slug)
    return slug or "sucursal"


# ============================================================================
# COMPATIBILIDAD CON FLUJO DE APROBACIÓN / SOLICITUDES EN /establecimientos
# ============================================================================
@router.get("/usuario/{usuario_id}/estado-sucursal", response_model=EstadoSucursalResponse)
def obtener_estado_sucursal_usuario(usuario_id: str, db: Session = Depends(get_db)):
    """Verifica si el usuario actual posee un establecimiento y una cuponera configurada."""
    usuario = db.query(Usuario).filter(Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    rol_str = usuario.rol.value if hasattr(usuario.rol, "value") else str(usuario.rol)
    establecimiento = (
        db.query(Establecimiento)
        .filter(Establecimiento.propietario_id == usuario_id)
        .first()
    )

    if not establecimiento:
        return {
            "tiene_sucursal": False,
            "rol": rol_str,
            "establecimiento": None,
            "cuponera_id": None,
        }

    cuponera = (
        db.query(Cuponera)
        .filter(Cuponera.establecimiento_id == establecimiento.id)
        .first()
    )

    return {
        "tiene_sucursal": True,
        "rol": rol_str,
        "establecimiento": establecimiento,
        "cuponera_id": cuponera.id if cuponera else None,
    }


@router.post("/solicitudes", response_model=MensajeResponse, status_code=status.HTTP_201_CREATED)
def crear_solicitud_establecimiento(
    datos: CrearSolicitudRequest,
    db: Session = Depends(get_db),
):
    """Registra una solicitud de alta de negocio con sus documentos probatorios."""
    usuario = db.query(Usuario).filter(Usuario.id == datos.usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    solicitud_existente = (
        db.query(SolicitudEstablecimiento)
        .filter(
            SolicitudEstablecimiento.usuario_id == datos.usuario_id,
            SolicitudEstablecimiento.estado == EstadoSolicitud.PENDIENTE.value,
        )
        .first()
    )

    if solicitud_existente:
        solicitud_existente.nombre_negocio = datos.nombre_negocio.strip()
        if datos.documentos_url:
            solicitud_existente.documentos_url = datos.documentos_url.strip()
        db.commit()
        return MensajeResponse(
            mensaje="Solicitud actualizada exitosamente. En espera de revisión."
        )

    nueva_solicitud = SolicitudEstablecimiento(
        id=str(uuid.uuid4()),
        usuario_id=datos.usuario_id,
        nombre_negocio=datos.nombre_negocio.strip(),
        documentos_url=datos.documentos_url or "/static/uploads/documentos/documento_verificacion.pdf",
        estado=EstadoSolicitud.PENDIENTE.value,
    )
    db.add(nueva_solicitud)
    db.commit()

    return MensajeResponse(
        mensaje="Solicitud enviada exitosamente. En espera de revisión."
    )


# ============================================================================
# ALTA DE SUCURSALES (SISTEMA COMPLETO)
# ============================================================================
@router.post("/", response_model=EstablecimientoResponse, status_code=status.HTTP_201_CREATED)
def dar_de_alta_sucursal(
    sucursal_in: EstablecimientoCreate,
    db: Session = Depends(get_db),
):
    """
    Da de alta una nueva sucursal (Establecimiento) asociada a un propietario,
    junto con su Cuponera inicial y registro de Diseño (Server-Driven UI).
    """
    propietario = db.query(Usuario).filter(Usuario.id == sucursal_in.propietario_id).first()
    if not propietario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="El propietario indicado no existe.",
        )

    if propietario.rol == RolUsuario.CLIENTE.value or propietario.rol == RolUsuario.CLIENTE:
        propietario.rol = RolUsuario.PROPIETARIO.value

    base_slug = slugify(sucursal_in.slug or sucursal_in.nombre)
    slug_candidato = base_slug
    contador = 1
    while db.query(Establecimiento).filter(Establecimiento.slug == slug_candidato).first():
        slug_candidato = f"{base_slug}-{contador}"
        contador += 1

    nueva_sucursal = Establecimiento(
        id=str(uuid.uuid4()),
        propietario_id=sucursal_in.propietario_id,
        nombre=sucursal_in.nombre.strip(),
        slug=slug_candidato,
        logo_url=sucursal_in.logo_url,
        activo=sucursal_in.activo,
    )
    db.add(nueva_sucursal)
    db.flush()

    nueva_cuponera = Cuponera(
        id=str(uuid.uuid4()),
        establecimiento_id=nueva_sucursal.id,
        titulo=f"Cuponera de {nueva_sucursal.nombre}",
        descripcion_premio="Premio por definir",
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
    db.refresh(nueva_sucursal)
    return nueva_sucursal


# ============================================================================
# VISTA DE ADMINISTRACIÓN: LISTADO Y CONSULTA DE SUCURSALES
# ============================================================================
@router.get("/", response_model=List[EstablecimientoResponse])
def listar_sucursales(
    propietario_id: Optional[str] = Query(None, description="Filtrar por ID de propietario"),
    activo: Optional[bool] = Query(None, description="Filtrar por estado activo/inactivo"),
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
):
    """
    Lista las sucursales registradas con soporte de filtros para el panel de administración.
    """
    query = db.query(Establecimiento)
    if propietario_id:
        query = query.filter(Establecimiento.propietario_id == propietario_id)
    if activo is not None:
        query = query.filter(Establecimiento.activo == activo)

    return query.order_by(Establecimiento.fecha_creacion.desc()).offset(skip).limit(limit).all()


@router.get("/{sucursal_id}", response_model=EstablecimientoResponse)
def obtener_detalle_sucursal(
    sucursal_id: str,
    db: Session = Depends(get_db),
):
    """
    Obtiene los datos completos de una sucursal específica.
    """
    sucursal = db.query(Establecimiento).filter(Establecimiento.id == sucursal_id).first()
    if not sucursal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sucursal no encontrada.",
        )
    return sucursal


# ============================================================================
# VISTA DE CONFIGURACIÓN ESPECIAL: ACTUALIZACIÓN DE DETALLES
# ============================================================================
@router.patch("/{sucursal_id}/configuracion", response_model=EstablecimientoResponse)
def actualizar_configuracion_sucursal(
    sucursal_id: str,
    config_in: EstablecimientoUpdate,
    db: Session = Depends(get_db),
):
    """
    Actualiza la configuración especial de una sucursal: nombre, logo_url y estado activo/inactivo.
    """
    sucursal = db.query(Establecimiento).filter(Establecimiento.id == sucursal_id).first()
    if not sucursal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sucursal no encontrada.",
        )

    if config_in.nombre is not None:
        sucursal.nombre = config_in.nombre
    if config_in.logo_url is not None:
        sucursal.logo_url = config_in.logo_url
    if config_in.activo is not None:
        sucursal.activo = config_in.activo

    db.commit()
    db.refresh(sucursal)
    return sucursal
