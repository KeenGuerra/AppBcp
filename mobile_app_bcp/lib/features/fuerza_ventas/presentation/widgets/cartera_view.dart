import 'package:flutter/material.dart';
import '../theme/fuerza_ventas_theme.dart';

class CarteraView extends StatelessWidget {
  final List<Map<String, dynamic>> cartera;
  final List<Map<String, dynamic>> filteredCartera;
  final String activeFilter;
  final String lastSyncTime;
  final int pendingSyncCount;
  final TextEditingController searchController;
  final ValueChanged<String> onFilterSelected;
  final Function(String clientId, String idCartera) onClientTap;
  final Function(int oldIndex, int newIndex) onReorder;

  const CarteraView({
    super.key,
    required this.cartera,
    required this.filteredCartera,
    required this.activeFilter,
    required this.lastSyncTime,
    required this.pendingSyncCount,
    required this.searchController,
    required this.onFilterSelected,
    required this.onClientTap,
    required this.onReorder,
  });

  Color _prioridadColor(String? prioridad) {
    if (prioridad == 'ALTA') return FuerzaVentasTheme.neonRed;
    if (prioridad == 'MEDIA') return FuerzaVentasTheme.neonOrange;
    return FuerzaVentasTheme.neonGreen;
  }

  Color _estadoColor(String? estado) {
    if (estado == 'REALIZADA' || estado == 'Visitado') return FuerzaVentasTheme.neonGreen;
    if (estado == 'Reprogramado') return FuerzaVentasTheme.neonCyan;
    return FuerzaVentasTheme.neonOrange;
  }

  IconData _gestionIcono(String? tipoGestion) {
    if (tipoGestion == 'RECUPERACION_MORA' || tipoGestion == 'Cobranza') {
      return Icons.payments_outlined;
    } else if (tipoGestion == 'RENOVACION' || tipoGestion == 'Renovación') {
      return Icons.autorenew_outlined;
    }
    return Icons.person_add_alt_1_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final total = cartera.length;
    final visitados = cartera.where((x) => x['estado_visita'] == 'REALIZADA').length;
    final pendientes = total - visitados;
    final progress = total > 0 ? visitados / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Metrics Summary Row
        Row(
          children: [
            Expanded(
              child: _buildResumenCard(
                titulo: 'Total',
                valor: '$total',
                icono: Icons.groups_outlined,
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F2B5C), Color(0xFF07193B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                highlightColor: FuerzaVentasTheme.neonCyan,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildResumenCard(
                titulo: 'Pendientes',
                valor: '$pendientes',
                icono: Icons.schedule_outlined,
                gradient: const LinearGradient(
                  colors: [Color(0xFF5C2C0F), Color(0xFF3B1907)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                highlightColor: FuerzaVentasTheme.neonOrange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildResumenCard(
                titulo: 'Visitados',
                valor: '$visitados',
                icono: Icons.check_circle_outline,
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F5C2C), Color(0xFF073B19)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                highlightColor: FuerzaVentasTheme.neonGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Progress indicators
        Container(
          padding: const EdgeInsets.all(18),
          decoration: FuerzaVentasTheme.glassDecoration(),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Avance del Día',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: FuerzaVentasTheme.neonGreen, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  color: FuerzaVentasTheme.bcpOrange,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Última sync: $lastSyncTime',
                    style: const TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                  if (pendingSyncCount > 0)
                    Text(
                      'Pendientes por enviar: $pendingSyncCount',
                      style: const TextStyle(fontSize: 11, color: FuerzaVentasTheme.neonRed, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Search Bar
        Container(
          decoration: FuerzaVentasTheme.glassDecoration(
            opacity: 0.4,
            borderOpacity: 0.04,
          ),
          child: TextField(
            controller: searchController,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            decoration: const InputDecoration(
              hintText: 'Buscar por nombre o DNI...',
              hintStyle: TextStyle(color: Colors.white30, fontSize: 14),
              prefixIcon: Icon(Icons.search_outlined, color: FuerzaVentasTheme.neonCyan),
              fillColor: Colors.transparent,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Filters scroll
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['TODOS', 'VISITADOS', 'RENOVACIONES', 'NUEVAS', 'AMPLIACIONES', 'MORA'].map((filter) {
              final isSelected = activeFilter == filter;
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
                    side: BorderSide(
                      color: isSelected ? FuerzaVentasTheme.bcpOrange : Colors.white10,
                      width: 1.2,
                    ),
                  ),
                  onSelected: (val) => onFilterSelected(filter),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Reorderable Client List
        Expanded(
          child: filteredCartera.isEmpty
              ? const Center(
                  child: Text(
                    'Sin clientes para el filtro seleccionado',
                    style: TextStyle(color: Colors.white30, fontSize: 14),
                  ),
                )
              : ReorderableListView.builder(
                  itemCount: filteredCartera.length,
                  onReorder: onReorder,
                  padding: const EdgeInsets.only(bottom: 24),
                  itemBuilder: (context, idx) {
                    final item = filteredCartera[idx];
                    final cli = item['cliente'];
                    final isVisited = item['estado_visita'] == 'REALIZADA';

                    // Censored DNI
                    String dni = cli?['documento'] ?? "********";
                    String censoredDni = dni.length > 4 ? "***${dni.substring(dni.length - 3)}" : "***129";

                    final priColor = _prioridadColor(item['prioridad']);

                    return Container(
                      key: ValueKey(item['id_cartera']),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: FuerzaVentasTheme.glassDecoration(
                        borderColor: priColor,
                        borderOpacity: 0.12,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            // Prioridad lateral stripe
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: 5,
                              child: Container(color: priColor),
                            ),
                            ListTile(
                              contentPadding: const EdgeInsets.only(left: 20, right: 16, top: 8, bottom: 8),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: FuerzaVentasTheme.bcpBlue.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: FuerzaVentasTheme.bcpCyan.withOpacity(0.2), width: 1.5),
                                ),
                                child: Icon(
                                  _gestionIcono(item['tipo_gestion']),
                                  color: FuerzaVentasTheme.bcpCyan,
                                  size: 20,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${cli?['nombres'] ?? "Cliente"} ${cli?['apellidos'] ?? ""}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 15,
                                        decoration: isVisited ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: priColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: priColor.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      item['prioridad'] ?? 'BAJA',
                                      style: TextStyle(
                                        color: priColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text(
                                  'DNI: $censoredDni | Gestión: ${item['tipo_gestion']}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12.5),
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _estadoColor(item['estado_visita']).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _estadoColor(item['estado_visita']).withOpacity(0.3)),
                                ),
                                child: Text(
                                  item['estado_visita'] == 'REALIZADA' ? 'VISITADO' : 'PENDIENTE',
                                  style: TextStyle(
                                    color: _estadoColor(item['estado_visita']),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              onTap: () => onClientTap(item['id_cliente'], item['id_cartera']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildResumenCard({
    required String titulo,
    required String valor,
    required IconData icono,
    required Gradient gradient,
    required Color highlightColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highlightColor.withOpacity(0.18),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icono,
                color: highlightColor,
                size: 20,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              valor,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              titulo,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
