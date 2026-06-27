# preevaluacion_service.py
from decimal import Decimal
import math
from app.models.solicitud_model import SolicitudCredito
from app.models.cliente_model import NegocioCliente
from app.repositories import cliente_repository

def calcular_cuota_estimada(monto: Decimal, tea: Decimal, plazo_meses: int) -> Decimal:
    # TEM = (1 + TEA)^(1/12) - 1
    # Conversión a flotante para cálculos matemáticos
    monto_f = float(monto)
    tea_f = float(tea) / 100.0
    
    tem_f = math.pow(1.0 + tea_f, 1.0 / 12.0) - 1.0
    
    if tem_f <= 0:
        return Decimal(str(round(monto_f / plazo_meses, 2)))
        
    cuota_f = (monto_f * tem_f) / (1.0 - math.pow(1.0 + tem_f, -plazo_meses))
    return Decimal(str(round(cuota_f, 2)))

def evaluar_solicitud(ingreso: Decimal, gasto: Decimal, cuota_estimada: Decimal):
    capacidad_pago = ingreso - gasto
    if capacidad_pago <= 0:
        return {
            "resultado": "NO_APTO",
            "puntaje": 30,
            "capacidad_pago": capacidad_pago,
            "ratio_cuota": Decimal("9.99"),
            "cuota_estimada": cuota_estimada
        }

    ratio_cuota = cuota_estimada / capacidad_pago
    ratio_f = float(ratio_cuota)

    if ratio_f <= 0.40:
        resultado = "APTO"
        puntaje = 85
    elif ratio_f <= 0.60:
        resultado = "REVISAR"
        puntaje = 60
    else:
        resultado = "NO_APTO"
        puntaje = 30

    return {
        "resultado": resultado,
        "puntaje": puntaje,
        "capacidad_pago": capacidad_pago,
        "ratio_cuota": ratio_cuota,
        "cuota_estimada": cuota_estimada
    }
