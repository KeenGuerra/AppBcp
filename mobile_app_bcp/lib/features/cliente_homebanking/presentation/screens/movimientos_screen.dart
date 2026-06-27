// features/cliente_homebanking/presentation/screens/movimientos_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/shared_providers.dart';
import '../../../../shared/models/movimiento_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'package:intl/intl.dart';

class MovimientosScreen extends ConsumerWidget {
  const MovimientosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movimientosAsync = ref.watch(movimientosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Movimientos'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
      ),
      body: movimientosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (movimientos) {
          if (movimientos.isEmpty) {
            return const Center(child: Text('No hay movimientos registrados'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: movimientos.length,
            itemBuilder: (context, index) {
              final mov = movimientos[index];
              return _buildMovimientoCard(mov);
            },
          );
        },
      ),
    );
  }

  Widget _buildMovimientoCard(MovimientoModel mov) {
    final icon = mov.esIngreso ? Icons.arrow_downward : Icons.arrow_upward;
    final color = mov.esIngreso ? AppColors.success : AppColors.error;
    final sign = mov.esIngreso ? '+' : '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(mov.descripcion ?? mov.tipoMovimiento, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          mov.fechaMovimiento != null ? DateFormat('dd/MM/yyyy HH:mm').format(mov.fechaMovimiento!) : '',
          style: AppTextStyles.bodySmall,
        ),
        trailing: Text(
          '$sign${mov.montoFormateado}',
          style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
        ),
      ),
    );
  }
}
