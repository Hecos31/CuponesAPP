from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List
from app.api.dependencies import get_db
from app.schemas import schemas
from app.models import models

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