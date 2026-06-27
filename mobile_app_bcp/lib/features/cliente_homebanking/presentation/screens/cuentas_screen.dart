// features/cliente_homebanking/presentation/screens/cuentas_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/shared_providers.dart';
import '../../../../shared/models/cuenta_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class CuentasScreen extends ConsumerWidget {
  const CuentasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuentasAsync = ref.watch(cuentasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Cuentas'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
      ),
      body: cuentasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (cuentas) {
          if (cuentas.isEmpty) {
            return const Center(child: Text('No tienes cuentas registradas'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cuentas.length,
            itemBuilder: (context, index) {
              final cuenta = cuentas[index];
              return _buildCuentaCard(cuenta);
            },
          );
        },
      ),
    );
  }

  Widget _buildCuentaCard(CuentaModel cuenta) {
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
                Text('Cuenta de Ahorro', style: AppTextStyles.label),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(cuenta.estado, style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(cuenta.numeroCuenta, style: AppTextStyles.h3),
            const SizedBox(height: 4),
            Text('CCI: ${ cuenta.cci ?? '—'}', style: AppTextStyles.bodySmall),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saldo Disponible', style: AppTextStyles.label),
                    Text(cuenta.saldoFormateado, style: AppTextStyles.amountMedium),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Saldo Contable', style: AppTextStyles.label),
                    Text('S/ ${cuenta.saldoContable.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
