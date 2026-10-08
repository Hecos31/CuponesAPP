from pydantic import BaseModel, EmailStr
from datetime import datetime

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class UsuarioResponse(BaseModel):
    id: str
    email: str
    rol: str

    class Config:
        from_attributes = True

class LoginResponse(BaseModel):
    mensaje: str
    usuario: UsuarioResponse
    token: str | None = None