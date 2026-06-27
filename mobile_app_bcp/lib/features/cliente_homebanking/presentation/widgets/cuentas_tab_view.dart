import 'package:flutter/material.dart';
import 'package:mobile_app_bcp/core/config/app_constants.dart';
import 'package:mobile_app_bcp/core/utils/money_formatter.dart';
import 'package:mobile_app_bcp/core/utils/date_formatter.dart';
import '../theme/cliente_theme.dart';

class CuentasTabView extends StatelessWidget {
  final List<dynamic> cuentas;
  final List<dynamic> tarjetas;
  final List<dynamic> movimientos;

  const CuentasTabView({
    super.key,
    required this.cuentas,
    required this.tarjetas,
    required this.movimientos,
  });

  @override
  Widget build(BuildContext context) {
    double totalBalance = 0.0;
    if (cuentas.isNotEmpty) {
      totalBalance = cuentas
          .map((c) => double.tryParse(c['saldo_disponible'].toString()) ?? 0.0)
          .reduce((a, b) => a + b);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BCP Account Balance Card with Gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: ClienteTheme.headerGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: ClienteTheme.bcpBlue.withOpacity(0.25),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saldo total disponible aproximado:',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  MoneyFormatter.format(totalBalance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.white12,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_outlined, color: ClienteTheme.bcpOrange, size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Tus cuentas están protegidas por Token Digital BCP',
                      style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Accounts List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mis Cuentas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ClienteTheme.bcpBlue),
              ),
              const Icon(Icons.arrow_forward_ios_outlined, size: 14, color: ClienteTheme.bcpTextGrey),
            ],
          ),
          const SizedBox(height: 10),
          if (cuentas.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: ClienteTheme.cardDecoration(),
              child: const Center(
                child: Text(
                  'No posee cuentas activas',
                  style: TextStyle(color: ClienteTheme.bcpTextGrey),
                ),
              ),
            )
          else
            ...cuentas.map((c) {
              final double saldo = double.tryParse(c['saldo_disponible'].toString()) ?? 0.0;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: ClienteTheme.cardDecoration(),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE6F0FA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet_outlined, color: ClienteTheme.bcpBlue, size: 22),
                  ),
                  title: Text(
                    c['numero_cuenta'] ?? 'Cuenta Soles',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: ClienteTheme.bcpTextDark, fontSize: 14.5),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'CCI: ${c['cci'] ?? ""}',
                      style: const TextStyle(color: ClienteTheme.bcpTextGrey, fontSize: 12),
                    ),
                  ),
                  trailing: Text(
                    MoneyFormatter.format(saldo),
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: ClienteTheme.bcpBlue),
                  ),
                ),
              );
            }),
          const SizedBox(height: 20),

          // Cards List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mis Tarjetas BCP',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ClienteTheme.bcpBlue),
              ),
              const Icon(Icons.arrow_forward_ios_outlined, size: 14, color: ClienteTheme.bcpTextGrey),
            ],
          ),
          const SizedBox(height: 10),
          if (tarjetas.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: ClienteTheme.cardDecoration(),
              child: const Center(
                child: Text(
                  'No posee tarjetas asociadas',
                  style: TextStyle(color: ClienteTheme.bcpTextGrey),
                ),
              ),
            )
          else
            ...tarjetas.map((t) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: ClienteTheme.cardDecoration(),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF0E6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.credit_card_outlined, color: ClienteTheme.bcpOrange, size: 22),
                    ),
                    title: Text(
                      t['numero_enmascarado'] ?? 'Tarjeta BCP',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: ClienteTheme.bcpTextDark, fontSize: 14.5),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Vence: ${t['fecha_vencimiento'] ?? ""}',
                        style: const TextStyle(color: ClienteTheme.bcpTextGrey, fontSize: 12),
                      ),
                    ),
                    trailing: Text(
                      (t['estado'] ?? 'ACTIVA').toString().toUpperCase(),
                      style: const TextStyle(
                        color: AppConstants.exitoGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                )),
          const SizedBox(height: 20),

          // Movements List
          const Text(
            'Últimos Movimientos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ClienteTheme.bcpBlue),
          ),
          const SizedBox(height: 10),
          if (movimientos.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: ClienteTheme.cardDecoration(),
              child: const Center(
                child: Text(
                  'No registra movimientos recientes',
                  style: TextStyle(color: ClienteTheme.bcpTextGrey),
                ),
              ),
            )
          else
            ...movimientos.map((m) {
              final double val = double.tryParse(m['monto'].toString()) ?? 0.0;
              final isExpense = val < 0;
              final color = isExpense ? AppConstants.errorRed : AppConstants.exitoGreen;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: ClienteTheme.cardDecoration(showShadow: false, border: Border.all(color: Colors.black.withOpacity(0.03))),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExpense ? Icons.arrow_downward_outlined : Icons.arrow_upward_outlined,
                      color: color,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    m['descripcion'] ?? 'Movimiento bancario',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: ClienteTheme.bcpTextDark, fontSize: 13.5),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      DateFormatter.formatShortString(m['fecha_movimiento'] ?? ''),
                      style: const TextStyle(color: ClienteTheme.bcpTextGrey, fontSize: 11.5),
                    ),
                  ),
                  trailing: Text(
                    MoneyFormatter.format(val),
                    style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
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
