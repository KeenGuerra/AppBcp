import 'package:flutter/material.dart';
import '../theme/fuerza_ventas_theme.dart';

class RutaView extends StatelessWidget {
  final List<Map<String, dynamic>> cartera;
  final List<Offset> clientOffsets;
  final List<Offset> geofenceZone;
  final List<int> optimizedRouteIndices;
  final bool isRouteOptimized;
  final int? hoveredMapClientIndex;
  final Offset mapOffset;
  final double mapZoom;

  final VoidCallback onOptimizeRoute;
  final Function(String clientName) onNavigate;
  final Function(Offset delta) onMapPan;
  final Function(double zoom) onMapZoomChanged;
  final Function(int? index) onMapHoverChanged;
  final Function(String clientId) onLoadCustomerFicha;

  const RutaView({
    super.key,
    required this.cartera,
    required this.clientOffsets,
    required this.geofenceZone,
    required this.optimizedRouteIndices,
    required this.isRouteOptimized,
    required this.hoveredMapClientIndex,
    required this.mapOffset,
    required this.mapZoom,
    required this.onOptimizeRoute,
    required this.onNavigate,
    required this.onMapPan,
    required this.onMapZoomChanged,
    required this.onMapHoverChanged,
    required this.onLoadCustomerFicha,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Navigation / Optimization Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: FuerzaVentasTheme.glassDecoration(
            borderRadius: 0,
            opacity: 0.4,
            borderOpacity: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Flexible(
                child: ElevatedButton.icon(
                  onPressed: onOptimizeRoute,
                  icon: const Icon(Icons.offline_bolt_outlined, color: Colors.white),
                  label: const Text('Optimizar Ruta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FuerzaVentasTheme.bcpOrange,
                    foregroundColor: Colors.white,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: ElevatedButton.icon(
                  onPressed: isRouteOptimized &&
                          optimizedRouteIndices.isNotEmpty &&
                          optimizedRouteIndices.first >= 0 &&
                          optimizedRouteIndices.first < cartera.length
                      ? () {
                          final firstIdx = optimizedRouteIndices.first;
                          final cli = cartera[firstIdx]['cliente'];
                          onNavigate('${cli?['nombres'] ?? ""}');
                        }
                      : null,
                  icon: const Icon(Icons.navigation_outlined, color: Colors.white),
                  label: const Text('Navegar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FuerzaVentasTheme.bcpBlue,
                    foregroundColor: Colors.white,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Custom Map Drawing Container
        Expanded(
          child: Stack(
            children: [
              // Vector Map Drawing Widget
              GestureDetector(
                onPanUpdate: (details) {
                  onMapPan(details.delta);
                },
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _MapVectorPainter(
                    mapOffset: mapOffset,
                    zoom: mapZoom,
                    clients: cartera,
                    clientOffsets: clientOffsets,
                    geofence: geofenceZone,
                    optimizedRoute: optimizedRouteIndices,
                    isOptimized: isRouteOptimized,
                    hoveredIndex: hoveredMapClientIndex,
                  ),
                ),
              ),
              
              // Map controls overlay (zoom in/out)
              Positioned(
                bottom: 16,
                right: 16,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'map_in',
                      backgroundColor: FuerzaVentasTheme.cardDark,
                      foregroundColor: Colors.white,
                      onPressed: () => onMapZoomChanged(mapZoom * 1.2),
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'map_out',
                      backgroundColor: FuerzaVentasTheme.cardDark,
                      foregroundColor: Colors.white,
                      onPressed: () => onMapZoomChanged(mapZoom / 1.2),
                      child: const Icon(Icons.remove),
                    )
                  ],
                ),
              ),
              
              // Interactive Client Tooltip overlay
              if (hoveredMapClientIndex != null &&
                  hoveredMapClientIndex! >= 0 &&
                  hoveredMapClientIndex! < cartera.length)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: FuerzaVentasTheme.glassDecoration(
                      color: FuerzaVentasTheme.cardDark,
                      opacity: 0.9,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Cliente: ${cartera[hoveredMapClientIndex!]['cliente']?['nombres'] ?? ""} ${cartera[hoveredMapClientIndex!]['cliente']?['apellidos'] ?? ""}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Prioridad: ${cartera[hoveredMapClientIndex!]['prioridad']} | Gestión: ${cartera[hoveredMapClientIndex!]['tipo_gestion']}',
                                style: const TextStyle(color: Colors.white60, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final id = cartera[hoveredMapClientIndex!]['id_cliente'];
                            onLoadCustomerFicha(id);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FuerzaVentasTheme.bcpOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Ver Ficha', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                )
            ],
          ),
        )
      ],
    );
  }
}

class _MapVectorPainter extends CustomPainter {
  final Offset mapOffset;
  final double zoom;
  final List<Map<String, dynamic>> clients;
  final List<Offset> clientOffsets;
  final List<Offset> geofence;
  final List<int> optimizedRoute;
  final bool isOptimized;
  final int? hoveredIndex;

  _MapVectorPainter({
    required this.mapOffset,
    required this.zoom,
    required this.clients,
    required this.clientOffsets,
    required this.geofence,
    required this.optimizedRoute,
    required this.isOptimized,
    required this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw grid background (Obsidian grids)
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.5;

    for (double i = 0; i < size.width; i += 60) {
      canvas.drawLine(Offset(i + (mapOffset.dx % 60), 0), Offset(i + (mapOffset.dx % 60), size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 60) {
      canvas.drawLine(Offset(0, i + (mapOffset.dy % 60)), Offset(size.width, i + (mapOffset.dy % 60)), gridPaint);
    }

    // 2. Draw Geofence semitransparent polygon (Neon Cyan / Green)
    final geofencePaint = Paint()
      ..color = FuerzaVentasTheme.neonCyan.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    
    final geofenceBorderPaint = Paint()
      ..color = FuerzaVentasTheme.neonCyan.withOpacity(0.3)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final geofencePath = Path();
    bool hasGeofencePoints = false;
    for (int i = 0; i < geofence.length; i++) {
      final p = (geofence[i] * zoom) + mapOffset;
      if (i == 0) {
        geofencePath.moveTo(p.dx, p.dy);
        hasGeofencePoints = true;
      } else {
        geofencePath.lineTo(p.dx, p.dy);
      }
    }
    geofencePath.close();
    if (hasGeofencePoints) {
      canvas.drawPath(geofencePath, geofencePaint);
      canvas.drawPath(geofencePath, geofenceBorderPaint);
    }

    // 3. Draw Optimized routing path
    if (isOptimized && optimizedRoute.isNotEmpty) {
      final pathPaint = Paint()
        ..color = FuerzaVentasTheme.neonOrange
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke;

      final routePath = Path();
      bool hasRoutePoints = false;
      int pointCount = 0;
      for (int i = 0; i < optimizedRoute.length; i++) {
        final clientIdx = optimizedRoute[i];
        if (clientIdx >= 0 && clientIdx < clientOffsets.length) {
          final p = (clientOffsets[clientIdx] * zoom) + mapOffset;
          if (pointCount == 0) {
            routePath.moveTo(p.dx, p.dy);
            hasRoutePoints = true;
          } else {
            routePath.lineTo(p.dx, p.dy);
          }
          pointCount++;
        }
      }
      if (hasRoutePoints) {
        canvas.drawPath(routePath, pathPaint);
      }
    }

    // 4. Draw Client Markers
    for (int i = 0; i < clients.length; i++) {
      if (i >= clientOffsets.length) continue;
      final item = clients[i];
      final rawPos = clientOffsets[i];
      final pos = (rawPos * zoom) + mapOffset;
      final isVisited = item['estado_visita'] == 'REALIZADA';

      Color markerColor = Colors.grey;
      if (!isVisited) {
        if (item['prioridad'] == 'ALTA') markerColor = FuerzaVentasTheme.neonRed;
        if (item['prioridad'] == 'MEDIA') markerColor = FuerzaVentasTheme.neonOrange;
        if (item['prioridad'] == 'NORMAL') markerColor = FuerzaVentasTheme.neonGreen;
      } else {
        markerColor = FuerzaVentasTheme.neonGreen;
      }

      final pinPaint = Paint()..color = markerColor;
      
      // Draw neon outer glow if hovered
      if (hoveredIndex == i) {
        canvas.drawCircle(pos, 14 * zoom, Paint()..color = markerColor.withOpacity(0.35));
      }

      canvas.drawCircle(pos, 10 * zoom, pinPaint);
      canvas.drawCircle(pos, 4 * zoom, Paint()..color = Colors.black);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
