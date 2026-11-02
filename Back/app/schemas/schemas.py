from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional, List 


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


# --- Solicitudes y Establecimientos (Sprint 3) ---

class SolicitudEstablecimientoBase(BaseModel):
    nombre_negocio: str
    documentos_url: Optional[str] = None

class SolicitudEstablecimientoCreate(SolicitudEstablecimientoBase):
    usuario_id: str

class SolicitudEstablecimientoUpdateEstado(BaseModel):
    estado: str  # PENDIENTE, APROBADA, RECHAZADA

class SolicitudEstablecimientoResponse(SolicitudEstablecimientoBase):
    id: str
    usuario_id: str
    estado: str
    fecha_solicitud: datetime

    class Config:
        from_attributes = True


class EstablecimientoBase(BaseModel):
    nombre: str
    logo_url: Optional[str] = None
    activo: bool = True

class EstablecimientoCreate(EstablecimientoBase):
    propietario_id: str
    slug: Optional[str] = None

class EstablecimientoUpdate(BaseModel):
    nombre: Optional[str] = None
    logo_url: Optional[str] = None
    activo: Optional[bool] = None

class EstablecimientoResponse(EstablecimientoBase):
    id: str
    propietario_id: str
    slug: str
    fecha_creacion: datetime

    class Config:
        from_attributes = True

class UploadDocumentoResponse(BaseModel):
    url: str
    filename: str
    tipo_documento: str = "INE"
    tamano_bytes: int = 0
    mensaje: str = "Documento probatorio almacenado de forma segura"
