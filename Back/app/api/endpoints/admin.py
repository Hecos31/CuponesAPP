from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy.orm import Session
from app.api.dependencies import get_db
from app.models.models import Establecimiento, Usuario
import uuid
from app.models.models import SolicitudEstablecimiento, EstadoSolicitud
router = APIRouter()

@router.get("/establishments")
def get_all_establishments(db: Session = Depends(get_db)):
    """Lista todos los establecimientos registrados en la base de datos."""
    establecimientos = db.query(Establecimiento).all()
    return establecimientos

@router.patch("/establishments/{establishment_id}/validate")
def validate_establishment(
    establishment_id: str,
    status: str = Body(..., embed=True), # Espera 'aprobado' o 'rechazado'
    db: Session = Depends(get_db)
):
    """Aprueba o bloquea un establecimiento usando el campo 'activo'."""
    establecimiento = db.query(Establecimiento).filter(Establecimiento.id == establishment_id).first()
    
    if not establecimiento:
        raise HTTPException(status_code=404, detail="Establecimiento no encontrado")
        
    if status == "aprobado":
        establecimiento.activo = True
    elif status == "rechazado":
        establecimiento.activo = False
    else:
        raise HTTPException(status_code=400, detail="Estado no válido. Usa 'aprobado' o 'rechazado'.")
        
    db.commit()
    db.refresh(establecimiento)
    
    return {
        "message": f"Establecimiento actualizado a {status}",
        "establishment_id": establecimiento.id,
        "activo": establecimiento.activo
    }

@router.post("/users/{usuario_id}/convert-to-local")
def convert_user_to_local(
    usuario_id: str, 
    nombre_local: str = Body(..., embed=True),
    db: Session = Depends(get_db)
):
    """Atajo para convertir un cliente normal en propietario."""
    usuario = db.query(Usuario).filter(Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    # Usamos la palabra exacta que permite tu base de datos
    usuario.rol = "propietario"

    # Creamos el local con activo=False (equivalente a pendiente)
    nuevo_local = Establecimiento(
        id=str(uuid.uuid4()),
        nombre=nombre_local,
        propietario_id=usuario_id,
        slug=nombre_local.lower().replace(" ", "-") + "-" + str(uuid.uuid4())[:4],
        activo=False 
    )
    
    db.add(nuevo_local)
    db.commit()
    db.refresh(nuevo_local)
    
    return {
        "mensaje": "¡Ahora eres un propietario!", 
        "nuevo_rol": usuario.rol,
        "establishment_id": nuevo_local.id
    }

@router.post("/establishments")
def create_test_establishment(
    nombre: str = Body(..., embed=True),
    propietario_id: str = Body(..., embed=True),
    db: Session = Depends(get_db)
):
    """Crea un nuevo establecimiento en estado pendiente para pruebas."""
    nuevo_local = Establecimiento(
        id=str(uuid.uuid4()), # Genera el ID automáticamente
        nombre=nombre,
        propietario_id=propietario_id,
        slug=nombre.lower().replace(" ", "-") + "-" + str(uuid.uuid4())[:4], # Genera un slug válido
        activo=False
    )
    
    if hasattr(nuevo_local, 'status'):
        nuevo_local.status = "pendiente"

    db.add(nuevo_local)
    db.commit()
    db.refresh(nuevo_local)
    return nuevo_local

@router.post("/users/{usuario_id}/convert-to-local")
def convert_user_to_local(
    usuario_id: str, 
    nombre_local: str = Body(..., embed=True),
    db: Session = Depends(get_db)
):
    """Atajo para convertir un cliente normal en dueño de un establecimiento."""
    # 1. Buscamos a tu usuario
    usuario = db.query(Usuario).filter(Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    # 2. Le cambiamos el rol
    usuario.rol = "local"

    # 3. Le creamos su local en estado pendiente
    nuevo_local = Establecimiento(
        id=str(uuid.uuid4()),
        nombre=nombre_local,
        propietario_id=usuario_id,
        slug=nombre_local.lower().replace(" ", "-") + "-" + str(uuid.uuid4())[:4],
        activo=False
    )
    
    if hasattr(nuevo_local, 'status'):
        nuevo_local.status = "pendiente"

    db.add(nuevo_local)
    db.commit()
    db.refresh(nuevo_local)
    
    return {
        "mensaje": "¡Ahora eres un local!", 
        "nuevo_rol": usuario.rol,
        "establishment_id": nuevo_local.id
    }

# 1. ENDPOINT PARA EL USUARIO: Enviar la solicitud (Mock)
@router.post("/solicitudes")
def crear_solicitud_negocio(
    usuario_id: str = Body(..., embed=True),
    nombre_negocio: str = Body(..., embed=True),
    db: Session = Depends(get_db)
):
    """Crea una solicitud de establecimiento. Simula la recepción de documentos."""
    
    # Verificamos si ya tiene una solicitud pendiente
    solicitud_existente = db.query(SolicitudEstablecimiento).filter(
        SolicitudEstablecimiento.usuario_id == usuario_id,
        SolicitudEstablecimiento.estado == EstadoSolicitud.PENDIENTE
    ).first()
    
    if solicitud_existente:
        raise HTTPException(status_code=400, detail="Ya tienes una solicitud en proceso.")

    nueva_solicitud = SolicitudEstablecimiento(
        id=str(uuid.uuid4()),
        usuario_id=usuario_id,
        nombre_negocio=nombre_negocio,
        documentos_url="https://mi-servidor.com/archivos/documento_simulado.pdf", # URL Simulada
        estado=EstadoSolicitud.PENDIENTE
    )
    
    db.add(nueva_solicitud)
    db.commit()
    db.refresh(nueva_solicitud)
    
    return {"mensaje": "Solicitud enviada correctamente", "solicitud_id": nueva_solicitud.id}

# 2. ENDPOINT PARA EL ADMIN: Aprobar la solicitud y crear el local automáticamente
@router.patch("/solicitudes/{solicitud_id}/aprobar")
def aprobar_solicitud_negocio(
    solicitud_id: str,
    db: Session = Depends(get_db)
):
    """El administrador aprueba la solicitud. El sistema crea el local y cambia el rol del usuario."""
    solicitud = db.query(SolicitudEstablecimiento).filter(SolicitudEstablecimiento.id == solicitud_id).first()
    
    if not solicitud:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")
    if solicitud.estado != EstadoSolicitud.PENDIENTE:
        raise HTTPException(status_code=400, detail="La solicitud ya fue procesada")

    # 1. Actualizamos la solicitud
    solicitud.estado = EstadoSolicitud.APROBADA

    # 2. Buscamos al usuario y le cambiamos el rol
    usuario = db.query(Usuario).filter(Usuario.id == solicitud.usuario_id).first()
    if usuario:
        usuario.rol = "propietario"

    # 3. Creamos el Establecimiento oficial y activo
    nuevo_local = Establecimiento(
        id=str(uuid.uuid4()),
        propietario_id=usuario.id,
        nombre=solicitud.nombre_negocio,
        slug=solicitud.nombre_negocio.lower().replace(" ", "-") + "-" + str(uuid.uuid4())[:4],
        activo=True
    )
    
    db.add(nuevo_local)
    db.commit()
    
    return {
        "mensaje": "Solicitud aprobada, usuario convertido a propietario y local creado.",
        "establishment_id": nuevo_local.id
    }