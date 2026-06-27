// shared/models/notificacion_model.dart
class NotificacionModel {
  final String idNotificacion;
  final String titulo;
  final String mensaje;
  final String tipo;
  final bool leida;
  final DateTime? createdAt;

  NotificacionModel({
    required this.idNotificacion,
    required this.titulo,
    required this.mensaje,
    this.tipo = 'INFORMATIVA',
    this.leida = false,
    this.createdAt,
  });

  factory NotificacionModel.fromJson(Map<String, dynamic> json) {
    return NotificacionModel(
      idNotificacion: json['id_notificacion'] ?? '',
      titulo: json['titulo'] ?? '',
      mensaje: json['mensaje'] ?? '',
      tipo: json['tipo'] ?? 'INFORMATIVA',
      leida: json['leida'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}
