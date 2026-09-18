import { supabaseAdmin } from '../config/supabase.js';

export type NotificationType = 'new_match' | 'match_status' | 'new_message' | 'visit' | 'contract';

export interface NotificationRecord {
  id: string;
  user_id: string;
  type: NotificationType;
  title: string;
  body: string | null;
  related_id: string | null;
  is_read: boolean;
  created_at: string;
}

export class NotificationModel {
  /**
   * Crea una notificación. Nunca lanza: un fallo al notificar no debe
   * interrumpir la acción principal (swipe, mensaje, firma, etc.).
   */
  static async create(
    userId: string,
    type: NotificationType,
    title: string,
    body?: string | null,
    relatedId?: string | null
  ): Promise<void> {
    try {
      const { error } = await supabaseAdmin.from('notifications').insert({
        user_id: userId,
        type,
        title,
        body: body || null,
        related_id: relatedId || null,
      });
      if (error) {
        console.error('No se pudo crear la notificación:', error.message);
      }
    } catch (err) {
      console.error('No se pudo crear la notificación:', err);
    }
  }

  static async listForUser(
    userId: string,
    pagination: { limit?: number; offset?: number } = {}
  ): Promise<{ items: NotificationRecord[]; hasMore: boolean }> {
    const limit = pagination.limit || 50;
    const offset = pagination.offset || 0;

    const { data, error } = await supabaseAdmin
      .from('notifications')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit);

    if (error) throw error;

    const rows = (data || []) as NotificationRecord[];
    const hasMore = rows.length > limit;
    return { items: hasMore ? rows.slice(0, limit) : rows, hasMore };
  }

  static async countUnread(userId: string): Promise<number> {
    const { count, error } = await supabaseAdmin
      .from('notifications')
      .select('id', { count: 'exact', head: true })
      .eq('user_id', userId)
      .eq('is_read', false);

    if (error) throw error;
    return count || 0;
  }

  static async markRead(id: string, userId: string): Promise<void> {
    const { error } = await supabaseAdmin
      .from('notifications')
      .update({ is_read: true })
      .eq('id', id)
      .eq('user_id', userId);

    if (error) throw error;
  }

  static async markAllRead(userId: string): Promise<void> {
    const { error } = await supabaseAdmin
      .from('notifications')
      .update({ is_read: true })
      .eq('user_id', userId)
      .eq('is_read', false);

    if (error) throw error;
  }
}
