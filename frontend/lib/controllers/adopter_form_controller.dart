import 'package:flutter/material.dart';

import '../core/services/api_service.dart';
import '../models/adopter_form_model.dart';

class AdopterFormController extends ChangeNotifier {
  final ApiService _api;

  AdopterFormController({ApiService? apiService})
    : _api = apiService ?? ApiService();

  AdopterFormModel form = AdopterFormModel();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isCompleted = false;

  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get isCompleted => _isCompleted;

  /// Carga el formulario ya guardado del adoptante (si existe)
  Future<void> loadExistingForm() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.get('/adopter/form');
      if (data != null) {
        form = AdopterFormModel.fromJson(data as Map<String, dynamic>);
        _isCompleted = true;
      }
    } catch (_) {
      // Sin formulario previo o sin conexión; se completa desde cero
    }
    _isLoading = false;
    notifyListeners();
  }

  void nextStep() {
    if (_currentStep < 3) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void updateHousing({
    required String type,
    required String status,
    required bool hasYard,
    required bool hasNetting,
  }) {
    form.housingType = type;
    form.housingStatus = status;
    form.hasYard = hasYard;
    form.hasProtectiveNetting = hasNetting;
    notifyListeners();
  }

  void updateHousehold({
    required String members,
    required bool allAgree,
    required bool hasAllergies,
  }) {
    form.householdMembers = members;
    form.allMembersAgree = allAgree;
    form.hasAllergies = hasAllergies;
    notifyListeners();
  }

  void updateLifestyle({
    required int hoursAlone,
    required bool hasOtherPets,
    String? otherPetsDetails,
  }) {
    form.hoursPetAlonePerDay = hoursAlone;
    form.hasOtherPets = hasOtherPets;
    form.otherPetsDetails = otherPetsDetails;
    notifyListeners();
  }

  void updateCommitment({
    required bool budgetConfirmed,
    required bool emergencyFund,
    required bool followUp,
    required bool neutering,
  }) {
    form.monthlyBudgetConfirmed = budgetConfirmed;
    form.emergencyFundAvailable = emergencyFund;
    form.agreesToFollowUp = followUp;
    form.agreesToMandatoryNeutering = neutering;
    notifyListeners();
  }

  Future<bool> submitForm() async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    if (!form.allMembersAgree) {
      _errorMessage = 'Es requisito fundamental que todos los miembros del hogar estén de acuerdo con la adopción.';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }

    try {
      final data = await _api.post('/adopter/form', form.toJson());
      form = AdopterFormModel.fromJson(data as Map<String, dynamic>);
      _isCompleted = true;
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }
}
