// cliente_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app_bcp/core/config/app_constants.dart';
import 'package:mobile_app_bcp/core/utils/money_formatter.dart';
import 'package:mobile_app_bcp/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:mobile_app_bcp/features/auth/presentation/providers/auth_provider.dart';
import 'dart:math';

// Custom BCP components
import '../theme/cliente_theme.dart';
import '../widgets/bcp_logo.dart';
import '../widgets/cuentas_tab_view.dart';
import '../widgets/creditos_tab_view.dart';
import '../widgets/operaciones_tab_view.dart';
import '../widgets/solicitar_tab_view.dart';
import '../widgets/alertas_tab_view.dart';

class ClienteDashboardScreen extends ConsumerStatefulWidget {
  const ClienteDashboardScreen({super.key});

  @override
  ConsumerState<ClienteDashboardScreen> createState() => _ClienteDashboardScreenState();
}

class _ClienteDashboardScreenState extends ConsumerState<ClienteDashboardScreen> {
  int _currentIndex = 0;
  bool _isLoading = false;

  // Form Controllers
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _plazoController = TextEditingController();
  final TextEditingController _garantiaController = TextEditingController();
  final TextEditingController _destinoController = TextEditingController();

  // Data Cache
  List<dynamic> _cuentas = [];
  List<dynamic> _tarjetas = [];
  List<dynamic> _creditos = [];
  List<dynamic> _movimientos = [];
  List<dynamic> _solicitudes = [];
  List<dynamic> _notificaciones = [];
  Map<String, dynamic>? _perfil;

  // Active operations sub-lists for M8 items
  List<Map<String, dynamic>> _ahorrosProgramados = [];
  List<Map<String, dynamic>> _metasAhorro = [];
  List<Map<String, dynamic>> _transferenciasProgramadas = [];
  List<Map<String, dynamic>> _gastosPersonales = [];
  List<Map<String, dynamic>> _comprobantes = [];
  List<Map<String, dynamic>> _retirosProgramados = [];
  List<Map<String, dynamic>> _reglasAhorroAutomatico = [];

  // Budgets per category (Comida, Transporte, Salud, Entretenimiento)
  final Map<String, double> _limitesPresupuesto = {
    'Comida': 1000.0,
    'Transporte': 300.0,
    'Salud': 500.0,
    'Entretenimiento': 400.0,
  };

  @override
  void initState() {
    super.initState();
    _fetchData();
    _loadInitialMocks();
  }

  @override
  void dispose() {
    _montoController.dispose();
    _plazoController.dispose();
    _garantiaController.dispose();
    _destinoController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final resPerfil = await DioClient.instance.get('/cliente/perfil');
      _perfil = resPerfil.data;

      final resCuentas = await DioClient.instance.get('/cliente/cuentas');
      _cuentas = resCuentas.data;

      final resTarjetas = await DioClient.instance.get('/cliente/tarjetas');
      _tarjetas = resTarjetas.data;

      final resCreditos = await DioClient.instance.get('/cliente/creditos');
      _creditos = resCreditos.data;

      final resMovimientos = await DioClient.instance.get('/cliente/movimientos');
      _movimientos = resMovimientos.data;

      final resSolicitudes = await DioClient.instance.get('/cliente/solicitudes');
      _solicitudes = resSolicitudes.data;

      final resNotif = await DioClient.instance.get('/cliente/notificaciones');
      _notificaciones = resNotif.data;

    } catch (e) {
      if (e is DioException && (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al sincronizar datos de servidor: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadInitialMocks() {
    if (mounted) {
      setState(() {
        _ahorrosProgramados = [
          {'id': 'a1', 'nombre': 'Viaje Cusco', 'monto_meta': 3000.0, 'monto_actual': 1200.0, 'frecuencia': 'Mensual', 'activo': true},
          {'id': 'a2', 'nombre': 'Estudios Certificación', 'monto_meta': 1500.0, 'monto_actual': 900.0, 'frecuencia': 'Semanal', 'activo': true}
        ];
        _metasAhorro = [
          {'id': 'm1', 'nombre': 'Fondo de Emergencia', 'categoria': 'Emergencia', 'monto_objetivo': 5000.0, 'monto_actual': 2500.0, 'fecha_limite': '2026-12-31', 'estado': 'ACTIVA'},
        ];
        _transferenciasProgramadas = [
          {'id': 'tp1', 'cuenta_destino': '191-456789-0-45', 'monto': 200.0, 'fecha_programada': '2026-07-15', 'estado': 'PENDIENTE'}
        ];
        _gastosPersonales = [
          {'id': 'g1', 'descripcion': 'Almuerzo Central', 'monto': 150.0, 'categoria': 'Comida', 'fecha': '2026-06-22'},
          {'id': 'g2', 'descripcion': 'Combustible Repsol', 'monto': 80.0, 'categoria': 'Transporte', 'fecha': '2026-06-23'}
        ];
        _comprobantes = [
          {'id': 'c1', 'tipo': 'TRANSFERENCIA', 'monto': 350.0, 'referencia_uuid': 'uuid-982-12-3a', 'fecha': '2026-06-20'},
          {'id': 'c2', 'tipo': 'PAGO_LUZ', 'monto': 120.0, 'referencia_uuid': 'uuid-128-44-bc', 'fecha': '2026-06-22'}
        ];
        _retirosProgramados = [
          {'id': 'rp1', 'monto': 500.0, 'fecha_programada': '2026-07-01', 'motivo': 'Alquiler', 'estado': 'PENDIENTE'}
        ];
        _reglasAhorroAutomatico = [
          {'id': 'ra1', 'cuenta_origen': 'Cuenta Soles', 'cuenta_destino': 'Fondo Cusco', 'porcentaje': 5.0, 'activa': true}
        ];
      });
    }
  }

  void _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  // -----------------------------------------------------------------
  // API and State helpers for BCP 35 Casuísticas
  // -----------------------------------------------------------------

  void _executeBalanceAdjustment(double val, String type, String desc) async {
    if (_cuentas.isEmpty) return;
    if (mounted) setState(() => _isLoading = true);

    try {
      await DioClient.instance.post('/cliente/operaciones/transferencia', data: {
        'cuenta_origen_id': _cuentas[0]['id_cuenta'],
        'cuenta_destino_numero': '191-00000000-0-00', 
        'monto': val.abs(),
        'descripcion': desc
      });

      final uuidRef = _generateUuid().substring(0, 8);
      if (mounted) {
        setState(() {
          _comprobantes.insert(0, {
            'id': _generateUuid(),
            'tipo': type,
            'monto': val.abs(),
            'referencia_uuid': 'uuid-$uuidRef',
            'fecha': DateTime.now().toIso8601String().substring(0, 10)
          });
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Operación exitosa! Comprobante: uuid-$uuidRef'),
          backgroundColor: AppConstants.exitoGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _fetchData();
    } catch (e) {
      if (e is DioException && (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al realizar operación: $e'), behavior: SnackBarBehavior.floating));
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _executeServicePayment(String serviceType, String refCode, double amount) async {
    if (_cuentas.isEmpty) return;
    if (mounted) setState(() => _isLoading = true);

    try {
      await DioClient.instance.post('/cliente/operaciones/transferencia', data: {
        'cuenta_origen_id': _cuentas[0]['id_cuenta'],
        'cuenta_destino_numero': '191-00000000-0-00',
        'monto': amount,
        'descripcion': 'Pago de servicio: $serviceType - Ref: $refCode'
      });

      final uuidRef = _generateUuid().substring(0, 8);
      if (mounted) {
        setState(() {
          _comprobantes.insert(0, {
            'id': _generateUuid(),
            'tipo': 'PAGO_$serviceType',
            'monto': amount,
            'referencia_uuid': 'uuid-$uuidRef',
            'fecha': DateTime.now().toIso8601String().substring(0, 10)
          });
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Pago de $serviceType realizado! Ref: uuid-$uuidRef'),
          backgroundColor: AppConstants.exitoGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _fetchData();
    } catch (e) {
      if (e is DioException && (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error en pago de servicio: $e'), behavior: SnackBarBehavior.floating));
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _executePagoCuota(double amount, String paymentType) async {
    if (_cuentas.isEmpty || _creditos.isEmpty) return;
    if (mounted) setState(() => _isLoading = true);

    try {
      await DioClient.instance.post('/cliente/operaciones/pago-credito', data: {
        'cuenta_origen_id': _cuentas[0]['id_cuenta'],
        'credito_id': _creditos[0]['id_credito'],
        'monto': amount,
        'numero_cuota': 1
      });

      final uuidRef = _generateUuid().substring(0, 8);
      if (mounted) {
        setState(() {
          _comprobantes.insert(0, {
            'id': _generateUuid(),
            'tipo': 'PAGO_CREDITO_$paymentType',
            'monto': amount,
            'referencia_uuid': 'uuid-$uuidRef',
            'fecha': DateTime.now().toIso8601String().substring(0, 10)
          });
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Pago de crédito procesado ($paymentType)! Ref: uuid-$uuidRef'),
          backgroundColor: AppConstants.exitoGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _fetchData();
    } catch (e) {
      if (e is DioException && (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error en pago de cuota: $e'), behavior: SnackBarBehavior.floating));
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _generateUuid() {
    final random = Random();
    final hex = List.generate(256, (i) => i.toRadixString(16).padLeft(2, '0'));
    final buf = StringBuffer();
    for (var i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) buf.write('-');
      final r = random.nextInt(256);
      if (i == 6) {
        buf.write(hex[(r & 0x0f) | 0x40]);
      } else if (i == 8) {
        buf.write(hex[(r & 0x3f) | 0x80]);
      } else {
        buf.write(hex[r]);
      }
    }
    return buf.toString();
  }

  void _enviarSolicitud() async {
    if (_perfil == null) return;

    final monto = double.tryParse(_montoController.text) ?? 0;
    if (monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese un monto válido mayor a S/ 0'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    if (mounted) setState(() => _isLoading = true);
    try {
      final resProd = await DioClient.instance.get('/admin/productos-creditos');
      final listProd = resProd.data as List;
      if (listProd.isEmpty) {
        throw 'No hay productos de créditos disponibles configurados por el administrador';
      }
      final prodId = listProd[0]['id_producto_credito'];

      final negocios = _perfil!['negocios'] as List<dynamic>? ?? [];
      final idNegocio = negocios.isNotEmpty ? negocios[0]['id_negocio'] : null;
      if (idNegocio == null) {
        throw 'No se encontró un negocio registrado para este cliente';
      }

      await DioClient.instance.post('/cliente/solicitudes', data: {
        'id_cliente': _perfil!['id_cliente'],
        'id_negocio': idNegocio,
        'id_producto_credito': prodId,
        'monto_solicitado': monto,
        'plazo_meses': int.tryParse(_plazoController.text) ?? 12,
        'con_seguro_desgravamen': true,
        'garantia': _garantiaController.text,
        'destino_credito': _destinoController.text,
        'lat_captura': -12.046374,
        'lng_captura': -77.042793
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Solicitud de crédito enviada exitosamente!'), behavior: SnackBarBehavior.floating),
      );
      _montoController.clear();
      _plazoController.clear();
      _garantiaController.clear();
      _destinoController.clear();
      _fetchData();
    } catch (e) {
      if (e is DioException && (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        return;
      }
      String msg = 'Error al enviar solicitud';
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data.containsKey('detail')) {
          msg = data['detail'];
        } else {
          msg = '$data';
        }
      } else {
        msg = 'Error al enviar solicitud: $e';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _viewCronogramaDialog(String idCredito) async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final res = await DioClient.instance.get('/cliente/creditos/$idCredito/cronograma');
      final list = res.data as List;
      
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: ClienteTheme.bcpBgGrey,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Cronograma de Pagos BCP',
            style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, idx) {
                final cuota = list[idx];
                final paid = cuota['estado'] == 'PAGADA';
                final double cuotaMonto = double.tryParse(cuota['monto_cuota']?.toString() ?? '0.0') ?? 0.0;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: ClienteTheme.cardDecoration(showShadow: false),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: paid ? AppConstants.exitoGreen : ClienteTheme.bcpBlue,
                      foregroundColor: Colors.white,
                      child: Text(cuota['numero_cuota'].toString()),
                    ),
                    title: Text(
                      MoneyFormatter.format(cuotaMonto),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: ClienteTheme.bcpTextDark),
                    ),
                    subtitle: Text('Vence: ${cuota['fecha_pago'] ?? ""}'),
                    trailing: Text(
                      cuota['estado'] ?? '',
                      style: TextStyle(
                        color: paid ? AppConstants.exitoGreen : ClienteTheme.bcpOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar', style: TextStyle(color: ClienteTheme.bcpOrange, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    } catch (e) {
      if (e is DioException && (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar cronograma: $e'), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // -----------------------------------------------------------------
  // 35 Operations Taps
  // -----------------------------------------------------------------

  void _opDepositoSimple() {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Depósito a Cuenta BCP', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Cuenta Destino'),
              value: _cuentas.isNotEmpty ? _cuentas[0]['numero_cuenta'] : '191-00021-0-12',
              items: _cuentas.map<DropdownMenuItem<String>>((c) => DropdownMenuItem(value: c['numero_cuenta'] as String, child: Text(c['numero_cuenta'] as String))).toList(),
              onChanged: (_) {},
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Monto a Depositar (S/)'),
              keyboardType: TextInputType.number,
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: ClienteTheme.bcpTextGrey))),
          ElevatedButton(
            onPressed: () {
              final double amount = double.tryParse(amountController.text) ?? 0.0;
              if (amount <= 0 || amount > 10000) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Monto debe ser mayor a 0 y hasta S/ 10,000'), behavior: SnackBarBehavior.floating));
                return;
              }
              Navigator.pop(ctx);
              _executeBalanceAdjustment(amount, 'DEPOSITO', 'Depósito simple en ventanilla');
            },
            child: const Text('Depositar'),
          )
        ],
      ),
    );
  }

  void _opRetiroCuenta() {
    if (_cuentas.isEmpty) return;
    final amountController = TextEditingController();
    final double saldo = double.tryParse(_cuentas[0]['saldo_disponible'].toString()) ?? 0.0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Retiro de Cuenta BCP', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saldo Disponible: S/ $saldo', style: const TextStyle(fontWeight: FontWeight.bold, color: ClienteTheme.bcpBlue)),
            const SizedBox(height: 12),
            TextFormField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Monto a Retirar (S/)'),
              keyboardType: TextInputType.number,
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: ClienteTheme.bcpTextGrey))),
          ElevatedButton(
            onPressed: () {
              final double amount = double.tryParse(amountController.text) ?? 0.0;
              if (amount <= 0 || amount > saldo) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Monto inválido o supera saldo disponible'), behavior: SnackBarBehavior.floating));
                return;
              }
              Navigator.pop(ctx);
              _executeBalanceAdjustment(-amount, 'RETIRO', 'Retiro de efectivo cajero');
            },
            child: const Text('Retirar'),
          )
        ],
      ),
    );
  }

  void _opTransferCuentasPropias() {
    if (_cuentas.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debe poseer al menos 2 cuentas para realizar transferencia entre propias'), behavior: SnackBarBehavior.floating));
      return;
    }
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Transferir Cuentas Propias BCP', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Cuenta Origen'),
              value: _cuentas[0]['numero_cuenta'],
              items: _cuentas.map<DropdownMenuItem<String>>((c) => DropdownMenuItem(value: c['numero_cuenta'] as String, child: Text(c['numero_cuenta'] as String))).toList(),
              onChanged: (_) {},
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Cuenta Destino'),
              value: _cuentas[1]['numero_cuenta'],
              items: _cuentas.map<DropdownMenuItem<String>>((c) => DropdownMenuItem(value: c['numero_cuenta'] as String, child: Text(c['numero_cuenta'] as String))).toList(),
              onChanged: (_) {},
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Monto a Transferir (S/)'),
              keyboardType: TextInputType.number,
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: ClienteTheme.bcpTextGrey))),
          ElevatedButton(
            onPressed: () {
              final double amount = double.tryParse(amountController.text) ?? 0.0;
              final double saldo = double.tryParse(_cuentas[0]['saldo_disponible'].toString()) ?? 0.0;
              if (amount <= 0 || amount > saldo) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Monto inválido o supera saldo disponible'), behavior: SnackBarBehavior.floating));
                return;
              }
              Navigator.pop(ctx);
              _executeBalanceAdjustment(-amount, 'TRANSFERENCIA', 'Trans. cuentas propias');
            },
            child: const Text('Transferir'),
          )
        ],
      ),
    );
  }

  void _opTransferTerceros() {
    final accountController = TextEditingController();
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Transferencia a Terceros BCP', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: accountController,
              decoration: const InputDecoration(labelText: 'Número de cuenta destino'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Monto a Transferir (S/)'),
              keyboardType: TextInputType.number,
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: ClienteTheme.bcpTextGrey))),
          ElevatedButton(
            onPressed: () {
              final double amount = double.tryParse(amountController.text) ?? 0.0;
              if (accountController.text.isEmpty || amount <= 0) return;
              Navigator.pop(ctx);
              _executeBalanceAdjustment(-amount, 'TRANSFERENCIA_TERCERO', 'Transf. cuenta ${accountController.text}');
            },
            child: const Text('Transferir'),
          )
        ],
      ),
    );
  }

  void _opTransferProgramada() {
    final accountController = TextEditingController();
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Programar Transferencia', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: accountController,
              decoration: const InputDecoration(labelText: 'Cuenta Destino'),
            ),
            TextFormField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Monto (S/)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.calendar_month, color: ClienteTheme.bcpOrange),
                SizedBox(width: 8),
                Text('Fecha Programada: 2026-07-15', style: TextStyle(fontWeight: FontWeight.bold, color: ClienteTheme.bcpTextDark)),
              ],
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: ClienteTheme.bcpTextGrey))),
          ElevatedButton(
            onPressed: () {
              final double amount = double.tryParse(amountController.text) ?? 0.0;
              if (amount <= 0) return;
              setState(() {
                _transferenciasProgramadas.add({
                  'id': _generateUuid(),
                  'cuenta_destino': accountController.text,
                  'monto': amount,
                  'fecha_programada': '2026-07-15',
                  'estado': 'PENDIENTE'
                });
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Transferencia programada registrada con éxito!'), behavior: SnackBarBehavior.floating));
            },
            child: const Text('Programar'),
          )
        ],
      ),
    );
  }

  void _opHistorialTransferencias() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Historial Transferencias BCP', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 300,
          height: 200,
          child: ListView(
            children: const [
              ListTile(title: Text('Transf. Recibida BCP'), subtitle: Text('S/ 350.00 · 2026-06-20 · Completada')),
              ListTile(title: Text('Transf. Terceros'), subtitle: Text('S/ -100.00 · 2026-06-22 · Completada')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar', style: TextStyle(color: ClienteTheme.bcpOrange, fontWeight: FontWeight.bold)))
        ],
      ),
    );
  }

  void _opPagoLuz() {
    final sumController = TextEditingController();
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pago Luz del Sur / Enel', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: sumController,
              decoration: const InputDecoration(labelText: 'Número de Suministro'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Monto a Pagar (S/)'),
              keyboardType: TextInputType.number,
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: ClienteTheme.bcpTextGrey))),
          ElevatedButton(
            onPressed: () {
              if (sumController.text.isEmpty || (double.tryParse(amountController.text) ?? 0) <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Campos obligatorios incorrectos'), behavior: SnackBarBehavior.floating));
                return;
              }
              Navigator.pop(ctx);
              _executeServicePayment('LUZ', sumController.text, double.tryParse(amountController.text) ?? 0.0);
            },
            child: const Text('Pagar'),
          )
        ],
      ),
    );
  }

  void _opPagoAgua() {
    final clientController = TextEditingController();
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pago de Agua: Sedapal', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: clientController,
              decoration: const InputDecoration(labelText: 'Código de Cliente (NIS)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Monto (S/)'),
              keyboardType: TextInputType.number,
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: ClienteTheme.bcpTextGrey))),
          ElevatedButton(
            onPressed: () {
              if (clientController.text.isEmpty || (double.tryParse(amountController.text) ?? 0) <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verifique NIS o monto'), behavior: SnackBarBehavior.floating));
                return;
              }
              Navigator.pop(ctx);
              _executeServicePayment('AGUA', clientController.text, double.tryParse(amountController.text) ?? 0.0);
            },
            child: const Text('Pagar'),
          )
        ],
      ),
    );
  }

  void _opPagoInternet() {
    final contractController = TextEditingController();
    final amountController = TextEditingController();
    String provider = 'Movistar';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pago Internet / Cable', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Proveedor'),
              value: provider,
              items: ['Movistar', 'Claro', 'Entel', 'WOM'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (val) => provider = val!,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: contractController,
              decoration: const InputDecoration(labelText: 'Número de Contrato'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Monto (S/)'),
              keyboardType: TextInputType.number,
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: ClienteTheme.bcpTextGrey))),
          ElevatedButton(
            onPressed: () {
              if (contractController.text.isEmpty || (double.tryParse(amountController.text) ?? 0) <= 0) return;
              Navigator.pop(ctx);
              _executeServicePayment('INTERNET ($provider)', contractController.text, double.tryParse(amountController.text) ?? 0.0);
            },
            child: const Text('Pagar'),
          )
        ],
      ),
    );
  }

  void _opPagoGas() {
    final clientController = TextEditingController();
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pago de Gas: Cálidda', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: clientController,
              decoration: const InputDecoration(labelText: 'Código de Cliente Gas'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Monto Consumo (S/)'),
              keyboardType: TextInputType.number,
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: ClienteTheme.bcpTextGrey))),
          ElevatedButton(
            onPressed: () {
              if (clientController.text.isEmpty || (double.tryParse(amountController.text) ?? 0) <= 0) return;
              Navigator.pop(ctx);
              _executeServicePayment('GAS', clientController.text, double.tryParse(amountController.text) ?? 0.0);
            },
            child: const Text('Pagar'),
          )
        ],
      ),
    );
  }

  void _opPagoTelefono() {
    final phoneController = TextEditingController();
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pago Teléfono Fijo', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Número telefónico (7 dígitos)'),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Monto (S/)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: ClienteTheme.bcpTextGrey))),
          ElevatedButton(
            onPressed: () {
              if (phoneController.text.length != 7 || (double.tryParse(amountController.text) ?? 0) <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Número de teléfono debe tener 7 dígitos'), behavior: SnackBarBehavior.floating));
                return;
              }
              Navigator.pop(ctx);
              _executeServicePayment('TELEFONO', phoneController.text, double.tryParse(amountController.text) ?? 0.0);
            },
            child: const Text('Pagar'),
          )
        ],
      ),
    );
  }

  void _opHistorialServicios() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Historial Pagos Servicios BCP', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 300,
          height: 200,
          child: ListView(
            children: const [
              ListTile(leading: Icon(Icons.lightbulb, color: Colors.blue), title: Text('Servicio LUZ del Sur'), subtitle: Text('S/ 120.00 · Pago realizado: 2026-06-20 · PAGADO')),
              ListTile(leading: Icon(Icons.water_drop, color: Colors.blue), title: Text('Servicio AGUA Sedapal'), subtitle: Text('S/ 45.00 · Pago realizado: 2026-06-22 · PAGADO')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar', style: TextStyle(color: ClienteTheme.bcpOrange, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _opSolicitudPrestamo() {
    setState(() {
      _currentIndex = 3; 
    });
  }

  void _opPagoCuotaPrestamo() {
    if (_creditos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No posee préstamos vigentes para pagar'), behavior: SnackBarBehavior.floating));
      return;
    }
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pago Cuota de Préstamo BCP', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Código Préstamo: ${_creditos[0]['numero_credito']}'),
            Text('Cuota Mensual: S/ ${_creditos[0]['cuota_mensual']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Monto del Pago (S/)'),
              keyboardType: TextInputType.number,
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: ClienteTheme.bcpTextGrey))),
          ElevatedButton(
            onPressed: () {
              final double amount = double.tryParse(amountController.text) ?? 0.0;
              if (amount <= 0) return;
              Navigator.pop(ctx);
              _executePagoCuota(amount, 'CUOTA');
            },
            child: const Text('Pagar Cuota'),
          )
        ],
      ),
    );
  }

  void _opAdelantoPagoPrestamo() {
    if (_creditos.isEmpty) return;
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Adelanto de Pago Préstamo BCP', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saldo Pendiente: S/ ${_creditos[0]['saldo_capital']}'),
            const SizedBox(height: 12),
            TextFormField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Monto del Adelanto (S/)'),
              keyboardType: TextInputType.number,
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: ClienteTheme.bcpTextGrey))),
          ElevatedButton(
            onPressed: () {
              final double amount = double.tryParse(amountController.text) ?? 0.0;
              if (amount <= 0) return;
              Navigator.pop(ctx);
              _executePagoCuota(amount, 'ADELANTO');
            },
            child: const Text('Confirmar Adelanto'),
          )
        ],
      ),
    );
  }

  void _opHistorialPagoPrestamo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Historial Pagos Préstamo', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 300,
          height: 200,
          child: ListView(
            children: const [
              ListTile(title: Text('Pago de Cuota N° 1'), subtitle: Text('S/ 450.00 · Pago realizado: 2026-06-15')),
              ListTile(title: Text('Adelanto Capital'), subtitle: Text('S/ 1200.00 · Pago realizado: 2026-06-20')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar', style: TextStyle(color: ClienteTheme.bcpOrange, fontWeight: FontWeight.bold)))
        ],
      ),
    );
  }

  void _opCancelacionAnticipada() {
    if (_creditos.isEmpty) return;
    final double balance = double.tryParse(_creditos[0]['saldo_capital'].toString()) ?? 0.0;
    final double discount = balance * 0.05;
    final double finalPay = balance - discount;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancelación Anticipada', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Capital Pendiente: S/ $balance'),
            Text('Descuento por cancelación (5%): S/ ${discount.toStringAsFixed(2)}', style: const TextStyle(color: AppConstants.exitoGreen)),
            Text('Monto Final a pagar: S/ ${finalPay.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: ClienteTheme.bcpTextGrey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _executePagoCuota(finalPay, 'CANCELACION_ANTICIPADA');
            },
            child: const Text('Pagar y Cancelar'),
          )
        ],
      ),
    );
  }

  void _opSimuladorCuotaBasico() {
    final mController = TextEditingController(text: '10000');
    final pController = TextEditingController(text: '12');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Simulador Cuota Básico BCP', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: mController,
              decoration: const InputDecoration(labelText: 'Monto del Préstamo (S/)'),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: pController,
              decoration: const InputDecoration(labelText: 'Plazo (Meses)'),
              keyboardType: TextInputType.number,
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: ClienteTheme.bcpTextGrey))),
          ElevatedButton(
            onPressed: () {
              final double amount = (double.tryParse(mController.text) ?? 5000).clamp(0.0, 9999999.0);
              final int months = (int.tryParse(pController.text) ?? 12).clamp(1, 120);
              final double tem = 0.03;
              final double cuota = amount * tem / (1 - pow(1 + tem, -months));
              Navigator.pop(ctx);
              
              showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  backgroundColor: ClienteTheme.bcpBgGrey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Resultado Simulación', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Cuota Mensual: S/ ${cuota.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: ClienteTheme.bcpBlue)),
                      const SizedBox(height: 12),
                      Text('TEA Equivalente: 38.4%'),
                      Text('Total a pagar: S/ ${(cuota * months).toStringAsFixed(2)}'),
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c), child: const Text('Entendido', style: TextStyle(color: ClienteTheme.bcpOrange, fontWeight: FontWeight.bold))),
                  ],
                ),
              );
            },
            child: const Text('Simular'),
          )
        ],
      ),
    );
  }

  void _opSimuladorAmortizacion() {
    final mController = TextEditingController(text: '10000');
    final pController = TextEditingController(text: '6');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tabla Amortización BCP', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: mController,
              decoration: const InputDecoration(labelText: 'Monto (S/)'),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: pController,
              decoration: const InputDecoration(labelText: 'Plazo (Meses)'),
              keyboardType: TextInputType.number,
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: ClienteTheme.bcpTextGrey))),
          ElevatedButton(
            onPressed: () {
              final double amount = (double.tryParse(mController.text) ?? 10000).clamp(0.0, 9999999.0);
              final int months = (int.tryParse(pController.text) ?? 6).clamp(1, 120);
              final double tem = 0.03;
              final double cuota = amount * tem / (1 - pow(1 + tem, -months));
              Navigator.pop(ctx);

              double saldo = amount;
              List<Map<String, dynamic>> rows = [];
              for (int i = 1; i <= months; i++) {
                final double interes = saldo * tem;
                final double capital = cuota - interes;
                final double finalSaldo = saldo - capital;
                rows.add({
                  'n': i,
                  'inicial': saldo,
                  'interes': interes,
                  'capital': capital,
                  'cuota': cuota,
                  'final': finalSaldo
                });
                saldo = finalSaldo;
              }

              showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  backgroundColor: ClienteTheme.bcpBgGrey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Cronograma Amortización (TEM 3%)', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
                  content: SizedBox(
                    width: 300,
                    height: 350,
                    child: ListView.builder(
                      itemCount: rows.length,
                      itemBuilder: (context, idx) {
                        final r = rows[idx];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Cuota ${r['n']} | S/ ${r['cuota'].toStringAsFixed(2)}\nCapital: S/ ${r['capital'].toStringAsFixed(2)} · Interés: S/ ${r['interes'].toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cerrar', style: TextStyle(color: ClienteTheme.bcpOrange, fontWeight: FontWeight.bold))),
                  ],
                ),
              );
            },
            child: const Text('Calcular'),
          )
        ],
      ),
    );
  }

  void _opSimuladorComparadorTasas() {
    final double amount = 10000;
    final int months = 12;
    final double c2 = amount * 0.02 / (1 - pow(1 + 0.02, -months));
    final double c3 = amount * 0.03 / (1 - pow(1 + 0.03, -months));
    final double c4 = amount * 0.04 / (1 - pow(1 + 0.04, -months));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Comparador de Tasas BCP', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Monto S/ 10,000.00 · Plazo 12 meses', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(title: const Text('Entidad A: TEM 2.0%'), subtitle: Text('Cuota: S/ ${c2.toStringAsFixed(2)} · Total: S/ ${(c2*12).toStringAsFixed(2)}')),
            ListTile(title: const Text('Entidad B (BCP): TEM 3.0%'), subtitle: Text('Cuota: S/ ${c3.toStringAsFixed(2)} · Total: S/ ${(c3*12).toStringAsFixed(2)}')),
            ListTile(title: const Text('Entidad C: TEM 4.0%'), subtitle: Text('Cuota: S/ ${c4.toStringAsFixed(2)} · Total: S/ ${(c4*12).toStringAsFixed(2)}')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar', style: TextStyle(color: ClienteTheme.bcpOrange, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _opComparadorSimulaciones() {
    final double amount = 10000;
    final double tem = 0.03;
    final double cuota12 = amount * tem / (1 - pow(1 + tem, -12));
    final double cuota24 = amount * tem / (1 - pow(1 + tem, -24));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Comparador de Préstamos', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Monto Base: S/ 10,000.00 (TEM 3%)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('Simulación 1: 12 meses'),
                subtitle: Text('Cuota: S/ ${cuota12.toStringAsFixed(2)}\nTotal intereses: S/ ${(cuota12*12 - amount).toStringAsFixed(2)}'),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Simulación 2: 24 meses'),
                subtitle: Text('Cuota: S/ ${cuota24.toStringAsFixed(2)}\nTotal intereses: S/ ${(cuota24*24 - amount).toStringAsFixed(2)}'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar', style: TextStyle(color: ClienteTheme.bcpOrange, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _opAhorroProgramadoCrear() {
    final nameController = TextEditingController();
    final metaController = TextEditingController();
    String frequency = 'Mensual';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Crear Ahorro Programado', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre del ahorro'),
            ),
            TextFormField(
              controller: metaController,
              decoration: const InputDecoration(labelText: 'Monto Meta (S/)'),
              keyboardType: TextInputType.number,
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Frecuencia'),
              value: frequency,
              items: ['Diario', 'Semanal', 'Mensual'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => frequency = val!,
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: ClienteTheme.bcpTextGrey))),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty || (double.tryParse(metaController.text) ?? 0) <= 0) return;
              setState(() {
                _ahorrosProgramados.add({
                  'id': _generateUuid(),
                  'nombre': nameController.text,
                  'monto_meta': double.tryParse(metaController.text) ?? 0.0,
                  'monto_actual': 0.0,
                  'frecuencia': frequency,
                  'activo': true
                });
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Ahorro programado creado exitosamente!'), behavior: SnackBarBehavior.floating));
            },
            child: const Text('Crear'),
          )
        ],
      ),
    );
  }

  void _opAhorroAbonar() {
    if (_ahorrosProgramados.isEmpty) return;
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Abonar a Ahorro BCP', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Seleccionar Ahorro'),
              value: _ahorrosProgramados[0]['nombre'],
              items: _ahorrosProgramados.map((a) => DropdownMenuItem<String>(value: a['nombre'] as String, child: Text(a['nombre'] as String))).toList(),
              onChanged: (_) {},
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Monto a Abonar (S/)'),
              keyboardType: TextInputType.number,
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: ClienteTheme.bcpTextGrey))),
          ElevatedButton(
            onPressed: () {
              final double amount = double.tryParse(amountController.text) ?? 0;
              if (amount <= 0) return;
              setState(() {
                _ahorrosProgramados[0]['monto_actual'] += amount;
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Abono realizado con éxito!'), behavior: SnackBarBehavior.floating));
            },
            child: const Text('Abonar'),
          )
        ],
      ),
    );
  }

  void _opMetaAhorroCrear() {
    final nameController = TextEditingController();
    final metaController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Crear Meta Ahorro', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre de la meta'),
            ),
            TextFormField(
              controller: metaController,
              decoration: const InputDecoration(labelText: 'Monto Objetivo (S/)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: ClienteTheme.bcpTextGrey))),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty || (double.tryParse(metaController.text) ?? 0) <= 0) return;
              setState(() {
                _metasAhorro.add({
                  'id': _generateUuid(),
                  'nombre': nameController.text,
                  'categoria': 'Ahorro',
                  'monto_objetivo': double.tryParse(metaController.text) ?? 0.0,
                  'monto_actual': 0.0,
                  'fecha_limite': '2026-12-31',
                  'estado': 'ACTIVA'
                });
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Meta de ahorro guardada!'), behavior: SnackBarBehavior.floating));
            },
            child: const Text('Crear Meta'),
          )
        ],
      ),
    );
  }

  void _opAporteMetaAhorro() {
    if (_metasAhorro.isEmpty) return;
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Aportar a Meta BCP', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Monto de aporte (S/)'),
              keyboardType: TextInputType.number,
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: ClienteTheme.bcpTextGrey))),
          ElevatedButton(
            onPressed: () {
              final double amount = double.tryParse(amountController.text) ?? 0;
              if (amount <= 0) return;
              setState(() {
                _metasAhorro[0]['monto_actual'] += amount;
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Aporte a meta guardado con éxito!'), behavior: SnackBarBehavior.floating));
            },
            child: const Text('Aportar'),
          )
        ],
      ),
    );
  }

  void _opAhorroAutomatico() {
    double selectedPercent = 5.0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: ClienteTheme.bcpBgGrey,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Ahorro Automático %', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ahorra un porcentaje de cada abono a tu cuenta principal de forma automática.'),
              const SizedBox(height: 12),
              Slider(
                min: 1,
                max: 30,
                divisions: 29,
                activeColor: ClienteTheme.bcpOrange,
                value: selectedPercent,
                onChanged: (val) {
                  setDialogState(() => selectedPercent = val);
                },
              ),
              Text('Porcentaje a Ahorrar: ${selectedPercent.round()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: ClienteTheme.bcpBlue)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: ClienteTheme.bcpTextGrey))),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _reglasAhorroAutomatico.add({
                    'id': _generateUuid(),
                    'cuenta_origen': 'Cuenta Soles',
                    'cuenta_destino': 'Fondo Cusco',
                    'porcentaje': selectedPercent,
                    'activa': true
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Regla de ahorro automático configurada!'), behavior: SnackBarBehavior.floating));
              },
              child: const Text('Activar'),
            )
          ],
        ),
      ),
    );
  }

  void _opPlazoFijoCrear() {
    final amountController = TextEditingController();
    String plazo = '360';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Crear Plazo Fijo', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Plazo en días'),
              value: plazo,
              items: const [
                DropdownMenuItem(value: '30', child: Text('30 días (TEA 3.0%)')),
                DropdownMenuItem(value: '90', child: Text('90 días (TEA 5.0%)')),
                DropdownMenuItem(value: '360', child: Text('360 días (TEA 8.0%)')),
              ],
              onChanged: (val) => plazo = val!,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Monto a Invertir (S/)'),
              keyboardType: TextInputType.number,
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: ClienteTheme.bcpTextGrey))),
          ElevatedButton(
            onPressed: () {
              final double amount = double.tryParse(amountController.text) ?? 0.0;
              if (amount < 500) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El monto mínimo es de S/ 500'), behavior: SnackBarBehavior.floating));
                return;
              }
              Navigator.pop(ctx);
              _executeBalanceAdjustment(-amount, 'DEPOSITO_PLAZO', 'Apertura plazo fijo');
            },
            child: const Text('Crear'),
          )
        ],
      ),
    );
  }

  void _opPlazoFijoRetirar() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Retiro Plazo Fijo BCP', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Plazo Fijo N° 002-1928-1123'),
            Text('Monto: S/ 10,000.00'),
            Text('Penalidad por retiro anticipado: 50% de intereses', style: TextStyle(color: AppConstants.errorRed, fontSize: 11)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: ClienteTheme.bcpTextGrey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _executeBalanceAdjustment(10050.0, 'RETIRO_PLAZO', 'Retiro plazo fijo cancelado');
            },
            child: const Text('Retirar'),
          )
        ],
      ),
    );
  }

  void _opRetiroProgramado() {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Retiro Programado', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Monto a Programar (S/)'),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Motivo del retiro'),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.calendar_month, color: ClienteTheme.bcpOrange),
                SizedBox(width: 8),
                Text('Fecha programada: 2026-07-05', style: TextStyle(fontWeight: FontWeight.bold, color: ClienteTheme.bcpTextDark)),
              ],
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: ClienteTheme.bcpTextGrey))),
          ElevatedButton(
            onPressed: () {
              final double amount = double.tryParse(amountController.text) ?? 0.0;
              if (amount <= 0) return;
              setState(() {
                _retirosProgramados.add({
                  'id': _generateUuid(),
                  'monto': amount,
                  'fecha_programada': '2026-07-05',
                  'motivo': reasonController.text,
                  'estado': 'PENDIENTE'
                });
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Retiro programado con éxito!'), behavior: SnackBarBehavior.floating));
            },
            child: const Text('Programar'),
          )
        ],
      ),
    );
  }

  void _opRecargaCelular() {
    final phoneController = TextEditingController();
    final amountController = TextEditingController();
    String operator = 'Claro';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Recarga de Celular', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Celular de destino (9 dígitos)'),
              keyboardType: TextInputType.number,
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Operadora'),
              value: operator,
              items: ['Claro', 'Movistar', 'Entel', 'Bitel'].map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
              onChanged: (val) => operator = val!,
            ),
            TextFormField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Monto de recarga (S/)'),
              keyboardType: TextInputType.number,
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: ClienteTheme.bcpTextGrey))),
          ElevatedButton(
            onPressed: () {
              final double amount = double.tryParse(amountController.text) ?? 0.0;
              if (phoneController.text.length != 9 || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verifique celular de 9 dígitos y monto'), behavior: SnackBarBehavior.floating));
                return;
              }
              Navigator.pop(ctx);
              _executeBalanceAdjustment(-amount, 'RECARGA', 'Recarga celular $operator a ${phoneController.text}');
            },
            child: const Text('Recargar'),
          )
        ],
      ),
    );
  }

  void _opHistorialRecargas() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Historial de Recargas', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 300,
          height: 200,
          child: ListView(
            children: const [
              ListTile(title: Text('Recarga Claro 987654321'), subtitle: Text('S/ 20.00 · Fecha: 2026-06-20')),
              ListTile(title: Text('Recarga Entel 987654322'), subtitle: Text('S/ 10.00 · Fecha: 2026-06-23')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar', style: TextStyle(color: ClienteTheme.bcpOrange, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _opRegistroGastos() {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    String category = 'Comida';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Registro de Gastos', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Descripción del gasto'),
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Categoría'),
              value: category,
              items: ['Comida', 'Transporte', 'Salud', 'Entretenimiento'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => category = val!,
            ),
            TextFormField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Monto (S/)'),
              keyboardType: TextInputType.number,
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: ClienteTheme.bcpTextGrey))),
          ElevatedButton(
            onPressed: () {
              final double amount = double.tryParse(amountController.text) ?? 0;
              if (descController.text.isEmpty || amount <= 0) return;
              setState(() {
                _gastosPersonales.add({
                  'id': _generateUuid(),
                  'descripcion': descController.text,
                  'monto': amount,
                  'categoria': category,
                  'fecha': DateTime.now().toIso8601String().substring(0, 10)
                });
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Gasto registrado en la bitácora financiera!'), behavior: SnackBarBehavior.floating));
            },
            child: const Text('Registrar'),
          )
        ],
      ),
    );
  }

  void _opPresupuestosMes() {
    showDialog(
      context: context,
      builder: (ctx) {
        Map<String, double> spent = {'Comida': 0.0, 'Transporte': 0.0, 'Salud': 0.0, 'Entretenimiento': 0.0};
        for (var g in _gastosPersonales) {
          final cat = g['categoria'];
          if (spent.containsKey(cat)) {
            spent[cat] = spent[cat]! + (double.tryParse(g['monto'].toString()) ?? 0.0);
          }
        }

        return AlertDialog(
          backgroundColor: ClienteTheme.bcpBgGrey,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Presupuesto por Categoría', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 300,
            height: 350,
            child: ListView(
              children: spent.keys.map((cat) {
                final double maxLimit = _limitesPresupuesto[cat] ?? 500.0;
                final double currentSpent = spent[cat]!;
                final double percent = maxLimit > 0 ? currentSpent / maxLimit : 0.0;
                final isWarning = percent >= 0.9;
                
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(cat, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('S/ $currentSpent / S/ $maxLimit', style: TextStyle(color: isWarning ? AppConstants.errorRed : Colors.grey, fontSize: 11.5)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(value: percent, color: isWarning ? AppConstants.errorRed : ClienteTheme.bcpBlue),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar', style: TextStyle(color: ClienteTheme.bcpOrange, fontWeight: FontWeight.bold))),
          ],
        );
      },
    );
  }

  void _opVouchersOperaciones() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Comprobantes Emitidos BCP', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 300,
          height: 250,
          child: ListView.builder(
            itemCount: _comprobantes.length,
            itemBuilder: (c, idx) {
              final comp = _comprobantes[idx];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.verified, color: AppConstants.exitoGreen),
                  title: Text('${comp['tipo']}'),
                  subtitle: Text('Monto: S/ ${comp['monto']} · Ref: ${comp['referencia_uuid']}'),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar', style: TextStyle(color: ClienteTheme.bcpOrange, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _opHistorialDepositos() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClienteTheme.bcpBgGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Historial Depósitos BCP', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 300,
          height: 200,
          child: ListView(
            children: const [
              ListTile(title: Text('Depósito en Ventanilla BCP'), subtitle: Text('S/ 1,500.00 · Fecha: 2026-06-15')),
              ListTile(title: Text('Depósito Simple Cuenta Propia'), subtitle: Text('S/ 200.00 · Fecha: 2026-06-22')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar', style: TextStyle(color: ClienteTheme.bcpOrange, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _getBody(int index) {
    switch (index) {
      case 0:
        return CuentasTabView(
          cuentas: _cuentas,
          tarjetas: _tarjetas,
          movimientos: _movimientos,
        );
      case 1:
        return CreditosTabView(
          creditos: _creditos,
          onViewCronograma: _viewCronogramaDialog,
        );
      case 2:
        return OperacionesTabView(
          onDepositoSimple: _opDepositoSimple,
          onRetiroCuenta: _opRetiroCuenta,
          onTransferCuentasPropias: _opTransferCuentasPropias,
          onTransferTerceros: _opTransferTerceros,
          onTransferProgramada: _opTransferProgramada,
          onHistorialTransferencias: _opHistorialTransferencias,
          onPagoLuz: _opPagoLuz,
          onPagoAgua: _opPagoAgua,
          onPagoInternet: _opPagoInternet,
          onPagoGas: _opPagoGas,
          onPagoTelefono: _opPagoTelefono,
          onHistorialServicios: _opHistorialServicios,
          onSolicitudPrestamo: _opSolicitudPrestamo,
          onPagoCuotaPrestamo: _opPagoCuotaPrestamo,
          onAdelantoPagoPrestamo: _opAdelantoPagoPrestamo,
          onHistorialPagoPrestamo: _opHistorialPagoPrestamo,
          onCancelacionAnticipada: _opCancelacionAnticipada,
          onSimuladorCuotaBasico: _opSimuladorCuotaBasico,
          onSimuladorAmortizacion: _opSimuladorAmortizacion,
          onSimuladorComparadorTasas: _opSimuladorComparadorTasas,
          onComparadorSimulaciones: _opComparadorSimulaciones,
          onAhorroProgramadoCrear: _opAhorroProgramadoCrear,
          onAhorroAbonar: _opAhorroAbonar,
          onMetaAhorroCrear: _opMetaAhorroCrear,
          onAporteMetaAhorro: _opAporteMetaAhorro,
          onAhorroAutomatico: _opAhorroAutomatico,
          onPlazoFijoCrear: _opPlazoFijoCrear,
          onPlazoFijoRetirar: _opPlazoFijoRetirar,
          onRetiroProgramado: _opRetiroProgramado,
          onRecargaCelular: _opRecargaCelular,
          onHistorialRecargas: _opHistorialRecargas,
          onRegistroGastos: _opRegistroGastos,
          onPresupuestosMes: _opPresupuestosMes,
          onVouchersOperaciones: _opVouchersOperaciones,
          onHistorialDepositos: _opHistorialDepositos,
        );
      case 3:
        return SolicitarTabView(
          montoController: _montoController,
          plazoController: _plazoController,
          garantiaController: _garantiaController,
          destinoController: _destinoController,
          onSendRequest: _enviarSolicitud,
          solicitudes: _solicitudes,
        );
      case 4:
        return AlertasTabView(
          notificaciones: _notificaciones,
        );
      default:
        return const Center(child: Text('Opción no disponible'));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.token == null) {
        context.go('/login');
      }
    });
    return Scaffold(
      backgroundColor: ClienteTheme.bcpBgGrey,
      appBar: AppBar(
        backgroundColor: ClienteTheme.bcpBlue,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const BcpLogo(fontSize: 13, paddingHorizontal: 8, paddingVertical: 4),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _perfil != null ? 'Hola, ${_perfil!['nombres']}' : 'Banca Móvil BCP',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: Colors.white),
            onPressed: _isLoading ? null : _fetchData,
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app_outlined, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: ClienteTheme.bcpOrange))
          : _getBody(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: ClienteTheme.bcpOrange,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Cuentas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monetization_on_outlined),
            activeIcon: Icon(Icons.monetization_on),
            label: 'Créditos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz_outlined),
            activeIcon: Icon(Icons.swap_horiz),
            label: 'Operaciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline_outlined),
            activeIcon: Icon(Icons.add_circle),
            label: 'Solicitar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Alertas',
          ),
        ],
      ),
    );
  }
}
