// features/admin/presentation/screens/productos_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  List<dynamic> _productos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProductos();
  }

  Future<void> _fetchProductos() async {
    setState(() => _loading = true);
    try {
      final response = await DioClient.instance.get('/admin/productos-creditos');
      setState(() => _productos = response.data);
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos Crediticios'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _productos.length,
              itemBuilder: (context, index) {
                final p = _productos[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['nombre'] ?? '', style: AppTextStyles.h4),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildChip('TEA', '${p['tea_con_seguro'] ?? 0}%', AppColors.success),
                            const SizedBox(width: 8),
                            _buildChip('Monto', 'S/ ${(p['monto_maximo'] ?? 0).toStringAsFixed(0)}', AppColors.info),
                            const SizedBox(width: 8),
                            _buildChip('Plazo', '${p['plazo_maximo'] ?? 0} meses', AppColors.primaryOrange),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label: $value', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
