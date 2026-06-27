// features/cliente_homebanking/presentation/screens/notificaciones_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/shared_providers.dart';
import '../../../../shared/models/notificacion_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class NotificacionesScreen extends ConsumerWidget {
  const NotificacionesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificacionesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
      ),
      body: notifAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notificaciones) {
          if (notificaciones.isEmpty) {
            return const Center(child: Text('No tienes notificaciones'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notificaciones.length,
            itemBuilder: (context, index) {
              final notif = notificaciones[index];
              return _buildNotificacionCard(notif);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificacionCard(NotificacionModel notif) {
    final icon = notif.tipo == 'ALERTA'
        ? Icons.warning
        : notif.tipo == 'CREDITO'
            ? Icons.account_balance
            : Icons.info;
    final color = notif.tipo == 'ALERTA'
        ? AppColors.warning
        : notif.tipo == 'CREDITO'
            ? AppColors.success
            : AppColors.info;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: notif.leida ? null : color.withOpacity(0.05),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(notif.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(notif.mensaje, style: AppTextStyles.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: notif.leida
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.primaryOrange, shape: BoxShape.circle),
              ),
      ),
    );
  }
}
