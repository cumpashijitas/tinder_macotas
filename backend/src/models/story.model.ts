import { supabaseAdmin } from '../config/supabase.js';

export interface StoryRecord {
  id: string;
  match_id: string | null;
  author_id: string;
  pet_name: string;
  title: string;
  content: string;
  photo_url: string | null;
  created_at: string;
}

export class StoryModel {
  static async list(limit = 30): Promise<unknown[]> {
    const { data, error } = await supabaseAdmin
      .from('adoption_stories')
      .select('*, author:profiles!adoption_stories_author_id_fkey(full_name, avatar_url), story_likes(user_id)')
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) throw error;
    return data || [];
  }

  static async validateMatchOwnership(matchId: string, authorId: string): Promise<boolean> {
    const { data, error } = await supabaseAdmin
      .from('matches')
      .select('adopter_id, status')
      .eq('id', matchId)
      .maybeSingle();

    if (error) throw error;
    if (!data) return false;
    return data.adopter_id === authorId && data.status === 'adoption_finalized';
  }

  static async create(
    authorId: string,
    input: { match_id?: string | null; pet_name: string; title: string; content: string; photo_url?: string | null }
  ): Promise<StoryRecord> {
    const { data, error } = await supabaseAdmin
      .from('adoption_stories')
      .insert({
        author_id: authorId,
        match_id: input.match_id || null,
        pet_name: input.pet_name,
        title: input.title,
        content: input.content,
        photo_url: input.photo_url || null,
      })
      .select()
      .single();

    if (error) throw error;
    return data as StoryRecord;
  }

  static async like(storyId: string, userId: string): Promise<void> {
    const { error } = await supabaseAdmin
      .from('story_likes')
      .upsert({ story_id: storyId, user_id: userId }, { onConflict: 'story_id,user_id' });

    if (error) throw error;
  }

  static async unlike(storyId: string, userId: string): Promise<void> {
    const { error } = await supabaseAdmin
      .from('story_likes')
      .delete()
      .eq('story_id', storyId)
      .eq('user_id', userId);

    if (error) throw error;
  }
}
