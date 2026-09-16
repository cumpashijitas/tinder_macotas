class AdopterFormModel {
  String housingType;
  String housingStatus;
  bool hasYard;
  bool hasProtectiveNetting;
  String householdMembers;
  bool allMembersAgree;
  bool hasAllergies;
  int hoursPetAlonePerDay;
  bool hasOtherPets;
  String? otherPetsDetails;
  String? previousPetExperience;
  bool monthlyBudgetConfirmed;
  bool emergencyFundAvailable;
  bool agreesToFollowUp;
  bool agreesToMandatoryNeutering;
  String? evaluationStatus;
  double? evaluationScore;

  AdopterFormModel({
    this.housingType = 'apartment',
    this.housingStatus = 'owned',
    this.hasYard = false,
    this.hasProtectiveNetting = true,
    this.householdMembers = 'alone',
    this.allMembersAgree = true,
    this.hasAllergies = false,
    this.hoursPetAlonePerDay = 4,
    this.hasOtherPets = false,
    this.otherPetsDetails,
    this.previousPetExperience,
    this.monthlyBudgetConfirmed = true,
    this.emergencyFundAvailable = true,
    this.agreesToFollowUp = true,
    this.agreesToMandatoryNeutering = true,
    this.evaluationStatus,
    this.evaluationScore,
  });

  factory AdopterFormModel.fromJson(Map<String, dynamic> json) {
    return AdopterFormModel(
      housingType: json['housing_type'] as String? ?? 'apartment',
      housingStatus: json['housing_status'] as String? ?? 'owned',
      hasYard: json['has_yard'] as bool? ?? false,
      hasProtectiveNetting: json['has_protective_netting'] as bool? ?? false,
      householdMembers: json['household_members'] as String? ?? 'alone',
      allMembersAgree: json['all_members_agree'] as bool? ?? true,
      hasAllergies: json['has_allergies'] as bool? ?? false,
      hoursPetAlonePerDay: json['hours_pet_alone_per_day'] as int? ?? 4,
      hasOtherPets: json['has_other_pets'] as bool? ?? false,
      otherPetsDetails: json['other_pets_details'] as String?,
      previousPetExperience: json['previous_pet_experience'] as String?,
      monthlyBudgetConfirmed: json['monthly_budget_confirmed'] as bool? ?? true,
      emergencyFundAvailable: json['emergency_fund_available'] as bool? ?? true,
      agreesToFollowUp: json['agrees_to_follow_up'] as bool? ?? true,
      agreesToMandatoryNeutering:
          json['agrees_to_mandatory_neutering'] as bool? ?? true,
      evaluationStatus: json['evaluation_status'] as String?,
      evaluationScore: (json['evaluation_score'] is num)
          ? (json['evaluation_score'] as num).toDouble()
          : null,
    );
  }

  String get housingTypeLabel {
    switch (housingType) {
      case 'house':
        return 'Casa';
      case 'apartment':
        return 'Departamento';
      case 'farm':
        return 'Chacra / Campo';
      default:
        return 'Otro';
    }
  }

  String get housingStatusLabel {
    switch (housingStatus) {
      case 'owned':
        return 'Propietario/a';
      case 'rented_allowed':
        return 'Alquiler (mascotas permitidas)';
      case 'rented_pending_permission':
        return 'Alquiler (permiso pendiente)';
      default:
        return housingStatus;
    }
  }

  String get householdMembersLabel {
    switch (householdMembers) {
      case 'alone':
        return 'Vive solo/a';
      case 'couple':
        return 'En pareja';
      case 'family_with_young_kids':
        return 'Familia con niños pequeños';
      case 'family_with_teens':
        return 'Familia con adolescentes';
      case 'roommates':
        return 'Con compañeros de casa';
      default:
        return householdMembers;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'housing_type': housingType,
      'housing_status': housingStatus,
      'has_yard': hasYard,
      'has_protective_netting': hasProtectiveNetting,
      'household_members': householdMembers,
      'all_members_agree': allMembersAgree,
      'has_allergies': hasAllergies,
      'hours_pet_alone_per_day': hoursPetAlonePerDay,
      'has_other_pets': hasOtherPets,
      'other_pets_details': otherPetsDetails,
      'previous_pet_experience': previousPetExperience,
      'monthly_budget_confirmed': monthlyBudgetConfirmed,
      'emergency_fund_available': emergencyFundAvailable,
      'agrees_to_follow_up': agreesToFollowUp,
      'agrees_to_mandatory_neutering': agreesToMandatoryNeutering,
    };
  }
}
