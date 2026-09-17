/// Modelos livianos para el historial consolidado (contratos y visitas),
/// que llegan del backend con el match y la mascota ya embebidos.
class ContractHistoryItem {
  final String id;
  final String matchId;
  final bool signedByAdopter;
  final bool signedByShelter;
  final String? petName;
  final String? petPhoto;
  final String matchStatus;
  final DateTime createdAt;

  ContractHistoryItem({
    required this.id,
    required this.matchId,
    required this.signedByAdopter,
    required this.signedByShelter,
    this.petName,
    this.petPhoto,
    required this.matchStatus,
    required this.createdAt,
  });

  factory ContractHistoryItem.fromJson(Map<String, dynamic> json) {
    final match = json['matches'] as Map<String, dynamic>?;
    final pet = match?['pets'] as Map<String, dynamic>?;
    final photos = (pet?['photos'] as List<dynamic>?)?.cast<String>();

    return ContractHistoryItem(
      id: json['id'] as String? ?? '',
      matchId: json['match_id'] as String? ?? '',
      signedByAdopter: json['signed_by_adopter'] as bool? ?? false,
      signedByShelter: json['signed_by_shelter'] as bool? ?? false,
      petName: pet?['name'] as String?,
      petPhoto: (photos != null && photos.isNotEmpty) ? photos.first : null,
      matchStatus: match?['status'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  bool get fullySigned => signedByAdopter && signedByShelter;
}

class VisitHistoryItem {
  final String id;
  final String matchId;
  final String status;
  final DateTime proposedAt;
  final String? notes;
  final String? petName;
  final String? petPhoto;

  VisitHistoryItem({
    required this.id,
    required this.matchId,
    required this.status,
    required this.proposedAt,
    this.notes,
    this.petName,
    this.petPhoto,
  });

  factory VisitHistoryItem.fromJson(Map<String, dynamic> json) {
    final match = json['matches'] as Map<String, dynamic>?;
    final pet = match?['pets'] as Map<String, dynamic>?;
    final photos = (pet?['photos'] as List<dynamic>?)?.cast<String>();

    return VisitHistoryItem(
      id: json['id'] as String? ?? '',
      matchId: json['match_id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      proposedAt: DateTime.tryParse(json['proposed_at']?.toString() ?? '') ?? DateTime.now(),
      notes: json['notes'] as String?,
      petName: pet?['name'] as String?,
      petPhoto: (photos != null && photos.isNotEmpty) ? photos.first : null,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'confirmed':
        return 'Confirmada';
      case 'declined':
        return 'Rechazada';
      case 'completed':
        return 'Completada';
      case 'cancelled':
        return 'Cancelada';
      case 'pending':
      default:
        return 'Pendiente';
    }
  }
}
