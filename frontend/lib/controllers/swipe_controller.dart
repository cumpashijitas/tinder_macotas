import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

import '../core/services/api_service.dart';
import '../models/pet_model.dart';

class SwipeController extends ChangeNotifier {
  final ApiService _api;
  final CardSwiperController cardSwiperController = CardSwiperController();

  SwipeController({ApiService? apiService}) : _api = apiService ?? ApiService();

  static const int _feedPageSize = 20;

  List<PetModel> _pets = [];
  List<PetModel> _inventory = [];
  bool _isLoading = false;
  bool _isLoadingMoreFeed = false;
  bool _hasMoreFeed = false;
  String? _feedSpecies;
  String? _feedPublisherType;
  String? _lastSwipeFeedback;
  String? _errorMessage;

  List<PetModel> get pets => _pets;
  List<PetModel> get inventory => _inventory;
  bool get isLoading => _isLoading;
  bool get isLoadingMoreFeed => _isLoadingMoreFeed;
  bool get hasMoreFeed => _hasMoreFeed;
  String? get lastSwipeFeedback => _lastSwipeFeedback;
  String? get errorMessage => _errorMessage;

  String _feedQuery({required int offset}) {
    final params = <String>['limit=$_feedPageSize', 'offset=$offset'];
    if (_feedSpecies != null) {
      params.add('species=${Uri.encodeQueryComponent(_feedSpecies!)}');
    }
    if (_feedPublisherType != null) {
      params.add('publisher_type=${Uri.encodeQueryComponent(_feedPublisherType!)}');
    }
    return '?${params.join('&')}';
  }

  /// Carga la primera página del feed de mascotas disponibles (excluye las ya swipeadas)
  Future<void> loadFeed({String? species, String? publisherType}) async {
    _isLoading = true;
    _errorMessage = null;
    _feedSpecies = species;
    _feedPublisherType = publisherType;
    notifyListeners();

    try {
      final data = await _api.get('/pets/feed${_feedQuery(offset: 0)}');
      _pets = (data as List<dynamic>)
          .map((e) => PetModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _hasMoreFeed = _pets.length == _feedPageSize;
    } catch (e) {
      _errorMessage = e.toString();
      _pets = [];
      _hasMoreFeed = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Trae la siguiente página y la agrega al final del feed ya cargado.
  Future<void> loadMoreFeed() async {
    if (_isLoadingMoreFeed || !_hasMoreFeed) return;

    _isLoadingMoreFeed = true;
    notifyListeners();

    try {
      final data = await _api.get('/pets/feed${_feedQuery(offset: _pets.length)}');
      final nextPage = (data as List<dynamic>)
          .map((e) => PetModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _pets = [..._pets, ...nextPage];
      _hasMoreFeed = nextPage.length == _feedPageSize;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoadingMoreFeed = false;
    notifyListeners();
  }

  /// Inventario completo del publicador actual (incluye pausadas/adoptadas/pendientes de moderación)
  Future<void> loadInventory() async {
    try {
      final data = await _api.get('/pets/inventory');
      _inventory = (data as List<dynamic>)
          .map((e) => PetModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
      _inventory = [];
    }
    notifyListeners();
  }

  /// Publica una mascota nueva (refugio o particular con camada)
  Future<PetModel?> publishPet(Map<String, dynamic> payload) async {
    try {
      final data = await _api.post('/pets', payload);
      final pet = PetModel.fromJson(data as Map<String, dynamic>);
      _inventory.insert(0, pet);
      notifyListeners();
      return pet;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Solicitud de reubicación responsable: queda pendiente de moderación,
  /// no se agrega al feed hasta que un admin la apruebe.
  Future<PetModel?> submitRelocation(Map<String, dynamic> payload) async {
    try {
      final data = await _api.post('/pets/relocate', payload);
      return PetModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updatePetStatus(PetModel pet, String newStatus) async {
    try {
      await _api.patch('/pets/${pet.id}/status', {'status': newStatus});
      pet.status = newStatus;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Edita los datos de una mascota ya publicada. Actualiza la copia en el
  /// inventario local con la respuesta real del servidor.
  Future<PetModel?> updatePet(String id, Map<String, dynamic> payload) async {
    try {
      final data = await _api.patch('/pets/$id', payload);
      final updated = PetModel.fromJson(data as Map<String, dynamic>);
      final index = _inventory.indexWhere((p) => p.id == id);
      if (index != -1) {
        _inventory[index] = updated;
      }
      notifyListeners();
      return updated;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Elimina una publicación. El backend rechaza el borrado (409) si la
  /// mascota ya tiene matches, para no perder historial de postulaciones.
  Future<bool> deletePet(String id) async {
    try {
      await _api.delete('/pets/$id');
      _inventory.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------
  // Moderación (solo admin): cola de mascotas pendientes de revisión
  // ---------------------------------------------------------------
  List<PetModel> _pendingModeration = [];
  List<PetModel> get pendingModeration => _pendingModeration;

  Future<void> loadPendingModeration() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.get('/pets/pending');
      _pendingModeration = (data as List<dynamic>)
          .map((e) => PetModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _pendingModeration = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> moderatePet(String id, String status, {String? notes}) async {
    try {
      await _api.patch('/pets/$id/moderate', {
        'moderation_status': status,
        if (notes != null) 'moderation_notes': notes,
      });
      _pendingModeration.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Postula directamente a una mascota (swipe a la derecha) fuera del deck,
  /// por ejemplo desde la ficha de detalle en la vista de cuadrícula.
  Future<bool> applyToAdopt(PetModel pet) async {
    try {
      final data = await _api.post('/swipes', {
        'pet_id': pet.id,
        'direction': 'right',
      });
      final matchCreated =
          (data as Map<String, dynamic>)['matchCreated'] == true;
      if (matchCreated) {
        _lastSwipeFeedback =
            '¡Postulación enviada por ${pet.name}! El publicador revisará tu formulario.';
        notifyListeners();
      }
      return matchCreated;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Callback síncrono requerido por CardSwiper: dispara el registro del swipe
  /// en el backend en segundo plano y deja que la animación continúe.
  bool handleSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    if (previousIndex < _pets.length) {
      _recordSwipe(_pets[previousIndex], direction);
    }
    return true;
  }

  Future<void> _recordSwipe(PetModel pet, CardSwiperDirection direction) async {
    String? apiDirection;
    if (direction == CardSwiperDirection.right) {
      apiDirection = 'right';
    } else if (direction == CardSwiperDirection.top) {
      apiDirection = 'superlike';
    } else if (direction == CardSwiperDirection.left) {
      apiDirection = 'left';
    }

    if (apiDirection == null) return;

    try {
      final data = await _api.post('/swipes', {
        'pet_id': pet.id,
        'direction': apiDirection,
      });
      final matchCreated =
          (data as Map<String, dynamic>)['matchCreated'] == true;

      if (matchCreated && apiDirection == 'right') {
        _lastSwipeFeedback =
            '¡Postulación enviada por ${pet.name}! El publicador revisará tu formulario.';
      } else if (matchCreated && apiDirection == 'superlike') {
        _lastSwipeFeedback = '⭐ ¡Super-Adopción enviada por ${pet.name}!';
      } else {
        _lastSwipeFeedback = null;
      }
    } catch (e) {
      _lastSwipeFeedback = null;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  void swipeLeft() => cardSwiperController.swipe(CardSwiperDirection.left);
  void swipeRight() => cardSwiperController.swipe(CardSwiperDirection.right);
  void swipeTop() => cardSwiperController.swipe(CardSwiperDirection.top);

  @override
  void dispose() {
    cardSwiperController.dispose();
    super.dispose();
  }
}
