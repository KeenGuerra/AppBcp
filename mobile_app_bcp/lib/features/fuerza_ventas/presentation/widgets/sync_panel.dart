import 'package:flutter/material.dart';
import '../theme/fuerza_ventas_theme.dart';

class SyncPanel extends StatelessWidget {
  final int pendingSyncCount;
  final bool isOnline;
  final VoidCallback onForceSync;

  const SyncPanel({
    super.key,
    required this.pendingSyncCount,
    required this.isOnline,
    required this.onForceSync,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = pendingSyncCount > 0 
        ? FuerzaVentasTheme.neonOrange 
        : FuerzaVentasTheme.neonGreen;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          decoration: FuerzaVentasTheme.glassDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon container with neon shadow glow
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
                  boxShadow: FuerzaVentasTheme.neonGlowShadow(color: statusColor, opacity: 0.15, blurRadius: 20),
                ),
                child: Icon(
                  pendingSyncCount > 0 ? Icons.sync_problem_outlined : Icons.sync_outlined,
                  size: 72,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 32),
              
              Text(
                pendingSyncCount > 0
                    ? 'Transmisiones Pendientes'
                    : 'Dispositivo Sincronizado',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: statusColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              
              Text(
                pendingSyncCount > 0
                    ? 'Tienes $pendingSyncCount transacciones almacenadas localmente en SQLite esperando cobertura de red.'
                    : 'Todas tus gestiones en campo y expedientes de crédito se encuentran transmitidos al Core BCP.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Las visitas, cobranzas y solicitudes registradas sin internet se guardan encriptadas en la base local segura y se sincronizan automáticamente en segundo plano cuando se detecta conexión activa.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white30, fontSize: 11.5, height: 1.4),
              ),
              const SizedBox(height: 36),
              
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: pendingSyncCount > 0 && isOnline 
                        ? FuerzaVentasTheme.bcpCyanGradient 
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: pendingSyncCount > 0 && isOnline 
                        ? FuerzaVentasTheme.neonGlowShadow(color: FuerzaVentasTheme.neonCyan, opacity: 0.25)
                        : null,
                  ),
                  child: ElevatedButton(
                    onPressed: pendingSyncCount > 0 && isOnline ? onForceSync : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pendingSyncCount > 0 && isOnline 
                          ? Colors.transparent 
                          : Colors.white.withOpacity(0.04),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white30,
                      shadowColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: pendingSyncCount > 0 && isOnline 
                              ? Colors.transparent 
                              : Colors.white10,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bolt_outlined),
                        const SizedBox(width: 8),
                        Text(
                          pendingSyncCount > 0 
                              ? 'Sincronizar Ahora' 
                              : 'Sincronización Completa',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (pendingSyncCount > 0 && !isOnline) ...[
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off_outlined, color: FuerzaVentasTheme.neonRed, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Sin red. Active WiFi o Datos para transmitir.',
                      style: TextStyle(color: FuerzaVentasTheme.neonRed, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
