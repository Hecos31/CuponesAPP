from pydantic import BaseModel, UUID4
from datetime import datetime

class TokenQRResponse(BaseModel):
    token: str
    expira_en_segundos: int

class EscaneoQRRequest(BaseModel):
    token: str
    usuario_id: UUID4 

class SelloResponse(BaseModel):
    progreso_id: UUID4
    sellos_acumulados: int
    estado: str
    fecha_sello: datetime

    class Config:
        from_attributes = True