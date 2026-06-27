# buro_service.py
from sqlalchemy.orm import Session
from app.models.solicitud_model import SolicitudCredito
from sqlalchemy import text
from typing import Dict, Any
from app.core.exceptions import NotFoundException
import uuid
from decimal import Decimal

# Models local import (kept for compatibility)
from app.models.cartera_model import Base


def consultar_buro(db: Session, id_solicitud: uuid.UUID) -> Dict[str, Any]:
    """
    Consulta el buró de crédito de forma determinista según el último dígito del DNI.

    Reglas (alineadas con los 30 casos de práctica):
    Dígito 0 → NORMAL:      1 entidad, S/ 4,500,  0 días mora   → APROBADO
    Dígito 1 → NORMAL:      2 entidades, S/ 12,000, 0 días mora  → APROBADO
    Dígito 2 → CPP:         2 entidades, S/ 18,000, 15 días mora → APROBADO (comité decide)
    Dígito 3 → NORMAL:      0 entidades, S/ 0,       0 días mora → APROBADO
    Dígito 4 → DUDOSO:      3 entidades, S/ 25,000, 95 días mora → APROBADO (comité decide)
    Dígito 5 → DEFICIENTE:  2 entidades, S/ 16,000, 45 días mora → APROBADO (comité decide)
    Dígito 6 → NORMAL:      1 entidad,  S/ 6,000,   0 días mora  → APROBADO
    Dígito 7 → PERDIDA:     4 entidades, S/ 40,000, 210 días mora → RECHAZADO (inhabilitado)
    Dígito 8 → CPP:         1 entidad,  S/ 9,000,  20 días mora  → APROBADO (comité decide)
    Dígito 9 → NORMAL:      2 entidades, S/ 14,000,  0 días mora → APROBADO
    """
    # 1. Fetch credit request
    solicitud = db.query(SolicitudCredito).filter(
        SolicitudCredito.id_solicitud == id_solicitud
    ).first()
    if not solicitud:
        raise NotFoundException("Solicitud de crédito")

    doc = solicitud.cliente.documento
    last_char = doc[-1] if doc else "0"
    last_digit = int(last_char) if last_char.isdigit() else 0

    # 2. Check blacklist first
    query_blacklisted = db.execute(
        text("SELECT motivo FROM listas_inhabilitados WHERE documento = :doc AND estado = 'ACTIVO'"),
        {"doc": doc}
    ).fetchone()

    esta_inhabilitado = bool(query_blacklisted)
    motivo_inhabilitacion = query_blacklisted[0] if query_blacklisted else None

    # 3. Deterministic rules by last digit
    DIGIT_RULES = {
        0: ("NORMAL",      1, Decimal("4500.00"),  0),
        1: ("NORMAL",      2, Decimal("12000.00"), 0),
        2: ("CPP",         2, Decimal("18000.00"), 15),
        3: ("NORMAL",      0, Decimal("0.00"),     0),
        4: ("DUDOSO",      3, Decimal("25000.00"), 95),
        5: ("DEFICIENTE",  2, Decimal("16000.00"), 45),
        6: ("NORMAL",      1, Decimal("6000.00"),  0),
        7: ("PERDIDA",     4, Decimal("40000.00"), 210),
        8: ("CPP",         1, Decimal("9000.00"),  20),
        9: ("NORMAL",      2, Decimal("14000.00"), 0),
    }

    calificacion, entidades_deuda, deuda_total, mayor_mora_dias = DIGIT_RULES.get(
        last_digit, ("NORMAL", 1, Decimal("0.00"), 0)
    )

    # 4. Override for blacklist or PERDIDA
    if esta_inhabilitado or last_digit == 7:
        calificacion = "PERDIDA"
        entidades_deuda = 4
        deuda_total = Decimal("40000.00")
        mayor_mora_dias = 210
        esta_inhabilitado = True
        resultado = "RECHAZADO"
        if not motivo_inhabilitacion:
            motivo_inhabilitacion = (
                "Registrado en historial de mora extrema en el sistema financiero"
            )
    else:
        # All other calificaciones (including DEFICIENTE and DUDOSO)
        # pass through to committee — no auto-reject
        resultado = "APROBADO"

    # 5. Insert in consultas_buro
    id_consulta = uuid.uuid4()
    db.execute(
        text("""
            INSERT INTO consultas_buro (
                id_consulta, id_solicitud, id_cliente, documento,
                calificacion, entidades_deuda, deuda_total,
                mayor_mora_dias, esta_inhabilitado, resultado
            )
            VALUES (
                :id_consulta, :id_solicitud, :id_cliente, :documento,
                :calificacion, :entidades_deuda, :deuda_total,
                :mayor_mora_dias, :esta_inhabilitado, :resultado
            )
        """),
        {
            "id_consulta":      id_consulta,
            "id_solicitud":     solicitud.id_solicitud,
            "id_cliente":       solicitud.id_cliente,
            "documento":        doc,
            "calificacion":     calificacion,
            "entidades_deuda":  entidades_deuda,
            "deuda_total":      deuda_total,
            "mayor_mora_dias":  mayor_mora_dias,
            "esta_inhabilitado": esta_inhabilitado,
            "resultado":        resultado,
        }
    )

    # 6. Update solicitud state
    solicitud.resultado_buro = calificacion
    if esta_inhabilitado:
        solicitud.estado = "RECHAZADO"
        solicitud.motivo_rechazo = (
            f"Cliente registrado en lista de inhabilitados: {motivo_inhabilitacion}"
        )
    # DEFICIENTE / DUDOSO / CPP → no state change here; committee will decide

    db.commit()

    return {
        "documento":        doc,
        "calificacion":     calificacion,
        "entidades_deuda":  entidades_deuda,
        "deuda_total":      deuda_total,
        "mayor_mora_dias":  mayor_mora_dias,
        "esta_inhabilitado": esta_inhabilitado,
        "resultado":        resultado,
    }
