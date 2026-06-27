# models/__init__.py
# Register all SQLAlchemy models in Base.metadata

from app.models.usuario_model import Usuario
from app.models.asesor_model import Asesor
from app.models.cliente_model import Cliente, NegocioCliente
from app.models.solicitud_model import SolicitudCredito, SolicitudNotaInterna, ProductoCredito
from app.models.cartera_model import CarteraDiaria
from app.models.campana_model import CampanaActiva
from app.models.alerta_model import AlertaCartera
from app.models.visita_model import VisitaCliente
from app.models.documento_model import SolicitudDocumento
from app.models.credito_model import Credito
from app.models.cronograma_model import CronogramaPago
from app.models.cuenta_model import CuentaAhorro
from app.models.movimiento_model import Movimiento, OperacionCliente
from app.models.notificacion_model import Notificacion
from app.models.preaprobado_model import CreditoPreaprobado
from app.models.sync_model import SyncOutbox, SyncLog
from app.models.auditoria_model import AuditoriaEvento
from app.models.banking_model import (
    BankingTransaccion,
    BankingTransferencia,
    BankingTransferenciaProgramada,
    BankingPagoServicio,
    BankingSimulacion,
    BankingSolicitudPrestamo,
    BankingPrestamo,
    BankingPagoPrestamo,
    BankingAhorro,
    BankingAbonoAhorro,
    BankingMetaAhorro,
    BankingAporteMeta,
    BankingDepositoPlazo,
    BankingRecarga,
    BankingGasto,
    BankingPresupuesto,
    BankingComparacionSim,
    BankingSimTasa,
    BankingComprobante,
    BankingRetiroProgramado,
    BankingReglaAhorro,
    BankingAhorroAutomaticoLog
)
