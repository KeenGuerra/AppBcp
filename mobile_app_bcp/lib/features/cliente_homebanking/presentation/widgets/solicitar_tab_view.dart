import 'package:flutter/material.dart';
import 'package:mobile_app_bcp/core/config/app_constants.dart';
import 'package:mobile_app_bcp/core/utils/date_formatter.dart';
import '../theme/cliente_theme.dart';

class SolicitarTabView extends StatelessWidget {
  final TextEditingController montoController;
  final TextEditingController plazoController;
  final TextEditingController garantiaController;
  final TextEditingController destinoController;
  final VoidCallback onSendRequest;
  final List<dynamic> solicitudes;

  const SolicitarTabView({
    super.key,
    required this.montoController,
    required this.plazoController,
    required this.garantiaController,
    required this.destinoController,
    required this.onSendRequest,
    required this.solicitudes,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nueva Solicitud de Crédito',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ClienteTheme.bcpBlue),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: ClienteTheme.cardDecoration(showShadow: false, border: Border.all(color: Colors.black.withOpacity(0.04))),
            child: const Text(
              'Solicita tu préstamo instantáneo desde Banca Móvil. El expediente será evaluado y asignado a un asesor en tu agencia de origen.',
              style: TextStyle(color: ClienteTheme.bcpTextGrey, fontSize: 13, height: 1.4),
            ),
          ),
          const SizedBox(height: 16),
          
          // Form Fields inside a Card container
          Container(
            padding: const EdgeInsets.all(18),
            decoration: ClienteTheme.cardDecoration(),
            child: Column(
              children: [
                TextFormField(
                  controller: montoController,
                  style: const TextStyle(color: ClienteTheme.bcpTextDark),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Monto Solicitado (S/)',
                    labelStyle: const TextStyle(color: ClienteTheme.bcpTextGrey),
                    prefixIcon: const Icon(Icons.monetization_on_outlined, color: ClienteTheme.bcpOrange),
                    filled: true,
                    fillColor: ClienteTheme.bcpBgGrey,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: plazoController,
                  style: const TextStyle(color: ClienteTheme.bcpTextDark),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Plazo en Meses',
                    labelStyle: const TextStyle(color: ClienteTheme.bcpTextGrey),
                    prefixIcon: const Icon(Icons.calendar_today_outlined, color: ClienteTheme.bcpOrange),
                    filled: true,
                    fillColor: ClienteTheme.bcpBgGrey,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: garantiaController,
                  style: const TextStyle(color: ClienteTheme.bcpTextDark),
                  decoration: InputDecoration(
                    labelText: 'Garantía Ofrecida',
                    labelStyle: const TextStyle(color: ClienteTheme.bcpTextGrey),
                    prefixIcon: const Icon(Icons.security_outlined, color: ClienteTheme.bcpOrange),
                    filled: true,
                    fillColor: ClienteTheme.bcpBgGrey,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: destinoController,
                  style: const TextStyle(color: ClienteTheme.bcpTextDark),
                  decoration: InputDecoration(
                    labelText: 'Destino del Préstamo',
                    labelStyle: const TextStyle(color: ClienteTheme.bcpTextGrey),
                    prefixIcon: const Icon(Icons.description_outlined, color: ClienteTheme.bcpOrange),
                    filled: true,
                    fillColor: ClienteTheme.bcpBgGrey,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Submit button with BCP Blue
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: ClienteTheme.orangeButtonGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ElevatedButton(
                      onPressed: onSendRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        surfaceTintColor: Colors.transparent,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Enviar Solicitud', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // History Title
          const Text(
            'Mis Solicitudes Enviadas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ClienteTheme.bcpBlue),
          ),
          const SizedBox(height: 12),
          if (solicitudes.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: ClienteTheme.cardDecoration(),
              child: const Center(
                child: Text(
                  'No registra solicitudes previas',
                  style: TextStyle(color: ClienteTheme.bcpTextGrey, fontSize: 13.5),
                ),
              ),
            )
          else
            ...solicitudes.map((s) {
              final double monto = double.tryParse(s['monto_solicitado']?.toString() ?? '0.0') ?? 0.0;
              final estado = (s['estado'] ?? 'ENVIADO').toString().toUpperCase();
              Color stateColor = ClienteTheme.bcpOrange;
              if (estado == 'APROBADO' || estado == 'DESEMBOLSADO') stateColor = AppConstants.exitoGreen;
              if (estado == 'RECHAZADO') stateColor = AppConstants.errorRed;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: ClienteTheme.cardDecoration(),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  title: Text(
                    s['numero_expediente'] ?? 'Expediente',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: ClienteTheme.bcpTextDark, fontSize: 14.5),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Text(
                          'S/ $monto  ·  ',
                          style: const TextStyle(color: ClienteTheme.bcpTextGrey, fontSize: 12.5),
                        ),
                        Text(
                          estado,
                          style: TextStyle(color: stateColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  trailing: Text(
                    DateFormatter.formatShortString(s['created_at'] ?? ''),
                    style: const TextStyle(fontSize: 11.5, color: ClienteTheme.bcpTextGrey),
                  ),
                ),
              );
            }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
