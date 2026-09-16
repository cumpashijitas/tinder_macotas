import { supabaseAdmin } from '../config/supabase.js';

export interface MessageRecord {
  id: string;
  match_id: string;
  sender_id: string;
  content: string;
  is_read: boolean;
  created_at: string;
}

export class MessageModel {
  static async isParticipant(matchId: string, userId: string): Promise<{ ok: boolean; status?: string }> {
    const { data, error } = await supabaseAdmin
      .from('matches')
      .select('adopter_id, shelter_id, status')
      .eq('id', matchId)
      .maybeSingle();

    if (error) throw error;
    if (!data) return { ok: false };

    const ok = data.adopter_id === userId || data.shelter_id === userId;
    return { ok, status: data.status };
  }

  static async findByMatchId(matchId: string): Promise<MessageRecord[]> {
    const { data, error } = await supabaseAdmin
      .from('messages')
      .select('*')
      .eq('match_id', matchId)
      .order('created_at', { ascending: true });

    if (error) throw error;
    return (data || []) as MessageRecord[];
  }

  static async create(matchId: string, senderId: string, content: string): Promise<MessageRecord> {
    const { data, error } = await supabaseAdmin
      .from('messages')
      .insert({ match_id: matchId, sender_id: senderId, content, is_read: false })
      .select()
      .single();

    if (error) throw error;
    return data as MessageRecord;
  }

  static async markReadForRecipient(matchId: string, recipientId: string): Promise<void> {
    const { error } = await supabaseAdmin
      .from('messages')
      .update({ is_read: true })
      .eq('match_id', matchId)
      .neq('sender_id', recipientId)
      .eq('is_read', false);

    if (error) throw error;
  }
}
