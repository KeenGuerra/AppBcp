// features/cliente_homebanking/presentation/screens/pago_credito_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/shared_providers.dart';
import '../../../../shared/models/credito_model.dart';
import '../../../../core/theme/app_colors.dart';

class PagoCreditoScreen extends ConsumerStatefulWidget {
  const PagoCreditoScreen({super.key});

  @override
  ConsumerState<PagoCreditoScreen> createState() => _PagoCreditoScreenState();
}

class _PagoCreditoScreenState extends ConsumerState<PagoCreditoScreen> {
  CreditoModel? _selectedCredito;
  final _montoController = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final creditosAsync = ref.watch(creditosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago de Crédito'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            creditosAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
              data: (creditos) {
                if (creditos.isEmpty) {
                  return const Text('No tienes créditos activos');
                }
                return DropdownButtonFormField<CreditoModel>(
                  value: _selectedCredito,
                  decoration: const InputDecoration(
                    labelText: 'Seleccionar crédito',
                    border: OutlineInputBorder(),
                  ),
                  items: creditos.map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Text('${c.numeroCredito} - ${c.saldoFormateado}'),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedCredito = v),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _montoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto a pagar (S/)',
                border: OutlineInputBorder(),
                prefixText: 'S/ ',
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
                  : const Text('Realizar Pago', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedCredito == null || _montoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un crédito y monto'), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final repo = ref.read(apiRepositoryProvider);
      await repo.pagarCredito({
        'id_credito': _selectedCredito!.idCredito,
        'monto': double.parse(_montoController.text),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago registrado correctamente'), backgroundColor: AppColors.success),
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
