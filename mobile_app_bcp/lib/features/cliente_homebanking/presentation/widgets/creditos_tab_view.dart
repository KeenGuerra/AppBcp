import 'package:flutter/material.dart';
import 'package:mobile_app_bcp/core/config/app_constants.dart';
import 'package:mobile_app_bcp/core/utils/money_formatter.dart';
import '../theme/cliente_theme.dart';

class CreditosTabView extends StatelessWidget {
  final List<dynamic> creditos;
  final Function(String idCredito) onViewCronograma;

  const CreditosTabView({
    super.key,
    required this.creditos,
    required this.onViewCronograma,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mis Préstamos Activos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ClienteTheme.bcpBlue),
          ),
          const SizedBox(height: 12),
          if (creditos.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              decoration: ClienteTheme.cardDecoration(),
              child: const Column(
                children: [
                  Icon(Icons.info_outline, color: ClienteTheme.bcpTextGrey, size: 40),
                  SizedBox(height: 12),
                  Text(
                    'No posee préstamos vigentes con nosotros.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ClienteTheme.bcpTextGrey, fontSize: 13.5),
                  ),
                ],
              ),
            )
          else
            ...creditos.map((cr) {
              final double desembolsado = double.tryParse(cr['monto_desembolsado']?.toString() ?? '0.0') ?? 0.0;
              final double saldoCapital = double.tryParse(cr['saldo_capital']?.toString() ?? '0.0') ?? 0.0;
              final double cuota = double.tryParse(cr['cuota_mensual']?.toString() ?? '0.0') ?? 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: ClienteTheme.cardDecoration(),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: ClienteTheme.bcpBlue.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.account_balance_outlined, color: ClienteTheme.bcpBlue, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                cr['numero_credito'] ?? 'Prestamo BCP',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: ClienteTheme.bcpTextDark),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppConstants.exitoGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              (cr['estado'] ?? 'ACTIVO').toString().toUpperCase(),
                              style: const TextStyle(color: AppConstants.exitoGreen, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 28, color: Colors.black12),
                      _buildCreditoDetailRow('Monto Desembolsado', MoneyFormatter.format(desembolsado)),
                      const SizedBox(height: 10),
                      _buildCreditoDetailRow('Saldo Capital Pendiente', MoneyFormatter.format(saldoCapital), valueColor: AppConstants.errorRed),
                      const SizedBox(height: 10),
                      _buildCreditoDetailRow('Cuota Mensual Aprox.', MoneyFormatter.format(cuota), isBoldValue: true, valueColor: ClienteTheme.bcpBlue),
                      const SizedBox(height: 18),
                      
                      // View Cronograma Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => onViewCronograma(cr['id_credito']?.toString() ?? ''),
                          icon: const Icon(Icons.calendar_month_outlined, color: ClienteTheme.bcpBlue, size: 18),
                          label: const Text('Ver Cronograma de Pagos', style: TextStyle(color: ClienteTheme.bcpBlue, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: ClienteTheme.bcpBlue, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCreditoDetailRow(
    String label,
    String value, {
    Color valueColor = ClienteTheme.bcpTextDark,
    bool isBoldValue = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: ClienteTheme.bcpTextGrey, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }
}
