# supabase_client.py
# Cliente Supabase singleton - usa la REST API (PostgREST)
# Reemplaza la conexion directa PostgreSQL que no funciona por IPv6
from supabase import create_client, Client
from app.core.config import settings

_supabase_client: Client = None

def get_supabase() -> Client:
    global _supabase_client
    if _supabase_client is None:
        _supabase_client = create_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_SERVICE_ROLE_KEY
        )
    return _supabase_client

# Singleton accesible globalmente
supabase: Client = None

def init_supabase():
    global supabase
    supabase = create_client(
        settings.SUPABASE_URL,
        settings.SUPABASE_SERVICE_ROLE_KEY
    )
    return supabase
