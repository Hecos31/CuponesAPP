from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional, List, Dict, Any


class CuponeraBase(BaseModel):
    titulo: str
    descripcion_premio: str
    total_sellos_requeridos: int
    activa: bool = True

class CuponeraListResponse(CuponeraBase):
    id: str
    establecimiento_id: str
    fecha_creacion: datetime
    fecha_expiracion: Optional[datetime] = None
    
    # 👇 AÑADIMOS ESTOS DOS CAMPOS PARA QUE VIAJEN A FLUTTER 👇
    premios_intermedios: Optional[str] = None
    configuracion_ui: Optional[Any] = None

    class Config:
        from_attributes = True


class TokenQRResponse(BaseModel):
    token: str
    expira_en_segundos: int

class OtorgarSelloRequest(BaseModel):
    token_cliente: str
    cuponera_id: str
    emisor_id: str

class SelloResponse(BaseModel):
    progreso_id: str
    sellos_acumulados: int
    estado: str
    fecha_sello: datetime

    class Config:
        from_attributes = True

class UsuarioBase(BaseModel):
    email: str

class UsuarioCreate(UsuarioBase):
    password: str

class UsuarioResponse(UsuarioBase):
    id: str
    rol: str
    fecha_creacion: datetime

    class Config:
        from_attributes = True

class UsuarioLogin(UsuarioBase):
    password: str

########################
class RecuperarPasswordRequest(BaseModel):
    email: EmailStr


class RecuperarPasswordResponse(BaseModel):
    mensaje: str
    token: str
    expira_en_segundos: int


class RestablecerPasswordRequest(BaseModel):
    token: str
    nueva_password: str


class MensajeResponse(BaseModel):
    mensaje: str


class UsuarioPerfilResponse(BaseModel):
    id: str
    email: EmailStr
    rol: str
    fecha_creacion: datetime

    class Config:
        from_attributes = True


class ActualizarPerfilRequest(BaseModel):
    email: Optional[EmailStr] = None

class SimularAltaSucursalResponse(BaseModel):
    mensaje: str
    establecimiento_id: str
    cuponera_id: str

class GuardarDisenoRequest(BaseModel):
    total_visitas: Optional[int] = None
    premios_intermedios: Optional[str] = None
    diseno_json: Dict[str, Any]