import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/controllers/pet_filter_controller.dart';
import 'package:frontend/models/pet_model.dart';

void main() {
  group('PetModel and PetFilterController Tests', () {
    late PetModel sampleDog;
    late PetModel sampleCat;
    late PetModel relocatedPet;
    late PetFilterController filterController;

    setUp(() {
      sampleDog = PetModel(
        id: 'd1',
        shelterId: 's1',
        publisherType: 'shelter',
        name: 'Toby',
        species: 'dog',
        breed: 'Labrador',
        ageYears: 2.0,
        gender: 'male',
        size: 'medium',
        energyLevel: 3,
        origin: 'street_rescue',
        isVaccinated: true,
        isNeutered: true,
        goodWithDogs: true,
        goodWithCats: false,
        goodWithKids: true,
        requiresYard: false,
        story: 'Perro alegre y muy cariñoso.',
        photos: ['https://example.com/toby.jpg'],
        status: 'available',
      );

      sampleCat = PetModel(
        id: 'c1',
        shelterId: 's2',
        publisherType: 'individual_rescuer',
        name: 'Michi',
        species: 'cat',
        breed: 'Siamés',
        ageYears: 0.5,
        gender: 'female',
        size: 'small',
        energyLevel: 2,
        origin: 'home_litter',
        isVaccinated: true,
        isNeutered: false,
        goodWithDogs: false,
        goodWithCats: true,
        goodWithKids: true,
        requiresYard: false,
        story: 'Gatita bebé.',
        photos: ['https://example.com/michi.jpg'],
        status: 'available',
      );

      relocatedPet = PetModel(
        id: 'r1',
        shelterId: 'u1',
        publisherType: 'individual_rescuer',
        name: 'Max',
        species: 'dog',
        breed: 'Pastor Alemán',
        ageYears: 5.0,
        gender: 'male',
        size: 'large',
        energyLevel: 4,
        origin: 'relinquished',
        isVaccinated: true,
        isNeutered: true,
        goodWithDogs: true,
        goodWithCats: true,
        goodWithKids: true,
        requiresYard: true,
        story: 'Reubicación por mudanza internacional forzada.',
        photos: ['https://example.com/max.jpg'],
        status: 'available',
        relocationReason: 'Mudanza al extranjero por trabajo con imposibilidad de transporte',
      );

      filterController = PetFilterController();
    });

    test('Age stages getters compute correctly', () {
      expect(sampleCat.ageStage, 'puppy');
      expect(sampleCat.ageStageLabel, 'Cachorro (<1 año)');

      expect(sampleDog.ageStage, 'young');
      expect(sampleDog.ageStageLabel, 'Joven (1-3 años)');

      expect(relocatedPet.ageStage, 'adult');
      expect(relocatedPet.ageStageLabel, 'Adulto (3-7 años)');
    });

    test('Relocation flag and badges work correctly', () {
      expect(relocatedPet.isRelocated, isTrue);
      expect(sampleDog.isRelocated, isFalse);
      expect(relocatedPet.relocationReason, isNotNull);
    });

    test('Filter by species works', () {
      final all = [sampleDog, sampleCat, relocatedPet];

      filterController.setSelectedSpecies('dog');
      var results = filterController.applyFilters(all);
      expect(results.length, 2);
      expect(results.every((p) => p.species == 'dog'), isTrue);

      filterController.setSelectedSpecies('cat');
      results = filterController.applyFilters(all);
      expect(results.length, 1);
      expect(results.first.name, 'Michi');
    });

    test('Filter by relocation publisher works', () {
      final all = [sampleDog, sampleCat, relocatedPet];

      filterController.setSelectedPublisherType('relinquished');
      final results = filterController.applyFilters(all);
      expect(results.length, 1);
      expect(results.first.name, 'Max');
      expect(results.first.isRelocated, isTrue);
    });

    test('Filter by age stage works', () {
      final all = [sampleDog, sampleCat, relocatedPet];

      filterController.toggleAgeStage('puppy');
      final results = filterController.applyFilters(all);
      expect(results.length, 1);
      expect(results.first.name, 'Michi');
    });

    test('Filter reset clears all selections', () {
      filterController.setSelectedSpecies('cat');
      filterController.toggleAgeStage('puppy');
      filterController.setOnlyGoodWithKids(true);
      expect(filterController.activeFilterCount, greaterThan(0));

      filterController.resetFilters();
      expect(filterController.selectedSpecies, 'all');
      expect(filterController.selectedAgeStages, isEmpty);
      expect(filterController.activeFilterCount, 0);
    });

    test('View mode toggle toggles between Grid and Swipe', () {
      expect(filterController.isGridView, isTrue);
      filterController.toggleViewMode();
      expect(filterController.isGridView, isFalse);
      filterController.setViewMode(true);
      expect(filterController.isGridView, isTrue);
    });
  });
}
