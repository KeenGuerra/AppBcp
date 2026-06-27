// features/fuerza_ventas/presentation/screens/mis_solicitudes_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/shared_providers.dart';
import 'solicitud_detalle_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class MisSolicitudesScreen extends ConsumerWidget {
  const MisSolicitudesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final solicitudesAsync = ref.watch(solicitudesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Solicitudes'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(solicitudesProvider),
          ),
        ],
      ),
      body: solicitudesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (solicitudes) {
          if (solicitudes.isEmpty) {
            return const Center(child: Text('No hay solicitudes'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: solicitudes.length,
            itemBuilder: (context, index) {
              final sol = solicitudes[index];
              final estado = sol.estado;
              final colorEstado = _getEstadoColor(estado);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SolicitudDetalleScreen(solicitud: sol.toJson()),
                      ),
                    );
                  ),
                  leading: CircleAvatar(
                    backgroundColor: colorEstado.withOpacity(0.1),
                    child: Icon(Icons.description, color: colorEstado),
                  ),
                  title: Text(sol.numeroExpediente ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${sol.montoFormateado} · ${sol.plazoMeses} meses', style: AppTextStyles.bodySmall),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorEstado.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(estado, style: TextStyle(color: colorEstado, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'APROBADO': return AppColors.success;
      case 'RECHAZADO': return AppColors.error;
      case 'DESEMBOLSADO': return AppColors.info;
      case 'CONDICIONADO': return AppColors.warning;
      default: return AppColors.textMuted;
    }
  }
}
