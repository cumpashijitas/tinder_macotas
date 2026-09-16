import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../controllers/matches_controller.dart';
import '../../models/match_model.dart';

class ShelterKanbanScreen extends StatefulWidget {
  const ShelterKanbanScreen({super.key});

  @override
  State<ShelterKanbanScreen> createState() => _ShelterKanbanScreenState();
}

class _ShelterKanbanScreenState extends State<ShelterKanbanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MatchesController>(context, listen: false).loadMatches();
    });
  }

  static const _columns = [
    ('pending_review', 'Nuevas Solicitudes', Colors.blue, Icons.inbox_outlined),
    (
      'approved_for_chat',
      'Aprobadas (Chat)',
      Colors.teal,
      Icons.chat_bubble_outline,
    ),
    (
      'interview_scheduled',
      'Visita Programada',
      Colors.purple,
      Icons.calendar_today_outlined,
    ),
    (
      'adoption_finalized',
      'Adoptado 🎉',
      Colors.green,
      Icons.celebration_outlined,
    ),
    ('rejected', 'Rechazadas', Colors.grey, Icons.block_outlined),
  ];

  String _columnTitle(String status) {
    for (final c in _columns) {
      if (c.$1 == status) return c.$2;
    }
    return status;
  }

  Future<void> _moveStatus(MatchModel match, String newStatus) async {
    final controller = Provider.of<MatchesController>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await controller.updateStatus(match.id, newStatus);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Solicitud de ${match.adopterName ?? 'adoptante'} movida a ${_columnTitle(newStatus)}'
              : controller.errorMessage ?? 'No se pudo actualizar la solicitud',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<MatchesController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tablero de Adopciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.isLoading
                ? null
                : () => controller.loadMatches(),
          ),
        ],
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 1000;

                final columns = _columns
                    .map(
                      (c) => _buildColumn(
                        controller.matches,
                        c.$1,
                        c.$2,
                        c.$3,
                        c.$4,
                      ),
                    )
                    .toList();

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: columns
                        .map((col) => Expanded(child: col))
                        .toList(),
                  );
                }

                final counts = {
                  for (final c in _columns)
                    c.$1: controller.matches
                        .where((m) => m.status == c.$1)
                        .length,
                };

                return DefaultTabController(
                  length: _columns.length,
                  child: Column(
                    children: [
                      TabBar(
                        isScrollable: true,
                        labelColor: AppTheme.primaryColor,
                        unselectedLabelColor: AppTheme.textMuted,
                        indicatorColor: AppTheme.primaryColor,
                        tabAlignment: TabAlignment.start,
                        tabs: _columns
                            .map((c) => Tab(text: '${c.$2} (${counts[c.$1]})'))
                            .toList(),
                      ),
                      Expanded(child: TabBarView(children: columns)),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildColumn(
    List<MatchModel> matches,
    String statusKey,
    String title,
    MaterialColor color,
    IconData icon,
  ) {
    final items = matches.where((m) => m.status == statusKey).toList();

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color[800], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color[900],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${items.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color[900],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'Sin postulaciones',
                      style: TextStyle(color: color[400], fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) =>
                        _buildApplicationCard(items[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(MatchModel match) {
    final pet = match.pet;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              match.adopterName ?? 'Adoptante',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              'Interesado/a en: ${pet?.name ?? '-'} (${pet?.species == 'cat'
                  ? 'Gato'
                  : pet?.species == 'dog'
                  ? 'Perro'
                  : 'Otro'})',
              style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
            ),
            if (match.adopterForm != null) ...[
              const SizedBox(height: 4),
              Text(
                'Vivienda: ${match.adopterForm!.housingTypeLabel} • ${match.adopterForm!.housingStatusLabel}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => _showAdopterFormModal(match),
                  child: const Text(
                    'Ver Formulario',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    if (match.status == 'pending_review') ...[
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.rejectRed,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onPressed: () => _moveStatus(match, 'rejected'),
                        child: const Text(
                          'Rechazar',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () =>
                            _moveStatus(match, 'approved_for_chat'),
                        child: const Text(
                          'Aprobar',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ] else if (match.status == 'approved_for_chat')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () =>
                            _moveStatus(match, 'interview_scheduled'),
                        child: const Text(
                          'Programar Visita',
                          style: TextStyle(fontSize: 12),
                        ),
                      )
                    else if (match.status == 'interview_scheduled')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () =>
                            _moveStatus(match, 'adoption_finalized'),
                        child: const Text(
                          'Concretar 🎉',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAdopterFormModal(MatchModel match) {
    final form = match.adopterForm;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cuestionario de ${match.adopterName ?? 'Adoptante'}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text('Interesado/a en: ${match.pet?.name ?? '-'}'),
              const Divider(height: 24),
              Expanded(
                child: form == null
                    ? const Center(
                        child: Text(
                          'Este adoptante todavía no completó el cuestionario de idoneidad.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      )
                    : ListView(
                        children: [
                          _infoRow('Vivienda', form.housingTypeLabel),
                          _infoRow(
                            'Condición de ocupación',
                            form.housingStatusLabel,
                          ),
                          _infoRow(
                            'Tiene patio cerrado',
                            form.hasYard ? 'Sí' : 'No',
                          ),
                          _infoRow(
                            'Red de balcón/ventana',
                            form.hasProtectiveNetting
                                ? 'Sí (instalada)'
                                : 'No posee',
                          ),
                          _infoRow('Convivencia', form.householdMembersLabel),
                          _infoRow(
                            'Todos de acuerdo en el hogar',
                            form.allMembersAgree ? 'Sí' : 'No',
                          ),
                          _infoRow(
                            'Horas que pasará solo',
                            '${form.hoursPetAlonePerDay} horas al día',
                          ),
                          _infoRow(
                            'Tiene otras mascotas',
                            form.hasOtherPets
                                ? (form.otherPetsDetails ?? 'Sí')
                                : 'No',
                          ),
                          _infoRow(
                            'Presupuesto mensual confirmado',
                            form.monthlyBudgetConfirmed ? 'Sí' : 'No',
                          ),
                          _infoRow(
                            'Fondo de emergencia disponible',
                            form.emergencyFundAvailable ? 'Sí' : 'No',
                          ),
                          _infoRow(
                            'Acepta seguimiento',
                            form.agreesToFollowUp ? 'Sí' : 'No',
                          ),
                          _infoRow(
                            'Acepta castración obligatoria',
                            form.agreesToMandatoryNeutering ? 'Sí' : 'No',
                          ),
                          if (form.evaluationScore != null)
                            _infoRow(
                              'Puntaje de idoneidad',
                              '${form.evaluationScore!.toStringAsFixed(0)}/100',
                            ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
