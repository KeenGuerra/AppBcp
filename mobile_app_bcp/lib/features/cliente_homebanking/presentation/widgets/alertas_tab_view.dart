import 'package:flutter/material.dart';
import 'package:mobile_app_bcp/core/utils/date_formatter.dart';
import '../theme/cliente_theme.dart';

class AlertasTabView extends StatelessWidget {
  final List<dynamic> notificaciones;

  const AlertasTabView({
    super.key,
    required this.notificaciones,
  });

  @override
  Widget build(BuildContext context) {
    if (notificaciones.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.notifications_none_outlined, color: ClienteTheme.bcpTextGrey, size: 48),
              SizedBox(height: 12),
              Text(
                'No tienes alertas o notificaciones pendientes en tu buzón BCP.',
                textAlign: TextAlign.center,
                style: TextStyle(color: ClienteTheme.bcpTextGrey, fontSize: 13.5),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notificaciones.length,
      itemBuilder: (context, idx) {
        final n = notificaciones[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: ClienteTheme.cardDecoration(),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ClienteTheme.bcpOrange.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                color: ClienteTheme.bcpOrange,
                size: 24,
              ),
            ),
            title: Text(
              n['titulo'] ?? 'Aviso BCP',
              style: const TextStyle(fontWeight: FontWeight.bold, color: ClienteTheme.bcpTextDark, fontSize: 14.5),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                n['mensaje'] ?? '',
                style: const TextStyle(color: ClienteTheme.bcpTextGrey, fontSize: 12.5, height: 1.3),
              ),
            ),
            trailing: Text(
              DateFormatter.formatShortString(n['created_at'] ?? ''),
              style: const TextStyle(fontSize: 10.5, color: ClienteTheme.bcpTextGrey),
            ),
          ),
        );
      },
    );
  }
}
