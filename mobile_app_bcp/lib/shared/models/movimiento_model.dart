// shared/models/movimiento_model.dart
class MovimientoModel {
  final String idMovimiento;
  final String idCliente;
  final String? idCuenta;
  final String? idCredito;
  final String tipoMovimiento;
  final String? descripcion;
  final double monto;
  final String moneda;
  final DateTime? fechaMovimiento;
  final String? canal;

  MovimientoModel({
    required this.idMovimiento,
    required this.idCliente,
    this.idCuenta,
    this.idCredito,
    required this.tipoMovimiento,
    this.descripcion,
    this.monto = 0,
    this.moneda = 'PEN',
    this.fechaMovimiento,
    this.canal,
  });

  String get montoFormateado => 'S/ ${monto.toStringAsFixed(2)}';
  bool get esIngreso => tipoMovimiento == 'DESEMBOLSO_CREDITO' || tipoMovimiento == 'DEPOSITO';
  bool get esEgreso => tipoMovimiento == 'TRANSFERENCIA' || tipoMovimiento == 'PAGO_CUOTA';

  factory MovimientoModel.fromJson(Map<String, dynamic> json) {
    return MovimientoModel(
      idMovimiento: json['id_movimiento'] ?? '',
      idCliente: json['id_cliente'] ?? '',
      idCuenta: json['id_cuenta'],
      idCredito: json['id_credito'],
      tipoMovimiento: json['tipo_movimiento'] ?? '',
      descripcion: json['descripcion'],
      monto: (json['monto'] ?? 0).toDouble(),
      moneda: json['moneda'] ?? 'PEN',
      fechaMovimiento: json['fecha_movimiento'] != null
          ? DateTime.tryParse(json['fecha_movimiento'])
          : null,
      canal: json['canal'],
    );
  }
}
