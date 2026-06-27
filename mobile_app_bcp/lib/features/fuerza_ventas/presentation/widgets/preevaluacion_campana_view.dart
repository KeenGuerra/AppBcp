import 'package:flutter/material.dart';
import '../theme/fuerza_ventas_theme.dart';

class PreevaluacionCampanaView extends StatefulWidget {
  final List<Map<String, dynamic>> campaigns;
  final String? evalResultado;
  final int? evalPuntaje;
  final double? evalCuota;
  final Function(String clientId, double montoOferta) onManageCampaign;
  final Function(String doc, String name, double amount) onPreEvaluate;
  final VoidCallback onStartFormalRequest;
  final Function(String motivo, String institucion) onRegisterDesertion;

  const PreevaluacionCampanaView({
    super.key,
    required this.campaigns,
    required this.evalResultado,
    required this.evalPuntaje,
    required this.evalCuota,
    required this.onManageCampaign,
    required this.onPreEvaluate,
    required this.onStartFormalRequest,
    required this.onRegisterDesertion,
  });

  @override
  State<PreevaluacionCampanaView> createState() => _PreevaluacionCampanaViewState();
}

class _PreevaluacionCampanaViewState extends State<PreevaluacionCampanaView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _docController = TextEditingController();
  final _nameController = TextEditingController();
  double _montoSolicitado = 5000.0;

  // Filter state for campaigns
  String _campanaFilter = 'TODOS';

  // Local evaluation history (simulated)
  final List<Map<String, dynamic>> _evalHistory = [];

  // Buro simulation state
  String? _buroCalificacion;
  String? _buroResultado;
  bool _buroLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _docController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // DIALOGS
  // ─────────────────────────────────────────────

  void _showDesertorDialog() {
    String selectedMotivo = 'Migró a la competencia';
    final competenciaController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FuerzaVentasTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.white10),
        ),
        title: const Text(
          'Registrar Deserción del Cliente',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              dropdownColor: FuerzaVentasTheme.cardDark,
              decoration: InputDecoration(
                labelText: 'Motivo de abandono',
                labelStyle: const TextStyle(color: Colors.white60),
                filled: true,
                fillColor: FuerzaVentasTheme.inputFieldColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
              value: selectedMotivo,
              items: [
                'Migró a la competencia',
                'Cierre de negocio',
                'Tasa muy alta',
                'Trámite muy demorado',
                'No necesita crédito',
                'Problemas en evaluación crediticia',
              ].map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(color: Colors.white)))).toList(),
              onChanged: (val) {
                if (val != null) selectedMotivo = val;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: competenciaController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: '¿A qué institución migró?',
                hintText: 'Ej: Mibanco, Caja Cusco...',
                hintStyle: const TextStyle(color: Colors.white24),
                labelStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.business_outlined, color: FuerzaVentasTheme.neonOrange),
                filled: true,
                fillColor: FuerzaVentasTheme.inputFieldColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onRegisterDesertion(selectedMotivo, competenciaController.text);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('¡Deserción registrada para seguimiento de agencia!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FuerzaVentasTheme.bcpOrange,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _showCampaignDetailDialog(Map<String, dynamic> c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FuerzaVentasTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.white10),
        ),
        title: Row(
          children: [
            const Icon(Icons.campaign_outlined, color: FuerzaVentasTheme.neonCyan),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                c['nombre_cliente'] ?? 'Campaña',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Tipo', c['tipo'] ?? '-', FuerzaVentasTheme.neonCyan),
            _buildDetailRow('DNI', c['documento'] ?? '-', Colors.white70),
            _buildDetailRow('Monto Oferta', 'S/ ${c['monto_oferta']}', FuerzaVentasTheme.neonGreen),
            _buildDetailRow('TEA Referencial', '${c['tea']}%', FuerzaVentasTheme.neonOrange),
            _buildDetailRow('Vigencia', '${c['dias_restantes']} días restantes',
                c['dias_restantes'] <= 3 ? FuerzaVentasTheme.neonRed : Colors.white70),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: FuerzaVentasTheme.neonCyan.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FuerzaVentasTheme.neonCyan.withValues(alpha: 0.15)),
              ),
              child: Text(
                'Cuota estimada aprox: S/ ${((double.tryParse(c['monto_oferta'].toString()) ?? 5000) / 12 * 1.12).toStringAsFixed(2)} / mes',
                style: const TextStyle(color: FuerzaVentasTheme.neonCyan, fontSize: 13, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              final double amount = double.tryParse(c['monto_oferta'].toString()) ?? 5000.0;
              widget.onManageCampaign(c['id_cliente'] ?? '', amount);
            },
            icon: const Icon(Icons.send_outlined, size: 16),
            label: const Text('Gestionar'),
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
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BURO SIMULATION
  // ─────────────────────────────────────────────

  Future<void> _runBuroCheck() async {
    if (_docController.text.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('DNI debe tener exactamente 8 dígitos'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _buroLoading = true);
    await Future.delayed(const Duration(milliseconds: 1200));

    final doc = _docController.text;
    final lastChar = doc.isNotEmpty ? doc[doc.length - 1] : '5';
    final charCode = lastChar.codeUnitAt(0);

    String calificacion;
    String resultado;
    if (charCode <= 50) {
      calificacion = 'NORMAL';
      resultado = 'Sin reportes negativos. Cliente apto para crédito.';
    } else if (charCode <= 53) {
      calificacion = 'CPP';
      resultado = 'Con problemas potenciales. Requiere revisión adicional.';
    } else if (charCode <= 55) {
      calificacion = 'DEFICIENTE';
      resultado = 'Historial deficiente en SBS. No recomendado.';
    } else if (charCode <= 57) {
      calificacion = 'DUDOSO';
      resultado = 'Alta probabilidad de incumplimiento.';
    } else {
      calificacion = 'PERDIDA';
      resultado = 'Crédito incobrable. No procede evaluación.';
    }

    if (mounted) {
      setState(() {
        _buroCalificacion = calificacion;
        _buroResultado = resultado;
        _buroLoading = false;
      });
    }
  }

  Color _buroColor(String cal) {
    switch (cal) {
      case 'NORMAL':
        return FuerzaVentasTheme.neonGreen;
      case 'CPP':
        return Colors.yellowAccent;
      case 'DEFICIENTE':
        return FuerzaVentasTheme.neonOrange;
      case 'DUDOSO':
        return FuerzaVentasTheme.neonRed;
      case 'PERDIDA':
        return Colors.red.shade900;
      default:
        return Colors.white54;
    }
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar Header
        Container(
          color: FuerzaVentasTheme.cardDark.withValues(alpha: 0.6),
          child: TabBar(
            controller: _tabController,
            dividerColor: Colors.white10,
            indicatorColor: FuerzaVentasTheme.bcpOrange,
            labelColor: FuerzaVentasTheme.neonOrange,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
            tabs: const [
              Tab(icon: Icon(Icons.campaign_outlined, size: 18), text: 'Campañas'),
              Tab(icon: Icon(Icons.query_stats_outlined, size: 18), text: 'Pre-evaluación'),
              Tab(icon: Icon(Icons.verified_user_outlined, size: 18), text: 'Buró'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCampanasTab(),
              _buildPreEvaluacionTab(),
              _buildBuroTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // TAB 1 — CAMPAÑAS
  // ─────────────────────────────────────────────

  Widget _buildCampanasTab() {
    final tipos = ['TODOS', 'RENOVACION', 'AMPLIACION', 'PRODUCTO_PARALELO'];

    final filtered = _campanaFilter == 'TODOS'
        ? widget.campaigns
        : widget.campaigns.where((c) => c['tipo'] == _campanaFilter).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Strip
          Row(
            children: [
              _buildKpiChip(
                '${widget.campaigns.length}',
                'Total',
                FuerzaVentasTheme.neonCyan,
                Icons.campaign_outlined,
              ),
              const SizedBox(width: 10),
              _buildKpiChip(
                '${widget.campaigns.where((c) => (c['dias_restantes'] as int? ?? 99) <= 5).length}',
                'Urgentes',
                FuerzaVentasTheme.neonRed,
                Icons.timer_outlined,
              ),
              const SizedBox(width: 10),
              _buildKpiChip(
                'S/ ${widget.campaigns.fold<double>(0, (sum, c) => sum + (double.tryParse(c['monto_oferta'].toString()) ?? 0)).toStringAsFixed(0)}',
                'Potencial',
                FuerzaVentasTheme.neonGreen,
                Icons.attach_money,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: tipos.map((t) {
                final isSelected = _campanaFilter == t;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      t == 'TODOS' ? 'Todas' : t.replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.black : Colors.white70,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: FuerzaVentasTheme.bcpOrange,
                    checkmarkColor: Colors.black,
                    backgroundColor: FuerzaVentasTheme.inputFieldColor,
                    side: BorderSide(
                      color: isSelected ? FuerzaVentasTheme.bcpOrange : Colors.white12,
                    ),
                    onSelected: (_) => setState(() => _campanaFilter = t),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Campaign List
          if (filtered.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: FuerzaVentasTheme.glassDecoration(),
              child: const Column(
                children: [
                  Icon(Icons.inbox_outlined, color: Colors.white24, size: 40),
                  SizedBox(height: 10),
                  Text(
                    'Sin campañas para el filtro seleccionado',
                    style: TextStyle(color: Colors.white30, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...filtered.map((c) => _buildCampanaCard(c)),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showDesertorDialog,
              icon: const Icon(Icons.report_gmailerrorred_outlined, color: FuerzaVentasTheme.neonOrange, size: 18),
              label: const Text(
                'Registrar abandono / deserción comercial',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: FuerzaVentasTheme.neonOrange, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildKpiChip(String value, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampanaCard(Map<String, dynamic> c) {
    final isRenovacion = c['tipo'] == 'RENOVACION';
    final isAmpliacion = c['tipo'] == 'AMPLIACION';
    final diasRestantes = c['dias_restantes'] as int? ?? 99;
    final accentColor = isRenovacion
        ? FuerzaVentasTheme.neonCyan
        : isAmpliacion
            ? FuerzaVentasTheme.neonGreen
            : FuerzaVentasTheme.neonOrange;
    final isUrgent = diasRestantes <= 5;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: FuerzaVentasTheme.glassDecoration(
        borderColor: accentColor,
        borderOpacity: isUrgent ? 0.4 : 0.12,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _showCampaignDetailDialog(c),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Campaign type badge
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor.withValues(alpha: 0.25), width: 1.5),
                  ),
                  child: Icon(
                    isRenovacion
                        ? Icons.autorenew_outlined
                        : isAmpliacion
                            ? Icons.expand_outlined
                            : Icons.add_circle_outline,
                    color: accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              c['nombre_cliente'] ?? 'Cliente',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isUrgent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: FuerzaVentasTheme.neonRed.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${diasRestantes}d',
                                style: const TextStyle(color: FuerzaVentasTheme.neonRed, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${c['tipo']?.toString().replaceAll('_', ' ')} · S/ ${c['monto_oferta']} · TEA ${c['tea']}%',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final double amount = double.tryParse(c['monto_oferta'].toString()) ?? 5000.0;
                    widget.onManageCampaign(c['id_cliente'] ?? '', amount);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor.withValues(alpha: 0.15),
                    foregroundColor: accentColor,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    side: BorderSide(color: accentColor.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('Activar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 2 — PRE-EVALUACIÓN
  // ─────────────────────────────────────────────

  Widget _buildPreEvaluacionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: FuerzaVentasTheme.bcpBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FuerzaVentasTheme.neonCyan.withValues(alpha: 0.15)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: FuerzaVentasTheme.neonCyan, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Evaluación rápida off-line. La respuesta definitiva proviene del motor de scoring del servidor.',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Pre-evaluar Prospecto Rápido',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: FuerzaVentasTheme.neonCyan,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: FuerzaVentasTheme.glassDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _docController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        maxLength: 8,
                        decoration: InputDecoration(
                          labelText: 'DNI del Prospecto',
                          labelStyle: const TextStyle(color: Colors.white60),
                          prefixIcon: const Icon(Icons.badge_outlined, color: FuerzaVentasTheme.neonCyan),
                          counterText: '',
                          filled: true,
                          fillColor: FuerzaVentasTheme.inputFieldColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Nombres y Apellidos',
                          labelStyle: const TextStyle(color: Colors.white60),
                          prefixIcon: const Icon(Icons.person_outline, color: FuerzaVentasTheme.neonCyan),
                          filled: true,
                          fillColor: FuerzaVentasTheme.inputFieldColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Monto Solicitado:', style: TextStyle(color: Colors.white70, fontSize: 13.5)),
                    Text(
                      'S/ ${_montoSolicitado.round()}',
                      style: const TextStyle(
                        color: FuerzaVentasTheme.neonCyan,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Slider(
                  min: 500,
                  max: 50000,
                  divisions: 99,
                  activeColor: FuerzaVentasTheme.bcpOrange,
                  inactiveColor: Colors.white10,
                  value: _montoSolicitado,
                  onChanged: (val) => setState(() => _montoSolicitado = val),
                ),
                // Quick amount chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [1000, 3000, 5000, 10000, 20000].map((amt) {
                      return GestureDetector(
                        onTap: () => setState(() => _montoSolicitado = amt.toDouble()),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _montoSolicitado == amt.toDouble()
                                ? FuerzaVentasTheme.bcpOrange.withValues(alpha: 0.2)
                                : FuerzaVentasTheme.inputFieldColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _montoSolicitado == amt.toDouble()
                                  ? FuerzaVentasTheme.bcpOrange
                                  : Colors.white12,
                            ),
                          ),
                          child: Text(
                            'S/ $amt',
                            style: TextStyle(
                              color: _montoSolicitado == amt.toDouble()
                                  ? FuerzaVentasTheme.neonOrange
                                  : Colors.white60,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: FuerzaVentasTheme.bcpOrangeGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: FuerzaVentasTheme.neonGlowShadow(
                          color: FuerzaVentasTheme.bcpOrange, opacity: 0.25),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        widget.onPreEvaluate(
                            _docController.text, _nameController.text, _montoSolicitado);
                        // Save to local history
                        if (_docController.text.length == 8) {
                          setState(() {
                            _evalHistory.insert(0, {
                              'doc': _docController.text,
                              'nombre': _nameController.text,
                              'monto': _montoSolicitado,
                              'hora': TimeOfDay.now().format(context),
                              'resultado': null,
                            });
                          });
                        }
                      },
                      icon: const Icon(Icons.search_outlined, color: Colors.white),
                      label: const Text(
                        'Pre-evaluar Ahora',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        surfaceTintColor: Colors.transparent,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),

                // Evaluation result
                if (widget.evalResultado != null) ...[
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 12),
                  _buildEvaluationResult(),
                ],
              ],
            ),
          ),

          // TEA Comparator
          const SizedBox(height: 24),
          const Text(
            'Comparador de TEA (BCP vs Competencia)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: FuerzaVentasTheme.neonCyan),
          ),
          const SizedBox(height: 12),
          _buildTeaComparator(),

          // Recent history
          if (_evalHistory.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Historial de pre-evaluaciones (sesión)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            const SizedBox(height: 10),
            ..._evalHistory.take(5).map((h) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: FuerzaVentasTheme.glassDecoration(opacity: 0.3),
                  child: Row(
                    children: [
                      const Icon(Icons.history, color: Colors.white30, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${h['nombre'] ?? 'Prospecto'} · DNI ${h['doc']} · S/ ${(h['monto'] as double).round()}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        h['hora'] ?? '',
                        style: const TextStyle(color: Colors.white30, fontSize: 11),
                      ),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTeaComparator() {
    final competidores = [
      {'nombre': 'BCP Emprendedor', 'tea': 24.0, 'color': FuerzaVentasTheme.bcpBlue, 'isUs': true},
      {'nombre': 'Mibanco', 'tea': 38.5, 'color': Colors.purple, 'isUs': false},
      {'nombre': 'Caja Cusco', 'tea': 42.0, 'color': Colors.teal, 'isUs': false},
      {'nombre': 'Financiera Oh!', 'tea': 55.0, 'color': Colors.orange, 'isUs': false},
    ];
    final maxTea = 60.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: FuerzaVentasTheme.glassDecoration(opacity: 0.3),
      child: Column(
        children: competidores.map((c) {
          final tea = c['tea'] as double;
          final isUs = c['isUs'] as bool;
          final color = c['color'] as Color;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    c['nombre'] as String,
                    style: TextStyle(
                      color: isUs ? Colors.white : Colors.white60,
                      fontSize: 12,
                      fontWeight: isUs ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: tea / maxTea,
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isUs ? FuerzaVentasTheme.neonCyan : color.withValues(alpha: 0.7),
                      ),
                      minHeight: isUs ? 10 : 7,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$tea%',
                  style: TextStyle(
                    color: isUs ? FuerzaVentasTheme.neonCyan : Colors.white54,
                    fontSize: 12,
                    fontWeight: isUs ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEvaluationResult() {
    final isApto = widget.evalResultado == 'APTO';
    final resultColor = isApto ? FuerzaVentasTheme.neonGreen : FuerzaVentasTheme.neonRed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: resultColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: resultColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isApto ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: resultColor,
                size: 26,
              ),
              const SizedBox(width: 10),
              Text(
                'Dictamen: ${widget.evalResultado}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: resultColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Scoring gauge
          if (widget.evalPuntaje != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Puntaje Scoring:', style: TextStyle(color: Colors.white60, fontSize: 13)),
                Text(
                  '${widget.evalPuntaje}/100',
                  style: TextStyle(color: resultColor, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (widget.evalPuntaje ?? 0) / 100.0,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(resultColor),
                minHeight: 8,
              ),
            ),
          ],
          if (widget.evalCuota != null) ...[
            const SizedBox(height: 10),
            Text(
              'Cuota Estimada: S/ ${widget.evalCuota!.toStringAsFixed(2)} / mes',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
          if (isApto) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onStartFormalRequest,
                icon: const Icon(Icons.arrow_forward_outlined),
                label: const Text('Iniciar Solicitud Formal', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FuerzaVentasTheme.bcpBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 3 — BURÓ
  // ─────────────────────────────────────────────

  Widget _buildBuroTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: FuerzaVentasTheme.neonOrange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FuerzaVentasTheme.neonOrange.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: FuerzaVentasTheme.neonOrange, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Consulta simulada del historial crediticio SBS. El resultado real proviene del core bancario.',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // DNI input
          TextFormField(
            controller: _docController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            maxLength: 8,
            decoration: InputDecoration(
              labelText: 'DNI del cliente a consultar',
              labelStyle: const TextStyle(color: Colors.white60),
              prefixIcon: const Icon(Icons.badge_outlined, color: FuerzaVentasTheme.neonOrange),
              counterText: '',
              filled: true,
              fillColor: FuerzaVentasTheme.inputFieldColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _buroLoading ? null : _runBuroCheck,
              icon: _buroLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.verified_user_outlined),
              label: Text(_buroLoading ? 'Consultando SBS...' : 'Consultar Buró de Crédito'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FuerzaVentasTheme.bcpBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          if (_buroCalificacion != null) ...[
            const SizedBox(height: 24),
            _buildBuroResultPanel(),
          ],

          const SizedBox(height: 28),

          // SBS Classification Reference
          const Text(
            'Tabla de Calificaciones SBS',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          _buildSbsReferenceTable(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBuroResultPanel() {
    final color = _buroColor(_buroCalificacion!);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(
            _buroCalificacion == 'NORMAL'
                ? Icons.check_circle_outline
                : _buroCalificacion == 'CPP'
                    ? Icons.warning_amber_outlined
                    : Icons.cancel_outlined,
            color: color,
            size: 48,
          ),
          const SizedBox(height: 10),
          Text(
            'Calificación SBS: $_buroCalificacion',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'DNI: ${_docController.text}',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _buroResultado ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          if (_buroCalificacion == 'NORMAL') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onStartFormalRequest,
                icon: const Icon(Icons.arrow_forward_outlined),
                label: const Text('Proceder con Evaluación Formal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FuerzaVentasTheme.neonGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSbsReferenceTable() {
    final rows = [
      {'cal': 'NORMAL', 'desc': 'Cumplimiento puntual, sin atraso', 'dias': '0 días'},
      {'cal': 'CPP', 'desc': 'Problemas potenciales, atraso leve', 'dias': '8-30 días'},
      {'cal': 'DEFICIENTE', 'desc': 'Atrasos significativos', 'dias': '31-60 días'},
      {'cal': 'DUDOSO', 'desc': 'Alta probabilidad de pérdida', 'dias': '61-120 días'},
      {'cal': 'PÉRDIDA', 'desc': 'Incobrable, muy alta morosidad', 'dias': '>120 días'},
    ];
    return Container(
      decoration: FuerzaVentasTheme.glassDecoration(opacity: 0.2),
      child: Column(
        children: rows.map((r) {
          final color = _buroColor(r['cal']!.replaceAll('É', 'E').replaceAll('PÉRDIDA', 'PERDIDA'));
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 90,
                  child: Text(r['cal']!, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                Expanded(
                  child: Text(r['desc']!, style: const TextStyle(color: Colors.white54, fontSize: 11.5)),
                ),
                Text(r['dias']!, style: const TextStyle(color: Colors.white30, fontSize: 11)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
