class PetModel {
  final String id;
  final String shelterId;
  final String publisherType; // 'shelter' | 'individual_rescuer'
  final String name;
  final String species;
  final String breed;
  final double ageYears;
  final String gender; // 'male' | 'female'
  final String size; // 'small' | 'medium' | 'large' | 'giant'
  final int energyLevel; // 1 a 5

  // Origen y Camadas
  final String
  origin; // 'home_litter' | 'street_rescue' | 'shelter_born' | 'relinquished'
  final bool isLitter;
  final bool weaningCompleted;

  // Plan Sanitario y Reproducción
  final bool isVaccinated;
  final List<String> vaccinesApplied;
  final bool dewormedInternal;
  final bool dewormedExternal;
  final bool hasMicrochip;
  final bool isNeutered;
  final String reproductiveStatus; // 'neutered' | 'spayed' | 'requires_spay_agreement' | 'intact'

  // Hábitos y Comportamiento
  final bool houseTrained;
  final bool goodWithDogs;
  final bool goodWithCats;
  final bool goodWithKids;
  final bool requiresYard;
  final int stormAnxiety; // 1 a 5
  final String? specialNeeds;
  final String story;

  // Requisitos de Adopción
  final bool requiresAdoptionContract;
  final bool requiresHomeCheck;
  final bool requiresFollowupPhotos;
  final String deliveryType;

  final List<String> photos;
  String status; // 'available' | 'paused' | 'in_process' | 'adopted'
  final String? relocationReason;
  final String moderationStatus; // 'pending' | 'approved' | 'rejected'
  final String? moderationNotes;
  final double? latitude;
  final double? longitude;

  PetModel({
    required this.id,
    required this.shelterId,
    this.publisherType = 'shelter',
    required this.name,
    required this.species,
    required this.breed,
    required this.ageYears,
    required this.gender,
    required this.size,
    required this.energyLevel,
    this.origin = 'street_rescue',
    this.isLitter = false,
    this.weaningCompleted = true,
    required this.isVaccinated,
    this.vaccinesApplied = const [],
    this.dewormedInternal = true,
    this.dewormedExternal = true,
    this.hasMicrochip = false,
    required this.isNeutered,
    this.reproductiveStatus = 'neutered',
    this.houseTrained = true,
    required this.goodWithDogs,
    required this.goodWithCats,
    required this.goodWithKids,
    required this.requiresYard,
    this.stormAnxiety = 1,
    this.specialNeeds,
    required this.story,
    this.requiresAdoptionContract = true,
    this.requiresHomeCheck = false,
    this.requiresFollowupPhotos = true,
    this.deliveryType = 'to_be_agreed',
    required this.photos,
    required this.status,
    this.relocationReason,
    this.moderationStatus = 'approved',
    this.moderationNotes,
    this.latitude,
    this.longitude,
  });

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'] as String? ?? '',
      shelterId: json['shelter_id'] as String? ?? '',
      publisherType: json['publisher_type'] as String? ?? 'shelter',
      name: json['name'] as String? ?? 'Sin nombre',
      species: json['species'] as String? ?? 'dog',
      breed: json['breed'] as String? ?? 'Mestizo',
      ageYears: (json['age_years'] is num)
          ? (json['age_years'] as num).toDouble()
          : 1.0,
      gender: json['gender'] as String? ?? 'male',
      size: json['size'] as String? ?? 'medium',
      energyLevel: json['energy_level'] as int? ?? 3,

      origin: json['origin'] as String? ?? 'street_rescue',
      isLitter: json['is_litter'] as bool? ?? false,
      weaningCompleted: json['weaning_completed'] as bool? ?? true,

      isVaccinated: json['is_vaccinated'] as bool? ?? false,
      vaccinesApplied:
          (json['vaccines_applied'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      dewormedInternal: json['dewormed_internal'] as bool? ?? true,
      dewormedExternal: json['dewormed_external'] as bool? ?? true,
      hasMicrochip: json['has_microchip'] as bool? ?? false,
      isNeutered: json['is_neutered'] as bool? ?? false,
      reproductiveStatus:
          json['reproductive_status'] as String? ??
          (json['is_neutered'] == true ? 'neutered' : 'intact'),

      houseTrained: json['house_trained'] as bool? ?? true,
      goodWithDogs: json['good_with_dogs'] as bool? ?? true,
      goodWithCats: json['good_with_cats'] as bool? ?? true,
      goodWithKids: json['good_with_kids'] as bool? ?? true,
      requiresYard: json['requires_yard'] as bool? ?? false,
      stormAnxiety: json['storm_anxiety'] as int? ?? 1,
      specialNeeds: json['special_needs'] as String?,
      story: json['story'] as String? ?? '',

      requiresAdoptionContract:
          json['requires_adoption_contract'] as bool? ?? true,
      requiresHomeCheck: json['requires_home_check'] as bool? ?? false,
      requiresFollowupPhotos: json['requires_followup_photos'] as bool? ?? true,
      deliveryType: json['delivery_type'] as String? ?? 'to_be_agreed',

      photos:
          (json['photos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      status: json['status'] as String? ?? 'available',
      relocationReason: json['relocation_reason'] as String?,
      moderationStatus: json['moderation_status'] as String? ?? 'approved',
      moderationNotes: json['moderation_notes'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shelter_id': shelterId,
      'publisher_type': publisherType,
      'name': name,
      'species': species,
      'breed': breed,
      'age_years': ageYears,
      'gender': gender,
      'size': size,
      'energy_level': energyLevel,
      'origin': origin,
      'is_litter': isLitter,
      'weaning_completed': weaningCompleted,
      'is_vaccinated': isVaccinated,
      'vaccines_applied': vaccinesApplied,
      'dewormed_internal': dewormedInternal,
      'dewormed_external': dewormedExternal,
      'has_microchip': hasMicrochip,
      'is_neutered': isNeutered,
      'reproductive_status': reproductiveStatus,
      'house_trained': houseTrained,
      'good_with_dogs': goodWithDogs,
      'good_with_cats': goodWithCats,
      'good_with_kids': goodWithKids,
      'requires_yard': requiresYard,
      'storm_anxiety': stormAnxiety,
      'special_needs': specialNeeds,
      'story': story,
      'requires_adoption_contract': requiresAdoptionContract,
      'requires_home_check': requiresHomeCheck,
      'requires_followup_photos': requiresFollowupPhotos,
      'delivery_type': deliveryType,
      'photos': photos,
      'status': status,
      'relocation_reason': relocationReason,
    };
  }

  String get ageStage {
    if (ageYears < 1.0) return 'puppy';
    if (ageYears < 3.0) return 'young';
    if (ageYears < 8.0) return 'adult';
    return 'senior';
  }

  String get ageStageLabel {
    switch (ageStage) {
      case 'puppy':
        return 'Cachorro (<1 año)';
      case 'young':
        return 'Joven (1-3 años)';
      case 'adult':
        return 'Adulto (3-7 años)';
      default:
        return 'Senior (+8 años)';
    }
  }

  bool get isRelocated => origin == 'relinquished';

  String get ageFormatted {
    if (ageYears < 1.0) {
      final months = (ageYears * 12).round();
      return '$months ${months == 1 ? 'mes' : 'meses'}';
    }
    return '${ageYears.toStringAsFixed(ageYears.truncateToDouble() == ageYears ? 0 : 1)} ${ageYears == 1.0 ? 'año' : 'años'}';
  }

  String get publisherBadgeText {
    return publisherType == 'individual_rescuer'
        ? 'Camada Particular / Rescatista'
        : 'Refugio Oficial';
  }

  String get genderBadgeText {
    return gender == 'female' ? 'Hembra' : 'Macho';
  }

  String get reproductiveBadgeText {
    switch (reproductiveStatus) {
      case 'spayed':
        return 'Esterilizada';
      case 'neutered':
        return 'Castrado';
      case 'requires_spay_agreement':
        return 'Compromiso de Castración (Cachorro)';
      case 'intact':
      default:
        return 'Sin Castrar';
    }
  }

  String get originBadgeText {
    switch (origin) {
      case 'home_litter':
        return 'Nacimiento en Casa (Camada)';
      case 'street_rescue':
        return 'Rescatado/a de la Calle';
      case 'shelter_born':
        return 'Nacido en Refugio';
      case 'relinquished':
        return 'En Adopción por Mudanza/Cesión';
      default:
        return 'Rescate';
    }
  }
}
