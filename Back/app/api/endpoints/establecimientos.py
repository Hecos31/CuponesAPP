from datetime import datetime
import re
import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.api.dependencies import get_db
from app.models.models import (
    Establecimiento,
    Usuario,
    RolUsuario,
    Cuponera,
    DisenoCuponera,
    SolicitudEstablecimiento,
    EstadoSolicitud,
)
from app.schemas.schemas import (
    EstablecimientoCreate,
    EstablecimientoUpdate,
    EstablecimientoResponse,
    EstadoSucursalResponse,
    CrearSolicitudRequest,
    MensajeResponse,
)

router = APIRouter()


def slugify(text: str) -> str:
    slug = text.lower().strip()
    slug = re.sub(r"[^\w\s-]", "", slug)
    slug = re.sub(r"[\s_-]+", "-", slug)
    return slug or "sucursal"


# ============================================================================
# COMPATIBILIDAD CON FLUJO DE APROBACIÓN / SOLICITUDES EN /establecimientos
# ============================================================================
@router.get("/usuario/{usuario_id}/estado-sucursal", response_model=EstadoSucursalResponse)
def obtener_estado_sucursal_usuario(usuario_id: str, db: Session = Depends(get_db)):
    """Verifica si el usuario actual posee un establecimiento, cuponera o solicitud de alta."""
    from app.api.endpoints.solicitudes import cargar_metadata_solicitudes

    usuario = db.query(Usuario).filter(Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    rol_str = usuario.rol.value if hasattr(usuario.rol, "value") else str(usuario.rol)
    establecimiento = (
        db.query(Establecimiento)
        .filter(Establecimiento.propietario_id == usuario_id)
        .order_by(Establecimiento.fecha_creacion.desc())
        .first()
    )

    ultima_solicitud = (
        db.query(SolicitudEstablecimiento)
        .filter(SolicitudEstablecimiento.usuario_id == usuario_id)
        .order_by(SolicitudEstablecimiento.fecha_solicitud.desc())
        .first()
    )

    estado_solicitud = None
    comentarios_evaluacion = None
    nombre_negocio_solicitud = None
    tipo_solicitud = None
    if ultima_solicitud:
        estado_solicitud = (
            ultima_solicitud.estado.value
            if hasattr(ultima_solicitud.estado, "value")
            else str(ultima_solicitud.estado)
        )
        nombre_negocio_solicitud = ultima_solicitud.nombre_negocio
        meta = cargar_metadata_solicitudes().get(ultima_solicitud.id, {})
        comentarios_evaluacion = meta.get("comentarios_evaluacion")
        tipo_solicitud = meta.get("tipo_solicitud") or "ALTA_SUCURSAL"

    if not establecimiento:
        return {
            "tiene_sucursal": False,
            "rol": rol_str,
            "establecimiento": None,
            "cuponera_id": None,
            "tiene_solicitud": ultima_solicitud is not None,
            "solicitud_id": ultima_solicitud.id if ultima_solicitud else None,
            "estado_solicitud": estado_solicitud,
            "nombre_negocio_solicitud": nombre_negocio_solicitud,
            "tipo_solicitud": tipo_solicitud,
            "comentarios_evaluacion": comentarios_evaluacion,
        }

    cuponera = (
        db.query(Cuponera)
        .filter(Cuponera.establecimiento_id == establecimiento.id)
        .first()
    )

    return {
        "tiene_sucursal": True,
        "rol": rol_str,
        "establecimiento": establecimiento,
        "cuponera_id": cuponera.id if cuponera else None,
        "tiene_solicitud": ultima_solicitud is not None,
        "solicitud_id": ultima_solicitud.id if ultima_solicitud else None,
        "estado_solicitud": estado_solicitud or "aprobada",
        "nombre_negocio_solicitud": nombre_negocio_solicitud,
        "tipo_solicitud": tipo_solicitud,
        "comentarios_evaluacion": comentarios_evaluacion,
    }


@router.post("/solicitudes", response_model=MensajeResponse, status_code=status.HTTP_201_CREATED)
def crear_solicitud_establecimiento(
    datos: CrearSolicitudRequest,
    db: Session = Depends(get_db),
):
    """Registra una solicitud de alta de negocio con sus documentos probatorios."""
    usuario = db.query(Usuario).filter(Usuario.id == datos.usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    nombre_clean = datos.nombre_negocio.strip()
    solicitud_existente = (
        db.query(SolicitudEstablecimiento)
        .filter(
            SolicitudEstablecimiento.usuario_id == datos.usuario_id,
            SolicitudEstablecimiento.nombre_negocio == nombre_clean,
            SolicitudEstablecimiento.estado == EstadoSolicitud.PENDIENTE.value,
        )
        .first()
    )

    if solicitud_existente:
        solicitud_existente.nombre_negocio = nombre_clean
        if datos.documentos_url:
            solicitud_existente.documentos_url = datos.documentos_url.strip()
        db.commit()
        return MensajeResponse(
            mensaje="Solicitud actualizada exitosamente. En espera de revisión."
        )

    nueva_solicitud = SolicitudEstablecimiento(
        id=str(uuid.uuid4()),
        usuario_id=datos.usuario_id,
        nombre_negocio=nombre_clean,
        documentos_url=datos.documentos_url or "/static/uploads/documentos/documento_verificacion.pdf",
        estado=EstadoSolicitud.PENDIENTE.value,
    )
    db.add(nueva_solicitud)
    db.commit()

    return MensajeResponse(
        mensaje="Solicitud enviada exitosamente. En espera de revisión."
    )


# ============================================================================
# ALTA DE SUCURSALES (SISTEMA COMPLETO)
# ============================================================================
@router.post("/", response_model=EstablecimientoResponse, status_code=status.HTTP_201_CREATED)
def dar_de_alta_sucursal(
    sucursal_in: EstablecimientoCreate,
    db: Session = Depends(get_db),
):
    """
    Da de alta una nueva sucursal (Establecimiento) asociada a un propietario,
    junto con su Cuponera inicial y registro de Diseño (Server-Driven UI).
    """
    propietario = db.query(Usuario).filter(Usuario.id == sucursal_in.propietario_id).first()
    if not propietario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="El propietario indicado no existe.",
        )

    if propietario.rol == RolUsuario.CLIENTE.value or propietario.rol == RolUsuario.CLIENTE:
        propietario.rol = RolUsuario.PROPIETARIO.value

    base_slug = slugify(sucursal_in.slug or sucursal_in.nombre)
    slug_candidato = base_slug
    contador = 1
    while db.query(Establecimiento).filter(Establecimiento.slug == slug_candidato).first():
        slug_candidato = f"{base_slug}-{contador}"
        contador += 1

    nueva_sucursal = Establecimiento(
        id=str(uuid.uuid4()),
        propietario_id=sucursal_in.propietario_id,
        nombre=sucursal_in.nombre.strip(),
        slug=slug_candidato,
        logo_url=sucursal_in.logo_url,
        activo=sucursal_in.activo,
    )
    db.add(nueva_sucursal)
    db.flush()

    nueva_cuponera = Cuponera(
        id=str(uuid.uuid4()),
        establecimiento_id=nueva_sucursal.id,
        titulo=f"Cuponera de {nueva_sucursal.nombre}",
        descripcion_premio="Premio por definir",
        total_sellos_requeridos=6,
        activa=True,
    )
    db.add(nueva_cuponera)
    db.flush()

    nuevo_diseno = DisenoCuponera(
        id=str(uuid.uuid4()),
        cuponera_id=nueva_cuponera.id,
        configuracion_ui={},
    )
    db.add(nuevo_diseno)

    db.commit()
    db.refresh(nueva_sucursal)
    return nueva_sucursal


# ============================================================================
# VISTA DE ADMINISTRACIÓN: LISTADO Y CONSULTA DE SUCURSALES
# ============================================================================
@router.get("/", response_model=List[EstablecimientoResponse])
def listar_sucursales(
    propietario_id: Optional[str] = Query(None, description="Filtrar por ID de propietario"),
    activo: Optional[bool] = Query(None, description="Filtrar por estado activo/inactivo"),
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
):
    """
    Lista las sucursales registradas con soporte de filtros para el panel de administración.
    """
    query = db.query(Establecimiento)
    if propietario_id:
        query = query.filter(Establecimiento.propietario_id == propietario_id)
    if activo is not None:
        query = query.filter(Establecimiento.activo == activo)

    return query.order_by(Establecimiento.fecha_creacion.desc()).offset(skip).limit(limit).all()


@router.get("/{sucursal_id}", response_model=EstablecimientoResponse)
def obtener_detalle_sucursal(
    sucursal_id: str,
    db: Session = Depends(get_db),
):
    """
    Obtiene los datos completos de una sucursal específica.
    """
    sucursal = db.query(Establecimiento).filter(Establecimiento.id == sucursal_id).first()
    if not sucursal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sucursal no encontrada.",
        )
    return sucursal


# ============================================================================
# VISTA DE CONFIGURACIÓN ESPECIAL: ACTUALIZACIÓN DE DETALLES
# ============================================================================
@router.patch("/{sucursal_id}/configuracion", response_model=EstablecimientoResponse)
def actualizar_configuracion_sucursal(
    sucursal_id: str,
    config_in: EstablecimientoUpdate,
    db: Session = Depends(get_db),
):
    """
    Actualiza la configuración especial de una sucursal:
    - El logotipo (logo_url) y el estado operativo (activo) se aplican de inmediato.
    - Si se cambia el nombre registrado de la sucursal, NO se cambia directamente, sino que
      genera/actualiza una solicitud de revisión ('CAMBIO_NOMBRE') en estado PENDIENTE para que
      el administrador evalúe y apruebe el cambio de nombre.
    """
    from app.api.endpoints.solicitudes import actualizar_metadata_solicitud, cargar_metadata_solicitudes

    sucursal = db.query(Establecimiento).filter(Establecimiento.id == sucursal_id).first()
    if not sucursal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sucursal no encontrada.",
        )

    # 1. Cambios directos que no requieren aprobación (logo_url y activo)
    if config_in.logo_url is not None:
        sucursal.logo_url = config_in.logo_url.strip() if config_in.logo_url.strip() else None
    if config_in.activo is not None:
        sucursal.activo = config_in.activo

    requiere_aprobacion_nombre = False
    solicitud_id_generada = None
    mensaje_respuesta = "Configuración de la sucursal actualizada correctamente."

    # 2. Verificar si cambió el nombre registrado
    if config_in.nombre is not None:
        nuevo_nombre = config_in.nombre.strip()
        if nuevo_nombre and nuevo_nombre != sucursal.nombre.strip():
            requiere_aprobacion_nombre = True
            nombre_anterior = sucursal.nombre

            # Buscar si ya hay una solicitud pendiente de cambio de nombre para esta sucursal
            meta_all = cargar_metadata_solicitudes()
            solicitudes_pendientes = (
                db.query(SolicitudEstablecimiento)
                .filter(
                    SolicitudEstablecimiento.usuario_id == sucursal.propietario_id,
                    SolicitudEstablecimiento.estado.in_([
                        EstadoSolicitud.PENDIENTE.value,
                        EstadoSolicitud.RECHAZADA.value,
                    ]),
                )
                .all()
            )

            sol_cambio_existente = None
            for s in solicitudes_pendientes:
                s_meta = meta_all.get(s.id, {})
                if (
                    s_meta.get("tipo_solicitud") == "CAMBIO_NOMBRE"
                    and s_meta.get("establecimiento_id") == sucursal.id
                ):
                    sol_cambio_existente = s
                    break

            doc_ref = sucursal.logo_url or ""

            if sol_cambio_existente:
                sol_cambio_existente.nombre_negocio = nuevo_nombre
                if doc_ref:
                    sol_cambio_existente.documentos_url = doc_ref
                sol_cambio_existente.estado = EstadoSolicitud.PENDIENTE.value
                sol_cambio_existente.fecha_solicitud = datetime.utcnow()
                solicitud_id_generada = sol_cambio_existente.id
            else:
                nueva_sol = SolicitudEstablecimiento(
                    id=str(uuid.uuid4()),
                    usuario_id=sucursal.propietario_id,
                    nombre_negocio=nuevo_nombre,
                    documentos_url=doc_ref,
                    estado=EstadoSolicitud.PENDIENTE.value,
                )
                db.add(nueva_sol)
                db.flush()
                solicitud_id_generada = nueva_sol.id

            actualizar_metadata_solicitud(
                solicitud_id_generada,
                tipo_solicitud="CAMBIO_NOMBRE",
                establecimiento_id=sucursal.id,
                nombre_anterior=nombre_anterior,
                comentarios_evaluacion="",
                fecha_evaluacion="",
            )
            mensaje_respuesta = (
                f"El logotipo y estado se guardaron. El cambio de nombre de '{nombre_anterior}' "
                f"a '{nuevo_nombre}' fue enviado a aprobación del administrador."
            )

    db.commit()
    db.refresh(sucursal)

    return EstablecimientoResponse(
        id=sucursal.id,
        propietario_id=sucursal.propietario_id,
        nombre=sucursal.nombre,
        slug=sucursal.slug,
        logo_url=sucursal.logo_url,
        activo=sucursal.activo,
        fecha_creacion=sucursal.fecha_creacion,
        requiere_aprobacion_nombre=requiere_aprobacion_nombre,
        solicitud_id=solicitud_id_generada,
        mensaje=mensaje_respuesta,
    )
