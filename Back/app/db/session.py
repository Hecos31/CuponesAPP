from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.pool import NullPool
from app.core.config import settings

from sqlalchemy.pool import NullPool

engine = create_engine(
    settings.DATABASE_URL, 
    pool_pre_ping=True, 
    poolclass=NullPool
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()