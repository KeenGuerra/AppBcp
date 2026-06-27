// shared/models/solicitud_model.dart
class SolicitudModel {
  final String idSolicitud;
  final String? numeroExpediente;
  final String idCliente;
  final String? idNegocio;
  final String? idAsesor;
  final String? idProductoCredito;
  final String? canalOrigen;
  final double montoSolicitado;
  final double? montoAprobado;
  final int plazoMeses;
  final String moneda;
  final double? teaReferencial;
  final bool? conSeguroDesgravamen;
  final String? garantia;
  final String? destinoCredito;
  final double? cuotaEstimada;
  final String estado;
  final String? resultadoPreevaluacion;
  final int? puntajePreevaluacion;
  final String? resultadoBuro;
  final String? motivoRechazo;
  final DateTime? createdAt;

  SolicitudModel({
    required this.idSolicitud,
    this.numeroExpediente,
    required this.idCliente,
    this.idNegocio,
    this.idAsesor,
    this.idProductoCredito,
    this.canalOrigen,
    this.montoSolicitado = 0,
    this.montoAprobado,
    this.plazoMeses = 12,
    this.moneda = 'PEN',
    this.teaReferencial,
    this.conSeguroDesgravamen,
    this.garantia,
    this.destinoCredito,
    this.cuotaEstimada,
    this.estado = 'BORRADOR',
    this.resultadoPreevaluacion,
    this.puntajePreevaluacion,
    this.resultadoBuro,
    this.motivoRechazo,
    this.createdAt,
  });

  String get montoFormateado => 'S/ ${montoSolicitado.toStringAsFixed(2)}';

  factory SolicitudModel.fromJson(Map<String, dynamic> json) {
    return SolicitudModel(
      idSolicitud: json['id_solicitud'] ?? '',
      numeroExpediente: json['numero_expediente'],
      idCliente: json['id_cliente'] ?? '',
      idNegocio: json['id_negocio'],
      idAsesor: json['id_asesor'],
      idProductoCredito: json['id_producto_credito'],
      canalOrigen: json['canal_origen'],
      montoSolicitado: (json['monto_solicitado'] ?? 0).toDouble(),
      montoAprobado: json['monto_aprobado'] != null
          ? (json['monto_aprobado']).toDouble()
          : null,
      plazoMeses: json['plazo_meses'] ?? 12,
      moneda: json['moneda'] ?? 'PEN',
      teaReferencial: json['tea_referencial'] != null
          ? (json['tea_referencial']).toDouble()
          : null,
      conSeguroDesgravamen: json['con_seguro_desgravamen'],
      garantia: json['garantia'],
      destinoCredito: json['destino_credito'],
      cuotaEstimada: json['cuota_estimada'] != null
          ? (json['cuota_estimada']).toDouble()
          : null,
      estado: json['estado'] ?? 'BORRADOR',
      resultadoPreevaluacion: json['resultado_preevaluacion'],
      puntajePreevaluacion: json['puntaje_preevaluacion'],
      resultadoBuro: json['resultado_buro'],
      motivoRechazo: json['motivo_rechazo'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}
