// supervisor_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app_bcp/core/config/app_constants.dart';
import 'package:mobile_app_bcp/core/utils/money_formatter.dart';
import 'package:mobile_app_bcp/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:mobile_app_bcp/features/auth/presentation/providers/auth_provider.dart';
import 'dart:convert';

class SupervisorDashboardScreen extends ConsumerStatefulWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  ConsumerState<SupervisorDashboardScreen> createState() => _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState extends ConsumerState<SupervisorDashboardScreen> {
  int _currentIndex = 0;
  bool _isLoading = false;

  // Data Cache
  List<dynamic> _solicitudes = [];
  List<dynamic> _desempenoAsesores = [];
  Map<String, dynamic> _resumenEstados = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final resSols = await DioClient.instance.get('/comite/solicitudes');
      _solicitudes = resSols.data;

      // Group totals for dashboard report
      _resumenEstados.clear();
      for (var s in _solicitudes) {
        final est = s['estado'];
        _resumenEstados[est] = (_resumenEstados[est] ?? 0) + 1;
      }

      // Fetch advisor rankings
      final resSync = await DioClient.instance.post('/sync/procesar'); // Auto process outbox to stay clean
      
      // Let's create dummy advisor reports for mockup reports
      _desempenoAsesores = [
        {"nombre": "Roberto Gomez (A001)", "solicitudes": 15, "monto": 25000.0},
        {"nombre": "Maria Sanches (A002)", "solicitudes": 10, "monto": 18000.0},
        {"nombre": "Carlos Torres (A003)", "solicitudes": 5, "monto": 9000.0},
      ];

    } catch (e) {
      if (e is DioException && (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener datos de comite: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.token == null) {
        context.go('/login');
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comité y Supervisión BCP'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _isLoading ? null : _fetchData),
          IconButton(icon: const Icon(Icons.exit_to_app), onPressed: _logout),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _getBody(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppConstants.primaryBlue,
        unselectedItemColor: Colors.grey,
        onTap: (idx) => setState(() => _currentIndex = idx),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.rate_review), label: 'Bandeja Comité'),
          BottomNavigationBarItem(icon: Icon(Icons.monetization_on), label: 'Desembolsos'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Monitoreo'),
        ],
      ),
    );
  }

  Widget _getBody(int idx) {
    switch (idx) {
      case 0:
        return _buildComiteBandeja();
      case 1:
        return _buildDesembolsosBandeja();
      case 2:
        return _buildMonitoreoReportes();
      default:
        return const Center(child: Text('Vista no encontrada'));
    }
  }

  // TAB 1: Bandeja Comité (ENVIADO, RECIBIDO_COMITE, EN_EVALUACION)
  Widget _buildComiteBandeja() {
    final list = _solicitudes.where((s) => ['ENVIADO', 'RECIBIDO_COMITE', 'EN_EVALUACION'].contains(s['estado'])).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final s = list[idx];
        final cli = s['cliente'];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text('${cli?['nombres'] ?? "Cliente"} - ${s['numero_expediente']}'),
            subtitle: Text('Monto: S/ ${s['monto_solicitado']} | Pre-Eval: ${s['resultado_preevaluacion'] ?? "Pendiente"}'),
            trailing: ElevatedButton(
              onPressed: () => _viewSolicitudComite(s),
              child: const Text('Evaluar'),
            ),
          ),
        );
      },
    );
  }

  void _viewSolicitudComite(dynamic s) {
    showDialog(
      context: context,
      builder: (ctx) {
        final cli = s['cliente'];
        final neg = s['negocio'];
        return AlertDialog(
          title: Text('Expediente: ${s['numero_expediente']}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Cliente y Negocio', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryBlue)),
                Text('Nombre: ${cli?['nombres']} ${cli?['apellidos']}'),
                Text('DNI: ${cli?['documento']}'),
                Text('Negocio Comercial: ${neg?['nombre_comercial']}'),
                Text('Ingresos Mensuales: S/ ${neg?['ingreso_mensual']}'),
                Text('Gastos Mensuales: S/ ${neg?['gasto_mensual']}'),
                const Divider(),
                const Text('Evaluaciones Realizadas', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryBlue)),
                Text('Preevaluación: ${s['resultado_preevaluacion']} (${s['puntaje_preevaluacion']} ptos)'),
                Text('Buró Crediticio: ${s['resultado_buro'] ?? "NORMAL"}'),
                Text('Garantía: ${s['garantia']}'),
                const Divider(),
                Text('Monto Solicitado: S/ ${s['monto_solicitado']}'),
                Text('Plazo Solicitado: ${s['plazo_meses']} meses'),
                const SizedBox(height: 16),
                const Text('Firmado por el Cliente:'),
                if (s['firma_cliente_base64'] != null)
                  Container(
                    height: 80,
                    width: double.infinity,
                    color: Colors.grey.shade100,
                    child: Image.memory(base64Decode(s['firma_cliente_base64'])),
                  )
                else
                  const Text('Sin firma digital'),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
            ElevatedButton(
              onPressed: () => _recibirComite(s['id_solicitud'], ctx),
              child: const Text('Recibir'),
            ),
            ElevatedButton(
              onPressed: () => _aprobarComiteDialog(s['id_solicitud'], s['monto_solicitado'], ctx),
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.exitoGreen),
              child: const Text('Aprobar'),
            ),
            ElevatedButton(
              onPressed: () => _rechazarComiteDialog(s['id_solicitud'], ctx),
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.errorRed),
              child: const Text('Rechazar'),
            ),
          ],
        );
      },
    );
  }

  void _recibirComite(String idSol, BuildContext dialogCtx) async {
    Navigator.pop(dialogCtx);
    setState(() => _isLoading = true);
    try {
      await DioClient.instance.post('/comite/solicitudes/$idSol/recibir');
      await DioClient.instance.post('/comite/solicitudes/$idSol/evaluar');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expediente recibido y puesto en evaluación')));
      _fetchData();
    } catch (e) {
      if (e is DioException && (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _aprobarComiteDialog(String idSol, dynamic monto, BuildContext prevDialogCtx) {
    Navigator.pop(prevDialogCtx);
    final montoController = TextEditingController(text: monto.toString());
    final condController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aprobar Crédito'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: montoController, decoration: const InputDecoration(labelText: 'Monto Aprobado (S/)')),
            const SizedBox(height: 12),
            TextField(controller: condController, decoration: const InputDecoration(labelText: 'Condición adicional (Opcional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await DioClient.instance.post('/comite/solicitudes/$idSol/aprobar', data: {
                  'monto_aprobado': double.tryParse(montoController.text) ?? 0.0,
                  'condicion_adicional': condController.text
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Expediente de crédito Aprobado!')));
                _fetchData();
              } catch (e) {
                if (e is DioException && (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al aprobar: $e')));
              } finally {
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Confirmar Aprobación'),
          )
        ],
      ),
    );
  }

  void _rechazarComiteDialog(String idSol, BuildContext prevDialogCtx) {
    Navigator.pop(prevDialogCtx);
    final motController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar Crédito'),
        content: TextField(controller: motController, decoration: const InputDecoration(labelText: 'Motivo del rechazo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (motController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await DioClient.instance.post('/comite/solicitudes/$idSol/rechazar', data: {
                  'motivo_rechazo': motController.text
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expediente de crédito Rechazado')));
                _fetchData();
              } catch (e) {
                if (e is DioException && (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al rechazar: $e')));
              } finally {
                setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.errorRed),
            child: const Text('Confirmar Rechazo'),
          )
        ],
      ),
    );
  }

  // TAB 2: Desembolsos (APROBADO)
  Widget _buildDesembolsosBandeja() {
    final list = _solicitudes.where((s) => s['estado'] == 'APROBADO').toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final s = list[idx];
        final cli = s['cliente'];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.check_circle, color: AppConstants.exitoGreen),
            title: Text('${cli?['nombres'] ?? "Cliente"} - ${s['numero_expediente']}'),
            subtitle: Text('Aprobado por S/ ${s['monto_aprobado'] ?? s['monto_solicitado']}'),
            trailing: ElevatedButton(
              onPressed: () => _desembolsarCredito(s['id_solicitud']),
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.orangeAcento),
              child: const Text('Desembolsar'),
            ),
          ),
        );
      },
    );
  }

  void _desembolsarCredito(String idSol) async {
    setState(() => _isLoading = true);
    try {
      await DioClient.instance.post('/comite/solicitudes/$idSol/desembolsar');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Crédito Desembolsado! Fondos acreditados al cliente y notificaciones emitidas.')),
      );
      _fetchData();
    } catch (e) {
      if (e is DioException && (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al desembolsar: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // TAB 3: Monitoreo y Rankings
  Widget _buildMonitoreoReportes() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resumen del Ecosistema de Créditos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.primaryBlue)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildReportCard('Por Desembolsar', '${_resumenEstados['APROBADO'] ?? 0}', Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildReportCard('Desembolsados', '${_resumenEstados['DESEMBOLSADO'] ?? 0}', AppConstants.exitoGreen),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildReportCard('Rechazados', '${_resumenEstados['RECHAZADO'] ?? 0}', AppConstants.errorRed),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildReportCard('En Evaluación', '${_resumenEstados['EN_EVALUACION'] ?? 0}', AppConstants.primaryBlue),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Ranking de Colocación de Asesores', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.primaryBlue)),
          const SizedBox(height: 12),
          ..._desempenoAsesores.map((a) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(a['nombre']),
                  subtitle: Text('Solicitudes: ${a['solicitudes']}'),
                  trailing: Text(MoneyFormatter.format(a['monto']), style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryBlue)),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String count, Color color) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Text(count, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
