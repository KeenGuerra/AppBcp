// shared/providers/shared_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/api_repository.dart';
import '../models/cliente_model.dart';
import '../models/cuenta_model.dart';
import '../models/credito_model.dart';
import '../models/movimiento_model.dart';
import '../models/solicitud_model.dart';
import '../models/notificacion_model.dart';

// Repository provider
final apiRepositoryProvider = Provider<ApiRepository>((ref) {
  return ApiRepository();
});

// Auth state
final currentUserProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

// Cliente data providers
final perfilProvider = FutureProvider<ClienteModel?>((ref) async {
  final repo = ref.read(apiRepositoryProvider);
  try {
    final data = await repo.getPerfil();
    return ClienteModel.fromJson(data);
  } catch (e) {
    return null;
  }
});

final cuentasProvider = FutureProvider<List<CuentaModel>>((ref) async {
  final repo = ref.read(apiRepositoryProvider);
  try {
    final data = await repo.getCuentas();
    return data.map((c) => CuentaModel.fromJson(c)).toList();
  } catch (e) {
    return [];
  }
});

final creditosProvider = FutureProvider<List<CreditoModel>>((ref) async {
  final repo = ref.read(apiRepositoryProvider);
  try {
    final data = await repo.getCreditos();
    return data.map((c) => CreditoModel.fromJson(c)).toList();
  } catch (e) {
    return [];
  }
});

final movimientosProvider = FutureProvider<List<MovimientoModel>>((ref) async {
  final repo = ref.read(apiRepositoryProvider);
  try {
    final data = await repo.getMovimientos();
    return data.map((m) => MovimientoModel.fromJson(m)).toList();
  } catch (e) {
    return [];
  }
});

final notificacionesProvider = FutureProvider<List<NotificacionModel>>((ref) async {
  final repo = ref.read(apiRepositoryProvider);
  try {
    final data = await repo.getNotificaciones();
    return data.map((n) => NotificacionModel.fromJson(n)).toList();
  } catch (e) {
    return [];
  }
});

final solicitudesProvider = FutureProvider<List<SolicitudModel>>((ref) async {
  final repo = ref.read(apiRepositoryProvider);
  try {
    final data = await repo.getSolicitudes();
    return data.map((s) => SolicitudModel.fromJson(s)).toList();
  } catch (e) {
    return [];
  }
});

// Cartera (fuerza de ventas)
final carteraProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.read(apiRepositoryProvider);
  try {
    return await repo.getCarteraHoy();
  } catch (e) {
    return [];
  }
});

// Comité (supervisor)
final solicitudesComiteProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.read(apiRepositoryProvider);
  try {
    return await repo.getSolicitudesComite();
  } catch (e) {
    return [];
  }
});
