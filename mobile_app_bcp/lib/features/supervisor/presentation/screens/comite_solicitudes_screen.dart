// features/supervisor/presentation/screens/comite_solicitudes_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/shared_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ComiteSolicitudesScreen extends ConsumerWidget {
  const ComiteSolicitudesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final solicitudesAsync = ref.watch(solicitudesComiteProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comité de Créditos'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(solicitudesComiteProvider),
          ),
        ],
      ),
      body: solicitudesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (solicitudes) {
          if (solicitudes.isEmpty) {
            return const Center(child: Text('No hay solicitudes pendientes'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: solicitudes.length,
            itemBuilder: (context, index) {
              final sol = solicitudes[index];
              return _buildSolicitudCard(context, ref, sol);
            },
          );
        },
      ),
    );
  }

  Widget _buildSolicitudCard(BuildContext context, WidgetRef ref, Map<String, dynamic> sol) {
    final estado = sol['estado'] ?? 'EN_EVALUACION';
    final colorEstado = estado == 'APROBADO'
        ? AppColors.success
        : estado == 'RECHAZADO'
            ? AppColors.error
            : AppColors.warning;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(sol['numero_expediente'] ?? '', style: AppTextStyles.h4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorEstado.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(estado, style: TextStyle(color: colorEstado, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Cliente: ${sol['cliente_nombre'] ?? '—'}', style: AppTextStyles.bodyMedium),
            Text('Monto: S/ ${(sol['monto_solicitado'] ?? 0).toStringAsFixed(2)}', style: AppTextStyles.bodyMedium),
            Text('Plazo: ${sol['plazo_meses'] ?? 0} meses', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final repo = ref.read(apiRepositoryProvider);
                      await repo.aprobarSolicitud(sol['id_solicitud']);
                      ref.invalidate(solicitudesComiteProvider);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                    child: const Text('Aprobar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final repo = ref.read(apiRepositoryProvider);
                      await repo.desembolsar(sol['id_solicitud']);
                      ref.invalidate(solicitudesComiteProvider);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                    child: const Text('Desembolsar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
