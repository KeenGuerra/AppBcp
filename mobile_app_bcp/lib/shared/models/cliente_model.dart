// shared/models/cliente_model.dart
class ClienteModel {
  final String idCliente;
  final String idUsuario;
  final String? idAgencia;
  final String documento;
  final String nombres;
  final String apellidos;
  final String? telefono;
  final String? correo;
  final String? direccion;
  final String? distrito;
  final String? provincia;
  final String? departamento;
  final DateTime? fechaNacimiento;
  final String? estadoCivil;
  final String? ocupacion;
  final String? tipoCliente;
  final String estado;

  ClienteModel({
    required this.idCliente,
    required this.idUsuario,
    this.idAgencia,
    required this.documento,
    required this.nombres,
    required this.apellidos,
    this.telefono,
    this.correo,
    this.direccion,
    this.distrito,
    this.provincia,
    this.departamento,
    this.fechaNacimiento,
    this.estadoCivil,
    this.ocupacion,
    this.tipoCliente,
    this.estado = 'ACTIVO',
  });

  String get nombreCompleto => '$nombres $apellidos';

  factory ClienteModel.fromJson(Map<String, dynamic> json) {
    return ClienteModel(
      idCliente: json['id_cliente'] ?? '',
      idUsuario: json['id_usuario'] ?? '',
      idAgencia: json['id_agencia'],
      documento: json['documento'] ?? '',
      nombres: json['nombres'] ?? '',
      apellidos: json['apellidos'] ?? '',
      telefono: json['telefono'],
      correo: json['correo'],
      direccion: json['direccion'],
      distrito: json['distrito'],
      provincia: json['provincia'],
      departamento: json['departamento'],
      fechaNacimiento: json['fecha_nacimiento'] != null
          ? DateTime.tryParse(json['fecha_nacimiento'])
          : null,
      estadoCivil: json['estado_civil'],
      ocupacion: json['ocupacion'],
      tipoCliente: json['tipo_cliente'],
      estado: json['estado'] ?? 'ACTIVO',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_cliente': idCliente,
      'id_usuario': idUsuario,
      'id_agencia': idAgencia,
      'documento': documento,
      'nombres': nombres,
      'apellidos': apellidos,
      'telefono': telefono,
      'correo': correo,
      'direccion': direccion,
      'distrito': distrito,
      'provincia': provincia,
      'departamento': departamento,
      'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
      'estado_civil': estadoCivil,
      'ocupacion': ocupacion,
      'tipo_cliente': tipoCliente,
      'estado': estado,
    };
  }
}
