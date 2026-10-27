from fastapi import APIRouter, Depends, HTTPException, Body, status
from sqlalchemy.orm import Session
from typing import List
import uuid

from app.api.dependencies import get_db
from app.models import models
from app.schemas import schemas

router = APIRouter()

@router.get("/usuario/{usuario_id}/estado-sucursal", response_model=schemas.EstadoSucursalResponse)
def obtener_estado_sucursal_usuario(usuario_id: str, db: Session = Depends(get_db)):
    """Verifica si el usuario actual posee un establecimiento y una cuponera configurada."""
    usuario = db.query(models.Usuario).filter(models.Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    rol_str = usuario.rol.value if hasattr(usuario.rol, 'value') else str(usuario.rol)
    establecimiento = db.query(models.Establecimiento).filter(models.Establecimiento.propietario_id == usuario_id).first()

    if not establecimiento:
        return {
            "tiene_sucursal": False,
            "rol": rol_str,
            "establecimiento": None,
            "cuponera_id": None
        }

    cuponera = db.query(models.Cuponera).filter(models.Cuponera.establecimiento_id == establecimiento.id).first()

    return {
        "tiene_sucursal": True,
        "rol": rol_str,
        "establecimiento": {
            "id": establecimiento.id,
            "propietario_id": establecimiento.propietario_id,
            "nombre": establecimiento.nombre,
            "slug": establecimiento.slug,
            "logo_url": establecimiento.logo_url,
            "activo": establecimiento.activo,
            "fecha_creacion": establecimiento.fecha_creacion
        },
        "cuponera_id": cuponera.id if cuponera else None
    }

@router.post("/solicitudes", response_model=schemas.MensajeResponse)
def crear_solicitud_negocio(datos: schemas.CrearSolicitudRequest, db: Session = Depends(get_db)):
    """Crea una solicitud formal para convertir una cuenta de cliente en sucursal/propietario."""
    solicitud_existente = db.query(models.SolicitudEstablecimiento).filter(
        models.SolicitudEstablecimiento.usuario_id == datos.usuario_id,
        models.SolicitudEstablecimiento.estado == models.EstadoSolicitud.PENDIENTE.value
    ).first()
    
    if solicitud_existente:
        raise HTTPException(status_code=400, detail="Ya tienes una solicitud pendiente de aprobación.")

    nueva_solicitud = models.SolicitudEstablecimiento(
        id=str(uuid.uuid4()),
        usuario_id=datos.usuario_id,
        nombre_negocio=datos.nombre_negocio,
        documentos_url=datos.documentos_url or "https://servidor.com/docs/default.pdf",
        estado=models.EstadoSolicitud.PENDIENTE.value
    )
    
    db.add(nueva_solicitud)
    db.commit()
    
    return schemas.MensajeResponse(mensaje="Solicitud enviada exitosamente. En espera de revisión.")

@router.patch("/solicitudes/{solicitud_id}/aprobar", response_model=schemas.MensajeResponse)
def aprobar_solicitud_negocio(solicitud_id: str, db: Session = Depends(get_db)):
    """Aprobación por admin: Actualiza rol, genera Establecimiento, Cuponera e registro de DisenoCuponera."""
    solicitud = db.query(models.SolicitudEstablecimiento).filter(models.SolicitudEstablecimiento.id == solicitud_id).first()
    if not solicitud:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")

    solicitud.estado = models.EstadoSolicitud.APROBADA.value

    usuario = db.query(models.Usuario).filter(models.Usuario.id == solicitud.usuario_id).first()
    if usuario:
        usuario.rol = models.RolUsuario.PROPIETARIO.value

    slug_base = solicitud.nombre_negocio.lower().replace(" ", "-")
    nuevo_local = models.Establecimiento(
        id=str(uuid.uuid4()),
        propietario_id=solicitud.usuario_id,
        nombre=solicitud.nombre_negocio,
        slug=f"{slug_base}-{str(uuid.uuid4())[:4]}",
        activo=True
    )
    db.add(nuevo_local)
    db.flush()

    nueva_cuponera = models.Cuponera(
        id=str(uuid.uuid4()),
        establecimiento_id=nuevo_local.id,
        titulo=f"Cuponera de Fidelidad - {nuevo_local.nombre}",
        descripcion_premio="Premio por definir por el comercio",
        total_sellos_requeridos=6,
        activa=True
    )
    db.add(nueva_cuponera)
    db.flush()

    nuevo_diseno = models.DisenoCuponera(
        id=str(uuid.uuid4()),
        cuponera_id=nueva_cuponera.id,
        configuracion_ui=None
    )
    db.add(nuevo_diseno)

    db.commit()
    
    return schemas.MensajeResponse(mensaje="Solicitud aprobada. Establecimiento, Cuponera y Diseño iniciales creados.")

@router.post("/users/{usuario_id}/convert-to-local", response_model=schemas.MensajeResponse)
def convert_user_to_local(
    usuario_id: str, 
    datos: schemas.ConvertirLocalRequest,
    db: Session = Depends(get_db)
):
    """Atajo directo de desarrollo: Convierte un usuario en propietario y crea sus registros relacionales."""
    usuario = db.query(models.Usuario).filter(models.Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    usuario.rol = models.RolUsuario.PROPIETARIO.value

    slug_base = datos.nombre_local.lower().replace(" ", "-")
    nuevo_local = models.Establecimiento(
        id=str(uuid.uuid4()),
        nombre=datos.nombre_local,
        propietario_id=usuario_id,
        slug=f"{slug_base}-{str(uuid.uuid4())[:4]}",
        activo=True 
    )
    db.add(nuevo_local)
    db.flush()

    nueva_cuponera = models.Cuponera(
        id=str(uuid.uuid4()),
        establecimiento_id=nuevo_local.id,
        titulo=f"Cuponera de Fidelidad - {nuevo_local.nombre}",
        descripcion_premio="Premio por definir por el negocio",
        total_sellos_requeridos=6,
        activa=True
    )
    db.add(nueva_cuponera)
    db.flush()

    nuevo_diseno = models.DisenoCuponera(
        id=str(uuid.uuid4()),
        cuponera_id=nueva_cuponera.id,
        configuracion_ui=None
    )
    db.add(nuevo_diseno)

    db.commit()
    
    return schemas.MensajeResponse(mensaje="Usuario convertido a propietario con cuponera y diseño asignados.")