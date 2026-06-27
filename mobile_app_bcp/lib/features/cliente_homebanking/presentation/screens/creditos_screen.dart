// features/cliente_homebanking/presentation/screens/creditos_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/shared_providers.dart';
import '../../../../shared/models/credito_model.dart';
import 'cronograma_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class CreditosScreen extends ConsumerWidget {
  const CreditosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditosAsync = ref.watch(creditosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Créditos'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
      ),
      body: creditosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (creditos) {
          if (creditos.isEmpty) {
            return const Center(child: Text('No tienes créditos activos'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: creditos.length,
            itemBuilder: (context, index) {
              final credito = creditos[index];
              return _buildCreditoCard(context, credito);
            },
          );
        },
      ),
    );
  }

  Widget _buildCreditoCard(BuildContext context, CreditoModel credito) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(credito.numeroCredito, style: AppTextStyles.h4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(credito.estado, style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(credito.producto ?? 'Crédito', style: AppTextStyles.bodySmall),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetail('Monto', credito.montoFormateado),
                _buildDetail('Saldo', credito.saldoFormateado),
                _buildDetail('Cuota', credito.cuotaFormateada),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CronogramaScreen(idCredito: credito.idCredito),
                    ),
                  );
                },
                icon: const Icon(Icons.calendar_today, size: 18),
                label: const Text('Ver Cronograma'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: const BorderSide(color: AppColors.primaryBlue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      ],
    );
  }
}
