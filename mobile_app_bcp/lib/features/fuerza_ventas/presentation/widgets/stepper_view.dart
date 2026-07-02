import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:mobile_app_bcp/core/utils/date_formatter.dart';
import 'dart:math';
import '../theme/fuerza_ventas_theme.dart';

class StepperView extends StatelessWidget {
  final int currentStep;
  final String stepperEstadoCivil;
  final bool dniUploaded;
  final List<Map<String, dynamic>> draftsList;
  
  // Controllers passed from parent
  final TextEditingController nameController;
  final TextEditingController docController;
  final TextEditingController telController;
  final TextEditingController incomeController;
  final TextEditingController expenseController;
  final TextEditingController destinoController;
  final TextEditingController montoController;
  final TextEditingController plazoController;
  final SignatureController sigController;

  // Callbacks
  final Function(int step) onStepChanged;
  final Function(String estadoCivil) onEstadoCivilChanged;
  final VoidCallback onSaveDraft;
  final VoidCallback onResetForm;
  final Function(String idBorrador) onDeleteDraft;
  final Function(Map<String, dynamic> draft) onLoadDraft;
  final VoidCallback onSimulateFoto;
  final VoidCallback onSubmit;

  const StepperView({
    super.key,
    required this.currentStep,
    required this.stepperEstadoCivil,
    required this.dniUploaded,
    required this.draftsList,
    required this.nameController,
    required this.docController,
    required this.telController,
    required this.incomeController,
    required this.expenseController,
    required this.destinoController,
    required this.montoController,
    required this.plazoController,
    required this.sigController,
    required this.onStepChanged,
    required this.onEstadoCivilChanged,
    required this.onSaveDraft,
    required this.onResetForm,
    required this.onDeleteDraft,
    required this.onLoadDraft,
    required this.onSimulateFoto,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: FuerzaVentasTheme.cardDark.withOpacity(0.5),
            child: const TabBar(
              dividerColor: Colors.white10,
              indicatorColor: FuerzaVentasTheme.bcpOrange,
              labelColor: FuerzaVentasTheme.neonOrange,
              unselectedLabelColor: Colors.white60,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(text: 'Solicitud'),
                Tab(text: 'Borradores'),
                Tab(text: 'Simulador'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildStepperForm(context),
                _buildDraftsPanel(context),
                _buildQuickSimulator(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperForm(BuildContext context) {
    return Column(
      children: [
        // Top options actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: ElevatedButton.icon(
                  onPressed: onSaveDraft,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Borrador local', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FuerzaVentasTheme.inputFieldColor,
                    foregroundColor: Colors.white,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: OutlinedButton.icon(
                  onPressed: onResetForm,
                  icon: const Icon(Icons.clear_all_outlined, size: 18),
                  label: const Text('Limpiar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FuerzaVentasTheme.neonRed,
                    side: const BorderSide(color: FuerzaVentasTheme.neonRed, width: 1.2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: FuerzaVentasTheme.neonCyan,
                onPrimary: Colors.black,
                secondary: FuerzaVentasTheme.bcpOrange,
                surface: FuerzaVentasTheme.cardDark,
              ),
            ),
            child: Stepper(
              type: StepperType.vertical,
              currentStep: currentStep,
              onStepTapped: onStepChanged,
              onStepCancel: () {
                if (currentStep > 0) {
                  onStepChanged(currentStep - 1);
                }
              },
              onStepContinue: () {
                if (currentStep < 3) {
                  onStepChanged(currentStep + 1);
                }
              },
              steps: [
                Step(
                  title: const Text(
                    'Paso 1: Solicitante',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  isActive: currentStep >= 0,
                  state: currentStep > 0 ? StepState.complete : StepState.editing,
                  content: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: FuerzaVentasTheme.glassDecoration(opacity: 0.3),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Nombre Completo',
                            labelStyle: const TextStyle(color: Colors.white60),
                            prefixIcon: const Icon(Icons.person_outline, color: FuerzaVentasTheme.neonCyan),
                            filled: true,
                            fillColor: FuerzaVentasTheme.inputFieldColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: docController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Documento DNI',
                            labelStyle: const TextStyle(color: Colors.white60),
                            prefixIcon: const Icon(Icons.badge_outlined, color: FuerzaVentasTheme.neonCyan),
                            filled: true,
                            fillColor: FuerzaVentasTheme.inputFieldColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          dropdownColor: FuerzaVentasTheme.cardDark,
                          decoration: InputDecoration(
                            labelText: 'Estado Civil',
                            labelStyle: const TextStyle(color: Colors.white60),
                            prefixIcon: const Icon(Icons.favorite_outline, color: FuerzaVentasTheme.neonCyan),
                            filled: true,
                            fillColor: FuerzaVentasTheme.inputFieldColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          value: stepperEstadoCivil,
                          items: ['SOLTERO', 'CASADO', 'CONVIVIENTE', 'DIVORCIADO'].map((e) {
                            return DropdownMenuItem(value: e, child: Text(e));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) onEstadoCivilChanged(val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Step(
                  title: const Text(
                    'Paso 2: Datos del Negocio',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  isActive: currentStep >= 1,
                  state: currentStep > 1 ? StepState.complete : (currentStep == 1 ? StepState.editing : StepState.disabled),
                  content: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: FuerzaVentasTheme.glassDecoration(opacity: 0.3),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: incomeController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Ingresos Mensuales Estimados (S/)',
                            labelStyle: const TextStyle(color: Colors.white60),
                            prefixIcon: const Icon(Icons.trending_up_outlined, color: FuerzaVentasTheme.neonCyan),
                            filled: true,
                            fillColor: FuerzaVentasTheme.inputFieldColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: expenseController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Gastos Mensuales Estimados (S/)',
                            labelStyle: const TextStyle(color: Colors.white60),
                            prefixIcon: const Icon(Icons.trending_down_outlined, color: FuerzaVentasTheme.neonCyan),
                            filled: true,
                            fillColor: FuerzaVentasTheme.inputFieldColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: destinoController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Destino del Crédito',
                            labelStyle: const TextStyle(color: Colors.white60),
                            prefixIcon: const Icon(Icons.business_center_outlined, color: FuerzaVentasTheme.neonCyan),
                            filled: true,
                            fillColor: FuerzaVentasTheme.inputFieldColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Step(
                  title: const Text(
                    'Paso 3: Condiciones del Crédito',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  isActive: currentStep >= 2,
                  state: currentStep > 2 ? StepState.complete : (currentStep == 2 ? StepState.editing : StepState.disabled),
                  content: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: FuerzaVentasTheme.glassDecoration(opacity: 0.3),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: montoController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Monto Solicitado (S/)',
                            labelStyle: const TextStyle(color: Colors.white60),
                            prefixIcon: const Icon(Icons.monetization_on_outlined, color: FuerzaVentasTheme.neonCyan),
                            filled: true,
                            fillColor: FuerzaVentasTheme.inputFieldColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: plazoController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Plazo en meses',
                            labelStyle: const TextStyle(color: Colors.white60),
                            prefixIcon: const Icon(Icons.calendar_today_outlined, color: FuerzaVentasTheme.neonCyan),
                            filled: true,
                            fillColor: FuerzaVentasTheme.inputFieldColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _mostrarSimulacionFrancesa(context),
                            icon: const Icon(Icons.calculate_outlined),
                            label: const Text('Simular Amortización Francesa', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FuerzaVentasTheme.bcpBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Step(
                  title: const Text(
                    'Paso 4: Conformidad y Firma',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  isActive: currentStep >= 3,
                  state: currentStep == 3 ? StepState.editing : StepState.disabled,
                  content: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: FuerzaVentasTheme.glassDecoration(opacity: 0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Document upload
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.camera_alt_outlined,
                            color: dniUploaded ? FuerzaVentasTheme.neonGreen : Colors.white60,
                            size: 26,
                          ),
                          title: const Text(
                            'Foto DNI (Blur Check)',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            dniUploaded ? 'Fotografía Aprobada ✓' : 'Capturar fotografía para procesar nitidez',
                            style: TextStyle(color: dniUploaded ? FuerzaVentasTheme.neonGreen : Colors.white38, fontSize: 12),
                          ),
                          trailing: ElevatedButton(
                            onPressed: onSimulateFoto,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FuerzaVentasTheme.inputFieldColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Capturar'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Firma táctil digital:',
                          style: TextStyle(color: Colors.white70, fontSize: 13.5, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: MediaQuery.of(context).size.height * 0.18,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white24, width: 1.5),
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Signature(
                              controller: sigController,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => sigController.clear(),
                              icon: const Icon(Icons.clear, color: FuerzaVentasTheme.neonRed, size: 18),
                              label: const Text('Borrar Firma', style: TextStyle(color: FuerzaVentasTheme.neonRed, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: FuerzaVentasTheme.bcpOrangeGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: FuerzaVentasTheme.neonGlowShadow(color: FuerzaVentasTheme.bcpOrange, opacity: 0.25),
                            ),
                            child: ElevatedButton(
                              onPressed: onSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                surfaceTintColor: Colors.transparent,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Enviar al Comité', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _mostrarSimulacionFrancesa(BuildContext context) {
    final double tea = 25.5;
    final double amount = (double.tryParse(montoController.text) ?? 5000.0).clamp(0.0, 9999999.0);
    final int plazo = (int.tryParse(plazoController.text) ?? 12).clamp(1, 120);

    final double tem = pow(1 + (tea / 100), 1 / 12) - 1;
    final double cuota = (amount * tem) / (1 - pow(1 + tem, -plazo));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FuerzaVentasTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.white10),
        ),
        title: const Text(
          'Cronograma Francés Simulado',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 320,
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monto: S/ $amount  |  Plazo: $plazo meses',
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
              Text(
                'Cuota estimada: S/ ${cuota.toStringAsFixed(2)}',
                style: const TextStyle(color: FuerzaVentasTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: plazo,
                  itemBuilder: (c, idx) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Mes ${idx + 1}', style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                          Text('S/ ${cuota.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar', style: TextStyle(color: FuerzaVentasTheme.neonCyan)),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftsPanel(BuildContext context) {
    if (draftsList.isEmpty) {
      return const Center(
        child: Text(
          'No tienes borradores guardados localmente.',
          style: TextStyle(color: Colors.white30, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      itemCount: draftsList.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, idx) {
        final d = draftsList[idx];
        return Dismissible(
          key: Key(d['id_borrador']),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) => onDeleteDraft(d['id_borrador']),
          background: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.only(right: 20),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              color: FuerzaVentasTheme.neonRed.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline, color: FuerzaVentasTheme.neonRed, size: 28),
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: FuerzaVentasTheme.glassDecoration(),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              title: Text(
                d['nombre_cliente'] ?? 'Borrador sin nombre',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Paso alcanzado: ${d['paso_alcanzado'] + 1} · Fecha: ${DateFormatter.formatShortString(d['fecha_edicion'])}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: FuerzaVentasTheme.neonCyan),
              onTap: () {
                final Map<String, dynamic> datos = d['datos'] is String 
                  ? {} // Handle if string encoded in older versions, fallback
                  : Map<String, dynamic>.from(d['datos'] ?? {});
                
                onLoadDraft({
                  'paso_alcanzado': d['paso_alcanzado'],
                  'nombre_cliente': d['nombre_cliente'],
                  'datos': datos,
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickSimulator(BuildContext context) {
    final double tea = 25.5;
    final double amount = (double.tryParse(montoController.text) ?? 5000.0).clamp(0.0, 9999999.0);
    final int plazo = (int.tryParse(plazoController.text) ?? 12).clamp(1, 120);

    final double tem = pow(1 + (tea / 100), 1 / 12) - 1;
    final double cuota = (amount * tem) / (1 - pow(1 + tem, -plazo));

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: FuerzaVentasTheme.glassDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Simulador Rápido de Crédito',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FuerzaVentasTheme.neonCyan),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: montoController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setLocalState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Monto Solicitado (S/)',
                    labelStyle: const TextStyle(color: Colors.white60),
                    filled: true,
                    fillColor: FuerzaVentasTheme.inputFieldColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: plazoController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setLocalState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Plazo en Meses',
                    labelStyle: const TextStyle(color: Colors.white60),
                    filled: true,
                    fillColor: FuerzaVentasTheme.inputFieldColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Result Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: FuerzaVentasTheme.bcpBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: FuerzaVentasTheme.neonCyan.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Cuota Mensual:', style: TextStyle(color: Colors.white70, fontSize: 13.5)),
                          Text(
                            'S/ ${cuota.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: FuerzaVentasTheme.neonCyan),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12, height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total a pagar:', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                          Text(
                            'S/ ${(cuota * plazo).toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TEA Referencial:', style: TextStyle(color: Colors.white60, fontSize: 11.5)),
                          Text(
                            '$tea%',
                            style: const TextStyle(color: FuerzaVentasTheme.neonOrange, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}
