import { z } from 'zod';
import { supabaseAdmin } from '../config/supabase.js';

// Esquema de validación estricto para el formulario de adopción
export const AdopterFormSchema = z.object({
  housing_type: z.enum(['house', 'apartment', 'farm', 'other']),
  housing_status: z.enum(['owned', 'rented_allowed', 'rented_pending_permission']),
  has_yard: z.boolean(),
  has_protective_netting: z.boolean(),
  household_members: z.enum(['alone', 'couple', 'family_with_young_kids', 'family_with_teens', 'roommates']),
  all_members_agree: z.boolean(),
  has_allergies: z.boolean(),
  hours_pet_alone_per_day: z.number().min(0).max(24),
  has_other_pets: z.boolean(),
  other_pets_details: z.string().optional().nullable(),
  previous_pet_experience: z.string().optional().nullable(),
  monthly_budget_confirmed: z.boolean(),
  emergency_fund_available: z.boolean(),
  agrees_to_follow_up: z.boolean(),
  agrees_to_mandatory_neutering: z.boolean(),
});

export type AdopterFormInput = z.infer<typeof AdopterFormSchema>;

export interface AdopterFormRecord extends AdopterFormInput {
  id: string;
  user_id: string;
  evaluation_status: 'pending' | 'approved' | 'requires_interview' | 'rejected';
  evaluation_score: number;
  reviewer_notes?: string | null;
  created_at: string;
  updated_at: string;
}

export class AdopterFormModel {
  /**
   * Algoritmo de idoneidad y scoring del adoptante:
   * Evalúa factores de riesgo (p.ej. horas solo, permiso de alquiler, redes en balcón)
   * y otorga un puntaje sobre 100.
   */
  static calculateSuitabilityScore(data: AdopterFormInput): { score: number; status: 'approved' | 'requires_interview' | 'rejected' } {
    let score = 50;

    // 1. Vivienda
    if (data.housing_status === 'rented_pending_permission') {
      score -= 25; // Riesgo de reclamo de desalojo
    } else {
      score += 10;
    }

    if (data.has_yard) score += 10;
    if (data.housing_type === 'apartment' && data.has_protective_netting) score += 10;

    // 2. Convivencia
    if (!data.all_members_agree) {
      return { score: 10, status: 'rejected' }; // Condición excluyente: todo el hogar debe estar de acuerdo
    }

    if (data.has_allergies) {
      score -= 10; // Requiere verificación o prueba de convivencia previa
    }

    // 3. Tiempo de soledad
    if (data.hours_pet_alone_per_day > 10) {
      score -= 20;
    } else if (data.hours_pet_alone_per_day <= 5) {
      score += 10;
    }

    // 4. Compromiso económico y veterinario
    if (!data.monthly_budget_confirmed || !data.emergency_fund_available) {
      score -= 25;
    } else {
      score += 10;
    }

    if (!data.agrees_to_follow_up || !data.agrees_to_mandatory_neutering) {
      return { score: 15, status: 'rejected' };
    }

    // Limitar entre 0 y 100
    score = Math.max(0, Math.min(100, score));

    let status: 'approved' | 'requires_interview' | 'rejected' = 'approved';
    if (score < 40) {
      status = 'rejected';
    } else if (score < 70) {
      status = 'requires_interview';
    }

    return { score, status };
  }

  static async findByUserId(userId: string): Promise<AdopterFormRecord | null> {
    const { data, error } = await supabaseAdmin
      .from('adopter_forms')
      .select('*')
      .eq('user_id', userId)
      .maybeSingle();

    if (error) throw error;
    return data as AdopterFormRecord | null;
  }

  static async upsertForm(userId: string, input: AdopterFormInput): Promise<AdopterFormRecord> {
    const evaluation = this.calculateSuitabilityScore(input);

    const payload = {
      user_id: userId,
      ...input,
      evaluation_score: evaluation.score,
      evaluation_status: evaluation.status,
      updated_at: new Date().toISOString(),
    };

    const { data, error } = await supabaseAdmin
      .from('adopter_forms')
      .upsert(payload, { onConflict: 'user_id' })
      .select()
      .single();

    if (error) throw error;
    return data as AdopterFormRecord;
  }
}
