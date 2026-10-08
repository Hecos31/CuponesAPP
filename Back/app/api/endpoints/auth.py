from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Any
from app.api.dependencies import get_db
from app.models.models import Usuario, RolUsuario
from app.schemas.schemas import UsuarioCreate, UsuarioResponse
from app.core.security import get_password_hash

from app.api.dependencies import get_db
from app.schemas.auth import LoginRequest, LoginResponse
from app.core.security import verify_password, generar_token_acceso

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


@router.post("/login", response_model=LoginResponse)
def login(datos: LoginRequest, db: Session = Depends(get_db)):
    usuario = db.query(Usuario).filter(Usuario.email == datos.email).first()

    if not usuario or not verify_password(datos.password, usuario.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Correo o contraseña incorrectos",
        )

    # Generamos el JWT de autenticación para la app móvil
    token = generar_token_acceso(usuario_id=usuario.id)

    return LoginResponse(
        mensaje="Inicio de sesión exitoso",
        usuario=usuario,
        token=token,)