// features/cliente_homebanking/presentation/screens/solicitar_credito_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/shared_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class SolicitarCreditoScreen extends ConsumerStatefulWidget {
  const SolicitarCreditoScreen({super.key});

  @override
  ConsumerState<SolicitarCreditoScreen> createState() => _SolicitarCreditoScreenState();
}

class _SolicitarCreditoScreenState extends ConsumerState<SolicitarCreditoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController(text: '10000');
  final _plazoController = TextEditingController(text: '12');
  final _destinoController = TextEditingController(text: 'Capital de trabajo');
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar Crédito'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Datos del Crédito', style: AppTextStyles.h4),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _montoController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Monto solicitado (S/)',
                          border: OutlineInputBorder(),
                          prefixText: 'S/ ',
                        ),
                        validator: (v) {
                          final monto = double.tryParse(v ?? '');
                          if (monto == null || monto < 1000) return 'Monto mínimo S/ 1,000';
                          if (monto > 50000) return 'Monto máximo S/ 50,000';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _plazoController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Plazo (meses)',
                          border: OutlineInputBorder(),
                          suffixText: 'meses',
                        ),
                        validator: (v) {
                          final plazo = int.tryParse(v ?? '');
                          if (plazo == null || plazo < 6) return 'Plazo mínimo 6 meses';
                          if (plazo > 48) return 'Plazo máximo 48 meses';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _destinoController,
                        decoration: const InputDecoration(
                          labelText: 'Destino del crédito',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Resumen', style: AppTextStyles.h4),
                      const SizedBox(height: 12),
                      _buildResumen('Monto', 'S/ ${_montoController.text}'),
                      _buildResumen('Plazo', '${_plazoController.text} meses'),
                      _buildResumen('TEA', '40.92%'),
                      _buildResumen('Cuota estimada', _calcularCuota()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: AppColors.white)
                    : const Text('Enviar Solicitud', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumen(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _calcularCuota() {
    final monto = double.tryParse(_montoController.text) ?? 0;
    final plazo = int.tryParse(_plazoController.text) ?? 12;
    if (monto == 0) return 'S/ 0.00';
    final tea = 0.4092;
    final tem = (1 + tea) / 12 - 1;
    final cuota = monto * tem / (1 - (1 + tem).pow(-plazo));
    return 'S/ ${cuota.toStringAsFixed(2)}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(apiRepositoryProvider);
      await repo.crearSolicitud({
        'monto_solicitado': double.parse(_montoController.text),
        'plazo_meses': int.parse(_plazoController.text),
        'destino_credito': _destinoController.text,
        'moneda': 'PEN',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud enviada correctamente'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }
}
