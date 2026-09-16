import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../controllers/adopter_form_controller.dart';

class AdoptionWizardScreen extends StatefulWidget {
  const AdoptionWizardScreen({super.key});

  @override
  State<AdoptionWizardScreen> createState() => _AdoptionWizardScreenState();
}

class _AdoptionWizardScreenState extends State<AdoptionWizardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdopterFormController>(
        context,
        listen: false,
      ).loadExistingForm();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdopterFormController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Formulario de Adoptante')),
          body: controller.isCompleted
              ? _buildSuccessView(context)
              : SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        children: [
                          // Barra de progreso de pasos
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            child: Row(
                              children: List.generate(4, (index) {
                                final isCurrentOrPast =
                                    index <= controller.currentStep;
                                return Expanded(
                                  child: Container(
                                    height: 6,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isCurrentOrPast
                                          ? AppTheme.primaryColor
                                          : Colors.grey[300],
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              _getStepTitle(controller.currentStep),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ),

                          if (controller.errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red[200]!),
                                ),
                                child: Text(
                                  controller.errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),

                          // Contenido del paso actual
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.all(24),
                              children: [
                                if (controller.currentStep == 0)
                                  _buildHousingStep(controller),
                                if (controller.currentStep == 1)
                                  _buildHouseholdStep(controller),
                                if (controller.currentStep == 2)
                                  _buildRoutineStep(controller),
                                if (controller.currentStep == 3)
                                  _buildCommitmentStep(controller),
                              ],
                            ),
                          ),

                          // Botones de Navegación
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Row(
                              children: [
                                if (controller.currentStep > 0)
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: controller.previousStep,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Atrás'),
                                    ),
                                  ),
                                if (controller.currentStep > 0)
                                  const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: controller.isSubmitting
                                        ? null
                                        : () {
                                            if (controller.currentStep < 3) {
                                              controller.nextStep();
                                            } else {
                                              controller.submitForm();
                                            }
                                          },
                                    child: controller.isSubmitting
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            controller.currentStep == 3
                                                ? 'Finalizar y Validar'
                                                : 'Siguiente',
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return '1. Tu Vivienda y Espacio';
      case 1:
        return '2. Convivencia y Familia';
      case 2:
        return '3. Rutina y Mascotas Actuales';
      case 3:
        return '4. Compromiso y Presupuesto';
      default:
        return '';
    }
  }

  Widget _buildHousingStep(AdopterFormController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de vivienda:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: c.form.housingType,
          isExpanded: true,
          items: const [
            DropdownMenuItem(
              value: 'apartment',
              child: Text(
                'Departamento / Piso',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: 'house',
              child: Text('Casa', overflow: TextOverflow.ellipsis),
            ),
            DropdownMenuItem(
              value: 'farm',
              child: Text('Quinta / Finca', overflow: TextOverflow.ellipsis),
            ),
            DropdownMenuItem(
              value: 'other',
              child: Text('Otro', overflow: TextOverflow.ellipsis),
            ),
          ],
          onChanged: (val) => c.updateHousing(
            type: val!,
            status: c.form.housingStatus,
            hasYard: c.form.hasYard,
            hasNetting: c.form.hasProtectiveNetting,
          ),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Situación de la vivienda:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: c.form.housingStatus,
          isExpanded: true,
          items: const [
            DropdownMenuItem(
              value: 'owned',
              child: Text('Propiedad Propia', overflow: TextOverflow.ellipsis),
            ),
            DropdownMenuItem(
              value: 'rented_allowed',
              child: Text(
                'Alquiler (Permiten mascotas)',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: 'rented_pending_permission',
              child: Text(
                'Alquiler (Aún consultando al dueño)',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          onChanged: (val) => c.updateHousing(
            type: c.form.housingType,
            status: val!,
            hasYard: c.form.hasYard,
            hasNetting: c.form.hasProtectiveNetting,
          ),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('¿Cuenta con patio o jardín cerrado?'),
          subtitle: const Text(
            'Importante para perros de tamaño grande o alta energía.',
          ),
          value: c.form.hasYard,
          onChanged: (val) => c.updateHousing(
            type: c.form.housingType,
            status: c.form.housingStatus,
            hasYard: val,
            hasNetting: c.form.hasProtectiveNetting,
          ),
        ),
        SwitchListTile(
          title: const Text('¿Tiene red de protección en balcones o ventanas?'),
          subtitle: const Text(
            'Requisito indispensable para la adopción de gatos en pisos altos.',
          ),
          value: c.form.hasProtectiveNetting,
          onChanged: (val) => c.updateHousing(
            type: c.form.housingType,
            status: c.form.housingStatus,
            hasYard: c.form.hasYard,
            hasNetting: val,
          ),
        ),
      ],
    );
  }

  Widget _buildHouseholdStep(AdopterFormController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿Con quién vives en el hogar?:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: c.form.householdMembers,
          isExpanded: true,
          items: const [
            DropdownMenuItem(
              value: 'alone',
              child: Text('Vivo solo/a', overflow: TextOverflow.ellipsis),
            ),
            DropdownMenuItem(
              value: 'couple',
              child: Text('En pareja', overflow: TextOverflow.ellipsis),
            ),
            DropdownMenuItem(
              value: 'family_with_young_kids',
              child: Text(
                'Familia con niños pequeños (<10 años)',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: 'family_with_teens',
              child: Text(
                'Familia con adolescentes / adultos',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: 'roommates',
              child: Text(
                'Compañeros de piso (Roommates)',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          onChanged: (val) => c.updateHousehold(
            members: val!,
            allAgree: c.form.allMembersAgree,
            hasAllergies: c.form.hasAllergies,
          ),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text(
            '¿Todos los miembros del hogar están de acuerdo con adoptar?',
          ),
          subtitle: const Text('Evita desacuerdos y devoluciones futuras.'),
          value: c.form.allMembersAgree,
          onChanged: (val) => c.updateHousehold(
            members: c.form.householdMembers,
            allAgree: val,
            hasAllergies: c.form.hasAllergies,
          ),
        ),
        SwitchListTile(
          title: const Text(
            '¿Alguien en la casa tiene alergia a pelos de animales?',
          ),
          value: c.form.hasAllergies,
          onChanged: (val) => c.updateHousehold(
            members: c.form.householdMembers,
            allAgree: c.form.allMembersAgree,
            hasAllergies: val,
          ),
        ),
      ],
    );
  }

  Widget _buildRoutineStep(AdopterFormController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Horas al día que la mascota estará sola: ${c.form.hoursPetAlonePerDay} horas',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Slider(
          value: c.form.hoursPetAlonePerDay.toDouble(),
          min: 0,
          max: 16,
          divisions: 16,
          label: '${c.form.hoursPetAlonePerDay} hs',
          onChanged: (val) => c.updateLifestyle(
            hoursAlone: val.round(),
            hasOtherPets: c.form.hasOtherPets,
            otherPetsDetails: c.form.otherPetsDetails,
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('¿Ya convives con otras mascotas actualmente?'),
          subtitle: const Text('Perros o gatos en el hogar.'),
          value: c.form.hasOtherPets,
          onChanged: (val) => c.updateLifestyle(
            hoursAlone: c.form.hoursPetAlonePerDay,
            hasOtherPets: val,
            otherPetsDetails: c.form.otherPetsDetails,
          ),
        ),
        if (c.form.hasOtherPets) ...[
          const SizedBox(height: 8),
          TextFormField(
            initialValue: c.form.otherPetsDetails,
            decoration: InputDecoration(
              labelText: 'Detalla tus mascotas actuales (edad, especie, si están castradas)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (val) => c.updateLifestyle(
              hoursAlone: c.form.hoursPetAlonePerDay,
              hasOtherPets: c.form.hasOtherPets,
              otherPetsDetails: val,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCommitmentStep(AdopterFormController c) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Presupuesto mensual para alimentación y vacunas'),
          subtitle: const Text(
            'Confirmo que puedo cubrir alimento de calidad, pipetas y controles.',
          ),
          value: c.form.monthlyBudgetConfirmed,
          onChanged: (val) => c.updateCommitment(
            budgetConfirmed: val,
            emergencyFund: c.form.emergencyFundAvailable,
            followUp: c.form.agreesToFollowUp,
            neutering: c.form.agreesToMandatoryNeutering,
          ),
        ),
        SwitchListTile(
          title: const Text('Fondo para emergencias veterinarias'),
          subtitle: const Text(
            'Capacidad de responder ante una urgencia médica o imprevisto.',
          ),
          value: c.form.emergencyFundAvailable,
          onChanged: (val) => c.updateCommitment(
            budgetConfirmed: c.form.monthlyBudgetConfirmed,
            emergencyFund: val,
            followUp: c.form.agreesToFollowUp,
            neutering: c.form.agreesToMandatoryNeutering,
          ),
        ),
        SwitchListTile(
          title: const Text('Acepto seguimiento post-adopción'),
          subtitle: const Text(
            'Envío de fotos periódicas y visitas acordadas con el refugio.',
          ),
          value: c.form.agreesToFollowUp,
          onChanged: (val) => c.updateCommitment(
            budgetConfirmed: c.form.monthlyBudgetConfirmed,
            emergencyFund: c.form.emergencyFundAvailable,
            followUp: val,
            neutering: c.form.agreesToMandatoryNeutering,
          ),
        ),
        SwitchListTile(
          title: const Text('Compromiso de castración / esterilización'),
          subtitle: const Text(
            'Esencial para el control ético de la sobrepoblación.',
          ),
          value: c.form.agreesToMandatoryNeutering,
          onChanged: (val) => c.updateCommitment(
            budgetConfirmed: c.form.monthlyBudgetConfirmed,
            emergencyFund: c.form.emergencyFundAvailable,
            followUp: c.form.agreesToFollowUp,
            neutering: val,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              size: 80,
              color: AppTheme.successGreen,
            ),
            const SizedBox(height: 24),
            const Text(
              '¡Formulario Completado!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tu perfil ha sido registrado como adoptante responsable. Ahora tus "Likes" se enviarán automáticamente acompañados de esta evaluación a los refugios.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ir a Ver Mascotas'),
            ),
          ],
        ),
      ),
    );
  }
}
