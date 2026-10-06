from pydantic import BaseModel, UUID4
from datetime import datetime
from typing import List, Optional

class TokenQRResponse(BaseModel):
    token: str
    expira_en_segundos: int

class OtorgarSelloRequest(BaseModel):
    token_cliente: str
    cuponera_id: UUID4
    emisor_id: UUID4

class SelloResponse(BaseModel):
    progreso_id: UUID4
    sellos_acumulados: int
    estado: str
    fecha_sello: datetime

    class Config:
        from_attributes = True

class DisenoCuponeraResponse(BaseModel):
    imagen_fondo_url: Optional[str]
    icono_sello_url: Optional[str]
    icono_sello_inactivo: Optional[str]
    configuracion_ui: Optional[dict]

    class Config:
        from_attributes = True

class CuponeraListResponse(BaseModel):
    id: UUID4
    titulo: str
    descripcion_premio: str
    total_sellos_requeridos: int
    fecha_expiracion: Optional[datetime]
    establecimiento_nombre: str
    diseno: Optional[DisenoCuponeraResponse]

    class Config:
        from_attributes = True

