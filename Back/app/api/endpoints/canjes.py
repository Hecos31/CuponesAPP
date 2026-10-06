from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.api.dependencies import get_db
from app.schemas import schemas
from app.core import security
from app.models import models

router = APIRouter()

@router.post("/generar-qr-cliente", response_model=schemas.TokenQRResponse)
def generar_qr_cliente(usuario_id: str, db: Session = Depends(get_db)):
    """Emite un token temporal de identidad para el cliente."""
    
    # Verifica la existencia del usuario en la base de datos antes de emitir un token
    usuario = db.query(models.Usuario).filter(models.Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado")

    # Define el tiempo de vida del token y procede con la encriptación JWT
    minutos_validez = 5
    token = security.generar_token_cliente(usuario_id, minutos_validez)
    
    return schemas.TokenQRResponse(
        token=token,
        expira_en_segundos=minutos_validez * 60
    )

@router.post("/otorgar-sello", response_model=schemas.SelloResponse)
def otorgar_sello(request: schemas.OtorgarSelloRequest, db: Session = Depends(get_db)):
    """Registra un nuevo sello validando el token del cliente y el estado de la cuponera."""
    
    # Decodifica el token para asegurar que proviene de un cliente válido y no ha expirado
    payload = security.decodificar_token_cliente(request.token_cliente)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, 
            detail="Token inválido o expirado"
        )
    
    # Extrae el identificador del cliente validado por el token criptográfico
    usuario_id = payload.get("usr")

    # Comprueba que la cuponera objetivo existe y permite recibir nuevos sellos
    cuponera = db.query(models.Cuponera).filter(models.Cuponera.id == str(request.cuponera_id)).first()
    if not cuponera or not cuponera.activa:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Cuponera no encontrada o inactiva")

    # Consulta si el usuario ya tiene un progreso activo en esta cuponera específica
    progreso = db.query(models.ProgresoUsuario).filter(
        models.ProgresoUsuario.usuario_id == usuario_id,
        models.ProgresoUsuario.cuponera_id == str(request.cuponera_id),
        models.ProgresoUsuario.estado == models.EstadoProgreso.ACTIVO
    ).first()

    # Si es el primer sello del usuario en esta cuponera, inicializa su registro de progreso
    if not progreso:
        progreso = models.ProgresoUsuario(
            usuario_id=usuario_id,
            cuponera_id=str(request.cuponera_id),
            sellos_acumulados=0
        )
        db.add(progreso)
        db.flush() # Asigna un ID al progreso temporalmente para usarlo en la siguiente tabla

    # Bloquea la transacción si el usuario ya ha alcanzado el máximo de sellos permitidos
    if progreso.sellos_acumulados >= cuponera.total_sellos_requeridos:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La cuponera ya alcanzó el límite de sellos"
        )

    # Crea el registro histórico del sello vinculándolo al progreso y al emisor de la petición
    nuevo_sello = models.RegistroSello(
        progreso_id=progreso.id,
        sellado_por=str(request.emisor_id),
        metodo=models.MetodoSello.QR
    )
    db.add(nuevo_sello)

    # Incrementa el contador general de sellos y actualiza el estado si se alcanza la meta
    progreso.sellos_acumulados += 1
    if progreso.sellos_acumulados == cuponera.total_sellos_requeridos:
        progreso.estado = models.EstadoProgreso.COMPLETADO

    # Persiste todos los cambios en la base de datos de forma atómica
    db.commit()
    db.refresh(progreso)

    return schemas.SelloResponse(
        progreso_id=progreso.id,
        sellos_acumulados=progreso.sellos_acumulados,
        estado=progreso.estado,
        fecha_sello=nuevo_sello.fecha_sello
    )