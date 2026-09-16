import { supabaseAdmin } from '../config/supabase.js';

export interface SwipeRecord {
  id: string;
  adopter_id: string;
  pet_id: string;
  direction: 'left' | 'right' | 'superlike';
  created_at: string;
}

export class SwipeModel {
  static async recordSwipe(
    adopterId: string,
    petId: string,
    direction: 'left' | 'right' | 'superlike'
  ): Promise<{ swipe: SwipeRecord; matchCreated: boolean }> {
    // 1. Guardar el swipe
    const { data: swipe, error: swipeError } = await supabaseAdmin
      .from('swipes')
      .upsert(
        {
          adopter_id: adopterId,
          pet_id: petId,
          direction,
        },
        { onConflict: 'adopter_id,pet_id' }
      )
      .select()
      .single();

    if (swipeError) throw swipeError;

    let matchCreated = false;

    // 2. Si el swipe fue a la derecha o superlike, se genera la postulación/match
    if (direction === 'right' || direction === 'superlike') {
      // Obtener el shelter_id de la mascota
      const { data: pet, error: petError } = await supabaseAdmin
        .from('pets')
        .select('shelter_id')
        .eq('id', petId)
        .single();

      if (!petError && pet) {
        const { error: matchError } = await supabaseAdmin
          .from('matches')
          .upsert(
            {
              pet_id: petId,
              adopter_id: adopterId,
              shelter_id: pet.shelter_id,
              status: 'pending_review',
            },
            { onConflict: 'pet_id,adopter_id' }
          );

        if (!matchError) {
          matchCreated = true;
        }
      }
    }

    return { swipe: swipe as SwipeRecord, matchCreated };
  }
}
