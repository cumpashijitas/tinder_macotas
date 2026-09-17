import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/pet_model.dart';

class PetFilterController extends ChangeNotifier {
  bool _isGridView = true;
  String _searchQuery = '';
  double _maxDistanceKm = 50.0;
  double? _adopterLat;
  double? _adopterLng;
  final Set<String> _selectedAgeStages =
      {}; // 'puppy', 'young', 'adult', 'senior'
  final Set<String> _selectedSizes = {}; // 'small', 'medium', 'large', 'giant'
  int _maxEnergyLevel = 5;
  bool _onlyGoodWithKids = false;
  bool _onlyGoodWithCats = false;
  bool _onlyGoodWithDogs = false;
  bool _onlySpecialNeeds = false;
  bool _onlyVaccinated = false;
  bool _onlyNeutered = false;
  String _selectedSpecies = 'all'; // 'all', 'dog', 'cat'
  String _selectedPublisherType =
      'all'; // 'all', 'shelter', 'individual_rescuer', 'relinquished'

  // Getters
  bool get isGridView => _isGridView;
  String get searchQuery => _searchQuery;
  double get maxDistanceKm => _maxDistanceKm;
  Set<String> get selectedAgeStages => _selectedAgeStages;
  Set<String> get selectedSizes => _selectedSizes;
  int get maxEnergyLevel => _maxEnergyLevel;
  bool get onlyGoodWithKids => _onlyGoodWithKids;
  bool get onlyGoodWithCats => _onlyGoodWithCats;
  bool get onlyGoodWithDogs => _onlyGoodWithDogs;
  bool get onlySpecialNeeds => _onlySpecialNeeds;
  bool get onlyVaccinated => _onlyVaccinated;
  bool get onlyNeutered => _onlyNeutered;
  String get selectedSpecies => _selectedSpecies;
  String get selectedPublisherType => _selectedPublisherType;

  int get activeFilterCount {
    int count = 0;
    if (_searchQuery.trim().isNotEmpty) count++;
    if (_maxDistanceKm < 50.0) count++;
    if (_selectedAgeStages.isNotEmpty) count += _selectedAgeStages.length;
    if (_selectedSizes.isNotEmpty) count += _selectedSizes.length;
    if (_maxEnergyLevel < 5) count++;
    if (_onlyGoodWithKids) count++;
    if (_onlyGoodWithCats) count++;
    if (_onlyGoodWithDogs) count++;
    if (_onlySpecialNeeds) count++;
    if (_onlyVaccinated) count++;
    if (_onlyNeutered) count++;
    if (_selectedSpecies != 'all') count++;
    if (_selectedPublisherType != 'all') count++;
    return count;
  }

  void toggleViewMode() {
    _isGridView = !_isGridView;
    notifyListeners();
  }

  void setViewMode(bool grid) {
    _isGridView = grid;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setMaxDistance(double km) {
    _maxDistanceKm = km;
    notifyListeners();
  }

  /// Ubicación real del adoptante (capturada vía geolocalización). Sin ella,
  /// no se puede calcular distancia real: el filtro de distancia se ignora
  /// y la insignia de "X km" simplemente no se muestra (nada inventado).
  void setAdopterLocation(double? lat, double? lng) {
    _adopterLat = lat;
    _adopterLng = lng;
    notifyListeners();
  }

  bool get hasAdopterLocation => _adopterLat != null && _adopterLng != null;

  void toggleAgeStage(String stage) {
    if (_selectedAgeStages.contains(stage)) {
      _selectedAgeStages.remove(stage);
    } else {
      _selectedAgeStages.add(stage);
    }
    notifyListeners();
  }

  void toggleSize(String size) {
    if (_selectedSizes.contains(size)) {
      _selectedSizes.remove(size);
    } else {
      _selectedSizes.add(size);
    }
    notifyListeners();
  }

  void setMaxEnergyLevel(int level) {
    _maxEnergyLevel = level;
    notifyListeners();
  }

  void setOnlyGoodWithKids(bool val) {
    _onlyGoodWithKids = val;
    notifyListeners();
  }

  void setOnlyGoodWithCats(bool val) {
    _onlyGoodWithCats = val;
    notifyListeners();
  }

  void setOnlyGoodWithDogs(bool val) {
    _onlyGoodWithDogs = val;
    notifyListeners();
  }

  void setOnlySpecialNeeds(bool val) {
    _onlySpecialNeeds = val;
    notifyListeners();
  }

  void setOnlyVaccinated(bool val) {
    _onlyVaccinated = val;
    notifyListeners();
  }

  void setOnlyNeutered(bool val) {
    _onlyNeutered = val;
    notifyListeners();
  }

  void setSelectedSpecies(String species) {
    _selectedSpecies = species;
    notifyListeners();
  }

  void setSelectedPublisherType(String pubType) {
    _selectedPublisherType = pubType;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _maxDistanceKm = 50.0;
    _selectedAgeStages.clear();
    _selectedSizes.clear();
    _maxEnergyLevel = 5;
    _onlyGoodWithKids = false;
    _onlyGoodWithCats = false;
    _onlyGoodWithDogs = false;
    _onlySpecialNeeds = false;
    _onlyVaccinated = false;
    _onlyNeutered = false;
    _selectedSpecies = 'all';
    _selectedPublisherType = 'all';
    notifyListeners();
  }

  /// Distancia real en km entre el adoptante y la mascota (fórmula de
  /// Haversine). Devuelve null si falta la ubicación de alguna de las dos
  /// partes — en ese caso la UI debe ocultar el dato en vez de inventarlo.
  double? getPetDistanceKm(PetModel pet) {
    if (_adopterLat == null ||
        _adopterLng == null ||
        pet.latitude == null ||
        pet.longitude == null) {
      return null;
    }

    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(pet.latitude! - _adopterLat!);
    final dLng = _toRadians(pet.longitude! - _adopterLng!);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(_adopterLat!)) *
            math.cos(_toRadians(pet.latitude!)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180.0);

  List<PetModel> applyFilters(List<PetModel> pets) {
    return pets.where((pet) {
      // Solo mascotas disponibles en la vista de búsqueda
      if (pet.status != 'available') return false;

      // Filtro de búsqueda por texto
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = pet.name.toLowerCase().contains(q);
        final matchesBreed = pet.breed.toLowerCase().contains(q);
        final matchesStory = pet.story.toLowerCase().contains(q);
        if (!matchesName && !matchesBreed && !matchesStory) return false;
      }

      // Especie
      if (_selectedSpecies != 'all' && pet.species != _selectedSpecies) {
        return false;
      }

      // Tipo de publicador u origen
      if (_selectedPublisherType != 'all') {
        if (_selectedPublisherType == 'relinquished') {
          if (pet.origin != 'relinquished') return false;
        } else if (pet.publisherType != _selectedPublisherType) {
          return false;
        }
      }

      // Distancia máxima (sólo filtra si conocemos la distancia real de ambos lados)
      final distance = getPetDistanceKm(pet);
      if (distance != null && distance > _maxDistanceKm) {
        return false;
      }

      // Rango de edad (etapas)
      if (_selectedAgeStages.isNotEmpty) {
        if (!_selectedAgeStages.contains(pet.ageStage)) {
          return false;
        }
      }

      // Tamaño
      if (_selectedSizes.isNotEmpty) {
        if (!_selectedSizes.contains(pet.size)) {
          return false;
        }
      }

      // Nivel de energía
      if (pet.energyLevel > _maxEnergyLevel) {
        return false;
      }

      // Sociabilidad y convivencia
      if (_onlyGoodWithKids && !pet.goodWithKids) return false;
      if (_onlyGoodWithCats && !pet.goodWithCats) return false;
      if (_onlyGoodWithDogs && !pet.goodWithDogs) return false;

      // Necesidades especiales
      if (_onlySpecialNeeds &&
          (pet.specialNeeds == null || pet.specialNeeds!.trim().isEmpty)) {
        return false;
      }

      // Plan sanitario
      if (_onlyVaccinated && !pet.isVaccinated) return false;
      if (_onlyNeutered && !pet.isNeutered) return false;

      return true;
    }).toList();
  }
}
