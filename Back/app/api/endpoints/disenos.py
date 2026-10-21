
import xml.etree.ElementTree as ET
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.dependencies import get_db
from app.models.models import Cuponera, DisenoCuponera
from app.schemas.schemas import (
    DisenoCuponeraUpdate,
    DisenoCuponeraResponse,
)

router = APIRouter()

MAX_SVG_BYTES = 2 * 1024 * 1024  # 2 MB

TAGS_PROHIBIDAS = {
    "script",
    "foreignObject",
    "iframe",
    "object",
    "embed",
}


def validar_svg(svg: str | None) -> str | None:
    """Valida un SVG antes de almacenarlo en la base de datos."""

    if svg is None:
        return None

    if len(svg.encode("utf-8")) > MAX_SVG_BYTES:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="El SVG no puede superar los 2 MB.",
        )

    try:
        raiz = ET.fromstring(svg)
    except ET.ParseError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El archivo no contiene XML válido.",
        )

    if raiz.tag.split("}")[-1].lower() != "svg":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El documento debe tener una raíz SVG.",
        )

    for elemento in raiz.iter():
        etiqueta = elemento.tag.split("}")[-1].lower()

        if etiqueta in TAGS_PROHIBIDAS:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"El SVG contiene una etiqueta no permitida: {etiqueta}.",
            )

        for atributo, valor in elemento.attrib.items():
            nombre = atributo.split("}")[-1].lower()
            contenido = valor.strip().lower()

            if nombre.startswith("on"):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="El SVG contiene un evento no permitido.",
                )

            if nombre in {"href", "src"} and contenido.startswith(
                ("http:", "https:", "//", "javascript:", "file:")
            ):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="El SVG no puede cargar recursos externos.",
                )

            if "javascript:" in contenido:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="El SVG contiene una referencia no permitida.",
                )

    return svg


def construir_respuesta(
    cuponera_id: str,
    diseno: DisenoCuponera,
) -> DisenoCuponeraResponse:
    configuracion = dict(diseno.configuracion_ui or {})

    svg = configuracion.pop("_svg_markup", None)

    return DisenoCuponeraResponse(
        cuponera_id=cuponera_id,
        configuracion_ui=configuracion,
        svg_markup=svg,
        actualizado=True,
    )


@router.get(
    "/{cuponera_id}/diseno",
    response_model=DisenoCuponeraResponse,
)
def obtener_diseno(
    cuponera_id: str,
    db: Session = Depends(get_db),
):
    cuponera = (
        db.query(Cuponera)
        .filter(Cuponera.id == cuponera_id)
        .first()
    )

    if cuponera is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="La cuponera no existe.",
        )

    diseno = (
        db.query(DisenoCuponera)
        .filter(DisenoCuponera.cuponera_id == cuponera_id)
        .first()
    )

    if diseno is None:
        return DisenoCuponeraResponse(
            cuponera_id=cuponera_id,
            configuracion_ui={},
            svg_markup=None,
            actualizado=False,
        )

    return construir_respuesta(cuponera_id, diseno)


@router.put(
    "/{cuponera_id}/diseno",
    response_model=DisenoCuponeraResponse,
)
def guardar_diseno(
    cuponera_id: str,
    datos: DisenoCuponeraUpdate,
    db: Session = Depends(get_db),
):
    cuponera = (
        db.query(Cuponera)
        .filter(Cuponera.id == cuponera_id)
        .first()
    )

    if cuponera is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="La cuponera no existe.",
        )

    svg_validado = validar_svg(datos.svg_markup)

    configuracion: dict[str, Any] = dict(datos.configuracion_ui)

    diseno = (
        db.query(DisenoCuponera)
        .filter(DisenoCuponera.cuponera_id == cuponera_id)
        .first()
    )

    if diseno is None:
        diseno = DisenoCuponera(
            cuponera_id=cuponera_id,
            configuracion_ui=configuracion,
        )
        db.add(diseno)

    configuracion_anterior = dict(
        diseno.configuracion_ui or {}
    )

    if datos.eliminar_svg:
        configuracion.pop("_svg_markup", None)

    elif svg_validado is not None:
        configuracion["_svg_markup"] = svg_validado

    elif configuracion_anterior.get("_svg_markup"):
        configuracion["_svg_markup"] = (
            configuracion_anterior["_svg_markup"]
        )

    diseno.configuracion_ui = configuracion

    try:
        db.commit()
        db.refresh(diseno)
    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="No se pudo guardar el diseño.",
        )

    return construir_respuesta(cuponera_id, diseno)
