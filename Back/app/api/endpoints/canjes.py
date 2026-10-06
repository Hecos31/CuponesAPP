from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.api.dependencies import get_db
from app.schemas import schemas
from app.core import security
from app.models import models

router = APIRouter()

@router.post("/generar-qr", response_model=schemas.TokenQRResponse)
def generar_qr_sello(cuponera_id: str, emisor_id: str, db: Session = Depends(get_db)):
    # Validar que la cuponera y el emisor (propietario) existan y estén activos
    cuponera = db.query(models.Cuponera).filter(models.Cuponera.id == cuponera_id).first()
    if not cuponera or not cuponera.activa:
        raise HTTPException(status_code=404, detail="Cuponera no encontrada o inactiva")

    minutos_validez = 2
    token = security.generar_token_sello(cuponera_id, emisor_id, minutos_validez)
    
    return schemas.TokenQRResponse(
        token=token,
        expira_en_segundos=minutos_validez * 60
    )

@router.post("/escanear-qr", response_model=schemas.SelloResponse)
def registrar_sello_qr(request: schemas.EscaneoQRRequest, db: Session = Depends(get_db)):
    # 1. Validar Token
    payload = security.decodificar_token_sello(request.token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, 
            detail="Token inválido o expirado"
        )
    
    cuponera_id = payload.get("cup")
    emisor_id = payload.get("emi")

    # 2. Buscar o crear el progreso del usuario
    progreso = db.query(models.ProgresoUsuario).filter(
        models.ProgresoUsuario.usuario_id == str(request.usuario_id),
        models.ProgresoUsuario.cuponera_id == cuponera_id,
        models.ProgresoUsuario.estado == models.EstadoProgreso.ACTIVO
    ).first()

    if not progreso:
        progreso = models.ProgresoUsuario(
            usuario_id=str(request.usuario_id),
            cuponera_id=cuponera_id,
            sellos_acumulados=0
        )
        db.add(progreso)
        db.commit()
        db.refresh(progreso)

    # 3. Validar límite de sellos
    cuponera = db.query(models.Cuponera).filter(models.Cuponera.id == cuponera_id).first()
    if progreso.sellos_acumulados >= cuponera.total_sellos_requeridos:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La cuponera ya está completa"
        )

    # 4. Registrar el sello
    nuevo_sello = models.RegistroSello(
        progreso_id=progreso.id,
        sellado_por=emisor_id,
        metodo=models.MetodoSello.QR
    )
    db.add(nuevo_sello)

    # 5. Actualizar progreso
    progreso.sellos_acumulados += 1
    if progreso.sellos_acumulados == cuponera.total_sellos_requeridos:
        progreso.estado = models.EstadoProgreso.COMPLETADO

    db.commit()
    db.refresh(progreso)

    return schemas.SelloResponse(
        progreso_id=progreso.id,
        sellos_acumulados=progreso.sellos_acumulados,
        estado=progreso.estado,
        fecha_sello=nuevo_sello.fecha_sello
    )