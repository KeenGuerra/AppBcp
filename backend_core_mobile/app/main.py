# main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.core.config import settings
from app.routes import auth_routes, cliente_routes, asesor_routes, comite_routes, admin_routes, sync_routes, banking_routes, supervisor_routes
import app.models
import os
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Verificar conexion a Supabase al iniciar
try:
    from supabase import create_client
    sb = create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_ROLE_KEY)
    r = sb.table('usuarios').select('count', count='exact').execute()
    logger.info(f"✅ Supabase conectado: {r.count} usuarios en la BD")
except Exception as e:
    logger.warning(f"⚠️  Supabase no disponible al iniciar: {e}")

app = FastAPI(
    title=settings.APP_NAME,
    debug=settings.APP_DEBUG,
    version="1.0.0"
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex="https?://.*",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount local upload directory for document files
uploads_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "uploads")
os.makedirs(uploads_dir, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=uploads_dir), name="uploads")

# Include Routers
app.include_router(auth_routes.router)
app.include_router(cliente_routes.router)
app.include_router(asesor_routes.router)
app.include_router(comite_routes.router)
app.include_router(admin_routes.router)
app.include_router(sync_routes.router)
app.include_router(banking_routes.router)
app.include_router(supervisor_routes.router)

@app.get("/health", tags=["Health"])
def health_check():
    try:
        from app.database.supabase_session import _get_supabase
        sb = _get_supabase()
        r = sb.table('usuarios').select('count', count='exact').execute()
        db_status = f"supabase_ok ({r.count} usuarios)"
    except Exception as e:
        db_status = f"error: {str(e)[:50]}"
    
    return {
        "status": "healthy",
        "app": settings.APP_NAME,
        "environment": settings.APP_ENV,
        "database": db_status
    }
