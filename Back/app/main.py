from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# 1. Importamos el engine y Base de tu archivo de sesión
from app.db.session import engine, Base

# 2. Importamos las rutas (esto también suele precargar los modelos que estas rutas usan)
from app.api.endpoints import cuponeras, canjes, usuarios, auth, admin

# 3. Instrucción clave: Crea todas las tablas en la base de datos (zelloapp.db) si no existen
Base.metadata.create_all(bind=engine)

app = FastAPI(title="API Cupones de Fidelidad")

# Permitir peticiones desde Flutter Web y Localhost
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Se registran las rutas principales
app.include_router(cuponeras.router, prefix="/api/v1/cuponeras", tags=["Cuponeras"])
app.include_router(canjes.router, prefix="/api/v1/canjes", tags=["Canjes QR"])
app.include_router(usuarios.router, prefix="/api/v1/usuarios", tags=["Usuarios"])
app.include_router(auth.router, prefix="/api/v1/auth", tags=["Autenticación"])

# Se registra la ruta de administración (Aprobación de establecimientos)
app.include_router(admin.router, prefix="/api/v1/admin", tags=["Administración"])

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Backend de Cupones Activo"}