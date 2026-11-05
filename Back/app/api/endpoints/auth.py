from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Any
from app.api.dependencies import get_db
from app.models.models import Usuario, RolUsuario
from app.schemas.schemas import UsuarioCreate, UsuarioResponse
from app.core.security import get_password_hash

from app.schemas.auth import LoginRequest, LoginResponse
from app.core.security import verify_password, generar_token_acceso

router = APIRouter()

ADMIN_EXCLUSIVE_EMAILS = {
    "admin@zello.com",
    "admin@cupones.com",
    "administrador@zello.com",
}


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

    rol_inicial = (
        RolUsuario.ADMIN.value
        if user_in.email.strip().lower() in ADMIN_EXCLUSIVE_EMAILS
        else RolUsuario.CLIENTE.value
    )

    user_obj = Usuario(
        email=user_in.email,
        password_hash=get_password_hash(user_in.password),
        rol=rol_inicial
    )
    db.add(user_obj)
    db.commit()
    db.refresh(user_obj)
    return user_obj


@router.post("/login", response_model=LoginResponse)
def login(datos: LoginRequest, db: Session = Depends(get_db)):
    email_clean = datos.email.strip().lower()
    usuario = db.query(Usuario).filter(Usuario.email == datos.email).first()

    # Auto-aprovisionamiento del usuario administrador exclusivo si aún no existe en la BD
    if not usuario and email_clean in ADMIN_EXCLUSIVE_EMAILS:
        usuario = Usuario(
            email=email_clean,
            password_hash=get_password_hash(datos.password),
            rol=RolUsuario.ADMIN.value,
        )
        db.add(usuario)
        db.commit()
        db.refresh(usuario)

    if not usuario or not verify_password(datos.password, usuario.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Correo o contraseña incorrectos",
        )

    # Asegurar que el correo exclusivo de administrador tenga siempre el rol 'admin'
    if email_clean in ADMIN_EXCLUSIVE_EMAILS and usuario.rol != RolUsuario.ADMIN.value:
        usuario.rol = RolUsuario.ADMIN.value
        db.commit()
        db.refresh(usuario)

    # Generamos el JWT de autenticación para la app móvil
    token = generar_token_acceso(usuario_id=usuario.id)

    return LoginResponse(
        mensaje="Inicio de sesión exitoso",
        usuario=usuario,
        token=token,
    )
