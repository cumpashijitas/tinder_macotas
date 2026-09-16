import crypto from 'crypto';
import { supabaseAdmin } from '../config/supabase.js';

export interface ContractRecord {
  id: string;
  match_id: string;
  adopter_id: string;
  shelter_id: string;
  terms_version: string;
  signed_by_adopter: boolean;
  signed_by_adopter_at: string | null;
  signed_by_shelter: boolean;
  signed_by_shelter_at: string | null;
  signature_hash: string | null;
  created_at: string;
  updated_at: string;
}

export class ContractModel {
  static async getMatch(matchId: string): Promise<{ adopter_id: string; shelter_id: string; status: string } | null> {
    const { data, error } = await supabaseAdmin
      .from('matches')
      .select('adopter_id, shelter_id, status')
      .eq('id', matchId)
      .maybeSingle();

    if (error) throw error;
    return data;
  }

  static async findByMatchId(matchId: string): Promise<ContractRecord | null> {
    const { data, error } = await supabaseAdmin
      .from('adoption_contracts')
      .select('*')
      .eq('match_id', matchId)
      .maybeSingle();

    if (error) throw error;
    return data as ContractRecord | null;
  }

  static async create(matchId: string, adopterId: string, shelterId: string): Promise<ContractRecord> {
    const { data, error } = await supabaseAdmin
      .from('adoption_contracts')
      .insert({
        match_id: matchId,
        adopter_id: adopterId,
        shelter_id: shelterId,
        terms_version: 'v1',
      })
      .select()
      .single();

    if (error) throw error;
    return data as ContractRecord;
  }

  /**
   * Firma el contrato por la parte que corresponda. Cuando ambas partes firmaron,
   * genera el hash de validez y finaliza la adopción (matches.status = adoption_finalized).
   */
  static async sign(contract: ContractRecord, signerId: string): Promise<ContractRecord> {
    const isAdopter = signerId === contract.adopter_id;
    const isShelter = signerId === contract.shelter_id;

    const patch: Record<string, unknown> = { updated_at: new Date().toISOString() };
    if (isAdopter) {
      patch.signed_by_adopter = true;
      patch.signed_by_adopter_at = new Date().toISOString();
    }
    if (isShelter) {
      patch.signed_by_shelter = true;
      patch.signed_by_shelter_at = new Date().toISOString();
    }

    const bothWillBeSigned =
      (isAdopter || contract.signed_by_adopter) && (isShelter || contract.signed_by_shelter);

    if (bothWillBeSigned && !contract.signature_hash) {
      patch.signature_hash = crypto
        .createHash('sha256')
        .update(`${contract.match_id}:${contract.adopter_id}:${contract.shelter_id}:${Date.now()}`)
        .digest('hex');
    }

    const { data, error } = await supabaseAdmin
      .from('adoption_contracts')
      .update(patch)
      .eq('id', contract.id)
      .select()
      .single();

    if (error) throw error;

    if (bothWillBeSigned) {
      await supabaseAdmin
        .from('matches')
        .update({ status: 'adoption_finalized', updated_at: new Date().toISOString() })
        .eq('id', contract.match_id)
        .neq('status', 'adoption_finalized');
    }

    return data as ContractRecord;
  }
}
