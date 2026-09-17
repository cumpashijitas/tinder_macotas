import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../controllers/history_controller.dart';
import '../../models/history_models.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HistoryController>(context, listen: false).load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<HistoryController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contratos y Visitas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Contratos (${controller.contracts.length})'),
            Tab(text: 'Visitas (${controller.visits.length})'),
          ],
        ),
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildContractsList(controller.contracts),
                _buildVisitsList(controller.visits),
              ],
            ),
    );
  }

  Widget _buildContractsList(List<ContractHistoryItem> contracts) {
    if (contracts.isEmpty) {
      return const Center(
        child: Text('Todavía no tenés contratos.', style: TextStyle(color: AppTheme.textMuted)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: contracts.length,
      itemBuilder: (context, index) {
        final c = contracts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: c.petPhoto != null ? NetworkImage(c.petPhoto!) : null,
              backgroundColor: Colors.grey[200],
              child: c.petPhoto == null ? const Icon(Icons.pets, color: Colors.grey) : null,
            ),
            title: Text(c.petName ?? 'Mascota'),
            subtitle: Text(
              c.fullySigned
                  ? 'Firmado por ambas partes ✅'
                  : 'Firmas: ${c.signedByAdopter ? "Adoptante ✅" : "Adoptante ⏳"} • ${c.signedByShelter ? "Refugio ✅" : "Refugio ⏳"}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Icon(
              c.fullySigned ? Icons.verified : Icons.hourglass_empty,
              color: c.fullySigned ? AppTheme.successGreen : Colors.amber,
            ),
          ),
        );
      },
    );
  }

  Widget _buildVisitsList(List<VisitHistoryItem> visits) {
    if (visits.isEmpty) {
      return const Center(
        child: Text('Todavía no tenés visitas agendadas.', style: TextStyle(color: AppTheme.textMuted)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: visits.length,
      itemBuilder: (context, index) {
        final v = visits[index];
        final statusColor = switch (v.status) {
          'confirmed' => AppTheme.successGreen,
          'declined' || 'cancelled' => AppTheme.rejectRed,
          'completed' => Colors.blue,
          _ => Colors.amber,
        };

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: v.petPhoto != null ? NetworkImage(v.petPhoto!) : null,
              backgroundColor: Colors.grey[200],
              child: v.petPhoto == null ? const Icon(Icons.pets, color: Colors.grey) : null,
            ),
            title: Text(v.petName ?? 'Mascota'),
            subtitle: Text(
              '${v.proposedAt.day}/${v.proposedAt.month}/${v.proposedAt.year} ${v.proposedAt.hour.toString().padLeft(2, '0')}:${v.proposedAt.minute.toString().padLeft(2, '0')}'
              '${v.notes != null && v.notes!.isNotEmpty ? '\n${v.notes}' : ''}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                v.statusLabel,
                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }
}
