from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, Request, Query
from sqlalchemy.orm import Session

from app.api.dependencies import get_db
from app.models.models import Usuario, Establecimiento, SolicitudEstablecimiento, EstadoSolicitud
from app.schemas import schemas
from app.core import security


router = APIRouter()


# --- NUEVO ENDPOINT: OBTENER ESTADO DEL USUARIO ACTUAL (/me) ---

@router.get("/me")
def get_current_user_status(
    request: Request,
    usuario_id: Optional[str] = Query(None, description="ID del usuario si se envía por query"),
    db: Session = Depends(get_db)
):
    """Devuelve el perfil del usuario logueado y el estado de su local o solicitud (`establishment_status`)."""
    usuario = None

    # 1. Intentar obtener usuario desde el header Authorization: Bearer <token>
    auth_header = request.headers.get("Authorization")
    if auth_header and auth_header.startswith("Bearer "):
        token_str = auth_header.replace("Bearer ", "").strip()
        if token_str and token_str != "null":
            payload = security.decodificar_token_cliente(token_str)
            if payload:
                uid_from_token = payload.get("sub") or payload.get("usr")
                if uid_from_token:
                    usuario = db.query(Usuario).filter(Usuario.id == uid_from_token).first()

    # 2. Si no vino en token, intentar por query param usuario_id
    if not usuario and usuario_id:
        usuario = db.query(Usuario).filter(Usuario.id == usuario_id).first()

    # 3. Fallback de compatibilidad si se prueba sin token ni query param
    if not usuario:
        usuario = db.query(Usuario).filter(Usuario.email == "4@gmail.com").first()
    if not usuario:
        usuario = db.query(Usuario).first()

    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado"
        )

    estado_local = "cliente"

    local = db.query(Establecimiento).filter(Establecimiento.propietario_id == usuario.id).first()
    ultima_solicitud = (
        db.query(SolicitudEstablecimiento)
        .filter(SolicitudEstablecimiento.usuario_id == usuario.id)
        .order_by(SolicitudEstablecimiento.fecha_solicitud.desc())
        .first()
    )

    if local and local.activo:
        estado_local = "aprobado"
    elif ultima_solicitud:
        if ultima_solicitud.estado == EstadoSolicitud.APROBADA:
            estado_local = "aprobado"
        elif ultima_solicitud.estado == EstadoSolicitud.RECHAZADA:
            estado_local = "rechazado"
        else:
            estado_local = "pendiente"
    elif local and not local.activo:
        estado_local = "pendiente"

    return {
        "id": usuario.id,
        "email": usuario.email,
        "rol": usuario.rol.value if hasattr(usuario.rol, "value") else str(usuario.rol),
        "establishment_status": estado_local,
        "solicitud_id": ultima_solicitud.id if ultima_solicitud else None,
        "establishment_id": local.id if local else None,
    }


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