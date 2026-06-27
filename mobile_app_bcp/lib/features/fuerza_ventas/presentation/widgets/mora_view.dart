import 'package:flutter/material.dart';
import '../theme/fuerza_ventas_theme.dart';

class MoraView extends StatefulWidget {
  final List<Map<String, dynamic>> moraList;
  final double montoTotalVencido;
  final Function(
    String idCartera,
    String tipo,
    String resultado,
    double monto,
    String obs,
  ) onRegisterCobranza;

  const MoraView({
    super.key,
    required this.moraList,
    required this.montoTotalVencido,
    required this.onRegisterCobranza,
  });

  @override
  State<MoraView> createState() => _MoraViewState();
}

class _MoraViewState extends State<MoraView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filtroActivo = 'TODOS'; // TODOS, ALTA, MEDIA, NORMAL
  String _ordenActivo = 'DIAS_DESC'; // DIAS_DESC, MONTO_DESC, NOMBRE_ASC

  // Local gestión history (session-level)
  final List<Map<String, dynamic>> _historialGestiones = [];

  // Compromisos de pago (session-level)
  final List<Map<String, dynamic>> _compromisos = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Pre-populate compromisos with demo data
    _compromisos.addAll([
      {
        'cliente': 'Pedro Salazar Torres',
        'monto': 1500.0,
        'fecha': '2026-07-01',
        'estado': 'PENDIENTE',
        'dias_restantes': 6,
      },
      {
        'cliente': 'Juana Quispe Ramos',
        'monto': 800.0,
        'fecha': '2026-06-30',
        'estado': 'PENDIENTE',
        'dias_restantes': 5,
      },
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  Color _semaforoColor(int dias) {
    if (dias > 60) return FuerzaVentasTheme.neonRed;
    if (dias > 30) return FuerzaVentasTheme.neonOrange;
    if (dias > 15) return Colors.yellowAccent;
    return FuerzaVentasTheme.neonGreen;
  }

  String _semaforoLabel(int dias) {
    if (dias > 60) return 'CRÍTICO';
    if (dias > 30) return 'ALTO';
    if (dias > 15) return 'MEDIO';
    return 'LEVE';
  }

  List<Map<String, dynamic>> get _filteredList {
    var list = List<Map<String, dynamic>>.from(widget.moraList);

    // Filter by prioridad
    if (_filtroActivo != 'TODOS') {
      list = list.where((m) => m['prioridad'] == _filtroActivo).toList();
    }

    // Sort
    switch (_ordenActivo) {
      case 'DIAS_DESC':
        list.sort((a, b) {
          final da = a['dias_mora'] is int ? a['dias_mora'] as int : 0;
          final db = b['dias_mora'] is int ? b['dias_mora'] as int : 0;
          return db.compareTo(da);
        });
        break;
      case 'MONTO_DESC':
        list.sort((a, b) {
          final ma = double.tryParse(a['monto_vencido'].toString()) ?? 0;
          final mb = double.tryParse(b['monto_vencido'].toString()) ?? 0;
          return mb.compareTo(ma);
        });
        break;
      case 'NOMBRE_ASC':
        list.sort((a, b) =>
            (a['cliente_nombre'] ?? '').toString().compareTo((b['cliente_nombre'] ?? '').toString()));
        break;
    }

    return list;
  }

  int get _totalClientes => widget.moraList.length;
  int get _clientesCriticos =>
      widget.moraList.where((m) => (m['dias_mora'] is int ? m['dias_mora'] as int : 0) > 60).length;
  int get _clientesConCompromiso => _compromisos.length;


  // ─────────────────────────────────────────────
  // DIALOG — GESTIÓN DE COBRANZA
  // ─────────────────────────────────────────────

  void _showCobranzaDialog(Map<String, dynamic> item) {
    final montoController = TextEditingController();
    final notesController = TextEditingController();
    final fechaCompromisoController =
        TextEditingController(text: _dateAfterDays(7));
    String actionType = 'Visita';
    String resultType = 'Compromiso de pago';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final showMonto =
              resultType == 'Compromiso de pago' || resultType == 'Pago parcial';
          final showFecha = resultType == 'Compromiso de pago';

          return AlertDialog(
            backgroundColor: FuerzaVentasTheme.cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Colors.white10),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.payment_outlined, color: FuerzaVentasTheme.neonOrange, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'Registrar Gestión de Mora',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item['cliente_nombre'] ?? '',
                  style: const TextStyle(color: Colors.white54, fontSize: 12.5, fontWeight: FontWeight.normal),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Client summary chip
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _semaforoColor(item['dias_mora'] is int ? item['dias_mora'] as int : 0)
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mora: S/ ${item['monto_vencido']}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${item['dias_mora'] ?? 0} días de atraso',
                          style: TextStyle(
                            color: _semaforoColor(item['dias_mora'] is int ? item['dias_mora'] as int : 0),
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Tipo de gestion
                  DropdownButtonFormField<String>(
                    dropdownColor: FuerzaVentasTheme.cardDark,
                    decoration: InputDecoration(
                      labelText: 'Tipo de gestión',
                      labelStyle: const TextStyle(color: Colors.white60),
                      prefixIcon: const Icon(Icons.work_outline, color: FuerzaVentasTheme.neonCyan, size: 20),
                      filled: true,
                      fillColor: FuerzaVentasTheme.inputFieldColor,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    style: const TextStyle(color: Colors.white),
                    initialValue: actionType,
                    items: ['Visita', 'Llamada telefónica', 'Mensaje WhatsApp', 'Carta notarial']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => actionType = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Resultado
                  DropdownButtonFormField<String>(
                    dropdownColor: FuerzaVentasTheme.cardDark,
                    decoration: InputDecoration(
                      labelText: 'Resultado de la gestión',
                      labelStyle: const TextStyle(color: Colors.white60),
                      prefixIcon: const Icon(Icons.check_circle_outline, color: FuerzaVentasTheme.neonCyan, size: 20),
                      filled: true,
                      fillColor: FuerzaVentasTheme.inputFieldColor,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    style: const TextStyle(color: Colors.white),
                    initialValue: resultType,
                    items: [
                      'Compromiso de pago',
                      'Pago parcial',
                      'Pago total',
                      'Sin contacto',
                      'Promesa no cumplida',
                      'Se niega a pagar',
                      'Imposible de ubicar',
                    ].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => resultType = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Monto (conditional)
                  if (showMonto)
                    TextFormField(
                      controller: montoController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: resultType == 'Pago parcial'
                            ? 'Monto recibido (S/)'
                            : 'Monto comprometido (S/)',
                        labelStyle: const TextStyle(color: Colors.white60),
                        prefixIcon:
                            const Icon(Icons.attach_money, color: FuerzaVentasTheme.neonGreen, size: 20),
                        filled: true,
                        fillColor: FuerzaVentasTheme.inputFieldColor,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  if (showMonto) const SizedBox(height: 12),

                  // Fecha compromiso (conditional)
                  if (showFecha)
                    TextFormField(
                      controller: fechaCompromisoController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Fecha de compromiso',
                        labelStyle: const TextStyle(color: Colors.white60),
                        prefixIcon:
                            const Icon(Icons.calendar_month_outlined, color: FuerzaVentasTheme.neonCyan, size: 20),
                        filled: true,
                        fillColor: FuerzaVentasTheme.inputFieldColor,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  if (showFecha) const SizedBox(height: 12),

                  // Observaciones
                  TextFormField(
                    controller: notesController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Observaciones detalladas',
                      labelStyle: const TextStyle(color: Colors.white60),
                      prefixIcon: const Icon(Icons.notes_outlined, color: FuerzaVentasTheme.neonCyan, size: 20),
                      filled: true,
                      fillColor: FuerzaVentasTheme.inputFieldColor,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  final monto = double.tryParse(montoController.text) ?? 0.0;
                  widget.onRegisterCobranza(
                    item['id_cartera'] ?? '',
                    actionType,
                    resultType,
                    monto,
                    notesController.text,
                  );
                  // Save locally to session history
                  setState(() {
                    _historialGestiones.insert(0, {
                      'cliente': item['cliente_nombre'],
                      'tipo': actionType,
                      'resultado': resultType,
                      'monto': monto,
                      'obs': notesController.text,
                      'hora': TimeOfDay.now().format(context),
                    });
                    // If compromiso, add to compromisos list
                    if (resultType == 'Compromiso de pago' && monto > 0) {
                      _compromisos.insert(0, {
                        'cliente': item['cliente_nombre'],
                        'monto': monto,
                        'fecha': fechaCompromisoController.text,
                        'estado': 'PENDIENTE',
                        'dias_restantes': 7,
                      });
                    }
                  });
                },
                icon: const Icon(Icons.save_outlined, size: 16),
                label: const Text('Guardar Gestión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FuerzaVentasTheme.bcpOrange,
                  foregroundColor: Colors.white,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _dateAfterDays(int days) {
    final date = DateTime.now().add(Duration(days: days));
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar
        Container(
          color: FuerzaVentasTheme.cardDark.withValues(alpha: 0.6),
          child: TabBar(
            controller: _tabController,
            dividerColor: Colors.white10,
            indicatorColor: FuerzaVentasTheme.neonRed,
            labelColor: FuerzaVentasTheme.neonRed,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.money_off_outlined, size: 16),
                    const SizedBox(width: 4),
                    const Text('Mora'),
                    if (_totalClientes > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: FuerzaVentasTheme.neonRed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_totalClientes',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(icon: Icon(Icons.history_outlined, size: 16), text: 'Historial'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.handshake_outlined, size: 16),
                    const SizedBox(width: 4),
                    const Text('Compromisos'),
                    if (_compromisos.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: FuerzaVentasTheme.neonOrange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_compromisos.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMoraTab(),
              _buildHistorialTab(),
              _buildCompromisosTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // TAB 1 — MORA
  // ─────────────────────────────────────────────

  Widget _buildMoraTab() {
    return Column(
      children: [
        // Dashboard KPI Strip
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: FuerzaVentasTheme.glassDecoration(
            borderColor: FuerzaVentasTheme.neonRed,
            borderOpacity: 0.2,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mora Total Asignada',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Cartera de recuperación activa',
                        style: TextStyle(color: Colors.white30, fontSize: 11),
                      ),
                    ],
                  ),
                  Text(
                    'S/ ${widget.montoTotalVencido.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: FuerzaVentasTheme.neonRed,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Mini KPI row
              Row(
                children: [
                  _buildMiniKpi('$_totalClientes', 'Clientes', FuerzaVentasTheme.neonOrange),
                  _buildDividerV(),
                  _buildMiniKpi('$_clientesCriticos', 'Críticos', FuerzaVentasTheme.neonRed),
                  _buildDividerV(),
                  _buildMiniKpi('$_clientesConCompromiso', 'Compromisos', FuerzaVentasTheme.neonCyan),
                  _buildDividerV(),
                  _buildMiniKpi(
                    '${_totalClientes > 0 ? ((_totalClientes - _clientesCriticos) / _totalClientes * 100).toStringAsFixed(0) : 0}%',
                    'Recuperables',
                    FuerzaVentasTheme.neonGreen,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Semáforo visual bar
        _buildSemaforoBars(),

        // Filter bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Priority filter
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['TODOS', 'ALTA', 'MEDIA', 'NORMAL'].map((f) {
                      final isSelected = _filtroActivo == f;
                      final color = f == 'ALTA'
                          ? FuerzaVentasTheme.neonRed
                          : f == 'MEDIA'
                              ? FuerzaVentasTheme.neonOrange
                              : f == 'NORMAL'
                                  ? FuerzaVentasTheme.neonGreen
                                  : Colors.white54;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            f,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.black : color,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: color,
                          backgroundColor: FuerzaVentasTheme.inputFieldColor,
                          checkmarkColor: Colors.black,
                          side: BorderSide(color: isSelected ? color : Colors.white12),
                          onSelected: (_) => setState(() => _filtroActivo = f),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              // Sort dropdown
              PopupMenuButton<String>(
                color: FuerzaVentasTheme.cardDark,
                icon: const Icon(Icons.sort_outlined, color: Colors.white60, size: 20),
                onSelected: (val) => setState(() => _ordenActivo = val),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'DIAS_DESC',
                    child: Text('Mayor atraso primero', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ),
                  const PopupMenuItem(
                    value: 'MONTO_DESC',
                    child: Text('Mayor monto primero', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ),
                  const PopupMenuItem(
                    value: 'NOMBRE_ASC',
                    child: Text('Por nombre A-Z', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Client list
        Expanded(
          child: _filteredList.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, color: FuerzaVentasTheme.neonGreen, size: 40),
                      SizedBox(height: 10),
                      Text(
                        'No hay clientes con mora\npara el filtro seleccionado.',
                        style: TextStyle(color: Colors.white30, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: _filteredList.length,
                  itemBuilder: (context, idx) => _buildMoraCard(_filteredList[idx]),
                ),
        ),
      ],
    );
  }

  Widget _buildMiniKpi(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white30, fontSize: 10.5)),
        ],
      ),
    );
  }

  Widget _buildDividerV() {
    return Container(width: 1, height: 28, color: Colors.white10, margin: const EdgeInsets.symmetric(horizontal: 4));
  }

  Widget _buildSemaforoBars() {
    final criticos = widget.moraList.where((m) => (m['dias_mora'] is int ? m['dias_mora'] as int : 0) > 60).length;
    final altos = widget.moraList.where((m) {
      final d = m['dias_mora'] is int ? m['dias_mora'] as int : 0;
      return d > 30 && d <= 60;
    }).length;
    final medios = widget.moraList.where((m) {
      final d = m['dias_mora'] is int ? m['dias_mora'] as int : 0;
      return d > 15 && d <= 30;
    }).length;
    final leves = widget.moraList.where((m) => (m['dias_mora'] is int ? m['dias_mora'] as int : 0) <= 15).length;
    final total = widget.moraList.isNotEmpty ? widget.moraList.length : 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _buildSemaforoSegment(criticos, total, FuerzaVentasTheme.neonRed, 'Crítico'),
          const SizedBox(width: 4),
          _buildSemaforoSegment(altos, total, FuerzaVentasTheme.neonOrange, 'Alto'),
          const SizedBox(width: 4),
          _buildSemaforoSegment(medios, total, Colors.yellowAccent, 'Medio'),
          const SizedBox(width: 4),
          _buildSemaforoSegment(leves, total, FuerzaVentasTheme.neonGreen, 'Leve'),
        ],
      ),
    );
  }

  Widget _buildSemaforoSegment(int count, int total, Color color, String label) {
    final pct = count / total;
    return Expanded(
      flex: (pct * 100).round().clamp(1, 100),
      child: Column(
        children: [
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Text('$count $label', style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMoraCard(Map<String, dynamic> m) {
    final dias = m['dias_mora'] is int ? m['dias_mora'] as int : 0;
    final colorSemaforo = _semaforoColor(dias);
    final labelSemaforo = _semaforoLabel(dias);
    final montoVencido = double.tryParse(m['monto_vencido'].toString()) ?? 0.0;
    final prioridad = m['prioridad'] ?? 'NORMAL';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: FuerzaVentasTheme.glassDecoration(
        borderColor: colorSemaforo,
        borderOpacity: 0.15,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showCobranzaDialog(m),
            child: Stack(
              children: [
                // Left color stripe
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 5,
                  child: Container(color: colorSemaforo),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 14, 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Avatar
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: colorSemaforo.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                              border: Border.all(color: colorSemaforo.withValues(alpha: 0.2), width: 1.5),
                            ),
                            child: Center(
                              child: Text(
                                (m['cliente_nombre'] ?? '?')[0].toUpperCase(),
                                style: TextStyle(
                                  color: colorSemaforo,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        m['cliente_nombre'] ?? 'Cliente',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 14.5),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: colorSemaforo.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        labelSemaforo,
                                        style: TextStyle(
                                            color: colorSemaforo,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'DNI: ${m['documento'] ?? '---'} · Prioridad: $prioridad',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Stats row
                      Row(
                        children: [
                          _buildStatBadge(
                              'S/ ${montoVencido.toStringAsFixed(2)}', 'Monto Vencido', FuerzaVentasTheme.neonRed),
                          const SizedBox(width: 8),
                          _buildStatBadge('$dias días', 'En atraso', colorSemaforo),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showCobranzaDialog(m),
                              icon: const Icon(Icons.add_task_outlined, size: 15),
                              label: const Text('Gestionar',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: FuerzaVentasTheme.bcpOrange.withValues(alpha: 0.15),
                                foregroundColor: FuerzaVentasTheme.neonOrange,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                side: BorderSide(color: FuerzaVentasTheme.bcpOrange.withValues(alpha: 0.3)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(label, style: const TextStyle(color: Colors.white30, fontSize: 10.5)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 2 — HISTORIAL
  // ─────────────────────────────────────────────

  Widget _buildHistorialTab() {
    return _historialGestiones.isEmpty
        ? const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_outlined, color: Colors.white24, size: 48),
                SizedBox(height: 14),
                Text(
                  'Aún no hay gestiones registradas\nen esta sesión.',
                  style: TextStyle(color: Colors.white30, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _historialGestiones.length,
            itemBuilder: (context, idx) {
              final g = _historialGestiones[idx];
              final resultado = g['resultado'] as String? ?? '';
              final isPago = resultado.contains('Pago') || resultado.contains('pago');
              final isCompromiso = resultado.contains('Compromiso') || resultado.contains('compromiso');
              final color = isPago
                  ? FuerzaVentasTheme.neonGreen
                  : isCompromiso
                      ? FuerzaVentasTheme.neonCyan
                      : resultado.contains('niega') || resultado.contains('Imposible')
                          ? FuerzaVentasTheme.neonRed
                          : Colors.white54;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: FuerzaVentasTheme.glassDecoration(
                  borderColor: color,
                  borderOpacity: 0.12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPago
                            ? Icons.check_circle_outline
                            : isCompromiso
                                ? Icons.handshake_outlined
                                : Icons.info_outline,
                        color: color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            g['cliente'] ?? 'Cliente',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13.5),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${g['tipo']} · $resultado',
                            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          if ((g['monto'] as double? ?? 0) > 0)
                            Text(
                              'Monto: S/ ${(g['monto'] as double).toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                            ),
                          if ((g['obs'] as String? ?? '').isNotEmpty)
                            Text(
                              g['obs'],
                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Text(
                      g['hora'] ?? '',
                      style: const TextStyle(color: Colors.white24, fontSize: 11),
                    ),
                  ],
                ),
              );
            },
          );
  }

  // ─────────────────────────────────────────────
  // TAB 3 — COMPROMISOS DE PAGO
  // ─────────────────────────────────────────────

  Widget _buildCompromisosTab() {
    return _compromisos.isEmpty
        ? const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.handshake_outlined, color: Colors.white24, size: 48),
                SizedBox(height: 14),
                Text(
                  'No hay compromisos de pago\nregistrados aún.',
                  style: TextStyle(color: Colors.white30, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _compromisos.length,
            itemBuilder: (context, idx) {
              final c = _compromisos[idx];
              final diasRestantes = c['dias_restantes'] as int? ?? 0;
              final estadoColor = diasRestantes <= 2
                  ? FuerzaVentasTheme.neonRed
                  : diasRestantes <= 5
                      ? FuerzaVentasTheme.neonOrange
                      : FuerzaVentasTheme.neonGreen;
              final estado = c['estado'] as String? ?? 'PENDIENTE';
              final isCumplido = estado == 'CUMPLIDO';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: FuerzaVentasTheme.glassDecoration(
                  borderColor: isCumplido ? FuerzaVentasTheme.neonGreen : estadoColor,
                  borderOpacity: 0.2,
                ),
                child: Row(
                  children: [
                    // Status icon
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: (isCumplido ? FuerzaVentasTheme.neonGreen : estadoColor)
                            .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (isCumplido ? FuerzaVentasTheme.neonGreen : estadoColor)
                              .withValues(alpha: 0.25),
                        ),
                      ),
                      child: Icon(
                        isCumplido ? Icons.check_circle_outline : Icons.schedule_outlined,
                        color: isCumplido ? FuerzaVentasTheme.neonGreen : estadoColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c['cliente'] ?? 'Cliente',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'S/ ${(c['monto'] as double).toStringAsFixed(2)} · Vence: ${c['fecha']}',
                            style: const TextStyle(color: Colors.white60, fontSize: 12.5),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: estadoColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isCumplido ? 'CUMPLIDO' : 'Faltan $diasRestantes días',
                                  style: TextStyle(
                                      color: isCumplido ? FuerzaVentasTheme.neonGreen : estadoColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!isCumplido)
                      Column(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _compromisos[idx] = Map.from(c)..['estado'] = 'CUMPLIDO';
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('¡Compromiso marcado como cumplido!'),
                                    behavior: SnackBarBehavior.floating),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FuerzaVentasTheme.neonGreen.withValues(alpha: 0.15),
                              foregroundColor: FuerzaVentasTheme.neonGreen,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              side: BorderSide(color: FuerzaVentasTheme.neonGreen.withValues(alpha: 0.3)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: const Text('Pagó', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 6),
                          ElevatedButton(
                            onPressed: () {
                              setState(() => _compromisos.removeAt(idx));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Compromiso eliminado'),
                                    behavior: SnackBarBehavior.floating),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FuerzaVentasTheme.neonRed.withValues(alpha: 0.1),
                              foregroundColor: FuerzaVentasTheme.neonRed,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              side: BorderSide(color: FuerzaVentasTheme.neonRed.withValues(alpha: 0.2)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: const Text('No pagó', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          );
  }
}
