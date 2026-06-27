// features/cliente_homebanking/presentation/screens/transferencia_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/shared_providers.dart';
import '../../../../core/theme/app_colors.dart';

class TransferenciaScreen extends ConsumerStatefulWidget {
  const TransferenciaScreen({super.key});

  @override
  ConsumerState<TransferenciaScreen> createState() => _TransferenciaScreenState();
}

class _TransferenciaScreenState extends ConsumerState<TransferenciaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cuentaDestinoController = TextEditingController();
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transferencia'),
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
              TextFormField(
                controller: _cuentaDestinoController,
                decoration: const InputDecoration(
                  labelText: 'Cuenta destino (número o CCI)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Ingrese cuenta destino' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _montoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto a transferir (S/)',
                  border: OutlineInputBorder(),
                  prefixText: 'S/ ',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (v) {
                  final monto = double.tryParse(v ?? '');
                  if (monto == null || monto <= 0) return 'Ingrese un monto válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  border: OutlineInputBorder(),
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
                    : const Text('Transferir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(apiRepositoryProvider);
      await repo.transferir({
        'cuenta_destino': _cuentaDestinoController.text,
        'monto': double.parse(_montoController.text),
        'descripcion': _descripcionController.text.isNotEmpty ? _descripcionController.text : null,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transferencia exitosa'), backgroundColor: AppColors.success),
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
