// shared/models/cuenta_model.dart
class CuentaModel {
  final String idCuenta;
  final String idCliente;
  final String numeroCuenta;
  final String? cci;
  final String moneda;
  final double saldoDisponible;
  final double saldoContable;
  final String estado;

  CuentaModel({
    required this.idCuenta,
    required this.idCliente,
    required this.numeroCuenta,
    this.cci,
    this.moneda = 'PEN',
    this.saldoDisponible = 0,
    this.saldoContable = 0,
    this.estado = 'ACTIVO',
  });

  String get saldoFormateado => 'S/ ${saldoDisponible.toStringAsFixed(2)}';

  factory CuentaModel.fromJson(Map<String, dynamic> json) {
    return CuentaModel(
      idCuenta: json['id_cuenta'] ?? '',
      idCliente: json['id_cliente'] ?? '',
      numeroCuenta: json['numero_cuenta'] ?? '',
      cci: json['cci'],
      moneda: json['moneda'] ?? 'PEN',
      saldoDisponible: (json['saldo_disponible'] ?? 0).toDouble(),
      saldoContable: (json['saldo_contable'] ?? 0).toDouble(),
      estado: json['estado'] ?? 'ACTIVO',
    );
  }
}
