// features/cliente_homebanking/presentation/screens/solicitar_credito_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
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
  bool _loadingProfile = true;
  String? _errorProfile;

  String? _idCliente;
  String? _idNegocio;
  String? _idProductoCredito;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final repo = ref.read(apiRepositoryProvider);
      final perfil = await repo.getPerfil();
      _idCliente = perfil['id_cliente'];

      final negocios = await repo.getNegocios(_idCliente!);
      if (negocios.isNotEmpty) {
        _idNegocio = negocios[0]['id_negocio'];
      }

      final productos = await repo.getProductosCredito();
      if (productos.isNotEmpty) {
        _idProductoCredito = productos[0]['id_producto_credito'];
      }

      if (mounted) setState(() => _loadingProfile = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingProfile = false;
          _errorProfile = 'Error al cargar perfil: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar Crédito'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : _errorProfile != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(_errorProfile!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadProfile, child: const Text('Reintentar')),
                    ],
                  ),
                )
              : SingleChildScrollView(
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
    final cuota = monto * tem / (1 - 1 / pow(1 + tem, plazo));
    return 'S/ ${cuota.toStringAsFixed(2)}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idCliente == null || _idNegocio == null || _idProductoCredito == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cargar los datos del perfil. Intente nuevamente.'), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final repo = ref.read(apiRepositoryProvider);
      await repo.crearSolicitud({
        'id_cliente': _idCliente,
        'id_negocio': _idNegocio,
        'id_producto_credito': _idProductoCredito,
        'monto_solicitado': double.parse(_montoController.text),
        'plazo_meses': int.parse(_plazoController.text),
        'destino_credito': _destinoController.text,
        'con_seguro_desgravamen': true,
        'garantia': 'Sola Firma',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud enviada correctamente'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Error: $e';
        if (e is DioException && e.response?.data != null) {
          final data = e.response!.data;
          if (data is Map && data.containsKey('detail')) {
            msg = data['detail'];
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }
}
