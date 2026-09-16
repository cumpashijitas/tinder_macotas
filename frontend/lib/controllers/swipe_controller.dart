import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../models/pet_model.dart';

class SwipeController extends ChangeNotifier {
  final CardSwiperController cardSwiperController = CardSwiperController();
  List<PetModel> _pets = [];
  bool _isLoading = false;
  String? _lastSwipeFeedback;

  List<PetModel> get pets => _pets;
  bool get isLoading => _isLoading;
  String? get lastSwipeFeedback => _lastSwipeFeedback;

  SwipeController() {
    loadSamplePets();
  }

  void loadSamplePets() {
    _isLoading = true;
    notifyListeners();

    // Mascotas demo: Refugios institucionales y particulares con camadas
    _pets = [
      PetModel(
        id: '1',
        shelterId: 'shelter_1',
        publisherType: 'shelter',
        name: 'Rocky',
        species: 'dog',
        breed: 'Mestizo Labrador',
        ageYears: 2.0,
        gender: 'male',
        size: 'medium',
        energyLevel: 3,
        origin: 'street_rescue',
        isLitter: false,
        weaningCompleted: true,
        isVaccinated: true,
        vaccinesApplied: ['Antirrábica', 'Séxtuple Canina'],
        dewormedInternal: true,
        dewormedExternal: true,
        hasMicrochip: true,
        isNeutered: true,
        reproductiveStatus: 'neutered',
        houseTrained: true,
        goodWithDogs: true,
        goodWithCats: false,
        goodWithKids: true,
        requiresYard: false,
        stormAnxiety: 1,
        requiresAdoptionContract: true,
        requiresHomeCheck: false,
        requiresFollowupPhotos: true,
        deliveryType: 'to_be_agreed',
        story: 'Rocky fue rescatado cerca de una plaza. Es muy alegre, le encanta jugar a la pelota y aprende trucos rápidamente. Esterilizado y con libreta sanitaria completa.',
        photos: [
          'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=800&q=80',
          'https://images.unsplash.com/photo-1537151625747-768eb6cf92b2?auto=format&fit=crop&w=800&q=80',
        ],
        status: 'available',
      ),
      PetModel(
        id: '2',
        shelterId: 'individual_1',
        publisherType: 'individual_rescuer',
        name: 'Simba',
        species: 'dog',
        breed: 'Cachorro Mestizo Golden',
        ageYears: 0.25, // 3 meses
        gender: 'male',
        size: 'medium',
        energyLevel: 4,
        origin: 'home_litter',
        isLitter: true,
        weaningCompleted: true, // Superó los 60 días
        isVaccinated: true,
        vaccinesApplied: ['Pupivac (1ra dosis Séxtuple)'],
        dewormedInternal: true,
        dewormedExternal: true,
        hasMicrochip: false,
        isNeutered: false,
        reproductiveStatus: 'requires_spay_agreement',
        houseTrained: false,
        goodWithDogs: true,
        goodWithCats: true,
        goodWithKids: true,
        requiresYard: true,
        stormAnxiety: 2,
        requiresAdoptionContract: true,
        requiresHomeCheck: false,
        requiresFollowupPhotos: true,
        deliveryType: 'home_delivery',
        story: 'Nació en casa tras rescatar a su mamá embarazada. Cumplió más de 60 días de destete con la madre, come alimento cachorro y buscamos familia con patio para él.',
        photos: [
          'https://images.unsplash.com/photo-1591160690555-5debfba289f0?auto=format&fit=crop&w=800&q=80',
        ],
        status: 'available',
      ),
      PetModel(
        id: '3',
        shelterId: 'shelter_1',
        publisherType: 'shelter',
        name: 'Luna',
        species: 'cat',
        breed: 'Común Europeo',
        ageYears: 1.2,
        gender: 'female',
        size: 'small',
        energyLevel: 2,
        origin: 'street_rescue',
        isLitter: false,
        weaningCompleted: true,
        isVaccinated: true,
        vaccinesApplied: ['Antirrábica', 'Triple Felina'],
        dewormedInternal: true,
        dewormedExternal: true,
        hasMicrochip: true,
        isNeutered: true,
        reproductiveStatus: 'spayed',
        houseTrained: true,
        goodWithDogs: false,
        goodWithCats: true,
        goodWithKids: true,
        requiresYard: false,
        stormAnxiety: 1,
        requiresAdoptionContract: true,
        requiresHomeCheck: true,
        requiresFollowupPhotos: true,
        deliveryType: 'pickup_at_shelter',
        story: 'Luna es una gatita dulce y tranquila que adora dormir en el regazo. Esterilizada, usa arenero y es ideal para departamentos con red de seguridad.',
        photos: [
          'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=800&q=80',
        ],
        status: 'available',
      ),
      PetModel(
        id: '4',
        shelterId: 'individual_2',
        publisherType: 'individual_rescuer',
        name: 'Mía & Hermanitos (Camada)',
        species: 'cat',
        breed: 'Gatitos Siameses Mix',
        ageYears: 0.2, // ~2.5 meses
        gender: 'female',
        size: 'small',
        energyLevel: 4,
        origin: 'home_litter',
        isLitter: true,
        weaningCompleted: true,
        isVaccinated: true,
        vaccinesApplied: ['1ra Triple Felina'],
        dewormedInternal: true,
        dewormedExternal: true,
        hasMicrochip: false,
        isNeutered: false,
        reproductiveStatus: 'requires_spay_agreement',
        houseTrained: true,
        goodWithDogs: true,
        goodWithCats: true,
        goodWithKids: true,
        requiresYard: false,
        stormAnxiety: 1,
        requiresAdoptionContract: true,
        requiresHomeCheck: false,
        requiresFollowupPhotos: true,
        deliveryType: 'to_be_agreed',
        story: 'Camada nacida en casa. Ya comen solos, aprendieron a usar el arenero perfectamente y se entregan con compromiso de castración a los 6 meses.',
        photos: [
          'https://images.unsplash.com/photo-1533738363-b7f9aef128ce?auto=format&fit=crop&w=800&q=80',
        ],
        status: 'available',
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  void addPet(PetModel pet) {
    _pets.insert(0, pet);
    notifyListeners();
  }

  void updatePetStatus(PetModel pet, String newStatus) {
    pet.status = newStatus;
    notifyListeners();
  }

  bool handleSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    if (previousIndex < _pets.length) {
      final pet = _pets[previousIndex];
      final dador = pet.publisherType == 'individual_rescuer' ? 'la familia dante' : 'el refugio';
      if (direction == CardSwiperDirection.right) {
        _lastSwipeFeedback = '¡Postulación enviada por ${pet.name}! $dador revisará tu formulario.';
      } else if (direction == CardSwiperDirection.top) {
        _lastSwipeFeedback = '⭐ ¡Super-Adopción enviada por ${pet.name}!';
      } else {
        _lastSwipeFeedback = null;
      }
      notifyListeners();
    }
    return true;
  }

  void swipeLeft() {
    cardSwiperController.swipe(CardSwiperDirection.left);
  }

  void swipeRight() {
    cardSwiperController.swipe(CardSwiperDirection.right);
  }

  void swipeTop() {
    cardSwiperController.swipe(CardSwiperDirection.top);
  }

  @override
  void dispose() {
    cardSwiperController.dispose();
    super.dispose();
  }
}
