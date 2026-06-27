import 'package:flutter/material.dart';
import '../theme/cliente_theme.dart';

class OperacionesTabView extends StatelessWidget {
  // Callback actions for the 35 casuísticas
  final VoidCallback onDepositoSimple;
  final VoidCallback onRetiroCuenta;
  final VoidCallback onTransferCuentasPropias;
  final VoidCallback onTransferTerceros;
  final VoidCallback onTransferProgramada;
  final VoidCallback onHistorialTransferencias;

  final VoidCallback onPagoLuz;
  final VoidCallback onPagoAgua;
  final VoidCallback onPagoInternet;
  final VoidCallback onPagoGas;
  final VoidCallback onPagoTelefono;
  final VoidCallback onHistorialServicios;

  final VoidCallback onSolicitudPrestamo;
  final VoidCallback onPagoCuotaPrestamo;
  final VoidCallback onAdelantoPagoPrestamo;
  final VoidCallback onHistorialPagoPrestamo;
  final VoidCallback onCancelacionAnticipada;
  final VoidCallback onSimuladorCuotaBasico;
  final VoidCallback onSimuladorAmortizacion;
  final VoidCallback onSimuladorComparadorTasas;
  final VoidCallback onComparadorSimulaciones;

  final VoidCallback onAhorroProgramadoCrear;
  final VoidCallback onAhorroAbonar;
  final VoidCallback onMetaAhorroCrear;
  final VoidCallback onAporteMetaAhorro;
  final VoidCallback onAhorroAutomatico;
  final VoidCallback onPlazoFijoCrear;
  final VoidCallback onPlazoFijoRetirar;
  final VoidCallback onRetiroProgramado;

  final VoidCallback onRecargaCelular;
  final VoidCallback onHistorialRecargas;
  final VoidCallback onRegistroGastos;
  final VoidCallback onPresupuestosMes;
  final VoidCallback onVouchersOperaciones;
  final VoidCallback onHistorialDepositos;

  const OperacionesTabView({
    super.key,
    required this.onDepositoSimple,
    required this.onRetiroCuenta,
    required this.onTransferCuentasPropias,
    required this.onTransferTerceros,
    required this.onTransferProgramada,
    required this.onHistorialTransferencias,
    required this.onPagoLuz,
    required this.onPagoAgua,
    required this.onPagoInternet,
    required this.onPagoGas,
    required this.onPagoTelefono,
    required this.onHistorialServicios,
    required this.onSolicitudPrestamo,
    required this.onPagoCuotaPrestamo,
    required this.onAdelantoPagoPrestamo,
    required this.onHistorialPagoPrestamo,
    required this.onCancelacionAnticipada,
    required this.onSimuladorCuotaBasico,
    required this.onSimuladorAmortizacion,
    required this.onSimuladorComparadorTasas,
    required this.onComparadorSimulaciones,
    required this.onAhorroProgramadoCrear,
    required this.onAhorroAbonar,
    required this.onMetaAhorroCrear,
    required this.onAporteMetaAhorro,
    required this.onAhorroAutomatico,
    required this.onPlazoFijoCrear,
    required this.onPlazoFijoRetirar,
    required this.onRetiroProgramado,
    required this.onRecargaCelular,
    required this.onHistorialRecargas,
    required this.onRegistroGastos,
    required this.onPresupuestosMes,
    required this.onVouchersOperaciones,
    required this.onHistorialDepositos,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Operaciones Financieras BCP',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ClienteTheme.bcpBlue),
          ),
          const SizedBox(height: 4),
          const Text(
            'Realiza transferencias, pagos de servicios, simula o solicita tus préstamos y gestiona tus presupuestos.',
            style: TextStyle(fontSize: 12.5, color: ClienteTheme.bcpTextGrey),
          ),
          const SizedBox(height: 12),
          
          _buildCategoryHeader('Transferencias & Cuentas', Icons.swap_horiz_outlined),
          _buildGridOptions([
            _GridOptionData('Depósito Simple', Icons.arrow_upward_outlined, onDepositoSimple),
            _GridOptionData('Retirar Dinero', Icons.arrow_downward_outlined, onRetiroCuenta),
            _GridOptionData('Entre Cuentas', Icons.compare_arrows_outlined, onTransferCuentasPropias),
            _GridOptionData('A Terceros BCP', Icons.send_to_mobile_outlined, onTransferTerceros),
            _GridOptionData('Programar Pago', Icons.calendar_month_outlined, onTransferProgramada),
            _GridOptionData('Historial Trans.', Icons.history_outlined, onHistorialTransferencias),
          ]),
          
          _buildCategoryHeader('Pago de Servicios', Icons.receipt_long_outlined),
          _buildGridOptions([
            _GridOptionData('Luz (Enel/Sur)', Icons.lightbulb_outline, onPagoLuz),
            _GridOptionData('Agua (Sedapal)', Icons.water_drop_outlined, onPagoAgua),
            _GridOptionData('Internet & Cable', Icons.router_outlined, onPagoInternet),
            _GridOptionData('Gas (Cálidda)', Icons.local_fire_department_outlined, onPagoGas),
            _GridOptionData('Teléfono Fijo', Icons.phone_outlined, onPagoTelefono),
            _GridOptionData('Historial Serv.', Icons.view_list_outlined, onHistorialServicios),
          ]),

          _buildCategoryHeader('Préstamos & Simuladores', Icons.account_balance_outlined),
          _buildGridOptions([
            _GridOptionData('Pedir Préstamo', Icons.monetization_on_outlined, onSolicitudPrestamo),
            _GridOptionData('Pagar Cuota', Icons.fact_check_outlined, onPagoCuotaPrestamo),
            _GridOptionData('Adelantar Cuota', Icons.fast_forward_outlined, onAdelantoPagoPrestamo),
            _GridOptionData('Historial Pagos', Icons.receipt_long_outlined, onHistorialPagoPrestamo),
            _GridOptionData('Cancelar Todo', Icons.cancel_presentation_outlined, onCancelacionAnticipada),
            _GridOptionData('Simular Cuota', Icons.calculate_outlined, onSimuladorCuotaBasico),
            _GridOptionData('Cronograma Sim.', Icons.table_view_outlined, onSimuladorAmortizacion),
            _GridOptionData('Comparador TEA', Icons.multiline_chart_outlined, onSimuladorComparadorTasas),
            _GridOptionData('Comparar Sims.', Icons.difference_outlined, onComparadorSimulaciones),
          ]),

          _buildCategoryHeader('Ahorros & Plazos Fijos', Icons.savings_outlined),
          _buildGridOptions([
            _GridOptionData('Ahorro Program.', Icons.playlist_add_outlined, onAhorroProgramadoCrear),
            _GridOptionData('Abonar Ahorro', Icons.add_circle_outline, onAhorroAbonar),
            _GridOptionData('Meta de Ahorro', Icons.flag_outlined, onMetaAhorroCrear),
            _GridOptionData('Aportar a Meta', Icons.star_outline, onAporteMetaAhorro),
            _GridOptionData('Ahorro Auto %', Icons.track_changes_outlined, onAhorroAutomatico),
            _GridOptionData('Crear Plazo Fijo', Icons.lock_clock_outlined, onPlazoFijoCrear),
            _GridOptionData('Retirar Plazo', Icons.lock_open_outlined, onPlazoFijoRetirar),
            _GridOptionData('Retiro Program.', Icons.alarm_outlined, onRetiroProgramado),
          ]),

          _buildCategoryHeader('Bitácora & Recargas', Icons.phone_iphone_outlined),
          _buildGridOptions([
            _GridOptionData('Recarga Celular', Icons.phone_android_outlined, onRecargaCelular),
            _GridOptionData('Hist. Recargas', Icons.history_edu_outlined, onHistorialRecargas),
            _GridOptionData('Registrar Gasto', Icons.money_off_outlined, onRegistroGastos),
            _GridOptionData('Presupuesto Mes', Icons.auto_graph_outlined, onPresupuestosMes),
            _GridOptionData('Vouchers Emit.', Icons.verified_outlined, onVouchersOperaciones),
            _GridOptionData('Hist. Depósitos', Icons.file_download_outlined, onHistorialDepositos),
          ]),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: ClienteTheme.bcpBlue, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.5,
              color: ClienteTheme.bcpBlue,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridOptions(List<_GridOptionData> options) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: options.length,
      itemBuilder: (context, idx) {
        final opt = options[idx];
        return Container(
          decoration: ClienteTheme.cardDecoration(showShadow: true),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: opt.onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: ClienteTheme.bcpOrange.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(opt.icon, color: ClienteTheme.bcpOrange, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      opt.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: ClienteTheme.bcpBlue,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GridOptionData {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  _GridOptionData(this.title, this.icon, this.onTap);
}
