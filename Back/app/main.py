from fastapi import FastAPI
from app.api.endpoints import cuponeras, canjes , usuarios

app = FastAPI(title="API Cupones de Fidelidad")

# Se registran los prefijos de las URLs y las etiquetas para la documentación autogenerada (Swagger)
app.include_router(cuponeras.router, prefix="/api/v1/cuponeras", tags=["Cuponeras"])
app.include_router(canjes.router, prefix="/api/v1/canjes", tags=["Canjes QR"])
app.include_router(usuarios.router,prefix="/api/v1/usuarios",tags=["Usuarios"])

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Backend de Cupones Activo"}