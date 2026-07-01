import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mobile_app_bcp/core/utils/date_formatter.dart';
import '../theme/fuerza_ventas_theme.dart';

class FichaView extends StatelessWidget {
  final String? stepperClientId;
  final String? selectedIdCartera;
  final Map<String, dynamic>? selectedFicha;
  final Function(double monto, int plazo) onUsePreapprovedOffer;
  final Function(String clientId) onUpdateGps;
  final Future<void> Function(String idCartera, String resultado, String observacion)? onRegistrarVisita;

  const FichaView({
    super.key,
    required this.stepperClientId,
    this.selectedIdCartera,
    required this.selectedFicha,
    required this.onUsePreapprovedOffer,
    required this.onUpdateGps,
    this.onRegistrarVisita,
  });

  Color _sbsColor(String? sbs) {
    if (sbs == 'CPP') return FuerzaVentasTheme.neonOrange;
    if (sbs == 'DEFICIENTE') return Colors.orangeAccent;
    if (sbs == 'DUDOSO') return FuerzaVentasTheme.neonRed;
    if (sbs == 'PERDIDA') return Colors.grey;
    return FuerzaVentasTheme.neonGreen;
  }

  @override
  Widget build(BuildContext context) {
    if (stepperClientId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Seleccione un cliente en Cartera o campañas para ver su ficha.',
            style: TextStyle(color: Colors.white60, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final cli = selectedFicha?['cliente'];
    final posicion = selectedFicha?['posicion'];

    if (selectedFicha == null || cli == null || posicion == null) {
      return const Center(child: CircularProgressIndicator(color: FuerzaVentasTheme.bcpOrange));
    }

    final sbs = posicion['calificacion_sbs'] ?? 'NORMAL';
    final colorSbs = _sbsColor(sbs);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile card (Obsidian / Glass)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: FuerzaVentasTheme.glassDecoration(),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: FuerzaVentasTheme.bcpBlue.withOpacity(0.4),
                  child: Text(
                    cli['nombres'] != null && cli['nombres'].isNotEmpty ? cli['nombres'][0] : 'C',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${cli['nombres'] ?? "Cliente"} ${cli['apellidos'] ?? ""}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'DNI: ${cli['documento']} · Tel: ${cli['telefono'] ?? "No registra"}',
                        style: const TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.call_outlined, color: FuerzaVentasTheme.neonCyan, size: 26),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Abriendo marcador telefónico para llamar a: ${cli['telefono'] ?? "No registra"}'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                )
              ],
            ),
          ),
          const SizedBox(height: 12),

          // SBS risk traffic light card (Pulsing neon style)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorSbs.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorSbs.withOpacity(0.35), width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.traffic_outlined, color: colorSbs, size: 24),
                const SizedBox(width: 12),
                const Text('Semáforo SBS: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 14)),
                Text(sbs, style: TextStyle(fontWeight: FontWeight.bold, color: colorSbs, fontSize: 16, letterSpacing: 0.5)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Posicion del cliente details
          const Text(
            'Posición Financiera del Cliente',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FuerzaVentasTheme.neonCyan, letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: FuerzaVentasTheme.glassDecoration(),
            child: Column(
              children: [
                _buildFichaRow('Deuda Total Consolidada', 'S/ ${posicion['deuda_total_consolidada']}', isHighlight: true),
                _buildDivider(),
                _buildFichaRow('Cuentas Vigentes', '${posicion['numero_cuentas_vigentes']} cuentas'),
                _buildDivider(),
                _buildFichaRow('Cuentas en Mora', '${posicion['numero_cuentas_en_mora']} mora', valueColor: FuerzaVentasTheme.neonRed),
                _buildDivider(),
                _buildFichaRow('Días Máximos Mora Histórica', '${posicion['dias_de_mayor_mora_historica']} días', valueColor: FuerzaVentasTheme.neonRed),
                _buildDivider(),
                _buildFichaRow(
                  'Fecha Último Pago Registrado',
                  posicion['fecha_del_ultimo_pago_registrado'] != null
                      ? DateFormatter.formatShortString(posicion['fecha_del_ultimo_pago_registrado'].toString())
                      : 'No registra',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Monthly payment behavior (fl_chart)
          const Text(
            'Historial de Comportamiento de Pago',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: FuerzaVentasTheme.glassDecoration(opacity: 0.4),
            child: Column(
              children: [
                _buildPaymentBehaviorChart(),
                const SizedBox(height: 14),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(children: [Icon(Icons.square, color: FuerzaVentasTheme.neonGreen, size: 12), Text(' Puntual', style: TextStyle(color: Colors.white70, fontSize: 11))]),
                    Row(children: [Icon(Icons.square, color: FuerzaVentasTheme.neonRed, size: 12), Text(' Mora', style: TextStyle(color: Colors.white70, fontSize: 11))]),
                    Row(children: [Icon(Icons.square, color: Colors.white24, size: 12), Text(' Sin cuota', style: TextStyle(color: Colors.white70, fontSize: 11))]),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Offer preapproved scoring widget
          const Text(
            'Oferta Scoring Preaprobada',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FuerzaVentasTheme.neonCyan, letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          if (selectedFicha?['preaprobado'] != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: FuerzaVentasTheme.glassDecoration(
                borderColor: FuerzaVentasTheme.neonGreen,
                borderOpacity: 0.25,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Oferta Vigente (${selectedFicha?['preaprobado']['nivel_confianza'] ?? 'ALTO'})',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: FuerzaVentasTheme.neonGreen, fontSize: 15),
                      ),
                      const Icon(Icons.verified_outlined, color: FuerzaVentasTheme.neonGreen),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 24),
                  Text(
                    'Monto Máximo: S/ ${selectedFicha?['preaprobado']['monto_maximo']}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Plazo sugerido: ${selectedFicha?['preaprobado']['plazo_sugerido']} meses · Tasa TEA: ${selectedFicha?['preaprobado']['tea_referencial']}%',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text('Confianza Scoring: ', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ((selectedFicha?['preaprobado']['score_confianza'] ?? 80) as int) / 100.0,
                            color: FuerzaVentasTheme.neonGreen,
                            backgroundColor: Colors.white.withOpacity(0.08),
                            minHeight: 6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: FuerzaVentasTheme.bcpOrangeGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: FuerzaVentasTheme.neonGlowShadow(color: FuerzaVentasTheme.bcpOrange, opacity: 0.25),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          final double offerMonto = double.tryParse(selectedFicha?['preaprobado']['monto_maximo'].toString() ?? '') ?? 15000;
                          final int offerPlazo = int.tryParse(selectedFicha?['preaprobado']['plazo_sugerido'].toString() ?? '') ?? 12;
                          onUsePreapprovedOffer(offerMonto, offerPlazo);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          surfaceTintColor: Colors.transparent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Usar esta oferta', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: FuerzaVentasTheme.glassDecoration(),
              child: const Text(
                'El cliente no cuenta con oferta preaprobada vigente.',
                style: TextStyle(color: Colors.white30, fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Registrar Visita button
          if (onRegistrarVisita != null && selectedIdCartera != null) ...[
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [FuerzaVentasTheme.neonGreen, FuerzaVentasTheme.neonGreen.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _showVisitaDialog(context),
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: const Text('Registrar Visita', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Action button (GPS)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => onUpdateGps(cli['id_cliente']),
              icon: const Icon(Icons.location_searching, color: FuerzaVentasTheme.neonCyan),
              label: const Text('Actualizar ubicación GPS del negocio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: FuerzaVentasTheme.bcpCyan, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPaymentBehaviorChart() {
    return SizedBox(
      height: 120,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 1,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  final months = ['E', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      months[val.toInt() % 12],
                      style: const TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(12, (index) {
            Color barColor = FuerzaVentasTheme.neonGreen;
            if (index == 2 || index == 5) barColor = FuerzaVentasTheme.neonRed;
            if (index == 8) barColor = Colors.white24;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: 0.8,
                  color: barColor,
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                )
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildFichaRow(String label, String value, {Color valueColor = Colors.white, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isHighlight ? Colors.white : Colors.white60,
              fontSize: 13.5,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isHighlight ? FuerzaVentasTheme.neonCyan : valueColor,
              fontWeight: FontWeight.bold,
              fontSize: isHighlight ? 15 : 13.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Divider(color: Colors.white10, height: 1),
    );
  }

  void _showVisitaDialog(BuildContext context) {
    String resultado = 'Contacto efectivo';
    final obsController = TextEditingController(text: 'Visita de cortesía realizada');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FuerzaVentasTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.white10),
        ),
        title: const Text('Registrar Visita', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Resultado de la visita:', style: TextStyle(color: Colors.white60)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildResultadoChip(ctx, resultado, 'Contacto efectivo', (v) => resultado = v),
                  _buildResultadoChip(ctx, resultado, 'No encontrado', (v) => resultado = v),
                  _buildResultadoChip(ctx, resultado, 'Reprogramar', (v) => resultado = v),
                  _buildResultadoChip(ctx, resultado, 'Cliente no desea', (v) => resultado = v),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: obsController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Observaciones',
                  labelStyle: const TextStyle(color: Colors.white60),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FuerzaVentasTheme.neonCyan)),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white60))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onRegistrarVisita?.call(selectedIdCartera!, resultado, obsController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: FuerzaVentasTheme.neonGreen),
            child: const Text('Confirmar Visita'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultadoChip(BuildContext context, String current, String label, Function(String) onSelected) {
    final isSelected = current == label;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontSize: 12)),
      selected: isSelected,
      selectedColor: FuerzaVentasTheme.bcpOrange,
      backgroundColor: Colors.white.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isSelected ? FuerzaVentasTheme.bcpOrange : Colors.white12),
      ),
      onSelected: (_) => onSelected(label),
    );
  }
}
