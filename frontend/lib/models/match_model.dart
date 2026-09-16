import 'pet_model.dart';
import 'adopter_form_model.dart';

class MatchModel {
  final String id;
  final String petId;
  final String adopterId;
  final String shelterId;
  final String status;
  final String? shelterComments;
  final PetModel? pet;
  final String? adopterName;
  final AdopterFormModel? adopterForm;
  final DateTime createdAt;

  MatchModel({
    required this.id,
    required this.petId,
    required this.adopterId,
    required this.shelterId,
    required this.status,
    this.shelterComments,
    this.pet,
    this.adopterName,
    this.adopterForm,
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
      pet: json['pets'] != null
          ? PetModel.fromJson(json['pets'] as Map<String, dynamic>)
          : null,
      adopterName: json['adopter'] != null
          ? (json['adopter'] as Map<String, dynamic>)['full_name'] as String?
          : null,
      adopterForm: json['adopter_form'] != null
          ? AdopterFormModel.fromJson(
              json['adopter_form'] as Map<String, dynamic>,
            )
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isChatEnabled =>
      status == 'approved_for_chat' ||
      status == 'interview_scheduled' ||
      status == 'adoption_finalized';

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
