# connection.py
# NOTA: La conexion directa PostgreSQL no esta disponible (el pooler Supabase requiere
# configuracion especial y el host directo solo tiene IPv6).
# El backend usa supabase-py via REST API para todas las operaciones.
# Este archivo existe por compatibilidad de imports pero no crea un engine real.

from app.core.config import settings
import logging

logger = logging.getLogger(__name__)

# Engine simulado para compatibilidad - las operaciones reales van via supabase-py
engine = None
logger.info("Trabajando netamente con la API REST de Supabase. El motor de PostgreSQL directo/local ha sido eliminado de la configuracion.")
