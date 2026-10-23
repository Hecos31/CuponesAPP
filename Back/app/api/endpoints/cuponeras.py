from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List
from app.api.dependencies import get_db
from app.schemas import schemas
from app.models import models
from app.models.models import Cuponera, Establecimiento
from app.schemas.schemas import CuponeraListResponse
from fastapi import APIRouter, Depends, HTTPException

router = APIRouter()

@router.get("/", response_model=List[schemas.CuponeraListResponse])
def listar_cuponeras(skip: int = 0, limit: int = 20, db: Session = Depends(get_db)):
    """Obtiene una lista paginada de cuponeras activas incluyendo datos relacionales del establecimiento y su diseño."""
    
    # Consulta las cuponeras activas y precarga las relaciones necesarias para evitar el problema de consultas N+1
    cuponeras = (
        db.query(models.Cuponera)
        .filter(models.Cuponera.activa == True)
        .offset(skip)
        .limit(limit)
        .all()
    )

    # Construye la respuesta adaptando los modelos de base de datos al esquema Pydantic esperado por el cliente
    resultados = []
    for cuponera in cuponeras:
        resultados.append({
            "id": cuponera.id,
            "titulo": cuponera.titulo,
            "descripcion_premio": cuponera.descripcion_premio,
            "total_sellos_requeridos": cuponera.total_sellos_requeridos,
            "fecha_expiracion": cuponera.fecha_expiracion,
            "establecimiento_nombre": cuponera.establecimiento.nombre,
            "diseno": cuponera.diseno
        })

    return resultados


@router.put("/{cuponera_id}/diseno", response_model=schemas.MensajeResponse)
def guardar_diseno_cuponera(
    cuponera_id: str,
    datos: schemas.GuardarDisenoRequest,
    db: Session = Depends(get_db)
):
    cuponera = db.query(models.Cuponera).filter(models.Cuponera.id == cuponera_id).first()
    
    if not cuponera:
        raise HTTPException(status_code=404, detail="Cuponera no encontrada")
        
    # Actualizamos la configuración lógica si fue modificada en el editor
    if datos.total_visitas is not None:
        cuponera.total_sellos_requeridos = datos.total_visitas
        
    # (Nota: Recuerda añadir la columna `premios_intermedios` a la clase Cuponera en models.py si aún no lo has hecho)
    if hasattr(cuponera, 'premios_intermedios') and datos.premios_intermedios is not None:
        cuponera.premios_intermedios = datos.premios_intermedios

    # Guardamos el diseño JSON visual
    if cuponera.diseno:
        cuponera.diseno.configuracion_ui = datos.diseno_json
    else:
        # Por seguridad, si por alguna razón no se generó el diseño en el alta, lo creamos
        nuevo_diseno = models.DisenoCuponera(
            cuponera_id=cuponera.id,
            configuracion_ui=datos.diseno_json
        )
        db.add(nuevo_diseno)
        
    db.commit()
    
    return schemas.MensajeResponse(mensaje="Diseño de cuponera guardado correctamente")

@router.get("/{cuponera_id}", response_model=schemas.CuponeraListResponse)
def obtener_cuponera(cuponera_id: str, db: Session = Depends(get_db)):
    cuponera = db.query(models.Cuponera).filter(models.Cuponera.id == cuponera_id).first()
    
    if not cuponera:
        raise HTTPException(status_code=404, detail="Cuponera no encontrada")
    
    # Extraemos el JSON de la tabla relacionada de forma segura
    diseno_json = cuponera.diseno.configuracion_ui if cuponera.diseno else None

    # Mapeamos los datos para que coincidan exactamente con lo que espera Flutter
    return {
        "id": cuponera.id,
        "establecimiento_id": cuponera.establecimiento_id,
        "titulo": cuponera.titulo,
        "descripcion_premio": cuponera.descripcion_premio,
        "total_sellos_requeridos": cuponera.total_sellos_requeridos,
        "premios_intermedios": cuponera.premios_intermedios,
        "fecha_expiracion": cuponera.fecha_expiracion,
        "activa": cuponera.activa,
        "fecha_creacion": cuponera.fecha_creacion,
        "configuracion_ui": diseno_json
    }