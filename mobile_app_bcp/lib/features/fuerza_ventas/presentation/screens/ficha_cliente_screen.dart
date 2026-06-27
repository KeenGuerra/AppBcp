// features/fuerza_ventas/presentation/screens/ficha_cliente_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class FichaClienteScreen extends StatelessWidget {
  final Map<String, dynamic> cliente;
  const FichaClienteScreen({super.key, required this.cliente});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ficha del Cliente'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primaryBlue,
                child: Text(
                  '${(cliente['nombres'] ?? '')[0]}${(cliente['apellidos'] ?? '')[0]}',
                  style: const TextStyle(fontSize: 28, color: AppColors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text('${cliente['nombres'] ?? ''} ${cliente['apellidos'] ?? ''}', style: AppTextStyles.h2),
            ),
            Center(child: Text('DNI: ${cliente['documento'] ?? ''}', style: AppTextStyles.bodyMedium)),
            const SizedBox(height: 24),
            _buildSection('Datos Personales', [
              _buildRow('Teléfono', cliente['telefono'] ?? '—'),
              _buildRow('Correo', cliente['correo'] ?? '—'),
              _buildRow('Dirección', cliente['direccion'] ?? '—'),
              _buildRow('Distrito', cliente['distrito'] ?? '—'),
              _buildRow('Ocupación', cliente['ocupacion'] ?? '—'),
            ]),
            const SizedBox(height: 16),
            _buildSection('Negocio', [
              _buildRow('Nombre', cliente['nombre_negocio'] ?? '—'),
              _buildRow('Giro', cliente['giro_negocio'] ?? '—'),
              _buildRow('Antigüedad', '${cliente['antiguedad_meses'] ?? 0} meses'),
              _buildRow('Ingreso mensual', 'S/ ${cliente['ingreso_mensual'] ?? 0}'),
              _buildRow('Gasto mensual', 'S/ ${cliente['gasto_mensual'] ?? 0}'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.h4),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
