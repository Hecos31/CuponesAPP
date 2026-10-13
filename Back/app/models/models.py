import enum
import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Boolean, DateTime, ForeignKey, Enum, Text, JSON
from sqlalchemy.orm import relationship
from app.db.session import Base

def generate_uuid():
    return str(uuid.uuid4())

class RolUsuario(str, enum.Enum):
    ADMIN = "admin"
    PROPIETARIO = "propietario"
    CLIENTE = "cliente"

class EstadoSolicitud(str, enum.Enum):
    PENDIENTE = "PENDIENTE"
    APROBADA = "APROBADA"
    RECHAZADA = "RECHAZADA"

class EstadoProgreso(str, enum.Enum):
    ACTIVO = "ACTIVO"
    COMPLETADO = "COMPLETADO"
    CANJEADO = "CANJEADO"

class MetodoSello(str, enum.Enum):
    QR = "QR"
    NFC = "NFC"
    MANUAL = "MANUAL"

class Usuario(Base):
    __tablename__ = "usuarios"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    rol = Column(Enum(RolUsuario, values_callable=lambda obj: [e.value for e in obj]), nullable=False, default=RolUsuario.CLIENTE)
    fecha_creacion = Column(DateTime, default=datetime.utcnow, nullable=False)

    establecimientos = relationship("Establecimiento", back_populates="propietario")
    progresos = relationship("ProgresoUsuario", back_populates="usuario")
    solicitudes = relationship("SolicitudEstablecimiento", back_populates="usuario")


class Establecimiento(Base):
    __tablename__ = "establecimientos"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    propietario_id = Column(String(36), ForeignKey("usuarios.id"), nullable=False)
    nombre = Column(String(255), nullable=False)
    slug = Column(String(255), unique=True, nullable=False, index=True)
    logo_url = Column(String(500), nullable=True)
    activo = Column(Boolean, default=True, nullable=False)
    fecha_creacion = Column(DateTime, default=datetime.utcnow, nullable=False)
    propietario = relationship("Usuario", back_populates="establecimientos")
    cuponeras = relationship("Cuponera", back_populates="establecimiento")
    #..Establecmiientos Ale#..
    __tablename__ = "establishments"
    
    status = Column(String(20), default="pendiente")
    admin_notes = Column(Text, nullable=True)


class SolicitudEstablecimiento(Base):
    __tablename__ = "solicitudes_establecimientos"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    usuario_id = Column(String(36), ForeignKey("usuarios.id"), nullable=False)
    nombre_negocio = Column(String(255), nullable=False)
    documentos_url = Column(String(500), nullable=True)
    estado = Column(Enum(EstadoSolicitud, values_callable=lambda obj: [e.value for e in obj]), default=EstadoSolicitud.PENDIENTE, nullable=False)
    fecha_solicitud = Column(DateTime, default=datetime.utcnow, nullable=False)

    usuario = relationship("Usuario", back_populates="solicitudes")


class Cuponera(Base):
    __tablename__ = "cuponeras"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    establecimiento_id = Column(String(36), ForeignKey("establecimientos.id"), nullable=False)
    titulo = Column(String(255), nullable=False)
    descripcion_premio = Column(Text, nullable=False)
    total_sellos_requeridos = Column(Integer, nullable=False)
    fecha_expiracion = Column(DateTime, nullable=True)
    activa = Column(Boolean, default=True, nullable=False)
    fecha_creacion = Column(DateTime, default=datetime.utcnow, nullable=False)

    establecimiento = relationship("Establecimiento", back_populates="cuponeras")
    diseno = relationship("DisenoCuponera", back_populates="cuponera", uselist=False)
    progresos = relationship("ProgresoUsuario", back_populates="cuponera")


class DisenoCuponera(Base):
    __tablename__ = "disenos_cuponera"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    cuponera_id = Column(String(36), ForeignKey("cuponeras.id"), nullable=False, unique=True)
    imagen_fondo_url = Column(String(500), nullable=True)
    icono_sello_url = Column(String(500), nullable=True)
    icono_sello_inactivo = Column(String(500), nullable=True)
    configuracion_ui = Column(JSON, nullable=True)

    cuponera = relationship("Cuponera", back_populates="diseno")


class ProgresoUsuario(Base):
    __tablename__ = "progreso_usuarios"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    usuario_id = Column(String(36), ForeignKey("usuarios.id"), nullable=False)
    cuponera_id = Column(String(36), ForeignKey("cuponeras.id"), nullable=False)
    sellos_acumulados = Column(Integer, default=0, nullable=False)
    estado = Column(Enum(EstadoProgreso, values_callable=lambda obj: [e.value for e in obj]), default=EstadoProgreso.ACTIVO, nullable=False)
    fecha_creacion = Column(DateTime, default=datetime.utcnow, nullable=False)
    fecha_actualizacion = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    usuario = relationship("Usuario", back_populates="progresos")
    cuponera = relationship("Cuponera", back_populates="progresos")
    registros_sellos = relationship("RegistroSello", back_populates="progreso")


class RegistroSello(Base):
    __tablename__ = "registro_sellos"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    progreso_id = Column(String(36), ForeignKey("progreso_usuarios.id"), nullable=False)
    sellado_por = Column(String(36), ForeignKey("usuarios.id"), nullable=False)
    metodo = Column(Enum(MetodoSello, values_callable=lambda obj: [e.value for e in obj]), nullable=False)
    fecha_sello = Column(DateTime, default=datetime.utcnow, nullable=False)

    progreso = relationship("ProgresoUsuario", back_populates="registros_sellos")
    emisor = relationship("Usuario")