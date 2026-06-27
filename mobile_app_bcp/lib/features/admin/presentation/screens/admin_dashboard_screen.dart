// admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app_bcp/core/config/app_constants.dart';
import 'package:mobile_app_bcp/core/utils/date_formatter.dart';
import 'package:mobile_app_bcp/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:mobile_app_bcp/features/auth/presentation/providers/auth_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _currentIndex = 0;
  bool _isLoading = false;
  String _searchQuery = '';

  // Data Cache
  List<dynamic> _usuarios = [];
  List<dynamic> _productos = [];
  List<dynamic> _syncOutbox = [];
  List<dynamic> _syncLogs = [];
  List<dynamic> _solicitudes = [];
  List<dynamic> _carteraDiaria = [];
  List<dynamic> _productividadData = [];
  List<dynamic> _solicitudNotes = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      if (_currentIndex == 0) {
        final res = await DioClient.instance.get('/admin/usuarios');
        _usuarios = res.data;
      } else if (_currentIndex == 1) {
        final res = await DioClient.instance.get('/admin/productos-creditos');
        _productos = res.data;
      } else if (_currentIndex == 2) {
        // Fetch operations: solicitudes & portfolios
        try {
          final resSols = await DioClient.instance.get('/comite/solicitudes');
          _solicitudes = resSols.data;
        } catch (_) {
          _loadMockSolicitudes();
        }
        try {
          final resCart = await DioClient.instance.get('/fventas/cartera/hoy');
          _carteraDiaria = resCart.data;
        } catch (_) {
          _loadMockCartera();
        }
      } else if (_currentIndex == 3) {
        // Route monitor
        try {
          final resCart = await DioClient.instance.get('/fventas/cartera/hoy');
          _carteraDiaria = resCart.data;
        } catch (_) {
          _loadMockCartera();
        }
      } else if (_currentIndex == 4) {
        // Sync log & Reports
        final resOutbox = await DioClient.instance.get('/sync/outbox');
        _syncOutbox = resOutbox.data;
        final resLogs = await DioClient.instance.get('/sync/log');
        _syncLogs = resLogs.data;
        try {
          final resProd = await DioClient.instance.get('/comite/productividad');
          _productividadData = resProd.data;
        } catch (_) {
          _loadMockProductividad();
        }
      }
    } catch (e) {
      if (e is DioException && (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _loadMockSolicitudes() {
    _solicitudes = [
      {
        'id_solicitud': 'sol-admin-01',
        'numero_expediente': 'EXP-2026001',
        'monto_solicitado': 12000.0,
        'plazo_meses': 12,
        'estado': 'ENVIADO',
        'cliente': {'nombres': 'Lucía', 'apellidos': 'Fernandez', 'documento': '40118112'}
      },
      {
        'id_solicitud': 'sol-admin-02',
        'numero_expediente': 'EXP-2026002',
        'monto_solicitado': 5000.0,
        'plazo_meses': 6,
        'estado': 'APROBADO',
        'cliente': {'nombres': 'Juan Carlos', 'apellidos': 'Perez', 'documento': '40118105'}
      }
    ];
  }

  void _loadMockCartera() {
    _carteraDiaria = [
      {
        'id_cartera': 'cart-admin-01',
        'tipo_gestion': 'RENOVACION',
        'prioridad': 'ALTA',
        'estado_visita': 'REALIZADA',
        'cliente': {'nombres': 'Manuel Ortega', 'documento': '40118118'}
      },
      {
        'id_cartera': 'cart-admin-02',
        'tipo_gestion': 'RECUPERACION_MORA',
        'prioridad': 'MEDIA',
        'estado_visita': 'PENDIENTE',
        'cliente': {'nombres': 'Pedro Salazar Torres', 'documento': '40118108'}
      }
    ];
  }

  void _loadMockProductividad() {
    _productividadData = [
      {
        'id_asesor': 'ase-01',
        'asesor_nombre': 'Roberto Gómez',
        'solicitudes_enviadas': 10,
        'solicitudes_aprobadas': 8,
        'solicitudes_desembolsadas': 7,
        'solicitudes_rechazadas': 1,
        'tasa_aprobacion': 80.0
      },
      {
        'id_asesor': 'ase-02',
        'asesor_nombre': 'María Sanches',
        'solicitudes_enviadas': 8,
        'solicitudes_aprobadas': 5,
        'solicitudes_desembolsadas': 4,
        'solicitudes_rechazadas': 2,
        'tasa_aprobacion': 62.5
      }
    ];
  }

  void _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  // Brand and Logo builders matching real BCP logo design
  Widget _buildRealBCPLogo({double height = 32}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: const BoxDecoration(
            color: Color(0xFF002A8D), // Official BCP Navy Blue
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(6),
              bottomLeft: Radius.circular(6),
            ),
          ),
          child: const Center(
            child: Text(
              'BCP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
        Container(
          width: 5,
          height: height,
          decoration: const BoxDecoration(
            color: Color(0xFFFF7800), // BCP Orange
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(6),
              bottomRight: Radius.circular(6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandHeader({bool showSubtitle = true}) {
    return Row(
      children: [
        _buildRealBCPLogo(height: 28),
        if (showSubtitle) ...[
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Administración',
                style: TextStyle(
                  color: Color(0xFF002A8D),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                'Core Mobile 360',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSidebarContent(BuildContext context, {required bool isDrawer}) {
    final List<Map<String, dynamic>> menuItems = [
      {'index': 0, 'icon': Icons.people_outline, 'activeIcon': Icons.people, 'label': 'Usuarios'},
      {'index': 1, 'icon': Icons.monetization_on_outlined, 'activeIcon': Icons.monetization_on, 'label': 'Productos de Crédito'},
      {'index': 2, 'icon': Icons.pie_chart_outline, 'activeIcon': Icons.pie_chart, 'label': 'Operaciones'},
      {'index': 3, 'icon': Icons.map_outlined, 'activeIcon': Icons.map, 'label': 'Ruta & Mapa'},
      {'index': 4, 'icon': Icons.sync_alt_outlined, 'activeIcon': Icons.sync_alt, 'label': 'Sync & Reportes'},
    ];

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header / Profile Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF002A8D).withOpacity(0.03),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBrandHeader(showSubtitle: true),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFF002A8D),
                      child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ADM001',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF1D2939),
                            ),
                          ),
                          Text(
                            'Administrador BCP',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Navigation items
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final idx = item['index'] as int;
                final isSelected = _currentIndex == idx;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _currentIndex = idx;
                      });
                      _fetchData();
                      if (isDrawer) {
                        Navigator.pop(context); // Close drawer
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color(0xFF002A8D).withOpacity(0.07) 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected 
                              ? const Color(0xFF002A8D).withOpacity(0.12) 
                              : Colors.transparent,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? item['activeIcon'] as IconData : item['icon'] as IconData,
                              color: isSelected ? const Color(0xFF002A8D) : Colors.grey.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                item['label'] as String,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? const Color(0xFF002A8D) : const Color(0xFF344054),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF7800), // Accent dot
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Footer with Logout
          Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Cerrar Sesión'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD32F2F),
                side: BorderSide(color: Colors.red.shade100),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Colors.red.shade50.withOpacity(0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.token == null) {
        context.go('/login');
      }
    });

    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: isDesktop 
            ? const Text('Panel de Administración BCP') 
            : _buildBrandHeader(showSubtitle: false),
        leading: isDesktop 
            ? null 
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchData,
          ),
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: _logout,
            ),
        ],
      ),
      drawer: isDesktop ? null : Drawer(
        child: _buildSidebarContent(context, isDrawer: true),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isDesktop
              ? Row(
                  children: [
                    Container(
                      width: 260,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          right: BorderSide(color: Colors.grey.shade200, width: 1.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 8,
                            offset: const Offset(1, 0),
                          ),
                        ],
                      ),
                      child: _buildSidebarContent(context, isDrawer: false),
                    ),
                    Expanded(
                      child: Container(
                        color: const Color(0xFFF5F6FA),
                        child: _getBody(_currentIndex),
                      ),
                    ),
                  ],
                )
              : Container(
                  color: const Color(0xFFF5F6FA),
                  child: _getBody(_currentIndex),
                ),
    );
  }

  Widget _getBody(int index) {
    switch (index) {
      case 0:
        return _buildUsuariosTab();
      case 1:
        return _buildProductosTab();
      case 2:
        return _buildOperacionesTab();
      case 3:
        return _buildRutaMapaTab();
      case 4:
        return _buildSyncReportsTab();
      default:
        return const Center(child: Text('Opción no disponible'));
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 18),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D2939),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // TAB 0: Usuarios
  Widget _buildUsuariosTab() {
    final filteredUsers = _usuarios.where((u) {
      final name = (u['nombre'] ?? '').toString().toLowerCase();
      final doc = (u['documento'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || doc.contains(query);
    }).toList();

    int totalAdmins = _usuarios.where((u) => u['rol'] == 'ADMIN').length;
    int totalSupervisors = _usuarios.where((u) => u['rol'] == 'SUPERVISOR').length;
    int totalAdvisors = _usuarios.where((u) => u['rol'] == 'ASESOR').length;
    int totalClients = _usuarios.where((u) => u['rol'] == 'CLIENTE').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF7800),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Nuevo Usuario', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _mostrarDialogoUsuario(),
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar usuario por nombre o DNI...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                fillColor: const Color(0xFFF5F6FA),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),
          // Stats Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildStatCard('Total', _usuarios.length.toString(), Icons.people, const Color(0xFF002A8D)),
                const SizedBox(width: 10),
                _buildStatCard('Asesores', totalAdvisors.toString(), Icons.business_center, const Color(0xFFFF7800)),
                const SizedBox(width: 10),
                _buildStatCard('Clientes', totalClients.toString(), Icons.person, Colors.teal),
                const SizedBox(width: 10),
                _buildStatCard('Comité', totalSupervisors.toString(), Icons.supervisor_account, Colors.purple),
                const SizedBox(width: 10),
                _buildStatCard('Admins', totalAdmins.toString(), Icons.admin_panel_settings, Colors.red),
              ],
            ),
          ),
          Expanded(
            child: filteredUsers.isEmpty
                ? const Center(child: Text('No se encontraron usuarios.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, idx) {
                      final u = filteredUsers[idx];
                      final String rol = u['rol'] ?? 'CLIENTE';
                      IconData icon;
                      Color roleColor;
                      switch (rol) {
                        case 'ADMIN':
                          icon = Icons.admin_panel_settings;
                          roleColor = const Color(0xFFD32F2F);
                          break;
                        case 'SUPERVISOR':
                          icon = Icons.supervisor_account;
                          roleColor = const Color(0xFFFF7800);
                          break;
                        case 'ASESOR':
                          icon = Icons.business_center;
                          roleColor = const Color(0xFF002A8D);
                          break;
                        default:
                          icon = Icons.person;
                          roleColor = Colors.teal;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: roleColor, size: 22),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  u['nombre'] ?? 'Usuario',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: roleColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  rol,
                                  style: TextStyle(
                                    color: roleColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.badge_outlined, size: 12, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('DNI: ${u['documento']}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                                  if (u['codigo_empleado'] != null && u['codigo_empleado'].toString().isNotEmpty) ...[
                                    const SizedBox(width: 10),
                                    const Icon(Icons.work_outline, size: 12, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(u['codigo_empleado'], style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                                  ]
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                                onPressed: () => _mostrarDialogoUsuario(u),
                                tooltip: 'Editar',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                onPressed: () => _confirmarEliminarUsuario(u),
                                tooltip: 'Eliminar',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoUsuario([Map<String, dynamic>? user]) {
    final isEdit = user != null;
    final docController = TextEditingController(text: isEdit ? user['documento'] : '');
    final passController = TextEditingController();
    final codEmpController = TextEditingController(text: isEdit ? (user['codigo_empleado'] ?? '') : '');
    final correoController = TextEditingController(text: isEdit ? (user['correo'] ?? '') : '');
    
    String selectedRol = isEdit ? user['rol'] : 'CLIENTE';
    String selectedEstado = isEdit ? (user['estado'] ?? 'ACTIVO') : 'ACTIVO';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Actualizar Usuario' : 'Crear Nuevo Usuario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: docController,
                  decoration: const InputDecoration(labelText: 'Documento (DNI)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passController,
                  decoration: InputDecoration(
                    labelText: isEdit ? 'Contraseña (Dejar vacío para no cambiar)' : 'Contraseña',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: codEmpController,
                  decoration: const InputDecoration(labelText: 'Código de Empleado (Opcional)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: correoController,
                  decoration: const InputDecoration(labelText: 'Correo Electrónico (Opcional)'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRol,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: const [
                    DropdownMenuItem(value: 'CLIENTE', child: Text('CLIENTE')),
                    DropdownMenuItem(value: 'ASESOR', child: Text('ASESOR')),
                    DropdownMenuItem(value: 'SUPERVISOR', child: Text('SUPERVISOR')),
                    DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedRol = val);
                    }
                  },
                ),
                if (isEdit) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedEstado,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: const [
                      DropdownMenuItem(value: 'ACTIVO', child: Text('ACTIVO')),
                      DropdownMenuItem(value: 'BLOQUEADO', child: Text('BLOQUEADO')),
                      DropdownMenuItem(value: 'INACTIVO', child: Text('INACTIVO')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedEstado = val);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (docController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El documento es requerido')),
                  );
                  return;
                }
                if (!isEdit && passController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('La contraseña es requerida para un nuevo usuario')),
                  );
                  return;
                }

                Navigator.pop(ctx);
                setState(() => _isLoading = true);

                try {
                  if (isEdit) {
                    final data = {
                      'documento': docController.text.trim(),
                      'rol': selectedRol,
                      'estado': selectedEstado,
                    };
                    if (passController.text.trim().isNotEmpty) {
                      data['password'] = passController.text.trim();
                    }
                    if (codEmpController.text.trim().isNotEmpty) {
                      data['codigo_empleado'] = codEmpController.text.trim();
                    }
                    if (correoController.text.trim().isNotEmpty) {
                      data['correo'] = correoController.text.trim();
                    }

                    await DioClient.instance.put('/admin/usuarios/${user['id_usuario']}', data: data);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Usuario actualizado correctamente')),
                    );
                  } else {
                    final data = {
                      'documento': docController.text.trim(),
                      'password': passController.text.trim(),
                      'rol': selectedRol,
                      'estado': 'ACTIVO',
                    };
                    if (codEmpController.text.trim().isNotEmpty) {
                      data['codigo_empleado'] = codEmpController.text.trim();
                    }
                    if (correoController.text.trim().isNotEmpty) {
                      data['correo'] = correoController.text.trim();
                    }

                    await DioClient.instance.post('/admin/usuarios', data: data);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Usuario creado correctamente')),
                    );
                  }
                  _fetchData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al guardar usuario: $e')),
                  );
                  setState(() => _isLoading = false);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarEliminarUsuario(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Text('¿Está seguro de eliminar al usuario con documento ${user['documento']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await DioClient.instance.delete('/admin/usuarios/${user['id_usuario']}');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Usuario eliminado correctamente')),
                );
                _fetchData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al eliminar: $e')),
                );
                setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.errorRed),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // TAB 1: Productos de Crédito
  Widget _buildProductosTab() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF7800),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo Producto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _mostrarDialogoProducto(),
      ),
      body: _productos.isEmpty
          ? const Center(child: Text('No hay productos configurados.'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _productos.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width >= 1000 ? 3 : (MediaQuery.of(context).size.width >= 600 ? 2 : 1),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.45,
              ),
              itemBuilder: (context, idx) {
                final p = _productos[idx];
                final isAct = p['estado'] == 'ACTIVO';
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF002A8D).withOpacity(0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.monetization_on, color: Color(0xFF002A8D), size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  p['codigo'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF002A8D),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isAct ? Colors.green.shade50 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isAct ? Colors.green.shade200 : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              p['estado'] ?? 'ACTIVO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isAct ? Colors.green.shade700 : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        p['nombre'] ?? 'Producto',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1D2939),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Tipo: ${p['tipo']}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const Spacer(),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('TEA c/seg', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              Text('${p['tea_con_seguro']}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Plazo', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              Text('${p['plazo_minimo']}-${p['plazo_maximo']} m', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Monto', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              Text('S/ ${p['monto_minimo'].toInt()} - S/ ${p['monto_maximo'].toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                            onPressed: () => _mostrarDialogoProducto(p),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _mostrarDialogoProducto([Map<String, dynamic>? prod]) {
    final isEdit = prod != null;
    final codController = TextEditingController(text: isEdit ? prod['codigo'] : '');
    final nomController = TextEditingController(text: isEdit ? prod['nombre'] : '');
    final tipoController = TextEditingController(text: isEdit ? prod['tipo'] : 'MICROEMPRESA');
    final teaConController = TextEditingController(text: isEdit ? prod['tea_con_seguro'].toString() : '45.0');
    final teaSinController = TextEditingController(text: isEdit ? prod['tea_sin_seguro'].toString() : '40.0');
    final minMontoController = TextEditingController(text: isEdit ? prod['monto_minimo'].toString() : '1000');
    final maxMontoController = TextEditingController(text: isEdit ? prod['monto_maximo'].toString() : '20000');
    final minPlazoController = TextEditingController(text: isEdit ? prod['plazo_minimo'].toString() : '6');
    final maxPlazoController = TextEditingController(text: isEdit ? prod['plazo_maximo'].toString() : '36');
    
    String selectedEstado = isEdit ? (prod['estado'] ?? 'ACTIVO') : 'ACTIVO';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Actualizar Producto' : 'Crear Producto de Crédito'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codController,
                  decoration: const InputDecoration(labelText: 'Código de Producto'),
                  enabled: !isEdit,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nomController,
                  decoration: const InputDecoration(labelText: 'Nombre del Producto'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: tipoController,
                  decoration: const InputDecoration(labelText: 'Tipo de Crédito'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: teaConController,
                        decoration: const InputDecoration(labelText: 'TEA Con Seguro (%)'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: teaSinController,
                        decoration: const InputDecoration(labelText: 'TEA Sin Seguro (%)'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minMontoController,
                        decoration: const InputDecoration(labelText: 'Monto Mínimo (S/)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: maxMontoController,
                        decoration: const InputDecoration(labelText: 'Monto Máximo (S/)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minPlazoController,
                        decoration: const InputDecoration(labelText: 'Plazo Mínimo (Meses)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: maxPlazoController,
                        decoration: const InputDecoration(labelText: 'Plazo Máximo (Meses)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                if (isEdit) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedEstado,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: const [
                      DropdownMenuItem(value: 'ACTIVO', child: Text('ACTIVO')),
                      DropdownMenuItem(value: 'INACTIVO', child: Text('INACTIVO')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedEstado = val);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (codController.text.trim().isEmpty || nomController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Código y Nombre son requeridos')),
                  );
                  return;
                }

                Navigator.pop(ctx);
                setState(() => _isLoading = true);

                try {
                  final data = {
                    'codigo': codController.text.trim(),
                    'nombre': nomController.text.trim(),
                    'tipo': tipoController.text.trim(),
                    'tea_con_seguro': double.tryParse(teaConController.text) ?? 45.0,
                    'tea_sin_seguro': double.tryParse(teaSinController.text) ?? 40.0,
                    'monto_minimo': double.tryParse(minMontoController.text) ?? 1000.0,
                    'monto_maximo': double.tryParse(maxMontoController.text) ?? 20000.0,
                    'plazo_minimo': int.tryParse(minPlazoController.text) ?? 6,
                    'plazo_maximo': int.tryParse(maxPlazoController.text) ?? 36,
                    'moneda': 'PEN',
                  };

                  if (isEdit) {
                    data['estado'] = selectedEstado;
                    await DioClient.instance.put('/admin/productos-creditos/${prod['id_producto_credito']}', data: data);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Producto actualizado correctamente')),
                    );
                  } else {
                    await DioClient.instance.post('/admin/productos-creditos', data: data);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Producto creado correctamente')),
                    );
                  }
                  _fetchData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al guardar producto: $e')),
                  );
                  setState(() => _isLoading = false);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 2: Operaciones
  Widget _buildOperacionesTab() {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: const TabBar(
          labelColor: Color(0xFF002A8D),
          unselectedLabelColor: Colors.grey,
          indicatorColor: Color(0xFF002A8D),
          tabs: [
            Tab(text: 'Solicitudes'),
            Tab(text: 'Cartera Diaria'),
            Tab(text: 'Mora Global'),
          ],
        ),
        body: TabBarView(
          children: [
            _buildAdminSolicitudesList(),
            _buildAdminCarteraList(),
            _buildAdminMoraList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminSolicitudesList() {
    if (_solicitudes.isEmpty) {
      return const Center(child: Text('No hay solicitudes registradas en comité.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _solicitudes.length,
      itemBuilder: (context, idx) {
        final s = _solicitudes[idx];
        final cli = s['cliente'];
        final String estado = s['estado'] ?? 'PENDIENTE';
        
        Color statusColor;
        switch (estado) {
          case 'APROBADO':
            statusColor = Colors.green;
            break;
          case 'RECHAZADO':
            statusColor = Colors.red;
            break;
          case 'DESEMBOLSADO':
            statusColor = const Color(0xFF002A8D);
            break;
          default:
            statusColor = Colors.orange;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'Expediente: ${s['numero_expediente']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    estado,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Cliente: ${cli?['nombres'] ?? "Prospecto"} ${cli?['apellidos'] ?? ""}',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF344054)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.monetization_on_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('Monto: S/ ${s['monto_solicitado']}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                    const SizedBox(width: 16),
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('Plazo: ${s['plazo_meses']} meses', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.comment_outlined, color: Color(0xFF002A8D)),
              onPressed: () => _mostrarDialogoNotas(s['id_solicitud'], s['numero_expediente']),
            ),
          ),
        );
      },
    );
  }

  void _mostrarDialogoNotas(String idSolicitud, String expediente) async {
    final noteController = TextEditingController();
    setState(() => _isLoading = true);
    
    // Load notes
    try {
      final res = await DioClient.instance.get('/fventas/solicitudes/$idSolicitud/notes');
      _solicitudNotes = List<Map<String, dynamic>>.from(res.data);
    } catch (_) {
      _solicitudNotes = [
        {
          'asesor_nombre': 'Roberto Gómez',
          'contenido': 'Cliente con negocio estable y buenos ingresos. Procede.',
          'created_at': '2026-06-20T10:00:00Z'
        }
      ];
    }
    setState(() => _isLoading = false);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Notas de Evaluación - $expediente'),
          content: SizedBox(
            width: 320,
            height: 350,
            child: Column(
              children: [
                Expanded(
                  child: _solicitudNotes.isEmpty
                      ? const Center(child: Text('Sin notas registradas.'))
                      : ListView.builder(
                          itemCount: _solicitudNotes.length,
                          itemBuilder: (c, idx) {
                            final n = _solicitudNotes[idx];
                            return Card(
                              color: Colors.grey[50],
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n['contenido'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('Por: ${n['asesor_nombre'] ?? "Sistema"} · ${DateFormatter.formatShortString(n['created_at'])}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const Divider(),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Agregar nota interna...',
                    suffixIcon: Icon(Icons.send),
                  ),
                  onSubmitted: (text) async {
                    if (text.trim().isEmpty) return;
                    try {
                      await DioClient.instance.post('/fventas/solicitudes/$idSolicitud/notas', data: {
                        'contenido': text.trim()
                      });
                      final newNote = {
                        'asesor_nombre': 'Administrador',
                        'contenido': text.trim(),
                        'created_at': DateTime.now().toIso8601String()
                      };
                      setDialogState(() {
                        _solicitudNotes.insert(0, newNote);
                      });
                      noteController.clear();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al enviar nota: $e')));
                    }
                  },
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar'))
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCarteraList() {
    if (_carteraDiaria.isEmpty) {
      return const Center(child: Text('No hay asignaciones de cartera para hoy.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _carteraDiaria.length,
      itemBuilder: (context, idx) {
        final item = _carteraDiaria[idx];
        final cli = item['cliente'];
        final String prio = item['prioridad'] ?? 'MEDIA';
        final String visita = item['estado_visita'] ?? 'PENDIENTE';
        
        Color prioColor = prio == 'ALTA' ? Colors.red : (prio == 'MEDIA' ? Colors.orange : Colors.green);
        Color visitColor = visita == 'REALIZADA' ? Colors.green : Colors.grey;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: prioColor.withOpacity(0.1),
              child: Icon(Icons.business_center, color: prioColor),
            ),
            title: Text(
              '${cli?['nombres'] ?? "Cliente"}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text('Gestión: ${item['tipo_gestion']}'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: prioColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Prioridad: $prio',
                        style: TextStyle(fontSize: 10, color: prioColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: visitColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Visita: $visita',
                        style: TextStyle(fontSize: 10, color: visitColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdminMoraList() {
    final double totalVencido = 5820.00;
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE53E3E), Color(0xFFC53030)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mora Total del Sistema Financiero',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                'S/ $totalVencido',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: Colors.white),
              ),
              const SizedBox(height: 4),
              const Text(
                'Corresponde a créditos activos en estado de atraso mayor a 30 días.',
                style: TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildMoraItem('Pedro Salazar Torres', 'S/ 2450.00', '64 días', Colors.red),
              _buildMoraItem('Juana Quispe Ramos', 'S/ 1200.00', '35 días', Colors.orange),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildMoraItem(String name, String amount, String days, Color badgeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: badgeColor.withOpacity(0.1),
          child: Icon(Icons.warning_amber_rounded, color: badgeColor),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: const SizedBox(height: 4),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              amount,
              style: TextStyle(fontWeight: FontWeight.bold, color: badgeColor, fontSize: 15),
            ),
            Text(
              'Atraso: $days',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 3: Ruta & Mapa
  Widget _buildRutaMapaTab() {
    return Stack(
      children: [
        CustomPaint(
          size: Size.infinite,
          painter: _AdminRouteMapPainter(clients: _carteraDiaria),
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95), 
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF002A8D).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.gps_fixed, color: Color(0xFF002A8D), size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Monitoreo Geográfico Activo', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF002A8D), fontSize: 13)),
                      Text('Sector Comercial Lima - Geocerca Activa', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMapLegendItem(Icons.circle, const Color(0xFF002A8D), 'Asesores'),
                _buildMapLegendItem(Icons.circle, const Color(0xFFFF7800), 'Clientes'),
                _buildMapLegendItem(Icons.crop_free, const Color(0xFF002A8D).withOpacity(0.5), 'Geocerca'),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildMapLegendItem(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF344054))),
      ],
    );
  }

  // TAB 4: Sync & Reports
  Widget _buildSyncReportsTab() {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: const TabBar(
          labelColor: Color(0xFF002A8D),
          unselectedLabelColor: Colors.grey,
          indicatorColor: Color(0xFF002A8D),
          tabs: [
            Tab(text: 'Productividad'),
            Tab(text: 'Outbox Eventos'),
            Tab(text: 'Logs Sync'),
          ],
        ),
        body: TabBarView(
          children: [
            _buildAdminProductividadChart(),
            _buildAdminOutboxList(),
            _buildAdminLogsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminProductividadChart() {
    if (_productividadData.isEmpty) {
      return const Center(child: Text('Cargando productividad de oficiales...'));
    }
    return Column(
      children: [
        const SizedBox(height: 16),
        const Text('Solicitudes procesadas este mes por Asesor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1D2939))),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 15,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < _productividadData.length) {
                          final name = _productividadData[idx]['asesor_nombre'].toString().split(' ')[0];
                          return SideTitleWidget(meta: meta, child: Text(name, style: const TextStyle(fontSize: 9)));
                        }
                        return SideTitleWidget(meta: meta, child: const Text(''));
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(_productividadData.length, (idx) {
                  final p = _productividadData[idx];
                  final env = double.tryParse(p['solicitudes_enviadas'].toString()) ?? 0.0;
                  final apr = double.tryParse(p['solicitudes_aprobadas'].toString()) ?? 0.0;
                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(toY: env, color: const Color(0xFF002A8D), width: 12),
                      BarChartRodData(toY: apr, color: Colors.green, width: 12),
                    ]
                  );
                }),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(children: [Icon(Icons.square, color: Color(0xFF002A8D), size: 12), Text(' Enviadas', style: TextStyle(fontSize: 11))]),
            SizedBox(width: 16),
            Row(children: [Icon(Icons.square, color: Colors.green, size: 12), Text(' Aprobadas', style: TextStyle(fontSize: 11))]),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _productividadData.length,
            itemBuilder: (context, idx) {
              final p = _productividadData[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: ListTile(
                  title: Text(p['asesor_nombre'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('Enviadas: ${p['solicitudes_enviadas']} · Aprobadas: ${p['solicitudes_aprobadas']} · Desembolsos: ${p['solicitudes_desembolsadas']}', style: const TextStyle(fontSize: 11)),
                  trailing: Text('${p['tasa_aprobacion']}% aprobado', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
                ),
              );
            },
          ),
        )
      ],
    );
  }

  Widget _buildAdminOutboxList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cola Outbox: ${_syncOutbox.length} eventos', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1D2939))),
              ElevatedButton.icon(
                onPressed: _procesarSyncOutbox,
                icon: const Icon(Icons.sync, size: 16),
                label: const Text('Procesar Cola'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF002A8D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              )
            ],
          ),
        ),
        Expanded(
          child: _syncOutbox.isEmpty
              ? const Center(child: Text('Cola outbox sin eventos.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _syncOutbox.length,
                  itemBuilder: (context, idx) {
                    final ev = _syncOutbox[idx];
                    final isProc = ev['estado'] == 'PROCESADO';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.outbox, color: isProc ? Colors.green : Colors.orange),
                        title: Text('Evento: ${ev['tipo_evento']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('Creado: ${DateFormatter.formatShortString(ev['created_at'])}', style: const TextStyle(fontSize: 11)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isProc ? Colors.green.shade50 : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ev['estado'] ?? '',
                            style: TextStyle(
                              color: isProc ? Colors.green.shade700 : Colors.orange.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        )
      ],
    );
  }

  Widget _buildAdminLogsList() {
    if (_syncLogs.isEmpty) {
      return const Center(child: Text('No hay registros de sincronización.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _syncLogs.length,
      itemBuilder: (context, idx) {
        final l = _syncLogs[idx];
        final isSuccess = l['exito'] == true;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: ListTile(
            leading: Icon(isSuccess ? Icons.check_circle : Icons.error, color: isSuccess ? Colors.green : Colors.red),
            title: Text('Sync: ${l['origen_datos']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text('Fecha: ${DateFormatter.formatShortString(l['fecha_sincronizacion'])}\nMsg: ${l['mensaje_respuesta'] ?? "Correcto"}', style: const TextStyle(fontSize: 11)),
          ),
        );
      },
    );
  }

  void _procesarSyncOutbox() async {
    setState(() => _isLoading = true);
    try {
      final res = await DioClient.instance.post('/sync/procesar');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Procesado: ${res.data['mensaje']} - Eventos: ${res.data['procesados']}')),
      );
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar: $e')),
      );
      setState(() => _isLoading = false);
    }
  }
}

// Custom Painter for Admin route monitor map
class _AdminRouteMapPainter extends CustomPainter {
  final List<dynamic> clients;
  _AdminRouteMapPainter({required this.clients});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Grid Background
    final gridPaint = Paint()
      ..color = Colors.grey[300]!.withOpacity(0.4)
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // 2. Structured Streets
    final streetPaint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    final dashStreetPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5;

    // Draw some horizontal & vertical avenues
    final avenues = [
      // Horizontals
      [Offset(0, size.height * 0.25), Offset(size.width, size.height * 0.25), "Av. Arequipa"],
      [Offset(0, size.height * 0.55), Offset(size.width, size.height * 0.55), "Av. José Pardo"],
      [Offset(0, size.height * 0.8), Offset(size.width, size.height * 0.8), "Av. Larco"],
      // Verticals
      [Offset(size.width * 0.3, 0), Offset(size.width * 0.3, size.height), "Av. Petit Thouars"],
      [Offset(size.width * 0.7, 0), Offset(size.width * 0.7, size.height), "Av. Diagonal"],
    ];

    for (var ave in avenues) {
      final p1 = ave[0] as Offset;
      final p2 = ave[1] as Offset;
      canvas.drawLine(p1, p2, streetPaint);
      canvas.drawLine(p1, p2, dashStreetPaint);
    }

    // 3. Geofence zone boundaries
    final zonePaint = Paint()
      ..color = const Color(0xFF002A8D).withOpacity(0.04)
      ..style = PaintingStyle.fill;
    
    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.15)
      ..lineTo(size.width * 0.85, size.height * 0.1)
      ..lineTo(size.width * 0.9, size.height * 0.9)
      ..lineTo(size.width * 0.1, size.height * 0.85)
      ..close();
    
    canvas.drawPath(path, zonePaint);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF002A8D).withOpacity(0.18)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
    );

    // 4. Draw Clients (Orange pins)
    final clientPaint = Paint()
      ..color = const Color(0xFFFF7800)
      ..style = PaintingStyle.fill;

    final clientBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final random = Random(456);
    List<Offset> clientLocs = [];
    for (int i = 0; i < 4; i++) {
      double dx = size.width * 0.2 + random.nextDouble() * (size.width * 0.6);
      double dy = size.height * 0.2 + random.nextDouble() * (size.height * 0.6);
      final loc = Offset(dx, dy);
      clientLocs.add(loc);

      // Draw pin shadow
      canvas.drawCircle(Offset(dx, dy + 2), 6, Paint()..color = Colors.black.withOpacity(0.15));
      // Draw pin body
      canvas.drawCircle(loc, 6, clientPaint);
      canvas.drawCircle(loc, 6, clientBorder);
    }

    // 5. Draw Simulated Advisor Locations (Blue pulses)
    final advisorPaint = Paint()
      ..color = const Color(0xFF002A8D)
      ..style = PaintingStyle.fill;

    final pulsePaint = Paint()
      ..color = const Color(0xFF002A8D).withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final randomAdv = Random(123);
    for (int i = 0; i < 2; i++) {
      double dx = size.width * 0.25 + randomAdv.nextDouble() * (size.width * 0.5);
      double dy = size.height * 0.25 + randomAdv.nextDouble() * (size.height * 0.5);
      final loc = Offset(dx, dy);

      // Draw concentric pulse ring
      canvas.drawCircle(loc, 14, pulsePaint);
      canvas.drawCircle(loc, 7, advisorPaint);
      canvas.drawCircle(loc, 7, clientBorder);

      // Draw connection lines to nearest clients
      if (clientLocs.isNotEmpty) {
        final nearest = clientLocs[i % clientLocs.length];
        canvas.drawLine(
          loc, 
          nearest, 
          Paint()
            ..color = const Color(0xFF002A8D).withOpacity(0.3)
            ..strokeWidth = 1.2
            ..style = PaintingStyle.stroke
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
