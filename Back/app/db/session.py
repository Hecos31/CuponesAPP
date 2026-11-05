from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.pool import NullPool
from app.core.config import settings

# Verificamos si estamos usando SQLite local o MySQL en la nube
if settings.DATABASE_URL.startswith("sqlite"):
    engine = create_engine(
        settings.DATABASE_URL, 
        connect_args={"check_same_thread": False} # Obligatorio para SQLite en FastAPI
    )
else:
    engine = create_engine(
        settings.DATABASE_URL, 
        pool_pre_ping=True, 
        poolclass=NullPool
    )

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()