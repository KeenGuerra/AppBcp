// shared/repositories/api_repository.dart
import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';

class ApiRepository {
  final Dio _dio = DioClient.instance.dio;

  // Auth
  Future<Map<String, dynamic>> login(String documento, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'documento': documento,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/auth/me');
    return response.data;
  }

  // Cliente
  Future<Map<String, dynamic>> getPerfil() async {
    final response = await _dio.get('/cliente/perfil');
    return response.data;
  }

  Future<List<dynamic>> getCuentas() async {
    final response = await _dio.get('/cliente/cuentas');
    return response.data;
  }

  Future<List<dynamic>> getMovimientos() async {
    final response = await _dio.get('/cliente/movimientos');
    return response.data;
  }

  Future<List<dynamic>> getTarjetas() async {
    final response = await _dio.get('/cliente/tarjetas');
    return response.data;
  }

  Future<List<dynamic>> getCreditos() async {
    final response = await _dio.get('/cliente/creditos');
    return response.data;
  }

  Future<Map<String, dynamic>> getCredito(String idCredito) async {
    final response = await _dio.get('/cliente/creditos/$idCredito');
    return response.data;
  }

  Future<List<dynamic>> getCronograma(String idCredito) async {
    final response = await _dio.get('/cliente/creditos/$idCredito/cronograma');
    return response.data;
  }

  Future<List<dynamic>> getNotificaciones() async {
    final response = await _dio.get('/cliente/notificaciones');
    return response.data;
  }

  Future<List<dynamic>> getSolicitudes() async {
    final response = await _dio.get('/cliente/solicitudes');
    return response.data;
  }

  Future<Map<String, dynamic>> crearSolicitud(Map<String, dynamic> data) async {
    final response = await _dio.post('/cliente/solicitudes', data: data);
    return response.data;
  }

  Future<void> transferir(Map<String, dynamic> data) async {
    await _dio.post('/cliente/operaciones/transferencia', data: data);
  }

  Future<void> pagarCredito(Map<String, dynamic> data) async {
    await _dio.post('/cliente/operaciones/pago-credito', data: data);
  }

  // Fuerza de ventas
  Future<List<dynamic>> getCarteraHoy() async {
    final response = await _dio.get('/fventas/cartera/hoy');
    return response.data;
  }

  Future<Map<String, dynamic>> getFichaCliente(String idCliente) async {
    final response = await _dio.get('/fventas/clientes/$idCliente/ficha');
    return response.data;
  }

  Future<void> registrarVisita(Map<String, dynamic> data) async {
    await _dio.post('/fventas/visitas', data: data);
  }

  Future<void> preevaluar(String idSolicitud) async {
    await _dio.post('/fventas/solicitudes/$idSolicitud/preevaluar');
  }

  Future<void> consultarBuro(String idSolicitud) async {
    await _dio.post('/fventas/solicitudes/$idSolicitud/buro');
  }

  Future<void> enviarComite(String idSolicitud) async {
    await _dio.post('/fventas/solicitudes/$idSolicitud/enviar-comite');
  }

  Future<List<dynamic>> getSolicitudesFventas() async {
    final response = await _dio.get('/fventas/solicitudes');
    return response.data;
  }

  // Comité / Supervisor
  Future<List<dynamic>> getSolicitudesComite() async {
    final response = await _dio.get('/comite/solicitudes');
    return response.data;
  }

  Future<void> aprobarSolicitud(String idSolicitud) async {
    await _dio.post('/comite/solicitudes/$idSolicitud/aprobar');
  }

  Future<void> rechazarSolicitud(String idSolicitud, String motivo) async {
    await _dio.post('/comite/solicitudes/$idSolicitud/rechazar', data: {'motivo': motivo});
  }

  Future<void> desembolsar(String idSolicitud) async {
    await _dio.post('/comite/solicitudes/$idSolicitud/desembolsar');
  }
}
