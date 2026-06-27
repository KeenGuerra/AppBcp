import 'package:flutter/material.dart';
import '../theme/fuerza_ventas_theme.dart';

class ReportesSupervisorView extends StatelessWidget {
  final List<dynamic> productividadData;
  final VoidCallback onLoadProductividad;

  const ReportesSupervisorView({
    super.key,
    required this.productividadData,
    required this.onLoadProductividad,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: FuerzaVentasTheme.cardDark.withOpacity(0.5),
            child: const TabBar(
              dividerColor: Colors.white10,
              indicatorColor: FuerzaVentasTheme.bcpOrange,
              labelColor: FuerzaVentasTheme.neonOrange,
              unselectedLabelColor: Colors.white60,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(text: 'Productividad'),
                Tab(text: 'Monitor Mapa'),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildProductividadTab(context),
            _buildMonitorMapTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProductividadTab(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Desempeño del Equipo',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              ElevatedButton.icon(
                onPressed: onLoadProductividad,
                icon: const Icon(Icons.refresh_outlined, size: 16),
                label: const Text('Cargar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FuerzaVentasTheme.bcpBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: productividadData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bar_chart_outlined, color: Colors.white24, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Sin datos de productividad cargados.',
                        style: TextStyle(color: Colors.white30, fontSize: 13.5),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: onLoadProductividad,
                        child: const Text('Consultar base de datos', style: TextStyle(color: FuerzaVentasTheme.neonCyan)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: productividadData.length,
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                  itemBuilder: (context, idx) {
                    final p = productividadData[idx];
                    final double tasa = double.tryParse(p['tasa_aprobacion']?.toString() ?? '0.0') ?? 0.0;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: FuerzaVentasTheme.glassDecoration(
                        borderColor: tasa > 80 ? FuerzaVentasTheme.neonGreen : FuerzaVentasTheme.neonCyan,
                        borderOpacity: 0.12,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        title: Text(
                          p['asesor_nombre'] ?? 'Asesor en Campo',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Enviadas: ${p['solicitudes_enviadas']} · Aprobadas: ${p['solicitudes_aprobadas']} · Desembolsadas: ${p['solicitudes_desembolsadas']}',
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: (tasa > 80 ? FuerzaVentasTheme.neonGreen : FuerzaVentasTheme.neonCyan).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${tasa.toStringAsFixed(1)}% Ok',
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              color: tasa > 80 ? FuerzaVentasTheme.neonGreen : FuerzaVentasTheme.neonCyan, 
                              fontSize: 12,
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

  Widget _buildMonitorMapTab(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(
          size: Size.infinite,
          painter: _SupervisorMapPainter(),
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: FuerzaVentasTheme.glassDecoration(
              color: FuerzaVentasTheme.cardDark,
              opacity: 0.85,
            ),
            child: const Row(
              children: [
                Icon(Icons.radar_outlined, color: FuerzaVentasTheme.neonCyan, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ubicación activa de asesores en campo',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Advisor indicators mock
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: FuerzaVentasTheme.glassDecoration(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMapLegendItem(FuerzaVentasTheme.neonCyan, 'María Sanches'),
                _buildMapLegendItem(FuerzaVentasTheme.neonOrange, 'Roberto Gómez'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapLegendItem(Color color, String name) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(name, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _SupervisorMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Obsidian grids
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.5;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // 2. Draw mock green geofence boundaries for team
    final boundaryPaint = Paint()
      ..color = FuerzaVentasTheme.neonGreen.withOpacity(0.1)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    canvas.drawRect(Rect.fromLTWH(size.width * 0.15, size.height * 0.2, size.width * 0.7, size.height * 0.5), boundaryPaint);

    // 3. Draw active advisor pins with neon glows
    final pin1 = Offset(size.width * 0.4, size.height * 0.55);
    final pin2 = Offset(size.width * 0.65, size.height * 0.35);

    // Glows
    canvas.drawCircle(pin1, 16, Paint()..color = FuerzaVentasTheme.neonCyan.withOpacity(0.2));
    canvas.drawCircle(pin2, 16, Paint()..color = FuerzaVentasTheme.neonOrange.withOpacity(0.2));

    // Outer circle
    canvas.drawCircle(pin1, 8, Paint()..color = FuerzaVentasTheme.neonCyan);
    canvas.drawCircle(pin2, 8, Paint()..color = FuerzaVentasTheme.neonOrange);

    // Center dot
    canvas.drawCircle(pin1, 3, Paint()..color = Colors.black);
    canvas.drawCircle(pin2, 3, Paint()..color = Colors.black);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
