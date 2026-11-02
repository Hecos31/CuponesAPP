import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.api.endpoints import cuponeras, canjes, usuarios, auth, solicitudes, establecimientos, admin

app = FastAPI(title="API Cupones de Fidelidad")

# Permitir peticiones desde Flutter Web, móvil y Localhost
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Servir archivos estáticos subidos (documentos probatorios, logos, etc.)
static_dir = os.path.join(os.path.dirname(__file__), "static")
os.makedirs(static_dir, exist_ok=True)
app.mount("/static", StaticFiles(directory=static_dir), name="static")

# Se registran los prefijos de las URLs y las etiquetas para Swagger
app.include_router(cuponeras.router, prefix="/api/v1/cuponeras", tags=["Cuponeras"])
app.include_router(canjes.router, prefix="/api/v1/canjes", tags=["Canjes QR"])
app.include_router(usuarios.router, prefix="/api/v1/usuarios", tags=["Usuarios"])
app.include_router(auth.router, prefix="/api/v1/auth", tags=["Autenticación"])
app.include_router(solicitudes.router, prefix="/api/v1/solicitudes", tags=["Solicitudes y Verificación"])
app.include_router(establecimientos.router, prefix="/api/v1/establecimientos", tags=["Sucursales / Establecimientos"])
app.include_router(admin.router, prefix="/api/v1/admin", tags=["Administración"])

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Backend de Cupones Activo"}
