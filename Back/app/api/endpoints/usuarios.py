from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.dependencies import get_db
from app.models.models import Usuario
from app.schemas import schemas
from app.core import security


router = APIRouter()


# RECUPERAR CONTRASEÑA

@router.post(
    "/recuperar-password",
    response_model=schemas.RecuperarPasswordResponse
)
def recuperar_password(
    datos: schemas.RecuperarPasswordRequest,
    db: Session = Depends(get_db)
):
    usuario = (
        db.query(Usuario)
        .filter(Usuario.email == datos.email)
        .first()
    )

    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No existe un usuario registrado con ese correo"
        )

    token = security.generar_token_recuperacion(
        usuario_id=usuario.id,
        minutos_validez=15
    )

    return schemas.RecuperarPasswordResponse(
        mensaje="Token de recuperación generado correctamente",
        token=token,
        expira_en_segundos=900
    )


# RESTABLECER CONTRASEÑA

@router.post(
    "/restablecer-password",
    response_model=schemas.MensajeResponse
)
def restablecer_password(
    datos: schemas.RestablecerPasswordRequest,
    db: Session = Depends(get_db)
):
    payload = security.decodificar_token_recuperacion(
        datos.token
    )

    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido o expirado"
        )

    usuario_id = payload.get("usr")

    usuario = (
        db.query(Usuario)
        .filter(Usuario.id == usuario_id)
        .first()
    )

    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado"
        )

    usuario.password_hash = security.generar_password_hash(
        datos.nueva_password
    )

    db.commit()

    return schemas.MensajeResponse(
        mensaje="Contraseña actualizada correctamente"
    )


# OBTENER PERFIL

@router.get(
    "/perfil/{usuario_id}",
    response_model=schemas.UsuarioPerfilResponse
)
def obtener_perfil(
    usuario_id: str,
    db: Session = Depends(get_db)
):
    usuario = (
        db.query(Usuario)
        .filter(Usuario.id == usuario_id)
        .first()
    )

    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado"
        )

    return usuario


# ACTUALIZAR PERFIL


@router.put(
    "/perfil/{usuario_id}",
    response_model=schemas.UsuarioPerfilResponse
)
def actualizar_perfil(
    usuario_id: str,
    datos: schemas.ActualizarPerfilRequest,
    db: Session = Depends(get_db)
):
    usuario = (
        db.query(Usuario)
        .filter(Usuario.id == usuario_id)
        .first()
    )

    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado"
        )

    if datos.email is not None:

        correo_existente = (
            db.query(Usuario)
            .filter(
                Usuario.email == datos.email,
                Usuario.id != usuario_id
            )
            .first()
        )

        if correo_existente:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="El correo electrónico ya está registrado"
            )

        usuario.email = datos.email

    db.commit()
    db.refresh(usuario)

    return usuario