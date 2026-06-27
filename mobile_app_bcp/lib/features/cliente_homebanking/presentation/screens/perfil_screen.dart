// features/cliente_homebanking/presentation/screens/perfil_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/shared_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfilAsync = ref.watch(perfilProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
      ),
      body: perfilAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (perfil) {
          if (perfil == null) {
            return const Center(child: Text('No se pudo cargar el perfil'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primaryBlue,
                  child: Text(
                    '${perfil.nombres[0]}${perfil.apellidos[0]}',
                    style: const TextStyle(fontSize: 32, color: AppColors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Text(perfil.nombreCompleto, style: AppTextStyles.h2),
                const SizedBox(height: 4),
                Text('DNI: ${perfil.documento}', style: AppTextStyles.bodyMedium),
                const SizedBox(height: 24),
                _buildInfoCard('Teléfono', perfil.telefono ?? '—', Icons.phone),
                _buildInfoCard('Correo', perfil.correo ?? '—', Icons.email),
                _buildInfoCard('Dirección', perfil.direccion ?? '—', Icons.location_on),
                _buildInfoCard('Distrito', perfil.distrito ?? '—', Icons.map),
                _buildInfoCard('Ocupación', perfil.ocupacion ?? '—', Icons.work),
                _buildInfoCard('Estado Civil', perfil.estadoCivil ?? '—', Icons.favorite),
                _buildInfoCard('Tipo Cliente', perfil.tipoCliente ?? '—', Icons.person),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryBlue),
        title: Text(label, style: AppTextStyles.label),
        subtitle: Text(value, style: AppTextStyles.bodyMedium),
      ),
    );
  }
}
