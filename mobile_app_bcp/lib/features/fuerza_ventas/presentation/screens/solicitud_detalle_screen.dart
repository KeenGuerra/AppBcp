// features/fuerza_ventas/presentation/screens/solicitud_detalle_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/shared_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class SolicitudDetalleScreen extends ConsumerWidget {
  final Map<String, dynamic> solicitud;
  const SolicitudDetalleScreen({super.key, required this.solicitud});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = solicitud['estado'] ?? 'BORRADOR';
    final colorEstado = _getEstadoColor(estado);

    return Scaffold(
      appBar: AppBar(
        title: Text(solicitud['numero_expediente'] ?? 'Solicitud'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorEstado.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(estado, style: TextStyle(color: colorEstado, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Monto: S/ ${(solicitud['monto_solicitado'] ?? 0).toStringAsFixed(2)}', style: AppTextStyles.h3),
                  Text('${solicitud['plazo_meses'] ?? 0} meses', style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSection('Información del Cliente', [
              _buildRow('Nombre', '${solicitud['cliente_nombre'] ?? '—'}'),
              _buildRow('DNI', solicitud['cliente_documento'] ?? '—'),
              _buildRow('Canal', solicitud['canal_origen'] ?? '—'),
            ]),
            const SizedBox(height: 12),
            _buildSection('Evaluación', [
              _buildRow('Preevaluación', solicitud['resultado_preevaluacion'] ?? '—'),
              _buildRow('Puntaje', '${solicitud['puntaje_preevaluacion'] ?? '—'}'),
              _buildRow('Buró', solicitud['resultado_buro'] ?? '—'),
            ]),
            const SizedBox(height: 20),
            if (estado == 'EN_EVALUACION') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final repo = ref.read(apiRepositoryProvider);
                    await repo.enviarComite(solicitud['id_solicitud']);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                  child: const Text('Enviar a Comité'),
                ),
              ),
            ],
          ],
        ),
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
