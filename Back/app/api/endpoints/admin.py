from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.session import SessionLocal

# Importa tus modelos y esquemas (ajusta los nombres según tu proyecto)
# from app.models.establishment import Establishment
# from app.schemas.establishment import EstablishmentValidate

router = APIRouter()

# Dependencia para obtener la sesión de la base de datos
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.patch("/establishments/{establishment_id}/validate")
def validate_establishment(
    establishment_id: int,
    validation_data: EstablishmentValidate, # Aquí usa el esquema que creaste
    db: Session = Depends(get_db)
    # Nota: Aquí deberías agregar tu dependencia de seguridad para verificar que el usuario es Admin
    # ej: current_user = Depends(get_current_active_admin)
):
    # 1. Buscar el local en la base de datos
    establishment = db.query(Establishment).filter(Establishment.id == establishment_id).first()
    
    if not establishment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail="Establecimiento no encontrado"
        )
    
    # 2. Actualizar el estado
    valid_statuses = ["aprobado", "rechazado", "pendiente"]
    if validation_data.status not in valid_statuses:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail=f"Estado inválido. Use uno de: {valid_statuses}"
        )

    establishment.status = validation_data.status
    
    if validation_data.admin_notes is not None:
        establishment.admin_notes = validation_data.admin_notes
    
    # 3. Guardar cambios
    db.commit()
    db.refresh(establishment)
    
    return {
        "message": f"Establecimiento actualizado a '{validation_data.status}'",
        "establishment_id": establishment.id,
        "status": establishment.status
    }