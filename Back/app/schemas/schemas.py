from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional, List, Dict, Any

# ==========================================
# 1. USUARIOS & AUTENTICACIÓN
# ==========================================
class UsuarioBase(BaseModel):
    email: EmailStr

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

class UsuarioPerfilResponse(BaseModel):
    id: str
    email: EmailStr
    rol: str
    fecha_creacion: datetime

    class Config:
        from_attributes = True

class ActualizarPerfilRequest(BaseModel):
    email: Optional[EmailStr] = None

class RecuperarPasswordRequest(BaseModel):
    email: EmailStr

class RecuperarPasswordResponse(BaseModel):
    mensaje: str
    token: str
    expira_en_segundos: int

class RestablecerPasswordRequest(BaseModel):
    token: str
    nueva_password: str


# ==========================================
# 2. SOLICITUDES & ESTABLECIMIENTOS
# ==========================================
class CrearSolicitudRequest(BaseModel):
    usuario_id: str
    nombre_negocio: str
    documentos_url: Optional[str] = None
    direccion: Optional[str] = None
    nombre_solicitante: Optional[str] = None
    tipo_solicitud: Optional[str] = "ALTA_SUCURSAL"  # ALTA_SUCURSAL | CAMBIO_NOMBRE
    establecimiento_id: Optional[str] = None
    nombre_anterior: Optional[str] = None

class SolicitudResponse(BaseModel):
    id: str
    usuario_id: str
    nombre_negocio: str
    documentos_url: Optional[str] = None
    estado: str
    fecha_solicitud: datetime
    usuario_email: Optional[str] = None
    direccion: Optional[str] = None
    nombre_solicitante: Optional[str] = None
    comentarios_evaluacion: Optional[str] = None
    fecha_evaluacion: Optional[str] = None
    tipo_solicitud: Optional[str] = "ALTA_SUCURSAL"
    establecimiento_id: Optional[str] = None
    nombre_anterior: Optional[str] = None

    class Config:
        from_attributes = True

class EstablecimientoResponse(BaseModel):
    id: str
    propietario_id: str
    nombre: str
    slug: str
    logo_url: Optional[str] = None
    activo: bool
    fecha_creacion: datetime
    requiere_aprobacion_nombre: bool = False
    solicitud_id: Optional[str] = None
    mensaje: Optional[str] = None

    class Config:
        from_attributes = True

class EstadoSucursalResponse(BaseModel):
    tiene_sucursal: bool
    rol: str
    establecimiento: Optional[EstablecimientoResponse] = None
    cuponera_id: Optional[str] = None
    tiene_solicitud: bool = False
    solicitud_id: Optional[str] = None
    estado_solicitud: Optional[str] = None
    nombre_negocio_solicitud: Optional[str] = None
    tipo_solicitud: Optional[str] = None
    comentarios_evaluacion: Optional[str] = None

class ConvertirLocalRequest(BaseModel):
    nombre_local: str

class SimularAltaSucursalResponse(BaseModel):
    mensaje: str
    establecimiento_id: str
    cuponera_id: str

class SolicitudEstablecimientoUpdateEstado(BaseModel):
    estado: str  # PENDIENTE, APROBADA, RECHAZADA
    comentarios_evaluacion: Optional[str] = None

class UploadDocumentoResponse(BaseModel):
    url: str
    filename: str
    tipo_documento: str = "INE"
    tamano_bytes: int = 0
    mensaje: str = "Documento probatorio almacenado de forma segura"

class EstablecimientoCreate(BaseModel):
    propietario_id: str
    nombre: str
    slug: Optional[str] = None
    logo_url: Optional[str] = None
    activo: bool = True

class EstablecimientoUpdate(BaseModel):
    nombre: Optional[str] = None
    logo_url: Optional[str] = None
    activo: Optional[bool] = None


# ==========================================
# 3. CUPONERAS & DISEÑO (SERVER-DRIVEN UI)
# ==========================================
class CuponeraBase(BaseModel):
    titulo: str
    descripcion_premio: str
    total_sellos_requeridos: int = 6
    activa: bool = True

class CuponeraListResponse(CuponeraBase):
    id: str
    establecimiento_id: str
    establecimiento_nombre: str
    establecimiento_logo: Optional[str] = None
    fecha_creacion: datetime
    fecha_expiracion: Optional[datetime] = None
    premios_intermedios: Optional[str] = None
    configuracion_ui: Optional[Any] = None

    class Config:
        from_attributes = True

class GuardarDisenoRequest(BaseModel):
    total_visitas: Optional[int] = None
    premios_intermedios: Optional[str] = None
    diseno_json: Dict[str, Any]


# ==========================================
# 4. PROGRESO DE CLIENTES & SUSCRIPCIONES
# ==========================================
class UnirseCuponeraResponse(BaseModel):
    progreso_id: str
    cuponera_id: str
    sellos_acumulados: int
    estado: str
    mensaje: str

class MisSuscripcionesResponse(BaseModel):
    progreso_id: str
    cuponera_id: str
    titulo_cuponera: str
    descripcion_premio: str
    establecimiento_nombre: str
    establecimiento_logo: Optional[str] = None
    sellos_acumulados: int
    total_sellos_requeridos: int
    estado: str
    configuracion_ui: Optional[Any] = None

    class Config:
        from_attributes = True


# ==========================================
# 5. RESPUESTAS GENERALES & QR
# ==========================================
class MensajeResponse(BaseModel):
    mensaje: str

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
