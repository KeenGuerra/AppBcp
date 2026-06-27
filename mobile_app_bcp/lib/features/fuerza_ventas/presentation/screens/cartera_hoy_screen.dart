// features/fuerza_ventas/presentation/screens/cartera_hoy_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/shared_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class CarteraHoyScreen extends ConsumerWidget {
  const CarteraHoyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carteraAsync = ref.watch(carteraProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cartera del Día'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(carteraProvider),
          ),
        ],
      ),
      body: carteraAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (cartera) {
          if (cartera.isEmpty) {
            return const Center(child: Text('No hay clientes en cartera hoy'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cartera.length,
            itemBuilder: (context, index) {
              final item = cartera[index];
              return _buildCarteraItem(context, item);
            },
          );
        },
      ),
    );
  }

  Widget _buildCarteraItem(BuildContext context, Map<String, dynamic> item) {
    final prioridad = item['prioridad'] ?? 'MEDIA';
    final colorPrioridad = prioridad == 'ALTA'
        ? AppColors.error
        : prioridad == 'MEDIA'
            ? AppColors.warning
            : AppColors.info;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorPrioridad.withOpacity(0.1),
          child: Icon(Icons.person, color: colorPrioridad),
        ),
        title: Text(item['cliente_nombre'] ?? 'Cliente', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(item['tipo_gestion'] ?? 'SEGUIMIENTO', style: AppTextStyles.bodySmall),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorPrioridad.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(prioridad, style: TextStyle(color: colorPrioridad, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
