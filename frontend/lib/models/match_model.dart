import 'pet_model.dart';

class MatchModel {
  final String id;
  final String petId;
  final String adopterId;
  final String shelterId;
  final String status;
  final String? shelterComments;
  final PetModel? pet;
  final DateTime createdAt;

  MatchModel({
    required this.id,
    required this.petId,
    required this.adopterId,
    required this.shelterId,
    required this.status,
    this.shelterComments,
    this.pet,
    required this.createdAt,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] as String? ?? '',
      petId: json['pet_id'] as String? ?? '',
      adopterId: json['adopter_id'] as String? ?? '',
      shelterId: json['shelter_id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending_review',
      shelterComments: json['shelter_comments'] as String?,
      pet: json['pets'] != null ? PetModel.fromJson(json['pets'] as Map<String, dynamic>) : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String get statusBadgeText {
    switch (status) {
      case 'pending_review':
        return 'En Revisión por Refugio';
      case 'approved_for_chat':
        return '¡Match Aprobado! (Chat Activo)';
      case 'interview_scheduled':
        return 'Visita / Entrevista Programada';
      case 'rejected':
        return 'No Apto para este perfil';
      case 'adoption_finalized':
        return '¡Adopción Concretada! 🎉';
      default:
        return status;
    }
  }
}
