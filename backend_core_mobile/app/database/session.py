# session.py
from sqlalchemy.orm import declarative_base

Base = declarative_base()

# Usar SupabaseSession para todas las operaciones netamente con Supabase
def SessionLocal():
    from app.database.supabase_session import SupabaseSession
    return SupabaseSession()
