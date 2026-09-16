import '../models/adopter_form_model.dart';
import '../models/pet_model.dart';

class CompatibilityResult {
  final int percentage;
  final List<String> positiveMatches;
  final List<String> warnings;

  CompatibilityResult({
    required this.percentage,
    required this.positiveMatches,
    required this.warnings,
  });

  String get matchBadgeText => '$percentage% Match';
}

class CompatibilityService {
  /// Algoritmo de ponderación de compatibilidad entre el hogar del adoptante
  /// y los requerimientos físicos/emocionales de la mascota.
  static CompatibilityResult calculateMatch({
    required AdopterFormModel adopter,
    required PetModel pet,
  }) {
    int score = 65; // Base neutra
    final List<String> positives = [];
    final List<String> warnings = [];

    // 1. Espacio y Vivienda vs Requerimientos del Animal
    if (pet.requiresYard) {
      if (adopter.hasYard) {
        score += 15;
        positives.add('Tu casa cuenta con el patio que este animal necesita');
      } else {
        score -= 25;
        warnings.add('Esta mascota requiere patio cerrado obligatorio');
      }
    } else {
      if (adopter.housingType == 'apartment') {
        if (pet.species == 'cat') {
          if (adopter.hasProtectiveNetting) {
            score += 15;
            positives.add('Tu departamento cuenta con red de seguridad para gatos');
          } else {
            score -= 20;
            warnings.add('Se recomienda red en balcones y ventanas para este gatito');
          }
        } else {
          score += 5;
          positives.add('Apto para vivir en departamento');
        }
      }
    }

    // 2. Composición del Hogar (Niños)
    final hasKids = adopter.householdMembers == 'family_with_young_kids';
    if (hasKids) {
      if (pet.goodWithKids) {
        score += 10;
        positives.add('Excelente temperamento y paciencia con niños pequeños');
      } else {
        score -= 25;
        warnings.add('No recomendado para convivir con niños pequeños');
      }
    }

    // 3. Convivencia con otras mascotas
    if (adopter.hasOtherPets) {
      if (pet.species == 'dog' && pet.goodWithDogs) {
        score += 10;
        positives.add('Muy sociable con otros perros');
      } else if (pet.species == 'cat' && pet.goodWithCats) {
        score += 10;
        positives.add('Sociable con otros gatos');
      } else if (!pet.goodWithDogs || !pet.goodWithCats) {
        score -= 15;
        warnings.add('Puede presentar dificultades de socialización con otras mascotas');
      }
    }

    // 4. Horas de Soledad vs Nivel de Energía
    if (adopter.hoursPetAlonePerDay > 8 && pet.energyLevel >= 4) {
      score -= 20;
      warnings.add('Tiene mucha energía para pasar más de 8 horas en soledad');
    } else if (adopter.hoursPetAlonePerDay <= 5) {
      score += 10;
      positives.add('Tendrás tiempo suficiente para acompañar su rutina');
    }

    // 5. Presupuesto y Compromiso
    if (adopter.monthlyBudgetConfirmed && adopter.emergencyFundAvailable) {
      score += 10;
      positives.add('Cuentas con la solvencia veterinaria que el dador solicita');
    }

    // Asegurar rango 15% - 98%
    final finalPercentage = score.clamp(15, 98);

    return CompatibilityResult(
      percentage: finalPercentage,
      positiveMatches: positives,
      warnings: warnings,
    );
  }
}
