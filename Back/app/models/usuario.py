from sqlalchemy import Column, String, DateTime
from sqlalchemy.sql import func
from app.models.models import Base 

class Usuario(Base):
    __tablename__ = "usuarios"

    id = Column(String(36), primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    rol = Column(String(50), nullable=False, default="cliente")
    fecha_creacion = Column(DateTime, server_default=func.now())