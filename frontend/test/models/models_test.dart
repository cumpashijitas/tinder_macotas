import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/match_model.dart';
import 'package:frontend/models/story_model.dart';
import 'package:frontend/models/adopter_form_model.dart';
import 'package:frontend/models/profile_model.dart';

void main() {
  group('MatchModel', () {
    test('isChatEnabled es true solo para los 3 estados que habilitan chat', () {
      for (final status in ['approved_for_chat', 'interview_scheduled', 'adoption_finalized']) {
        final m = MatchModel.fromJson({'id': 'm', 'status': status});
        expect(m.isChatEnabled, isTrue, reason: status);
      }
      for (final status in ['pending_review', 'rejected']) {
        final m = MatchModel.fromJson({'id': 'm', 'status': status});
        expect(m.isChatEnabled, isFalse, reason: status);
      }
    });

    test('parsea adopterName y adopterForm anidados cuando vienen del backend', () {
      final m = MatchModel.fromJson({
        'id': 'm1',
        'status': 'pending_review',
        'adopter': {'full_name': 'Bruno Silva'},
        'adopter_form': {'housing_type': 'apartment', 'housing_status': 'rented_allowed'},
      });

      expect(m.adopterName, 'Bruno Silva');
      expect(m.adopterForm, isNotNull);
      expect(m.adopterForm!.housingType, 'apartment');
    });

    test('sin datos anidados, adopterName y adopterForm son null (no inventa datos)', () {
      final m = MatchModel.fromJson({'id': 'm1', 'status': 'pending_review'});
      expect(m.adopterName, isNull);
      expect(m.adopterForm, isNull);
    });
  });

  group('StoryModel', () {
    test('likedBy y likeCount reflejan story_likes del backend', () {
      final s = StoryModel.fromJson({
        'id': 's1',
        'author_id': 'a1',
        'pet_name': 'Toby',
        'title': 'Título',
        'content': 'Contenido',
        'story_likes': [
          {'user_id': 'u1'},
          {'user_id': 'u2'},
        ],
      });

      expect(s.likeCount, 2);
      expect(s.likedBy('u1'), isTrue);
      expect(s.likedBy('u3'), isFalse);
      expect(s.likedBy(null), isFalse);
    });

    test('toggleLike agrega o quita el propio like sin mutar la instancia original', () {
      final s = StoryModel.fromJson({
        'id': 's1',
        'author_id': 'a1',
        'pet_name': 'Toby',
        'title': 'Título',
        'content': 'Contenido',
        'story_likes': <Map<String, dynamic>>[],
      });

      final liked = s.toggleLike('u1');
      expect(liked.likedBy('u1'), isTrue);
      expect(s.likedBy('u1'), isFalse); // el original no cambia

      final unliked = liked.toggleLike('u1');
      expect(unliked.likedBy('u1'), isFalse);
    });
  });

  group('AdopterFormModel labels', () {
    test('housingTypeLabel y housingStatusLabel traducen los códigos del schema', () {
      final form = AdopterFormModel(housingType: 'house', housingStatus: 'rented_pending_permission');
      expect(form.housingTypeLabel, 'Casa');
      expect(form.housingStatusLabel, 'Alquiler (permiso pendiente)');
    });

    test('householdMembersLabel cubre todos los valores del enum', () {
      const expected = {
        'alone': 'Vive solo/a',
        'couple': 'En pareja',
        'family_with_young_kids': 'Familia con niños pequeños',
        'family_with_teens': 'Familia con adolescentes',
        'roommates': 'Con compañeros de casa',
      };
      expected.forEach((code, label) {
        final form = AdopterFormModel(householdMembers: code);
        expect(form.householdMembersLabel, label);
      });
    });
  });

  group('ProfileModel', () {
    test('roleTitle traduce cada rol del sistema', () {
      const expected = {
        'adopter': 'Adoptante',
        'shelter': 'Refugio u ONG',
        'individual_rescuer': 'Particular con Camada / Rescatista',
        'admin': 'Administrador',
      };
      expected.forEach((role, title) {
        final p = ProfileModel(id: 'x', fullName: 'Test', role: role);
        expect(p.roleTitle, title);
      });
    });
  });
}
