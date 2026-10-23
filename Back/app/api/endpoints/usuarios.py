import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.dependencies import get_db
# Asegúrate de importar los demás modelos necesarios
from app.models.models import Usuario, Establecimiento, Cuponera, DisenoCuponera, RolUsuario 
from app.schemas import schemas
from app.core import security


router = APIRouter()


# RECUPERAR CONTRASEÑA

@router.post(
    "/recuperar-password",
    response_model=schemas.RecuperarPasswordResponse
)
def recuperar_password(
    datos: schemas.RecuperarPasswordRequest,
    db: Session = Depends(get_db)
):
    usuario = (
        db.query(Usuario)
        .filter(Usuario.email == datos.email)
        .first()
    )

    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No existe un usuario registrado con ese correo"
        )

    token = security.generar_token_recuperacion(
        usuario_id=usuario.id,
        minutos_validez=15
    )

    return schemas.RecuperarPasswordResponse(
        mensaje="Token de recuperación generado correctamente",
        token=token,
        expira_en_segundos=900
    )


# RESTABLECER CONTRASEÑA

@router.post(
    "/restablecer-password",
    response_model=schemas.MensajeResponse
)
def restablecer_password(
    datos: schemas.RestablecerPasswordRequest,
    db: Session = Depends(get_db)
):
    payload = security.decodificar_token_recuperacion(
        datos.token
    )

    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido o expirado"
        )

    usuario_id = payload.get("usr")

    usuario = (
        db.query(Usuario)
        .filter(Usuario.id == usuario_id)
        .first()
    )

    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado"
        )

    usuario.password_hash = security.generar_password_hash(
        datos.nueva_password
    )

    db.commit()

    return schemas.MensajeResponse(
        mensaje="Contraseña actualizada correctamente"
    )


# OBTENER PERFIL

@router.get(
    "/perfil/{usuario_id}",
    response_model=schemas.UsuarioPerfilResponse
)
def obtener_perfil(
    usuario_id: str,
    db: Session = Depends(get_db)
):
    usuario = (
        db.query(Usuario)
        .filter(Usuario.id == usuario_id)
        .first()
    )

    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado"
        )

    return usuario


# ACTUALIZAR PERFIL


@router.put(
    "/perfil/{usuario_id}",
    response_model=schemas.UsuarioPerfilResponse
)
def actualizar_perfil(
    usuario_id: str,
    datos: schemas.ActualizarPerfilRequest,
    db: Session = Depends(get_db)
):
    usuario = (
        db.query(Usuario)
        .filter(Usuario.id == usuario_id)
        .first()
    )

    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado"
        )

    if datos.email is not None:

        correo_existente = (
            db.query(Usuario)
            .filter(
                Usuario.email == datos.email,
                Usuario.id != usuario_id
            )
            .first()
        )

        if correo_existente:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="El correo electrónico ya está registrado"
            )

        usuario.email = datos.email

    db.commit()
    db.refresh(usuario)

    return usuario


# SIMULAR ALTA DE SUCURSAL

@router.post(
    "/{usuario_id}/simular-alta-sucursal",
    response_model=schemas.SimularAltaSucursalResponse
)
def simular_alta_sucursal(
    usuario_id: str,
    nombre_negocio: str,
    db: Session = Depends(get_db)
):
    usuario = db.query(Usuario).filter(Usuario.id == usuario_id).first()
    
    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado"
        )
        
    # 1. Cambiamos el rol del usuario a propietario
    usuario.rol = RolUsuario.PROPIETARIO
    
    # 2. Creamos su establecimiento asociado
    nuevo_establecimiento = Establecimiento(
        propietario_id=usuario.id,
        nombre=nombre_negocio,
        slug=nombre_negocio.lower().replace(" ", "-") + "-" + str(uuid.uuid4())[:4]
    )
    db.add(nuevo_establecimiento)
    db.flush() # flush() nos da el ID antes de hacer commit
    
    # 3. Creamos su Cuponera Lógica Base
    nueva_cuponera = Cuponera(
        establecimiento_id=nuevo_establecimiento.id,
        titulo=f"Cuponera de {nombre_negocio}",
        descripcion_premio="Premio por definir",
        total_sellos_requeridos=6
    )
    db.add(nueva_cuponera)
    db.flush()
    
    # 4. Creamos el espacio para guardar su JSON (Diseño Visual)
    nuevo_diseno = DisenoCuponera(
        cuponera_id=nueva_cuponera.id,
        configuracion_ui={} # Inicia con JSON vacío
    )
    db.add(nuevo_diseno)
    
    db.commit()
    
    return schemas.SimularAltaSucursalResponse(
        mensaje="Alta exitosa. Ahora eres una sucursal.",
        establecimiento_id=nuevo_establecimiento.id,
        cuponera_id=nueva_cuponera.id
    )


@router.get("/{usuario_id}/estado-sucursal")
def obtener_estado_sucursal(usuario_id: str, db: Session = Depends(get_db)):
    usuario = db.query(Usuario).filter(Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    # Buscamos si el usuario tiene un establecimiento registrado en la BD
    establecimiento = db.query(Establecimiento).filter(Establecimiento.propietario_id == usuario.id).first()
    
    cuponera_id = None
    if establecimiento:
        cuponera = db.query(Cuponera).filter(Cuponera.establecimiento_id == establecimiento.id).first()
        if cuponera:
            cuponera_id = cuponera.id

    return {
        "rol": usuario.rol,
        "es_sucursal": establecimiento is not None,
        "establecimiento_id": establecimiento.id if establecimiento else None,
        "cuponera_id": cuponera_id
    }