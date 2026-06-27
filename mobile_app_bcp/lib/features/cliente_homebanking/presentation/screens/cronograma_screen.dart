// features/cliente_homebanking/presentation/screens/cronograma_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/shared_providers.dart';
import '../../../../shared/models/cronograma_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class CronogramaScreen extends ConsumerWidget {
  final String idCredito;
  const CronogramaScreen({super.key, required this.idCredito});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cronogramaAsync = ref.watch(cronogramaProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cronograma de Pagos'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
      ),
      body: cronogramaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (cronograma) {
          if (cronograma.isEmpty) {
            return const Center(child: Text('No hay cuotas registradas'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cronograma.length,
            itemBuilder: (context, index) {
              final cuota = cronograma[index];
              return _buildCuotaCard(cuota);
            },
          );
        },
      ),
    );
  }

  Widget _buildCuotaCard(CronogramaModel cuota) {
    final color = cuota.estado == 'PAGADA'
        ? AppColors.success
        : cuota.estado == 'VENCIDA'
            ? AppColors.error
            : cuota.estado == 'PARCIAL'
                ? AppColors.warning
                : AppColors.textMuted;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text('${cuota.numeroCuota}', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cuota.fechaPago != null
                        ? '${cuota.fechaPago!.day}/${cuota.fechaPago!.month}/${cuota.fechaPago!.year}'
                        : 'Sin fecha',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Capital: ${cuota.capitalFormateado}', style: AppTextStyles.bodySmall),
                      const SizedBox(width: 12),
                      Text('Interés: ${cuota.interesFormateado}', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(cuota.montoFormateado, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(cuota.estado, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
