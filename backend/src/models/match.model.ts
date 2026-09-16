import { supabaseAdmin } from '../config/supabase.js';

export interface MatchRecord {
  id: string;
  pet_id: string;
  adopter_id: string;
  shelter_id: string;
  status: 'pending_review' | 'approved_for_chat' | 'interview_scheduled' | 'rejected' | 'adoption_finalized';
  shelter_comments?: string | null;
  created_at: string;
  updated_at: string;
}

export class MatchModel {
  static async getMatchesByUserId(userId: string, role: 'adopter' | 'shelter'): Promise<unknown[]> {
    const column = role === 'shelter' ? 'shelter_id' : 'adopter_id';

    const { data, error } = await supabaseAdmin
      .from('matches')
      .select(`
        *,
        pets (*),
        adopter:profiles!matches_adopter_id_fkey (*),
        adopter_form:adopter_forms!adopter_forms_user_id_fkey (*)
      `)
      .eq(column, userId)
      .order('created_at', { ascending: false });

    if (error) {
      // Si la consulta relacional con joins falla por falta de llaves específicas de Supabase, fallback a consulta simple
      const { data: fallbackData, error: fallbackError } = await supabaseAdmin
        .from('matches')
        .select('*, pets (*)')
        .eq(column, userId)
        .order('created_at', { ascending: false });

      if (fallbackError) throw fallbackError;
      return fallbackData || [];
    }

    return data || [];
  }

  static async updateStatus(
    matchId: string,
    shelterId: string,
    status: MatchRecord['status'],
    comments?: string
  ): Promise<MatchRecord> {
    const { data, error } = await supabaseAdmin
      .from('matches')
      .update({
        status,
        shelter_comments: comments,
        updated_at: new Date().toISOString(),
      })
      .eq('id', matchId)
      .eq('shelter_id', shelterId)
      .select()
      .single();

    if (error) throw error;
    return data as MatchRecord;
  }
}
