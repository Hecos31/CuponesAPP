from datetime import datetime, timedelta
from jose import jwt, JWTError
from app.core.config import settings

ALGORITHM = "HS256"

def generar_token_sello(cuponera_id: str, emisor_id: str, minutos_validez: int = 2) -> str:
    """Genera un token JWT temporal para ser codificado en un QR."""
    expiracion = datetime.utcnow() + timedelta(minutes=minutos_validez)
    payload = {
        "sub": "sello_qr",
        "cup": str(cuponera_id),
        "emi": str(emisor_id),
        "exp": expiracion
    }
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=ALGORITHM)

def decodificar_token_sello(token: str) -> dict:
    """Decodifica y valida la firma y expiración del token JWT."""
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        return None