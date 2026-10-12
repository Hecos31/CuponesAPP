import re
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.api.dependencies import get_db
from app.models.models import Establecimiento, Usuario, RolUsuario
from app.schemas.schemas import (
    EstablecimientoCreate,
    EstablecimientoUpdate,
    EstablecimientoResponse
)

router = APIRouter()


def slugify(text: str) -> str:
    slug = text.lower().strip()
    slug = re.sub(r'[^\w\s-]', '', slug)
    slug = re.sub(r'[\s_-]+', '-', slug)
    return slug or "sucursal"


# ============================================================================
# ALTA DE SUCURSALES (SISTEMA COMPLETO)
# ============================================================================
@router.post("/", response_model=EstablecimientoResponse, status_code=status.HTTP_201_CREATED)
def dar_de_alta_sucursal(
    sucursal_in: EstablecimientoCreate,
    db: Session = Depends(get_db)
):
    """
    Da de alta una nueva sucursal (Establecimiento) asociada a un propietario.
    Genera un slug amigable y único automáticamente si no se provee.
    """
    propietario = db.query(Usuario).filter(Usuario.id == sucursal_in.propietario_id).first()
    if not propietario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="El propietario indicado no existe."
        )

    # Si el usuario es cliente, al dar de alta sucursal lo promovemos a propietario
    if propietario.rol == RolUsuario.CLIENTE:
        propietario.rol = RolUsuario.PROPIETARIO

    # Generación de slug único
    base_slug = slugify(sucursal_in.slug or sucursal_in.nombre)
    slug_candidato = base_slug
    contador = 1
    while db.query(Establecimiento).filter(Establecimiento.slug == slug_candidato).first():
        slug_candidato = f"{base_slug}-{contador}"
        contador += 1

    nueva_sucursal = Establecimiento(
        propietario_id=sucursal_in.propietario_id,
        nombre=sucursal_in.nombre,
        slug=slug_candidato,
        logo_url=sucursal_in.logo_url,
        activo=sucursal_in.activo
    )
    db.add(nueva_sucursal)
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
    db: Session = Depends(get_db)
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
    db: Session = Depends(get_db)
):
    """
    Obtiene los datos completos de una sucursal específica.
    """
    sucursal = db.query(Establecimiento).filter(Establecimiento.id == sucursal_id).first()
    if not sucursal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sucursal no encontrada."
        )
    return sucursal


# ============================================================================
# VISTA DE CONFIGURACIÓN ESPECIAL: ACTUALIZACIÓN DE DETALLES
# ============================================================================
@router.patch("/{sucursal_id}/configuracion", response_model=EstablecimientoResponse)
def actualizar_configuracion_sucursal(
    sucursal_id: str,
    config_in: EstablecimientoUpdate,
    db: Session = Depends(get_db)
):
    """
    Actualiza la configuración especial de una sucursal: nombre, logo_url y estado activo/inactivo.
    """
    sucursal = db.query(Establecimiento).filter(Establecimiento.id == sucursal_id).first()
    if not sucursal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sucursal no encontrada."
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
