// shared/models/credito_model.dart
class CreditoModel {
  final String idCredito;
  final String idSolicitud;
  final String idCliente;
  final String numeroCredito;
  final String? producto;
  final double montoDesembolsado;
  final double saldoCapital;
  final int plazoMeses;
  final double tea;
  final double tem;
  final double cuotaMensual;
  final DateTime? fechaDesembolso;
  final int? diaPago;
  final String estado;

  CreditoModel({
    required this.idCredito,
    required this.idSolicitud,
    required this.idCliente,
    required this.numeroCredito,
    this.producto,
    this.montoDesembolsado = 0,
    this.saldoCapital = 0,
    this.plazoMeses = 0,
    this.tea = 0,
    this.tem = 0,
    this.cuotaMensual = 0,
    this.fechaDesembolso,
    this.diaPago,
    this.estado = 'VIGENTE',
  });

  String get montoFormateado => 'S/ ${montoDesembolsado.toStringAsFixed(2)}';
  String get saldoFormateado => 'S/ ${saldoCapital.toStringAsFixed(2)}';
  String get cuotaFormateada => 'S/ ${cuotaMensual.toStringAsFixed(2)}';

  factory CreditoModel.fromJson(Map<String, dynamic> json) {
    return CreditoModel(
      idCredito: json['id_credito'] ?? '',
      idSolicitud: json['id_solicitud'] ?? '',
      idCliente: json['id_cliente'] ?? '',
      numeroCredito: json['numero_credito'] ?? '',
      producto: json['producto'],
      montoDesembolsado: (json['monto_desembolsado'] ?? 0).toDouble(),
      saldoCapital: (json['saldo_capital'] ?? 0).toDouble(),
      plazoMeses: json['plazo_meses'] ?? 0,
      tea: (json['tea'] ?? 0).toDouble(),
      tem: (json['tem'] ?? 0).toDouble(),
      cuotaMensual: (json['cuota_mensual'] ?? 0).toDouble(),
      fechaDesembolso: json['fecha_desembolso'] != null
          ? DateTime.tryParse(json['fecha_desembolso'])
          : null,
      diaPago: json['dia_pago'],
      estado: json['estado'] ?? 'VIGENTE',
    );
  }
}
