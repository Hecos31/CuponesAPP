from fastapi import FastAPI
from app.api.endpoints import cuponeras, canjes , usuarios, auth , disenos
from fastapi.middleware.cors import CORSMiddleware



app = FastAPI(title="API Cupones de Fidelidad")

# Permitir peticiones desde Flutter Web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Se registran las rutas
app.include_router(cuponeras.router, prefix="/api/v1/cuponeras", tags=["Cuponeras"])
app.include_router(canjes.router, prefix="/api/v1/canjes", tags=["Canjes QR"])
app.include_router(usuarios.router,prefix="/api/v1/usuarios",tags=["Usuarios"])
app.include_router(usuarios.router,prefix="/api/v1/usuarios",tags=["Autenticación"])

app.include_router(auth.router, prefix="/api/v1/auth", tags=["Autenticación"])
##Nueva Ruta de diseños
app.include_router(disenos.router, prefix="/api/v1/cuponeras", tags=["Diseño de cuponeras"],
)



@app.get("/")
def read_root():
    return {"status": "ok", "message": "Backend de Cupones Activo"}