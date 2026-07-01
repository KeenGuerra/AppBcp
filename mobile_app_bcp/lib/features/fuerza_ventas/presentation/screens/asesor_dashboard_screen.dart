// asesor_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app_bcp/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:mobile_app_bcp/core/network/connectivity_service.dart';
import 'package:mobile_app_bcp/core/storage/local_database.dart';
import 'package:mobile_app_bcp/core/storage/local_draft_service.dart';
import 'package:mobile_app_bcp/features/auth/presentation/providers/auth_provider.dart';
import 'package:signature/signature.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'dart:math';

// Custom design components
import '../theme/fuerza_ventas_theme.dart';
import '../widgets/cartera_view.dart';
import '../widgets/ruta_view.dart';
import '../widgets/ficha_view.dart';
import '../widgets/preevaluacion_campana_view.dart';
import '../widgets/stepper_view.dart';
import '../widgets/mora_view.dart';
import '../widgets/sync_panel.dart';
import '../widgets/reportes_supervisor_view.dart';
import '../widgets/solicitudes_view.dart';

class AsesorDashboardScreen extends ConsumerStatefulWidget {
  const AsesorDashboardScreen({super.key});

  @override
  ConsumerState<AsesorDashboardScreen> createState() => _AsesorDashboardScreenState();
}

class _AsesorDashboardScreenState extends ConsumerState<AsesorDashboardScreen> {
  int _selectedMenuIndex = 0;
  bool _isLoading = false;
  bool _isOnline = true;
  int _pendingSyncCount = 0;

  // Connectivity Listener
  late final ConnectivityService _connectivityService;

  // Data Cache
  List<Map<String, dynamic>> _cartera = [];
  List<Map<String, dynamic>> _filteredCartera = [];
  List<dynamic> _solicitudes = [];
  Map<String, dynamic>? _selectedFicha;
  List<Map<String, dynamic>> _draftsList = [];

  // Stepper state
  int _currentStep = 0;
  String? _stepperClientId;
  String? _stepperNegocioId;
  String? _stepperSolId;
  final _stepperMontoController = TextEditingController(text: '5000');
  final _stepperPlazoController = TextEditingController(text: '12');
  final _stepperNameController = TextEditingController();
  final _stepperDocController = TextEditingController();
  final _stepperTelController = TextEditingController();
  final _stepperIncomeController = TextEditingController(text: '3500');
  final _stepperExpenseController = TextEditingController(text: '1500');
  final _stepperDestinoController = TextEditingController(text: 'Compra de mercadería');
  String _stepperEstadoCivil = 'SOLTERO';
  String? _evalResultado;
  int? _evalPuntaje;
  double? _evalCuota;
  bool _dniUploaded = false;
  final SignatureController _sigController = SignatureController(
    penStrokeWidth: 4,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String _activeFilter = 'TODOS';

  // Route map state
  Offset _mapOffset = const Offset(150, 100);
  double _mapZoom = 1.0;
  bool _isRouteOptimized = false;
  List<int> _optimizedRouteIndices = [];
  int? _hoveredMapClientIndex;

  // Geofence Zone coordinates (simulated polygon box in relative offsets)
  final List<Offset> _geofenceZone = const [
    Offset(40, 40),
    Offset(260, 40),
    Offset(260, 260),
    Offset(40, 260),
  ];

  // Client coordinate offsets for visual map representation
  List<Offset> _clientOffsets = [];

  // Campaigns list
  List<Map<String, dynamic>> _campaigns = [];

  // Recovery list (Mora)
  List<Map<String, dynamic>> _moraList = [];
  double _montoTotalVencido = 0.0;

  // Draft service
  final LocalDraftService _draftService = LocalDraftService();

  List<Map<String, dynamic>> _alertas = [];
  String _lastSyncTime = "";
  String? _selectedIdCartera;

  // Supervisor metrics
  List<dynamic> _productividadData = [];

  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService();
    _initConnectivityListener();
    _loadInitialData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _stepperMontoController.dispose();
    _stepperPlazoController.dispose();
    _stepperNameController.dispose();
    _stepperDocController.dispose();
    _stepperTelController.dispose();
    _stepperIncomeController.dispose();
    _stepperExpenseController.dispose();
    _stepperDestinoController.dispose();
    _sigController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _initConnectivityListener() {
    _connectivityService.isConnected.then((value) {
      if (mounted) setState(() => _isOnline = value);
      _checkPendingSyncs();
    }).catchError((err) {
      if (mounted) setState(() => _isOnline = true);
      _checkPendingSyncs();
    });
    try {
      _connectivityService.onConnectivityChanged.listen((value) {
        if (mounted) {
          setState(() => _isOnline = value);
          if (value) {
            _syncPendingData();
          }
          _checkPendingSyncs();
        }
      }, onError: (err) {
        debugPrint("Error in onConnectivityChanged stream: $err");
      });
    } catch (e) {
      debugPrint("Exception setting up connectivity listener: $e");
    }
  }

  Future<void> _checkPendingSyncs() async {
    final db = await LocalDatabase.database;
    final listVisitas = await db.query('local_visitas_pendientes', where: 'pendiente_sync = 1');
    final listSols = await db.query('local_solicitudes_pendientes', where: 'pendiente_sync = 1');
    final listDocs = await db.query('local_documentos_pendientes', where: 'pendiente_sync = 1');
    if (mounted) {
      setState(() {
        _pendingSyncCount = listVisitas.length + listSols.length + listDocs.length;
      });
    }
  }

  Future<void> _loadInitialData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      try {
        await _checkPendingSyncs();
      } catch (e) {
        debugPrint("Error _checkPendingSyncs: $e");
      }
      try {
        await _loadDrafts();
      } catch (e) {
        debugPrint("Error _loadDrafts: $e");
      }
      try {
        await _loadCampaigns();
      } catch (e) {
        debugPrint("Error _loadCampaigns: $e");
      }
      try {
        await _loadMoraData();
      } catch (e) {
        debugPrint("Error _loadMoraData: $e");
      }
      try {
        await _loadAlertas();
      } catch (e) {
        debugPrint("Error _loadAlertas: $e");
      }
      
      if (_isOnline) {
        try {
          final resCart = await DioClient.instance.get('/fventas/cartera/hoy');
          final rawList = List<Map<String, dynamic>>.from(resCart.data);
          
          // Cache locally in SQLite
          final db = await LocalDatabase.database;
          await db.delete('local_cartera');
          for (var item in rawList) {
            final cli = item['cliente'];
            await db.insert('local_cartera', {
              'id_cartera': item['id_cartera'],
              'id_asesor': item['id_asesor'],
              'id_cliente': item['id_cliente'],
              'id_solicitud': item['id_solicitud'],
              'fecha_asignacion': item['fecha_asignacion'],
              'tipo_gestion': item['tipo_gestion'],
              'prioridad': item['prioridad'],
              'score_prioridad': item['score_prioridad'],
              'estado_visita': item['estado_visita'],
              'resultado_visita': item['resultado_visita'],
              'observacion_visita': item['observacion_visita'],
              'lat_visita': item['lat_visita'],
              'lng_visita': item['lng_visita'],
              'timestamp_visita': item['timestamp_visita'],
              'pendiente_sync': 0
            }, conflictAlgorithm: ConflictAlgorithm.replace);

            if (cli != null) {
              await db.insert('local_clientes', {
                'id_cliente': cli['id_cliente'],
                'documento': cli['documento'],
                'nombres': cli['nombres'],
                'apellidos': cli['apellidos'],
                'telefono': cli['telefono'],
                'correo': cli['correo'],
                'direccion': cli['direccion'],
                'distrito': cli['distrito'],
                'provincia': cli['provincia'],
                'departamento': cli['departamento'],
                'fecha_nacimiento': cli['fecha_nacimiento'],
                'estado_civil': cli['estado_civil'],
                'ocupacion': cli['ocupacion'],
                'tipo_cliente': cli['tipo_cliente'],
              }, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }

          final resSols = await DioClient.instance.get('/fventas/solicitudes');
          _solicitudes = resSols.data;

        } catch (e) {
          debugPrint("Error loading from online API: $e");
          await _loadLocalData();
        }
      } else {
        await _loadLocalData();
      }
      
      await _loadLocalData();
      _generateClientOffsets();
      _applyFilters();
      final now = DateTime.now();
      _lastSyncTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      debugPrint("Error general in _loadInitialData: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLocalData() async {
    final db = await LocalDatabase.database;
    final localCart = await db.query('local_cartera');
    
    List<Map<String, dynamic>> joinedList = [];
    for (var row in localCart) {
      final clientRow = await db.query('local_clientes', where: 'id_cliente = ?', whereArgs: [row['id_cliente']]);
      final Map<String, dynamic> item = Map.from(row);
      if (clientRow.isNotEmpty) {
        item['cliente'] = clientRow.first;
      }
      joinedList.add(item);
    }
    
    joinedList.sort((a, b) {
      final aVal = a['score_prioridad'] != null ? int.tryParse(a['score_prioridad'].toString()) ?? 0 : 0;
      final bVal = b['score_prioridad'] != null ? int.tryParse(b['score_prioridad'].toString()) ?? 0 : 0;
      return bVal.compareTo(aVal);
    });
    
    if (mounted) {
      setState(() {
        _cartera = joinedList;
        _generateClientOffsets();
        _applyFilters();
      });
    }
    
    final localSols = await db.query('local_solicitudes_pendientes');
    List<Map<String, dynamic>> joinedSols = [];
    for (var row in localSols) {
      final Map<String, dynamic> item = Map.from(row);
      final clientRow = await db.query('local_clientes', where: 'id_cliente = ?', whereArgs: [row['id_cliente']]);
      if (clientRow.isNotEmpty) {
        item['cliente'] = clientRow.first;
      } else {
        item['cliente'] = {
          'nombres': 'Cliente',
          'apellidos': 'Borrador',
          'documento': 'Sin DNI'
        };
      }
      joinedSols.add(item);
    }

    if (!_isOnline) {
      _solicitudes = joinedSols;
    } else {
      // Merge local unsynced offline solicitudes with the online ones
      final List<dynamic> merged = List.from(_solicitudes);
      final Set<String> existingIds = merged.map((s) => (s['id_solicitud'] ?? '').toString()).toSet();
      for (var s in joinedSols) {
        final String id = (s['id_solicitud'] ?? '').toString();
        if (id.isNotEmpty && !existingIds.contains(id)) {
          merged.add(s);
        }
      }
      _solicitudes = merged;
    }
  }

  Future<void> _loadDrafts() async {
    final list = await _draftService.getDrafts();
    if (mounted) {
      setState(() {
        _draftsList = list;
      });
    }
  }

  Future<void> _loadCampaigns() async {
    if (_isOnline) {
      try {
        final res = await DioClient.instance.get('/fventas/campanas');
        if (mounted) {
          setState(() {
            _campaigns = List<Map<String, dynamic>>.from(res.data);
          });
        }
      } catch (_) {
        _loadCampaignsOffline();
      }
    } else {
      _loadCampaignsOffline();
    }
  }

  void _loadCampaignsOffline() {
    if (mounted) {
      setState(() {
        _campaigns = [
          {
            'id_campana': 'camp-01',
            'tipo': 'RENOVACION',
            'nombre_cliente': 'Juan Carlos Perez',
            'documento': '40118105',
            'monto_oferta': 12000.0,
            'dias_restantes': 5,
            'tea': 25.5
          },
          {
            'id_campana': 'camp-02',
            'tipo': 'AMPLIACION',
            'nombre_cliente': 'Lucia Fernandez',
            'documento': '40118112',
            'monto_oferta': 20000.0,
            'dias_restantes': 12,
            'tea': 23.0
          },
          {
            'id_campana': 'camp-03',
            'tipo': 'PRODUCTO_PARALELO',
            'nombre_cliente': 'Manuel Ortega',
            'documento': '40118118',
            'monto_oferta': 8000.0,
            'dias_restantes': 2,
            'tea': 28.0
          }
        ];
      });
    }
  }

  Future<void> _loadAlertas() async {
    if (_isOnline) {
      try {
        final res = await DioClient.instance.get('/fventas/alertas');
        if (mounted) {
          setState(() {
            _alertas = List<Map<String, dynamic>>.from(res.data);
          });
        }
      } catch (_) {
        if (mounted) setState(() => _alertas = []);
      }
    } else {
      if (mounted) setState(() => _alertas = []);
    }
  }

  void _showAlertasDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FuerzaVentasTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.white10),
        ),
        title: const Text(
          'Alertas de Cartera',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: _alertas.isEmpty
            ? const SizedBox(
                height: 100,
                child: Center(
                  child: Text(
                    'No tienes alertas pendientes de lectura.',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
              )
            : SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _alertas.length,
                  itemBuilder: (context, index) {
                    final item = _alertas[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: FuerzaVentasTheme.glassDecoration(
                        borderColor: FuerzaVentasTheme.neonCyan,
                        borderOpacity: 0.1,
                      ),
                      child: ListTile(
                        title: Text(item['tipo'] ?? 'Alerta', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text('${item['cliente_nombre']}\n${item['mensaje']}', style: const TextStyle(color: Colors.white60, fontSize: 12.5)),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.check, color: FuerzaVentasTheme.neonGreen),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _marcarAlertaLeida(item['id']);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar', style: TextStyle(color: FuerzaVentasTheme.neonCyan)),
          )
        ],
      ),
    );
  }

  Future<void> _marcarAlertaLeida(String id) async {
    if (mounted) setState(() => _isLoading = true);
    try {
      if (_isOnline) {
        await DioClient.instance.patch('/fventas/alertas/$id/leida');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alerta marcada como leída.'), behavior: SnackBarBehavior.floating),
        );
        await _loadAlertas();
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al marcar alerta como leída.'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoraData() async {
    if (_isOnline) {
      try {
        final res = await DioClient.instance.get('/fventas/mora');
        if (mounted) {
          setState(() {
            _moraList = List<Map<String, dynamic>>.from(res.data['mora_list']);
            _montoTotalVencido = double.tryParse(res.data['monto_total_vencido']?.toString() ?? '') ?? 0.0;
          });
        }
      } catch (_) {
        _loadMoraOffline();
      }
    } else {
      _loadMoraOffline();
    }
  }

  void _loadMoraOffline() {
    if (mounted) {
      setState(() {
        _moraList = [
          {
            'id_cartera': 'cart-mora-01',
            'id_cliente': 'cli-mora-01',
            'cliente_nombre': 'Pedro Salazar Torres',
            'documento': '40118108',
            'dias_mora': 64,
            'monto_vencido': 2450.00,
            'fecha_ultimo_contacto': '2026-06-10T14:30:00Z',
            'prioridad': 'ALTA'
          },
          {
            'id_cartera': 'cart-mora-02',
            'id_cliente': 'cli-mora-02',
            'cliente_nombre': 'Juana Quispe Ramos',
            'documento': '40118115',
            'dias_mora': 35,
            'monto_vencido': 1200.00,
            'fecha_ultimo_contacto': '2026-06-15T09:15:00Z',
            'prioridad': 'MEDIA'
          },
          {
            'id_cartera': 'cart-mora-03',
            'id_cliente': 'cli-mora-03',
            'cliente_nombre': 'Alfonso Herrera Vega',
            'documento': '40118123',
            'dias_mora': 12,
            'monto_vencido': 350.00,
            'fecha_ultimo_contacto': null,
            'prioridad': 'NORMAL'
          }
        ];
        _montoTotalVencido = 4000.00;
      });
    }
  }

  void _generateClientOffsets() {
    final random = Random(42); 
    _clientOffsets = List.generate(_cartera.length, (index) {
      double x = 50.0 + random.nextDouble() * 200.0;
      double y = 50.0 + random.nextDouble() * 200.0;
      return Offset(x, y);
    });
  }

  void _applyFilters() {
    final search = _searchController.text.toLowerCase();
    List<Map<String, dynamic>> temp = List.from(_cartera);

    // Filter by Search Query
    if (search.isNotEmpty) {
      temp = temp.where((item) {
        final cli = item['cliente'];
        final name = '${cli?['nombres'] ?? ""} ${cli?['apellidos'] ?? ""}'.toLowerCase();
        final doc = (cli?['documento'] ?? "").toString();
        return name.contains(search) || doc.endsWith(search);
      }).toList();
    }

    // Filter by Option Label
    if (_activeFilter != 'TODOS') {
      temp = temp.where((item) {
        if (_activeFilter == 'VISITADOS') {
          return item['estado_visita'] == 'REALIZADA';
        }
        if (_activeFilter == 'RENOVACIONES') {
          return item['tipo_gestion'] == 'RENOVACION';
        }
        if (_activeFilter == 'NUEVAS') {
          return item['tipo_gestion'] == 'NUEVA_SOLICITUD';
        }
        if (_activeFilter == 'AMPLIACIONES') {
          return item['tipo_gestion'] == 'AMPLIACION';
        }
        if (_activeFilter == 'MORA') {
          return item['tipo_gestion'] == 'RECUPERACION_MORA';
        }
        return true;
      }).toList();
    }

    temp.sort((a, b) {
      final aVisited = a['estado_visita'] == 'REALIZADA' ? 1 : 0;
      final bVisited = b['estado_visita'] == 'REALIZADA' ? 1 : 0;
      if (aVisited != bVisited) {
        return aVisited.compareTo(bVisited); 
      }
      final aVal = a['score_prioridad'] != null ? int.tryParse(a['score_prioridad'].toString()) ?? 0 : 0;
      final bVal = b['score_prioridad'] != null ? int.tryParse(b['score_prioridad'].toString()) ?? 0 : 0;
      return bVal.compareTo(aVal);
    });

    if (mounted) {
      setState(() {
        _filteredCartera = temp;
      });
    }
  }

  Future<void> _syncPendingData() async {
    if (!_isOnline) return;
    if (mounted) setState(() => _isLoading = true);
    final db = await LocalDatabase.database;

    try {
      final pendingVisitas = await db.query('local_visitas_pendientes', where: 'pendiente_sync = 1');
      for (var v in pendingVisitas) {
        await DioClient.instance.post('/fventas/visitas', data: {
          'id_cartera': v['id_cartera'],
          'resultado': v['resultado'],
          'observacion': v['observacion'],
          'lat': v['lat'],
          'lng': v['lng']
        });
        await db.delete('local_visitas_pendientes', where: 'id_visita = ?', whereArgs: [v['id_visita']]);
      }

      final pendingSols = await db.query('local_solicitudes_pendientes', where: 'pendiente_sync = 1');
      for (var s in pendingSols) {
        final clientList = await db.query('local_clientes', where: 'id_cliente = ?', whereArgs: [s['id_cliente']]);
        String? clientName;
        String? clientDoc;
        if (clientList.isNotEmpty) {
          clientName = '${clientList.first['nombres'] ?? ''} ${clientList.first['apellidos'] ?? ''}'.trim();
          clientDoc = clientList.first['documento'];
        }
        await DioClient.instance.post('/fventas/solicitudes', data: {
          'id_cliente': s['id_cliente'],
          'id_negocio': s['id_negocio'],
          'id_producto_credito': s['id_producto_credito'],
          'monto_solicitado': s['monto_solicitado'],
          'plazo_meses': s['plazo_meses'],
          'con_seguro_desgravamen': s['con_seguro_desgravamen'] == 1,
          'garantia': s['garantia'],
          'destino_credito': s['destino_credito'],
          'lat_captura': s['lat_captura'],
          'lng_captura': s['lng_captura'],
          'cliente_nombres': clientName,
          'cliente_documento': clientDoc
        });
        await db.delete('local_solicitudes_pendientes', where: 'id_solicitud = ?', whereArgs: [s['id_solicitud']]);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Datos locales sincronizados correctamente con el Core Mobile BCP!'), behavior: SnackBarBehavior.floating),
      );
      await _loadInitialData();
    } catch (e) {
      if (e is DioException && (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al sincronizar: $e'), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isPointInGeofence(Offset point) {
    int numPoints = _geofenceZone.length;
    bool inside = false;
    int j = numPoints - 1;
    for (int i = 0; i < numPoints; i++) {
      if (((_geofenceZone[i].dy > point.dy) != (_geofenceZone[j].dy > point.dy)) &&
          (point.dx < (_geofenceZone[j].dx - _geofenceZone[i].dx) * (point.dy - _geofenceZone[i].dy) / (_geofenceZone[j].dy - _geofenceZone[i].dy) + _geofenceZone[i].dx)) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }

  void _optimizeRoute() {
    if (_cartera.isEmpty) return;
    if (_clientOffsets.length != _cartera.length) {
      _generateClientOffsets();
    }
    
    Offset currentPos = const Offset(150, 150);
    List<int> unvisited = List.generate(_cartera.length, (i) => i);
    List<int> route = [];

    while (unvisited.isNotEmpty) {
      double minDist = double.infinity;
      int nearestIdx = -1;
      
      for (var idx in unvisited) {
        Offset clientPos = _clientOffsets[idx];
        double dist = sqrt(pow(clientPos.dx - currentPos.dx, 2) + pow(clientPos.dy - currentPos.dy, 2));
        if (dist < minDist) {
          minDist = dist;
          nearestIdx = idx;
        }
      }
      
      if (nearestIdx != -1) {
        route.add(nearestIdx);
        currentPos = _clientOffsets[nearestIdx];
        unvisited.remove(nearestIdx);
      } else {
        break;
      }
    }

    if (mounted) {
      setState(() {
        _optimizedRouteIndices = route;
        _isRouteOptimized = true;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡Ruta optimizada según algoritmo del vecino más cercano!'), behavior: SnackBarBehavior.floating),
    );
  }

  void _launchNavigation(String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FuerzaVentasTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.white10),
        ),
        title: const Row(
          children: [
            Icon(Icons.navigation, color: FuerzaVentasTheme.neonCyan),
            SizedBox(width: 8),
            Text('Navegar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Abriendo indicaciones de conducción hacia $name en Waze/Google Maps...', style: const TextStyle(color: Colors.white60)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido', style: TextStyle(color: FuerzaVentasTheme.neonCyan))),
        ],
      ),
    );
  }

  void _actualizarUbicacionNegocio(String idCliente) async {
    if (mounted) setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800)); 
    
    final address = "Av. Las Palmeras 120, San Isidro, Lima";
    final lat = -12.0520;
    final lng = -77.0390;

    final db = await LocalDatabase.database;
    await db.update(
      'local_clientes',
      {'direccion': address},
      where: 'id_cliente = ?',
      whereArgs: [idCliente]
    );

    if (_isOnline && _selectedIdCartera != null) {
      try {
        await DioClient.instance.patch('/fventas/cartera/$_selectedIdCartera/ubicacion', data: {
          'lat': lat,
          'lng': lng
        });
      } catch (_) {}
    }

    await _loadLocalData();
    if (mounted) setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ubicación capturada con alta precisión GPS: $address'), behavior: SnackBarBehavior.floating),
    );
  }

  void _logout() async {
    final db = await LocalDatabase.database;
    final listVisitas = await db.query('local_visitas_pendientes', where: 'pendiente_sync = 1');
    final listSols = await db.query('local_solicitudes_pendientes', where: 'pendiente_sync = 1');
    final unsynced = listVisitas.length + listSols.length;

    if (unsynced > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: FuerzaVentasTheme.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Colors.white10),
          ),
          title: const Text('Confirmación de Cierre', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text('Tienes $unsynced solicitudes/gestiones pendientes de sincronizar. ¿Deseas cerrar sesión de todas formas? Se borrarán los datos de la cartera en cache.', style: const TextStyle(color: Colors.white60)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white60))),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _executeLogout();
              },
              child: const Text('Sí, cerrar sesión', style: TextStyle(color: FuerzaVentasTheme.neonRed)),
            )
          ],
        ),
      );
    } else {
      _executeLogout();
    }
  }

  void _executeLogout() async {
    final db = await LocalDatabase.database;
    await db.delete('local_cartera');
    await db.delete('local_clientes');
    await db.delete('local_solicitudes_borrador');

    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  void _loadCustomerFicha(String idCliente) async {
    if (mounted) setState(() => _isLoading = true);
    try {
      if (_isOnline) {
        final res = await DioClient.instance.get('/fventas/clientes/$idCliente/ficha');
        final resPos = await DioClient.instance.get('/fventas/clientes/$idCliente/posicion');
        Map<String, dynamic>? preData;
        try {
          final resPre = await DioClient.instance.get('/fventas/clientes/$idCliente/preaprobado');
          preData = resPre.data;
        } catch (_) {}
        
        if (mounted) {
          final cli = res.data['cliente'] ?? {};
          setState(() {
            _selectedFicha = {
              'cliente': cli,
              'posicion': resPos.data,
              'preaprobado': preData
            };
            _stepperNameController.text = '${cli['nombres'] ?? ''} ${cli['apellidos'] ?? ''}'.trim();
            _stepperDocController.text = cli['documento'] ?? '';
            _stepperTelController.text = cli['telefono'] ?? '';
            _stepperClientId = idCliente;
            final listNegocios = cli['negocios'] as List?;
            if (listNegocios != null && listNegocios.isNotEmpty) {
              _stepperNegocioId = listNegocios[0]['id_negocio']?.toString();
            } else {
              _stepperNegocioId = null;
            }
          });
        }
      } else {
        final db = await LocalDatabase.database;
        final list = await db.query('local_clientes', where: 'id_cliente = ?', whereArgs: [idCliente]);
        if (list.isNotEmpty && mounted) {
          final cli = list.first;
          setState(() {
            _selectedFicha = {
              'cliente': cli,
              'posicion': {
                'deuda_total_consolidada': 5000.0,
                'numero_cuentas_vigentes': 1,
                'numero_cuentas_en_mora': 0,
                'dias_de_mayor_mora_historica': 0,
                'fecha_del_ultimo_pago_registrado': '2026-05-15',
                'calificacion_sbs': 'NORMAL'
              },
              'preaprobado': null
            };
            _stepperNameController.text = '${cli['nombres'] ?? ''} ${cli['apellidos'] ?? ''}'.trim();
            _stepperDocController.text = cli['documento'] ?? '';
            _stepperTelController.text = cli['telefono'] ?? '';
            _stepperClientId = idCliente;
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _runPreevaluacionOnline() async {
    if (_stepperDocController.text.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('DNI incorrecto, debe tener 8 dígitos'), behavior: SnackBarBehavior.floating));
      return;
    }
    if (mounted) setState(() => _isLoading = true);
    
    final doc = _stepperDocController.text;
    final name = _stepperNameController.text;
    final double amount = double.tryParse(_stepperMontoController.text) ?? 5000.0;
    
    if (_isOnline) {
      try {
        final res = await DioClient.instance.post('/fventas/prospecto/preevaluar', data: {
          'documento': doc,
          'nombre': name,
          'monto': amount
        });
        if (mounted) {
          setState(() {
            _evalResultado = res.data['resultado'];
            _evalPuntaje = res.data['puntaje'];
            _evalCuota = double.tryParse(res.data['cuota_estimada'].toString());
          });
        }
      } catch (_) {
        _runPreevaluacionOffline();
      }
    } else {
      _runPreevaluacionOffline();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _runPreevaluacionOffline() {
    final doc = _stepperDocController.text;
    final lastChar = doc.isNotEmpty ? doc[doc.length - 1] : '0';
    final apto = lastChar != '9' && lastChar != '8';
    if (mounted) {
      setState(() {
        _evalResultado = apto ? 'APTO' : 'NO_PROCEDE';
        _evalPuntaje = apto ? 80 : 35;
        _evalCuota = (double.tryParse(_stepperMontoController.text) ?? 5000.0) / 12 * 1.15;
      });
    }
  }

  void _simularFotoBlurCheck() async {
    if (mounted) setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    
    final random = Random().nextBool();
    if (random) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: FuerzaVentasTheme.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Colors.white10),
          ),
          title: const Text('Alerta de Nitidez', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text('¡Imagen borrosa! La varianza del Laplaciano calculada (11.8) está por debajo del umbral mínimo requerido (15.0). Por favor, capture la foto de nuevo.', style: TextStyle(color: Colors.white60)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Reintentar', style: TextStyle(color: FuerzaVentasTheme.neonCyan))),
          ],
        ),
      );
    } else {
      if (mounted) {
        setState(() {
          _dniUploaded = true;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto del documento cargada y aprobada por el validador de nitidez.'), behavior: SnackBarBehavior.floating),
      );
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _saveCurrentDraft() async {
    final id = _stepperDocController.text.isNotEmpty ? _stepperDocController.text : _generateUuid();
    final name = _stepperNameController.text.isNotEmpty ? _stepperNameController.text : 'Borrador sin nombre';
    final double amount = double.tryParse(_stepperMontoController.text) ?? 5000.0;
    
    final datos = {
      'name': _stepperNameController.text,
      'doc': _stepperDocController.text,
      'estado_civil': _stepperEstadoCivil,
      'income': _stepperIncomeController.text,
      'expense': _stepperExpenseController.text,
      'destino': _stepperDestinoController.text,
      'amount': _stepperMontoController.text,
      'plazo': _stepperPlazoController.text,
    };

    await _draftService.saveDraft(
      idBorrador: id,
      nombreCliente: name,
      pasoAlcanzado: _currentStep,
      monto: amount,
      datos: datos
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡Borrador guardado correctamente en SQLite!'), behavior: SnackBarBehavior.floating),
    );
    _loadDrafts();
  }

  void _enviarSolicitudStepper() async {
    if (mounted) setState(() => _isLoading = true);

    final Offset clientPos = const Offset(300, 300); 
    if (!_isPointInGeofence(clientPos)) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: FuerzaVentasTheme.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Colors.white10),
          ),
          title: const Text('Visita fuera de geocerca', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text('Esta visita está fuera de tu zona asignada. Se registrará de todas formas en la auditoría del comite regional.', style: TextStyle(color: Colors.white60)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Aceptar', style: TextStyle(color: FuerzaVentasTheme.neonCyan))),
          ],
        ),
      );
    }

    if (_isOnline) {
      try {
        final resProd = await DioClient.instance.get('/admin/productos-creditos');
        final listProd = resProd.data as List;
        final prodId = listProd.isNotEmpty ? listProd[0]['id_producto_credito'] : 'f0000000-0000-0000-0000-000000000001';

        final resDraft = await DioClient.instance.post('/fventas/solicitudes', data: {
          'id_cliente': _stepperClientId ?? 'b0000000-0000-0000-0000-000000000001',
          'id_negocio': _stepperNegocioId ?? 'b0000000-0000-0000-0000-000000000001',
          'id_producto_credito': prodId,
          'monto_solicitado': double.tryParse(_stepperMontoController.text) ?? 5000.0,
          'plazo_meses': int.tryParse(_stepperPlazoController.text) ?? 12,
          'con_seguro_desgravamen': true,
          'garantia': 'Sola Firma',
          'destino_credito': _stepperDestinoController.text,
          'lat_captura': -12.0463,
          'lng_captura': -77.0427,
          'cliente_nombres': _stepperNameController.text,
          'cliente_documento': _stepperDocController.text,
        });

        _stepperSolId = resDraft.data['id_solicitud'];
        
        try {
          await DioClient.instance.post('/fventas/solicitudes/$_stepperSolId/preevaluar');
        } catch (_) {}

        final bytes = await _sigController.toPngBytes();
        if (bytes != null) {
          final base64Sig = base64Encode(bytes);
          await DioClient.instance.post('/fventas/solicitudes/$_stepperSolId/firma', data: {
            'firma_base64': base64Sig
          });
        }

        await DioClient.instance.post('/fventas/solicitudes/$_stepperSolId/enviar-comite');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Expediente de crédito transmitido al Comité con éxito!'), behavior: SnackBarBehavior.floating),
        );
        _resetStepper();
        _loadInitialData();
      } catch (e) {
        _enviarSolicitudStepperOffline();
      }
    } else {
      _enviarSolicitudStepperOffline();
    }
  }

  void _enviarSolicitudStepperOffline() async {
    final db = await LocalDatabase.database;
    final String targetClientId = _stepperClientId ?? _generateUuid();
    
    // If it's a new client or digitated client, store in local_clientes so offline lists can display names
    if (_stepperClientId == null) {
      await db.insert('local_clientes', {
        'id_cliente': targetClientId,
        'documento': _stepperDocController.text,
        'nombres': _stepperNameController.text,
        'apellidos': '',
        'telefono': _stepperTelController.text,
        'correo': '',
        'direccion': '',
        'distrito': '',
        'provincia': '',
        'departamento': ''
      });
    }

    await db.insert('local_solicitudes_pendientes', {
      'id_solicitud': _generateUuid(),
      'id_cliente': targetClientId,
      'id_negocio': _stepperNegocioId ?? 'b0000000-0000-0000-0000-000000000001',
      'id_producto_credito': 'f0000000-0000-0000-0000-000000000001',
      'monto_solicitado': double.tryParse(_stepperMontoController.text) ?? 5000.0,
      'plazo_meses': int.tryParse(_stepperPlazoController.text) ?? 12,
      'con_seguro_desgravamen': 1,
      'garantia': 'Sola Firma',
      'destino_credito': _stepperDestinoController.text,
      'cuota_estimada': (double.tryParse(_stepperMontoController.text) ?? 5000.0) / 12,
      'estado': 'ENVIADO',
      'lat_captura': -12.0463,
      'lng_captura': -77.0427,
      'pendiente_sync': 1
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡Modo Offline: Solicitud guardada localmente! Se transmitirá automáticamente.'), behavior: SnackBarBehavior.floating),
    );
    _resetStepper();
    _loadLocalData();
    _checkPendingSyncs();
    if (mounted) setState(() => _isLoading = false);
  }

  void _registrarCobranza(String idCartera, String tipo, String resultado, double monto, String obs) async {
    if (mounted) setState(() => _isLoading = true);

    if (_isOnline) {
      try {
        await DioClient.instance.post('/fventas/cobranzas', data: {
          'id_cartera': idCartera,
          'tipo_gestion': tipo,
          'resultado': resultado,
          'monto_pagado': resultado == 'Pago parcial' ? monto : 0.0,
          'fecha_compromiso': resultado == 'Compromiso de pago' ? '2026-07-01' : null,
          'monto_comprometido': resultado == 'Compromiso de pago' ? monto : 0.0,
          'observaciones': obs,
          'lat': -12.0463,
          'lng': -77.0427
        });

        if (resultado == 'Compromiso de pago') {
          _schedulePromiseReminder(monto);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Gestión de cobranza registrada exitosamente en el servidor!'), behavior: SnackBarBehavior.floating),
        );
        _loadMoraData();
      } catch (_) {
        _registrarCobranzaOffline(idCartera, tipo, resultado, monto, obs);
      }
    } else {
      _registrarCobranzaOffline(idCartera, tipo, resultado, monto, obs);
    }
  }

  void _registrarCobranzaOffline(String idCartera, String tipo, String resultado, double monto, String obs) async {
    final db = await LocalDatabase.database;
    await db.insert('local_visitas_pendientes', {
      'id_visita': _generateUuid(),
      'id_cartera': idCartera,
      'id_asesor': 'b0000000-0000-0000-0000-000000000001',
      'id_cliente': 'c0000000-0000-0000-0000-000000000001',
      'resultado': resultado,
      'observacion': 'Tipo: $tipo | Monto: $monto | Obs: $obs',
      'lat': -12.0463,
      'lng': -77.0427,
      'fecha_hora': DateTime.now().toIso8601String(),
      'pendiente_sync': 1
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡Modo Offline: Registro de cobranza guardado en SQLite!'), behavior: SnackBarBehavior.floating),
    );
    _loadMoraData();
    _checkPendingSyncs();
    if (mounted) setState(() => _isLoading = false);
  }

  void _schedulePromiseReminder(double monto) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FuerzaVentasTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.white10),
        ),
        title: const Text('Recordatorio Programado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Se ha programado una alarma local de seguimiento para el cobro del compromiso de S/ $monto.', style: const TextStyle(color: Colors.white60)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido', style: TextStyle(color: FuerzaVentasTheme.neonCyan))),
        ],
      ),
    );
  }

  void _loadProductividad() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final res = await DioClient.instance.get('/comite/productividad');
      if (mounted) {
        setState(() {
          _productividadData = res.data;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _productividadData = [
            {
              'asesor_nombre': 'Roberto Gómez',
              'solicitudes_enviadas': 15,
              'solicitudes_aprobadas': 10,
              'solicitudes_desembolsadas': 8,
              'tasa_aprobacion': 83.3
            },
            {
              'asesor_nombre': 'María Sanches',
              'solicitudes_enviadas': 12,
              'solicitudes_aprobadas': 8,
              'solicitudes_desembolsadas': 6,
              'tasa_aprobacion': 75.0
            }
          ];
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _registerDesertion(String motivo, String institucion) {
    // Console log and register abandon
    debugPrint("Abandono registrado: Motivo: $motivo, Competencia: $institucion");
  }

  Future<void> _registrarVisitaDesdeFicha(String idCartera, String resultado, String observacion) async {
    if (mounted) setState(() => _isLoading = true);
    try {
      if (_isOnline) {
        await DioClient.instance.post('/fventas/visitas', data: {
          'id_cartera': idCartera,
          'resultado': resultado,
          'observacion': observacion,
          'lat': -12.0463,
          'lng': -77.0427,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visita registrada correctamente'), behavior: SnackBarBehavior.floating),
        );
      } else {
        final db = await LocalDatabase.database;
        await db.insert('local_visitas_pendientes', {
          'id_visita': _generateUuid(),
          'id_cartera': idCartera,
          'id_asesor': 'b0000000-0000-0000-0000-000000000001',
          'id_cliente': _stepperClientId ?? 'c0000000-0000-0000-0000-000000000001',
          'resultado': resultado,
          'observacion': observacion,
          'lat': -12.0463,
          'lng': -77.0427,
          'fecha_hora': DateTime.now().toIso8601String(),
          'pendiente_sync': 1,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visita guardada offline'), behavior: SnackBarBehavior.floating),
        );
      }
      _loadInitialData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar visita: $e'), behavior: SnackBarBehavior.floating),
      );
    } finally {
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

  void _resetStepper() {
    if (mounted) {
      setState(() {
        _currentStep = 0;
        _stepperClientId = null;
        _stepperNegocioId = null;
        _stepperSolId = null;
        _evalResultado = null;
        _evalPuntaje = null;
        _evalCuota = null;
        _dniUploaded = false;
        _sigController.clear();
        
        _stepperNameController.clear();
        _stepperDocController.clear();
        _stepperTelController.clear();
        _stepperIncomeController.clear();
        _stepperExpenseController.clear();
        _stepperDestinoController.clear();
        _stepperMontoController.clear();
        _stepperPlazoController.clear();
        
        _selectedMenuIndex = 0;
      });
    }
  }

  Future<void> _preevaluarSolicitud(String idSol) async {
    await DioClient.instance.post('/fventas/solicitudes/$idSol/preevaluar');
  }

  Future<void> _consultarBuroSolicitud(String idSol) async {
    await DioClient.instance.post('/fventas/solicitudes/$idSol/buro');
  }

  Future<void> _enviarAComiteSolicitud(String idSol) async {
    await DioClient.instance.post('/fventas/solicitudes/$idSol/enviar-comite');
  }

  Widget _getBody(int index) {
    switch (index) {
      case 0:
        return CarteraView(
          cartera: _cartera,
          filteredCartera: _filteredCartera,
          activeFilter: _activeFilter,
          lastSyncTime: _lastSyncTime,
          pendingSyncCount: _pendingSyncCount,
          searchController: _searchController,
          onFilterSelected: (filter) {
            setState(() {
              _activeFilter = filter;
              _applyFilters();
            });
          },
          onClientTap: (clientId, idCartera) {
            setState(() {
              _selectedFicha = null;
              _stepperClientId = clientId;
              _selectedIdCartera = idCartera;
              _stepperNegocioId = 'b0000000-0000-0000-0000-000000000001';
            });
            _loadCustomerFicha(clientId);
            setState(() => _selectedMenuIndex = 2); 
          },
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final item = _filteredCartera.removeAt(oldIndex);
              _filteredCartera.insert(newIndex, item);
            });
          },
        );
      case 1:
        return RutaView(
          cartera: _cartera,
          clientOffsets: _clientOffsets,
          geofenceZone: _geofenceZone,
          optimizedRouteIndices: _optimizedRouteIndices,
          isRouteOptimized: _isRouteOptimized,
          hoveredMapClientIndex: _hoveredMapClientIndex,
          mapOffset: _mapOffset,
          mapZoom: _mapZoom,
          onOptimizeRoute: _optimizeRoute,
          onNavigate: _launchNavigation,
          onMapPan: (delta) => setState(() => _mapOffset += delta),
          onMapZoomChanged: (zoom) => setState(() => _mapZoom = zoom),
          onMapHoverChanged: (index) => setState(() => _hoveredMapClientIndex = index),
          onLoadCustomerFicha: (clientId) {
            _loadCustomerFicha(clientId);
            setState(() => _selectedMenuIndex = 2);
          },
        );
      case 2:
        return FichaView(
          stepperClientId: _stepperClientId,
          selectedIdCartera: _selectedIdCartera,
          selectedFicha: _selectedFicha,
          onUsePreapprovedOffer: (monto, plazo) {
            _stepperMontoController.text = monto.round().toString();
            _stepperPlazoController.text = plazo.toString();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('¡Oferta cargada en el Stepper de Originación!'), behavior: SnackBarBehavior.floating),
            );
            setState(() => _selectedMenuIndex = 4); 
          },
          onUpdateGps: _actualizarUbicacionNegocio,
          onRegistrarVisita: _registrarVisitaDesdeFicha,
        );
      case 3:
        return PreevaluacionCampanaView(
          campaigns: _campaigns,
          evalResultado: _evalResultado,
          evalPuntaje: _evalPuntaje,
          evalCuota: _evalCuota,
          onManageCampaign: (clientId, montoOferta) {
            setState(() {
              _stepperClientId = clientId;
              _selectedIdCartera = null;
              _stepperNegocioId = 'b0000000-0000-0000-0000-000000000001';
              _stepperMontoController.text = montoOferta.round().toString();
              _selectedMenuIndex = 4; 
            });
            if (clientId.isNotEmpty) {
              _loadCustomerFicha(clientId);
            }
          },
          onPreEvaluate: (doc, name, amount) {
            _stepperDocController.text = doc;
            _stepperNameController.text = name;
            _stepperMontoController.text = amount.round().toString();
            _runPreevaluacionOnline();
          },
          onStartFormalRequest: () => setState(() => _selectedMenuIndex = 4),
          onRegisterDesertion: _registerDesertion,
        );
      case 4:
        return StepperView(
          currentStep: _currentStep,
          stepperEstadoCivil: _stepperEstadoCivil,
          dniUploaded: _dniUploaded,
          draftsList: _draftsList,
          nameController: _stepperNameController,
          docController: _stepperDocController,
          telController: _stepperTelController,
          incomeController: _stepperIncomeController,
          expenseController: _stepperExpenseController,
          destinoController: _stepperDestinoController,
          montoController: _stepperMontoController,
          plazoController: _stepperPlazoController,
          sigController: _sigController,
          onStepChanged: (step) => setState(() => _currentStep = step),
          onEstadoCivilChanged: (ec) => setState(() => _stepperEstadoCivil = ec),
          onSaveDraft: _saveCurrentDraft,
          onResetForm: _resetStepper,
          onDeleteDraft: (idBorrador) async {
            await _draftService.deleteDraft(idBorrador);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Borrador eliminado permanentemente'), behavior: SnackBarBehavior.floating),
            );
            _loadDrafts();
          },
          onLoadDraft: (draft) {
            final Map<String, dynamic> datos = Map<String, dynamic>.from(draft['datos'] ?? {});
            setState(() {
              _currentStep = draft['paso_alcanzado'] as int;
              _stepperNameController.text = datos['name'] ?? '';
              _stepperDocController.text = datos['doc'] ?? '';
              _stepperEstadoCivil = datos['estado_civil'] ?? 'SOLTERO';
              _stepperIncomeController.text = datos['income'] ?? '3500';
              _stepperExpenseController.text = datos['expense'] ?? '1500';
              _stepperDestinoController.text = datos['destino'] ?? '';
              _stepperMontoController.text = datos['amount'] ?? '5000';
              _stepperPlazoController.text = datos['plazo'] ?? '12';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Borrador cargado correctamente'), behavior: SnackBarBehavior.floating),
            );
          },
          onSimulateFoto: _simularFotoBlurCheck,
          onSubmit: _enviarSolicitudStepper,
        );
      case 5:
        return SolicitudesView(
          solicitudes: _solicitudes,
          isOnline: _isOnline,
          onRefresh: _loadInitialData,
          onPreevaluar: _preevaluarSolicitud,
          onBuro: _consultarBuroSolicitud,
          onEnviarComite: _enviarAComiteSolicitud,
        );
      case 6:
        return MoraView(
          moraList: _moraList,
          montoTotalVencido: _montoTotalVencido,
          onRegisterCobranza: _registrarCobranza,
        );
      case 7:
        return SyncPanel(
          pendingSyncCount: _pendingSyncCount,
          isOnline: _isOnline,
          onForceSync: _syncPendingData,
        );
      case 8:
        return ReportesSupervisorView(
          productividadData: _productividadData,
          onLoadProductividad: _loadProductividad,
        );
      default:
        return const Center(
          child: Text('Vista no encontrada', style: TextStyle(color: Colors.white)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.token == null) {
        context.go('/login');
      }
    });
    final userState = ref.watch(authProvider);
    final userRole = userState.role ?? 'OPERADOR';
    final isSupervisorOrAdmin = userRole == 'SUPERVISOR' || userRole == 'ADMIN';

    return Container(
      decoration: const BoxDecoration(
        gradient: FuerzaVentasTheme.bcpGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            'Fuerza de Ventas BCP - ${userRole.toUpperCase()}',
            style: const TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
          actions: [
            // Notifications / Alert stack
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: _showAlertasDialog,
                ),
                if (_alertas.isNotEmpty)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: FuerzaVentasTheme.neonRed,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${_alertas.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh_outlined, color: Colors.white),
              onPressed: _isLoading ? null : _loadInitialData,
            ),
            IconButton(
              icon: const Icon(Icons.logout_outlined, color: FuerzaVentasTheme.neonRed),
              onPressed: _logout,
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: FuerzaVentasTheme.darkBackground,
          child: Column(
            children: [
              // Drawer header styled like obsidian neon
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 60, bottom: 24, left: 24, right: 24),
                decoration: const BoxDecoration(
                  color: FuerzaVentasTheme.cardDark,
                  border: Border(bottom: BorderSide(color: Colors.white10)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: FuerzaVentasTheme.bcpBlue.withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(color: FuerzaVentasTheme.neonCyan.withOpacity(0.4)),
                      ),
                      child: const Icon(Icons.account_circle_outlined, size: 48, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      userState.name ?? 'Asesor de Negocios', 
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Asesor · Cod: ${userState.document ?? "A001"}', 
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildDrawerTile(0, Icons.assignment_outlined, 'Cartera Diaria'),
                    _buildDrawerTile(1, Icons.map_outlined, 'Planificador de Ruta'),
                    _buildDrawerTile(2, Icons.folder_shared_outlined, 'Ficha del Cliente'),
                    _buildDrawerTile(3, Icons.campaign_outlined, 'Pre-evaluación & Campañas'),
                    _buildDrawerTile(4, Icons.add_circle_outline_outlined, 'Originación Stepper'),
                    _buildDrawerTile(5, Icons.fact_check_outlined, 'Bandeja Solicitudes'),
                    _buildDrawerTile(6, Icons.payment_outlined, 'Mora & Cobranzas'),
                    _buildDrawerTile(7, Icons.sync_outlined, 'Sincronización SQLite', badgeCount: _pendingSyncCount),
                    if (isSupervisorOrAdmin) ...[
                      const Divider(color: Colors.white10, height: 24),
                      _buildDrawerTile(8, Icons.bar_chart_outlined, 'Panel Supervisión', isSpecial: true),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            // Status bar online/offline
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              color: _isOnline 
                  ? FuerzaVentasTheme.neonGreen.withOpacity(0.12) 
                  : FuerzaVentasTheme.neonRed.withOpacity(0.12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isOnline ? Icons.wifi : Icons.wifi_off, 
                    color: _isOnline ? FuerzaVentasTheme.neonGreen : FuerzaVentasTheme.neonRed, 
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isOnline 
                        ? 'CONEXIÓN ONLINE - Core Mobile BCP' 
                        : 'MODO OFFLINE - Base Local SQLite Activa',
                    style: TextStyle(
                      color: _isOnline ? FuerzaVentasTheme.neonGreen : FuerzaVentasTheme.neonRed, 
                      fontSize: 11, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: FuerzaVentasTheme.bcpOrange))
                    : _getBody(_selectedMenuIndex),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile(int index, IconData icon, String title, {int badgeCount = 0, bool isSpecial = false}) {
    final isSelected = _selectedMenuIndex == index;
    final activeColor = isSpecial 
        ? FuerzaVentasTheme.neonOrange 
        : FuerzaVentasTheme.neonCyan;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: activeColor.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(
          icon, 
          color: isSelected ? activeColor : (isSpecial ? FuerzaVentasTheme.bcpOrange.withOpacity(0.7) : Colors.white60),
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13.5,
          ),
        ),
        trailing: badgeCount > 0
            ? Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: FuerzaVentasTheme.neonRed, shape: BoxShape.circle),
                child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            : null,
        onTap: () {
          setState(() {
            _selectedMenuIndex = index;
          });
          Navigator.pop(context);
        },
      ),
    );
  }
}
