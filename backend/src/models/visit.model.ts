import { supabaseAdmin } from '../config/supabase.js';
import { NotificationModel } from './notification.model.js';

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

  /**
   * Todas las visitas donde el usuario participa (como adoptante o refugio),
   * para el historial consolidado.
   */
  static async listForUser(
    userId: string,
    pagination: { limit?: number; offset?: number } = {}
  ): Promise<{ items: unknown[]; hasMore: boolean }> {
    const limit = pagination.limit || 50;
    const offset = pagination.offset || 0;

    const { data, error } = await supabaseAdmin
      .from('visit_requests')
      .select('*, matches!inner(*, pets(name, photos))')
      .or(`adopter_id.eq.${userId},shelter_id.eq.${userId}`, { referencedTable: 'matches' })
      .order('proposed_at', { ascending: false })
      .range(offset, offset + limit);

    if (error) throw error;

    const rows = data || [];
    const hasMore = rows.length > limit;
    return { items: hasMore ? rows.slice(0, limit) : rows, hasMore };
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

    const participants = await this.getMatchParticipants(matchId);
    if (participants) {
      const otherId = requestedBy === participants.adopter_id ? participants.shelter_id : participants.adopter_id;
      const dateLabel = new Date(proposedAt).toLocaleString('es-AR', { dateStyle: 'short', timeStyle: 'short' });
      await NotificationModel.create(
        otherId,
        'visit',
        'Nueva propuesta de visita',
        `Te proponen una visita para el ${dateLabel}.`,
        matchId
      );
    }

    return data as VisitRecord;
  }

  static async updateStatus(id: string, status: VisitRecord['status'], actorId: string): Promise<VisitRecord> {
    const { data, error } = await supabaseAdmin
      .from('visit_requests')
      .update({ status, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    const record = data as VisitRecord;
    const participants = await this.getMatchParticipants(record.match_id);
    if (participants) {
      const otherId = actorId === participants.adopter_id ? participants.shelter_id : participants.adopter_id;
      const STATUS_LABELS: Record<VisitRecord['status'], string> = {
        pending: 'pendiente',
        confirmed: 'confirmada',
        declined: 'rechazada',
        completed: 'completada',
        cancelled: 'cancelada',
      };
      await NotificationModel.create(
        otherId,
        'visit',
        'Actualización de visita',
        `La visita quedó ${STATUS_LABELS[status]}.`,
        record.match_id
      );
    }

    return record;
  }
}
