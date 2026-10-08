from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Any
from app.api.dependencies import get_db
from app.models.models import Usuario, RolUsuario
from app.schemas.schemas import UsuarioCreate, UsuarioResponse
from app.core.security import get_password_hash

router = APIRouter()

@router.post("/register", response_model=UsuarioResponse, status_code=status.HTTP_201_CREATED)
def register_user(
    user_in: UsuarioCreate,
    db: Session = Depends(get_db)
) -> Any:
    """
    Registra un nuevo usuario.
    """
    user = db.query(Usuario).filter(Usuario.email == user_in.email).first()
    if user:
        raise HTTPException(
            status_code=400,
            detail="El email ya está registrado en el sistema."
        )
    
    user_obj = Usuario(
        email=user_in.email,
        password_hash=get_password_hash(user_in.password),
        rol=RolUsuario.CLIENTE
    )
    db.add(user_obj)
    db.commit()
    db.refresh(user_obj)
    return user_obj
