from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import uuid

from app.api.dependencies import get_db
from app.models import models
from app.schemas import schemas

router = APIRouter()

@router.get("/", response_model=List[schemas.CuponeraListResponse])
def listar_cuponeras(skip: int = 0, limit: int = 20, usuario_id: str = None, db: Session = Depends(get_db)):
    """Obtiene el catálogo público de cuponeras activas excluyendo las que el usuario ya tiene suscritas."""
    
    # Subconsulta con los IDs de cuponeras a las que el usuario ya está suscrito
    cuponeras_excluidas = []
    if usuario_id:
        suscripciones = db.query(models.ProgresoUsuario.cuponera_id).filter(
            models.ProgresoUsuario.usuario_id == usuario_id
        ).all()
        cuponeras_excluidas = [s[0] for s in suscripciones]

    query = db.query(models.Cuponera).filter(models.Cuponera.activa == True)
    
    if cuponeras_excluidas:
        query = query.filter(~models.Cuponera.id.in_(cuponeras_excluidas))

    cuponeras = query.offset(skip).limit(limit).all()

    resultados = []
    for c in cuponeras:
        diseno_json = c.diseno.configuracion_ui if c.diseno else None
        resultados.append({
            "id": c.id,
            "establecimiento_id": c.establecimiento_id,
            "establecimiento_nombre": c.establecimiento.nombre if c.establecimiento else "Establecimiento",
            "establecimiento_logo": c.establecimiento.logo_url if c.establecimiento else None,
            "titulo": c.titulo,
            "descripcion_premio": c.descripcion_premio,
            "total_sellos_requeridos": c.total_sellos_requeridos,
            "premios_intermedios": getattr(c, 'premios_intermedios', None),
            "fecha_expiracion": c.fecha_expiracion,
            "activa": c.activa,
            "fecha_creacion": c.fecha_creacion,
            "configuracion_ui": diseno_json
        })

    return resultados

@router.get("/{cuponera_id}", response_model=schemas.CuponeraListResponse)
def obtener_cuponera(cuponera_id: str, db: Session = Depends(get_db)):
    """Obtiene el detalle completo de una cuponera específica para el editor o la vista detallada."""
    cuponera = db.query(models.Cuponera).filter(models.Cuponera.id == cuponera_id).first()
    
    if not cuponera:
        raise HTTPException(status_code=404, detail="Cuponera no encontrada")
    
    diseno_json = cuponera.diseno.configuracion_ui if cuponera.diseno else None

    return {
        "id": cuponera.id,
        "establecimiento_id": cuponera.establecimiento_id,
        "establecimiento_nombre": cuponera.establecimiento.nombre if cuponera.establecimiento else "Establecimiento",
        "establecimiento_logo": cuponera.establecimiento.logo_url if cuponera.establecimiento else None,
        "titulo": cuponera.titulo,
        "descripcion_premio": cuponera.descripcion_premio,
        "total_sellos_requeridos": cuponera.total_sellos_requeridos,
        "premios_intermedios": getattr(cuponera, 'premios_intermedios', None),
        "fecha_expiracion": cuponera.fecha_expiracion,
        "activa": cuponera.activa,
        "fecha_creacion": cuponera.fecha_creacion,
        "configuracion_ui": diseno_json
    }


@router.put("/{cuponera_id}/diseno", response_model=schemas.MensajeResponse)
def guardar_diseno_cuponera(
    cuponera_id: str,
    datos: schemas.GuardarDisenoRequest,
    db: Session = Depends(get_db)
):
    """Guarda el diseño JSON personalizado y ajusta reglas lógicas (visitas y premios)."""
    cuponera = db.query(models.Cuponera).filter(models.Cuponera.id == cuponera_id).first()
    
    if not cuponera:
        raise HTTPException(status_code=404, detail="Cuponera no encontrada")
        
    if datos.total_visitas is not None:
        cuponera.total_sellos_requeridos = datos.total_visitas
        
    if hasattr(cuponera, 'premios_intermedios') and datos.premios_intermedios is not None:
        cuponera.premios_intermedios = datos.premios_intermedios

    if cuponera.diseno:
        cuponera.diseno.configuracion_ui = datos.diseno_json
    else:
        nuevo_diseno = models.DisenoCuponera(
            id=str(uuid.uuid4()),
            cuponera_id=cuponera.id,
            configuracion_ui=datos.diseno_json
        )
        db.add(nuevo_diseno)
        
    db.commit()
    return schemas.MensajeResponse(mensaje="Diseño de cuponera guardado correctamente")


@router.post("/{cuponera_id}/unirse", response_model=schemas.UnirseCuponeraResponse)
def unirse_a_cuponera(cuponera_id: str, usuario_id: str, db: Session = Depends(get_db)):
    """Suscripción de un cliente a una cuponera. Crea registro en progreso_usuarios."""
    cuponera = db.query(models.Cuponera).filter(models.Cuponera.id == cuponera_id, models.Cuponera.activa == True).first()
    if not cuponera:
        raise HTTPException(status_code=404, detail="Cuponera no encontrada o inactiva")

    progreso = db.query(models.ProgresoUsuario).filter(
        models.ProgresoUsuario.usuario_id == usuario_id,
        models.ProgresoUsuario.cuponera_id == cuponera_id
    ).first()

    if progreso:
        return schemas.UnirseCuponeraResponse(
            progreso_id=progreso.id,
            cuponera_id=cuponera.id,
            sellos_acumulados=progreso.sellos_acumulados,
            estado=progreso.estado.value if hasattr(progreso.estado, 'value') else str(progreso.estado),
            mensaje="Ya estás suscrito a esta cuponera"
        )

    nuevo_progreso = models.ProgresoUsuario(
        id=str(uuid.uuid4()),
        usuario_id=usuario_id,
        cuponera_id=cuponera_id,
        sellos_acumulados=0,
        estado=models.EstadoProgreso.ACTIVO.value
    )
    db.add(nuevo_progreso)
    db.commit()

    return schemas.UnirseCuponeraResponse(
        progreso_id=nuevo_progreso.id,
        cuponera_id=cuponera_id,
        sellos_acumulados=0,
        estado="ACTIVO",
        mensaje="¡Te has suscrito exitosamente a la cuponera!"
    )


@router.get("/mis-suscripciones/{usuario_id}", response_model=List[schemas.MisSuscripcionesResponse])
def obtener_mis_suscripciones(usuario_id: str, db: Session = Depends(get_db)):
    """Obtiene la lista de cuponeras a las que el cliente está suscrito con sus sellos acumulados."""
    progresos = db.query(models.ProgresoUsuario).filter(models.ProgresoUsuario.usuario_id == usuario_id).all()

    respuesta = []
    for p in progresos:
        if p.cuponera and p.cuponera.activa:
            diseno_json = p.cuponera.diseno.configuracion_ui if p.cuponera.diseno else None
            estado_str = p.estado.value if hasattr(p.estado, 'value') else str(p.estado)
            respuesta.append({
                "progreso_id": p.id,
                "cuponera_id": p.cuponera_id,
                "titulo_cuponera": p.cuponera.titulo,
                "descripcion_premio": p.cuponera.descripcion_premio,
                "establecimiento_nombre": p.cuponera.establecimiento.nombre if p.cuponera.establecimiento else "Establecimiento",
                "establecimiento_logo": p.cuponera.establecimiento.logo_url if p.cuponera.establecimiento else None,
                "sellos_acumulados": p.sellos_acumulados,
                "total_sellos_requeridos": p.cuponera.total_sellos_requeridos,
                "estado": estado_str,
                "configuracion_ui": diseno_json
            })

    return respuesta


