import { supabaseAdmin } from '../config/supabase.js';

export interface VisitRecord {
  id: string;
  match_id: string;
  requested_by: string;
  proposed_at: string;
  status: 'pending' | 'confirmed' | 'declined' | 'completed' | 'cancelled';
  notes?: string | null;
  created_at: string;
  updated_at: string;
}

export class VisitModel {
  static async getMatchParticipants(matchId: string): Promise<{ adopter_id: string; shelter_id: string } | null> {
    const { data, error } = await supabaseAdmin
      .from('matches')
      .select('adopter_id, shelter_id')
      .eq('id', matchId)
      .maybeSingle();

    if (error) throw error;
    return data;
  }

  static async findByMatchId(matchId: string): Promise<VisitRecord[]> {
    const { data, error } = await supabaseAdmin
      .from('visit_requests')
      .select('*')
      .eq('match_id', matchId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return (data || []) as VisitRecord[];
  }

  static async findById(id: string): Promise<VisitRecord | null> {
    const { data, error } = await supabaseAdmin
      .from('visit_requests')
      .select('*')
      .eq('id', id)
      .maybeSingle();

    if (error) throw error;
    return data as VisitRecord | null;
  }

  static async create(matchId: string, requestedBy: string, proposedAt: string, notes?: string): Promise<VisitRecord> {
    const { data, error } = await supabaseAdmin
      .from('visit_requests')
      .insert({
        match_id: matchId,
        requested_by: requestedBy,
        proposed_at: proposedAt,
        notes: notes || null,
      })
      .select()
      .single();

    if (error) throw error;
    return data as VisitRecord;
  }

  static async updateStatus(id: string, status: VisitRecord['status']): Promise<VisitRecord> {
    const { data, error } = await supabaseAdmin
      .from('visit_requests')
      .update({ status, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data as VisitRecord;
  }
}
