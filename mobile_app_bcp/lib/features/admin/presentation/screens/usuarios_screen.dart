// features/admin/presentation/screens/usuarios_screen.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  List<dynamic> _usuarios = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsuarios();
  }

  Future<void> _fetchUsuarios() async {
    setState(() => _loading = true);
    try {
      final response = await DioClient.instance.dio.get('/admin/usuarios');
      setState(() => _usuarios = response.data);
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
        title: const Text('Gestión de Usuarios'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _usuarios.length,
              itemBuilder: (context, index) {
                final u = _usuarios[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getRolColor(u['rol']).withOpacity(0.1),
                      child: Icon(Icons.person, color: _getRolColor(u['rol'])),
                    ),
                    title: Text(u['nombre'] ?? u['documento'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('DNI: ${u['documento'] ?? ''} · ${u['rol'] ?? ''}', style: AppTextStyles.bodySmall),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRolColor(u['rol']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(u['rol'] ?? '', style: TextStyle(color: _getRolColor(u['rol']), fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _getRolColor(String? rol) {
    switch (rol) {
      case 'ADMIN': return AppColors.error;
      case 'SUPERVISOR': return AppColors.primaryOrange;
      case 'ASESOR': return AppColors.info;
      default: return AppColors.textMuted;
    }
  }
}
