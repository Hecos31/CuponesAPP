from pydantic import BaseModel
from typing import Optional

class EstablishmentValidate(BaseModel):
    # Puede recibir: 'aprobado', 'rechazado', o 'pendiente'
    status: str 
    # Opcional: Para que el admin deje un comentario (ej. "Faltan documentos")
    admin_notes: Optional[str] = None