from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.endpoints import cuponeras, canjes, auth

app = FastAPI(title="API Cupones de Fidelidad")

# Permitir peticiones desde Flutter Web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Permite cualquier origen en desarrollo
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Se registran las rutas
app.include_router(cuponeras.router, prefix="/api/v1/cuponeras", tags=["Cuponeras"])
app.include_router(canjes.router, prefix="/api/v1/canjes", tags=["Canjes QR"])
app.include_router(auth.router, prefix="/api/v1/auth", tags=["Autenticación"])

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Backend de Cupones Activo"}