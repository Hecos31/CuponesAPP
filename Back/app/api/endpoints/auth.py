from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.api.dependencies import get_db
from app.models.models import Usuario
from app.schemas.auth import LoginRequest, LoginResponse
from app.core.security import verify_password, generar_token_acceso

router = APIRouter()

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
        token=token,
    )