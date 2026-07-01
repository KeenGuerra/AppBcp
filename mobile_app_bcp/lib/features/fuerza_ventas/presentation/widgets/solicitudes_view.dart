import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/fuerza_ventas_theme.dart';

class SolicitudesView extends StatefulWidget {
  final List<dynamic> solicitudes;
  final bool isOnline;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String idSol) onPreevaluar;
  final Future<void> Function(String idSol) onBuro;
  final Future<void> Function(String idSol) onEnviarComite;

  const SolicitudesView({
    super.key,
    required this.solicitudes,
    required this.isOnline,
    required this.onRefresh,
    required this.onPreevaluar,
    required this.onBuro,
    required this.onEnviarComite,
  });

  @override
  State<SolicitudesView> createState() => _SolicitudesViewState();
}

class _SolicitudesViewState extends State<SolicitudesView> {
  final TextEditingController _searchController = TextEditingController();
  String _activeFilter = 'TODOS';
  bool _isActionLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _statusColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'APROBADO':
        return FuerzaVentasTheme.neonGreen;
      case 'DESEMBOLSADO':
        return FuerzaVentasTheme.neonCyan;
      case 'ENVIADO':
      case 'RECIBIDO_COMITE':
        return FuerzaVentasTheme.neonOrange;
      case 'RECHAZADO':
        return FuerzaVentasTheme.neonRed;
      case 'EN_EVALUACION':
        return Colors.blue;
      default:
        return Colors.white60;
    }
  }

  List<dynamic> _getFilteredSolicitudes() {
    final query = _searchController.text.toLowerCase().trim();
    List<dynamic> filtered = widget.solicitudes;

    // Filter by tab
    if (_activeFilter != 'TODOS') {
      filtered = filtered.where((s) {
        final est = (s['estado'] ?? '').toString().toUpperCase();
        if (_activeFilter == 'APROBADOS') return est == 'APROBADO' || est == 'DESEMBOLSADO';
        if (_activeFilter == 'PENDIENTES') return est == 'EN_EVALUACION' || est == 'BORRADOR' || est == 'ENVIADO';
        if (_activeFilter == 'COMITE') return est == 'ENVIADO' || est == 'RECIBIDO_COMITE';
        if (_activeFilter == 'RECHAZADOS') return est == 'RECHAZADO';
        return true;
      }).toList();
    }

    // Filter by query
    if (query.isNotEmpty) {
      filtered = filtered.where((s) {
        final client = s['cliente'] ?? {};
        final nombres = (client['nombres'] ?? '').toString().toLowerCase();
        final apellidos = (client['apellidos'] ?? '').toString().toLowerCase();
        final doc = (client['documento'] ?? '').toString().toLowerCase();
        final exp = (s['numero_expediente'] ?? '').toString().toLowerCase();
        return nombres.contains(query) || apellidos.contains(query) || doc.contains(query) || exp.contains(query);
      }).toList();
    }

    return filtered;
  }

  void _runAction(Future<void> Function() action, String successMsg) async {
    setState(() => _isActionLoading = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMsg), backgroundColor: FuerzaVentasTheme.neonGreen.withOpacity(0.9), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: FuerzaVentasTheme.neonRed.withOpacity(0.9), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
        widget.onRefresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _getFilteredSolicitudes();
    
    // Stats calculation
    final total = widget.solicitudes.length;
    final aprobados = widget.solicitudes.where((s) => ['APROBADO', 'DESEMBOLSADO'].contains(s['estado'])).length;
    final enComite = widget.solicitudes.where((s) => ['ENVIADO', 'RECIBIDO_COMITE'].contains(s['estado'])).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Metrics row
        Row(
          children: [
            Expanded(
              child: _buildMetricTile('Total', '$total', Icons.assignment_outlined, FuerzaVentasTheme.neonCyan),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile('Aprobados', '$aprobados', Icons.check_circle_outline, FuerzaVentasTheme.neonGreen),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile('En Comité', '$enComite', Icons.gavel_outlined, FuerzaVentasTheme.neonOrange),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Search Bar
        Container(
          decoration: FuerzaVentasTheme.glassDecoration(opacity: 0.4, borderOpacity: 0.04),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            decoration: const InputDecoration(
              hintText: 'Buscar por cliente, documento o expediente...',
              hintStyle: TextStyle(color: Colors.white30, fontSize: 14),
              prefixIcon: Icon(Icons.search_outlined, color: FuerzaVentasTheme.neonCyan),
              fillColor: Colors.transparent,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['TODOS', 'PENDIENTES', 'COMITE', 'APROBADOS', 'RECHAZADOS'].map((filter) {
              final isSelected = _activeFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  selectedColor: FuerzaVentasTheme.bcpOrange,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  backgroundColor: FuerzaVentasTheme.cardDark.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: isSelected ? FuerzaVentasTheme.bcpOrange : Colors.white10),
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _activeFilter = filter);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Solicitudes List
        Expanded(
          child: _isActionLoading
              ? const Center(child: CircularProgressIndicator(color: FuerzaVentasTheme.bcpOrange))
              : filteredList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open_outlined, size: 48, color: Colors.white24),
                          const SizedBox(height: 12),
                          const Text('No se encontraron solicitudes', style: TextStyle(color: Colors.white30)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: widget.onRefresh,
                      color: FuerzaVentasTheme.bcpOrange,
                      backgroundColor: FuerzaVentasTheme.cardDark,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: filteredList.length,
                        itemBuilder: (context, idx) {
                          final s = filteredList[idx];
                          return _buildSolicitudCard(s);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: FuerzaVentasTheme.glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 18, color: color),
              Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildSolicitudCard(dynamic s) {
    final String idSol = s['id_solicitud'] ?? '';
    final String exp = s['numero_expediente'] ?? 'EXP-PENDIENTE';
    final String estado = (s['estado'] ?? 'BORRADOR').toString().toUpperCase();
    final double monto = double.tryParse(s['monto_solicitado']?.toString() ?? '0') ?? 0.0;
    final int plazo = s['plazo_meses'] ?? 12;
    
    final client = s['cliente'] ?? {};
    final String clienteName = '${client['nombres'] ?? "Cliente"} ${client['apellidos'] ?? ""}';
    final String clienteDoc = client['documento'] ?? 'Sin DNI';
    
    final prod = s['producto'] ?? {};
    final String productoName = prod['nombre'] ?? 'Crédito Negocio';
    
    final String resultPreeval = s['resultado_preevaluacion'] ?? '';
    final String resultBuro = s['resultado_buro'] ?? '';

    final isPreevaluated = resultPreeval.isNotEmpty;
    final isBuroChecked = resultBuro.isNotEmpty;
    final canSubmitToCommittee = (estado == 'BORRADOR' || estado == 'EN_EVALUACION' || estado == 'ENVIADO') && isPreevaluated;

    final String fechaStr = s['created_at'] != null 
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(s['created_at']))
        : 'Reciente';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: FuerzaVentasTheme.glassDecoration(
        opacity: 0.15,
        borderOpacity: 0.06,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exp, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(fechaStr, style: const TextStyle(color: Colors.white30, fontSize: 11)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(estado).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _statusColor(estado).withOpacity(0.3)),
                ),
                child: Text(
                  estado,
                  style: TextStyle(color: _statusColor(estado), fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),

          // Customer and loan detail
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline, color: FuerzaVentasTheme.neonCyan, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(clienteName, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Text('DNI: $clienteDoc', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PRODUCTO', style: TextStyle(fontSize: 10, color: Colors.white30, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(productoName, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('MONTO / PLAZO', style: TextStyle(fontSize: 10, color: Colors.white30, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    'S/ ${monto.toStringAsFixed(2)}  ·  $plazo meses',
                    style: const TextStyle(color: FuerzaVentasTheme.neonCyan, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),

          // Analysis Pills
          if (estado == 'BORRADOR' || estado == 'EN_EVALUACION' || estado == 'ENVIADO') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _buildAnalysisPill(
                  'Buró: ${isBuroChecked ? resultBuro : "Pendiente"}',
                  isBuroChecked
                      ? (resultBuro == 'APROBADO' ? FuerzaVentasTheme.neonGreen : FuerzaVentasTheme.neonRed)
                      : Colors.white24,
                ),
                const SizedBox(width: 8),
                _buildAnalysisPill(
                  'Preeval: ${isPreevaluated ? resultPreeval : "Pendiente"}',
                  isPreevaluated
                      ? (resultPreeval == 'APTO' ? FuerzaVentasTheme.neonGreen : FuerzaVentasTheme.neonOrange)
                      : Colors.white24,
                ),
              ],
            ),
          ],

          // Actions
          if (widget.isOnline && (estado == 'BORRADOR' || estado == 'EN_EVALUACION' || estado == 'ENVIADO')) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (!isBuroChecked)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _buildActionButton(
                        'Buró',
                        Icons.shield_outlined,
                        () => _runAction(
                          () => widget.onBuro(idSol),
                          '¡Buró consultado correctamente!',
                        ),
                      ),
                    ),
                  ),
                if (!isPreevaluated)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _buildActionButton(
                        'Pre-evaluar',
                        Icons.analytics_outlined,
                        () => _runAction(
                          () => widget.onPreevaluar(idSol),
                          '¡Pre-evaluación completada con éxito!',
                        ),
                      ),
                    ),
                  ),
                if (canSubmitToCommittee)
                  Expanded(
                    child: _buildActionButton(
                      'A Comité',
                      Icons.gavel_outlined,
                      () => _runAction(
                        () => widget.onEnviarComite(idSol),
                        '¡Expediente enviado al comité exitosamente!',
                      ),
                      isPrimary: true,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap, {bool isPrimary = false}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? FuerzaVentasTheme.bcpOrange : Colors.white.withOpacity(0.04),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: isPrimary ? Colors.transparent : Colors.white12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
