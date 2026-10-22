from pydantic import BaseModel, EmailStr , Field , field_validator
from datetime import datetime
from typing import Optional, List, Dict, Optional , Any


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

########Diseños SVG
class DisenoCuponeraUpdate(BaseModel):
    configuracion_ui: Dict[str, Any] = Field(default_factory=dict)
    svg_markup: Optional[str] = None
    eliminar_svg: bool = False

    @field_validator("configuracion_ui")
    @classmethod
    def validar_configuracion(cls, valor: Dict[str, Any]) -> Dict[str, Any]:
        # Ahora los SVG viajan dentro de los elementos, por eso el límite es mayor (~10 MB).
        if len(str(valor)) > 10_000_000:
            raise ValueError("La configuración del diseño es demasiado grande.")
        return valor


class DisenoCuponeraResponse(BaseModel):
    cuponera_id: str
    configuracion_ui: Dict[str, Any] = Field(default_factory=dict)
    svg_markup: Optional[str] = None
    actualizado: bool = True

DisenoCuponeraUpdate.model_rebuild()
DisenoCuponeraResponse.model_rebuild()