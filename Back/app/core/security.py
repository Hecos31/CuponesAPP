from datetime import datetime, timedelta, timezone
from jose import jwt, JWTError
from app.core.config import settings
import bcrypt

ALGORITHM = "HS256"

# Hashing con bcrypt directo (passlib es incompatible con bcrypt >= 4.1)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verifica si la contraseña ingresada coincide con el hash o texto plano."""
    if plain_password == hashed_password:
        return True
    try:
        return bcrypt.checkpw(
            plain_password.encode("utf-8")[:72],
            hashed_password.encode("utf-8"),
        )
    except Exception:
        return False

def hash_password(password: str) -> str:
    """Genera el hash bcrypt para guardar contraseñas nuevas."""
    return bcrypt.hashpw(password.encode("utf-8")[:72], bcrypt.gensalt()).decode("utf-8")

def get_password_hash(password: str) -> str:
    return hash_password(password)

def generar_token_acceso(usuario_id: str, minutos_validez: int = 60 * 24 * 7) -> str:
    """Genera el token de sesión para la app móvil (por defecto 7 días)."""
    expiracion = datetime.now(timezone.utc) + timedelta(minutes=minutos_validez)
    payload = {
        "sub": str(usuario_id),
        "type": "access_token",
        "exp": expiracion
    }
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=ALGORITHM)

def generar_token_cliente(usuario_id: str, minutos_validez: int = 5) -> str:
    """Genera un token JWT temporal para operaciones rápidas o canjes QR."""
    expiracion = datetime.now(timezone.utc) + timedelta(minutes=minutos_validez)
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

###############
def generar_token_recuperacion(
    usuario_id: str,
    minutos_validez: int = 15
) -> str:

    expiracion = datetime.utcnow() + timedelta(
        minutes=minutos_validez
    )

    payload = {
        "sub": "recuperacion_password",
        "usr": str(usuario_id),
        "exp": expiracion
    }

    return jwt.encode(
        payload,
        settings.SECRET_KEY,
        algorithm=ALGORITHM
    )


def decodificar_token_recuperacion(
    token: str
) -> dict | None:

    try:

        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=[ALGORITHM]
        )

        if payload.get("sub") != "recuperacion_password":
            return None

        return payload

    except JWTError:
        return None


def generar_password_hash(password: str) -> str:

    password_bytes = password.encode("utf-8")

    salt = bcrypt.gensalt()

    hashed = bcrypt.hashpw(
        password_bytes,
        salt
    )

    return hashed.decode("utf-8")
