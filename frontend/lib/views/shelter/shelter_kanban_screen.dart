import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class KanbanApplication {
  final String id;
  final String adopterName;
  final String petName;
  final String petSpecies;
  final int matchPercentage;
  final String housingType;
  final bool hasYard;
  final bool hasNetting;
  final int hoursAlone;
  String status; // 'new' | 'reviewing' | 'interview' | 'adopted'

  KanbanApplication({
    required this.id,
    required this.adopterName,
    required this.petName,
    required this.petSpecies,
    required this.matchPercentage,
    required this.housingType,
    required this.hasYard,
    required this.hasNetting,
    required this.hoursAlone,
    required this.status,
  });
}

class ShelterKanbanScreen extends StatefulWidget {
  const ShelterKanbanScreen({super.key});

  @override
  State<ShelterKanbanScreen> createState() => _ShelterKanbanScreenState();
}

class _ShelterKanbanScreenState extends State<ShelterKanbanScreen> {
  late List<KanbanApplication> _applications;

  @override
  void initState() {
    super.initState();
    _applications = [
      KanbanApplication(
        id: '1',
        adopterName: 'Sofía Navarro',
        petName: 'Rocky',
        petSpecies: 'dog',
        matchPercentage: 94,
        housingType: 'Casa con patio cerrado',
        hasYard: true,
        hasNetting: false,
        hoursAlone: 4,
        status: 'new',
      ),
      KanbanApplication(
        id: '2',
        adopterName: 'Martín y Lucas',
        petName: 'Luna',
        petSpecies: 'cat',
        matchPercentage: 98,
        housingType: 'Departamento 3 amb.',
        hasYard: false,
        hasNetting: true,
        hoursAlone: 5,
        status: 'reviewing',
      ),
      KanbanApplication(
        id: '3',
        adopterName: 'Familia Morales',
        petName: 'Simba',
        petSpecies: 'dog',
        matchPercentage: 90,
        housingType: 'Casa quinta en zona norte',
        hasYard: true,
        hasNetting: false,
        hoursAlone: 3,
        status: 'interview',
      ),
      KanbanApplication(
        id: '4',
        adopterName: 'Camila Ríos',
        petName: 'Mía',
        petSpecies: 'cat',
        matchPercentage: 96,
        housingType: 'Depto con balcón cerrado',
        hasYard: false,
        hasNetting: true,
        hoursAlone: 4,
        status: 'adopted',
      ),
    ];
  }

  void _moveStatus(KanbanApplication app, String newStatus) {
    setState(() {
      app.status = newStatus;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Solicitud de ${app.adopterName} movida a ${_columnTitle(newStatus)}')),
    );
  }

  String _columnTitle(String status) {
    switch (status) {
      case 'new':
        return 'Nuevas Solicitudes';
      case 'reviewing':
        return 'En Evaluación';
      case 'interview':
        return 'Visita Programada';
      case 'adopted':
        return 'Adopción Concretada 🎉';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tablero de Adopciones'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;

          final columns = [
            _buildColumn('new', 'Nuevas Solicitudes', Colors.blue, Icons.inbox_outlined),
            _buildColumn('reviewing', 'En Evaluación', Colors.orange, Icons.find_in_page_outlined),
            _buildColumn('interview', 'Visita Programada', Colors.purple, Icons.calendar_today_outlined),
            _buildColumn('adopted', 'Adoptado 🎉', Colors.green, Icons.celebration_outlined),
          ];

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: columns.map((col) => Expanded(child: col)).toList(),
            );
          } else {
            // Versión responsiva móvil con TabBar navegable
            final newCount = _applications.where((a) => a.status == 'new').length;
            final revCount = _applications.where((a) => a.status == 'reviewing').length;
            final intCount = _applications.where((a) => a.status == 'interview').length;
            final adpCount = _applications.where((a) => a.status == 'adopted').length;

            return DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  TabBar(
                    isScrollable: true,
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: AppTheme.textMuted,
                    indicatorColor: AppTheme.primaryColor,
                    tabAlignment: TabAlignment.start,
                    tabs: [
                      Tab(text: 'Nuevas ($newCount)'),
                      Tab(text: 'Evaluación ($revCount)'),
                      Tab(text: 'Visitas ($intCount)'),
                      Tab(text: 'Adoptados 🎉 ($adpCount)'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: columns,
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildColumn(String statusKey, String title, MaterialColor color, IconData icon) {
    final apps = _applications.where((a) => a.status == statusKey).toList();

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
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color[900]),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: color[200], borderRadius: BorderRadius.circular(12)),
                child: Text(
                  '${apps.length}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color[900], fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: apps.isEmpty
                ? Center(
                    child: Text('Sin postulaciones', style: TextStyle(color: color[400], fontSize: 13)),
                  )
                : ListView.builder(
                    itemCount: apps.length,
                    itemBuilder: (context, index) {
                      final app = apps[index];
                      return _buildApplicationCard(app);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(KanbanApplication app) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    app.adopterName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${app.matchPercentage}% Match',
                    style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Interesado/a en: ${app.petName} (${app.petSpecies == 'dog' ? 'Perro' : 'Gato'})',
                style: const TextStyle(fontSize: 13, color: AppTheme.textDark)),
            const SizedBox(height: 4),
            Text('Vivienda: ${app.housingType}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => _showAdopterFormModal(app),
                  child: const Text('Ver Formulario', style: TextStyle(fontSize: 12)),
                ),
                if (app.status == 'new')
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                    onPressed: () => _moveStatus(app, 'reviewing'),
                    child: const Text('Evaluar', style: TextStyle(fontSize: 12)),
                  )
                else if (app.status == 'reviewing')
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                    onPressed: () => _moveStatus(app, 'interview'),
                    child: const Text('Agendar Visita', style: TextStyle(fontSize: 12)),
                  )
                else if (app.status == 'interview')
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: () => _moveStatus(app, 'adopted'),
                    child: const Text('Concretar 🎉', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAdopterFormModal(KanbanApplication app) {
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
                'Cuestionario de ${app.adopterName}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('Compatibilidad calculada: ${app.matchPercentage}% con ${app.petName}'),
              const Divider(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _infoRow('Vivienda', app.housingType),
                    _infoRow('Tiene Patio Cerrado', app.hasYard ? 'Sí' : 'No'),
                    _infoRow('Red de Balcón/Ventana', app.hasNetting ? 'Sí (Instalada)' : 'No posee'),
                    _infoRow('Horas que pasará solo', '${app.hoursAlone} horas al día'),
                    _infoRow('Solvencia Veterinaria', 'Confirmada con fondo de emergencias'),
                    _infoRow('Acuerdo de Todos los Miembros', 'Todos de acuerdo en el hogar'),
                    _infoRow('Acepta Seguimiento', 'Sí (Fotos periódicas y visitas)'),
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
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
