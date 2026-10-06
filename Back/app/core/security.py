from datetime import datetime, timedelta
from jose import jwt, JWTError
from app.core.config import settings

ALGORITHM = "HS256"

def generar_token_cliente(usuario_id: str, minutos_validez: int = 5) -> str:
    """Genera un token JWT codificado con el identificador del usuario y tiempo de expiración."""
    expiracion = datetime.utcnow() + timedelta(minutes=minutos_validez)
    payload = {
        "sub": "identidad_cliente",
        "usr": str(usuario_id),
        "exp": expiracion
    }
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=ALGORITHM)

def decodificar_token_cliente(token: str) -> dict | None:
    """Decodifica el token JWT y valida su firma y tiempo de vigencia."""
    try:
        return jwt.decode(token, settings.SECRET_KEY, algorithms=[ALGORITHM])
    except JWTError:
        return None