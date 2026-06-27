// shared/models/cronograma_model.dart
class CronogramaModel {
  final String idCuota;
  final String idCredito;
  final int numeroCuota;
  final DateTime? fechaPago;
  final double montoCuota;
  final double capital;
  final double interes;
  final double saldo;
  final String estado;
  final DateTime? fechaPagoReal;
  final double montoPagado;

  CronogramaModel({
    required this.idCuota,
    required this.idCredito,
    required this.numeroCuota,
    this.fechaPago,
    this.montoCuota = 0,
    this.capital = 0,
    this.interes = 0,
    this.saldo = 0,
    this.estado = 'PENDIENTE',
    this.fechaPagoReal,
    this.montoPagado = 0,
  });

  String get montoFormateado => 'S/ ${montoCuota.toStringAsFixed(2)}';
  String get capitalFormateado => 'S/ ${capital.toStringAsFixed(2)}';
  String get interesFormateado => 'S/ ${interes.toStringAsFixed(2)}';
  String get saldoFormateado => 'S/ ${saldo.toStringAsFixed(2)}';

  factory CronogramaModel.fromJson(Map<String, dynamic> json) {
    return CronogramaModel(
      idCuota: json['id_cuota'] ?? '',
      idCredito: json['id_credito'] ?? '',
      numeroCuota: json['numero_cuota'] ?? 0,
      fechaPago: json['fecha_pago'] != null
          ? DateTime.tryParse(json['fecha_pago'])
          : null,
      montoCuota: (json['monto_cuota'] ?? 0).toDouble(),
      capital: (json['capital'] ?? 0).toDouble(),
      interes: (json['interes'] ?? 0).toDouble(),
      saldo: (json['saldo'] ?? 0).toDouble(),
      estado: json['estado'] ?? 'PENDIENTE',
      fechaPagoReal: json['fecha_pago_real'] != null
          ? DateTime.tryParse(json['fecha_pago_real'])
          : null,
      montoPagado: (json['monto_pagado'] ?? 0).toDouble(),
    );
  }
}
