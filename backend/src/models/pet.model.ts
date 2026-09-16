import { supabaseAdmin } from '../config/supabase.js';

export interface PetRecord {
  id: string;
  shelter_id: string; // ID del publicador (refugio o particular)
  publisher_type: 'shelter' | 'individual_rescuer';
  name: string;
  species: 'dog' | 'cat' | 'other';
  breed: string;
  age_years: number;
  gender: 'male' | 'female';
  size: 'small' | 'medium' | 'large' | 'giant';
  energy_level: number;

  // Origen y Camadas
  origin: 'home_litter' | 'street_rescue' | 'shelter_born' | 'relinquished';
  is_litter: boolean;
  birth_date?: string | null;
  weaning_completed: boolean; // Destete completado (mínimo 60 días)

  // Plan Sanitario y Reproducción
  is_vaccinated: boolean;
  vaccines_applied: string[]; // Ej: ['Antirrábica', 'Séxtuple', 'Triple Felina']
  dewormed_internal: boolean;
  dewormed_external: boolean; // Pipeta contra pulgas/garrapatas
  has_microchip: boolean;
  is_neutered: boolean;
  reproductive_status: 'neutered' | 'spayed' | 'requires_spay_agreement' | 'intact';

  // Hábitos y Comportamiento
  house_trained: boolean;
  good_with_dogs: boolean;
  good_with_cats: boolean;
  good_with_kids: boolean;
  requires_yard: boolean;
  storm_anxiety: number; // 1 (sin miedo) a 5 (pánico severo)
  special_needs?: string | null;
  story: string;

  // Requisitos de Entrega
  requires_adoption_contract: boolean;
  requires_home_check: boolean;
  requires_followup_photos: boolean;
  delivery_type: 'pickup_at_shelter' | 'home_delivery' | 'to_be_agreed';

  photos: string[];
  status: 'available' | 'paused' | 'in_process' | 'adopted';
  relocation_reason?: string | null;
  created_at: string;
  updated_at: string;
}

export class PetModel {
  static async findById(id: string): Promise<PetRecord | null> {
    const { data, error } = await supabaseAdmin
      .from('pets')
      .select('*')
      .eq('id', id)
      .maybeSingle();

    if (error) throw error;
    return data as PetRecord | null;
  }

  /**
   * Obtiene las mascotas disponibles para un adoptante que aún NO hayan sido swipéadas
   * Permite filtrar opcionalmente por especie y tipo de publicador (refugio o camada particular)
   */
  static async getFeedForAdopter(
    adopterId: string,
    options: { limit?: number; species?: string; publisherType?: string } = {}
  ): Promise<PetRecord[]> {
    const limit = options.limit || 20;

    // 1. Obtener IDs de mascotas ya swipéadas por este usuario
    const { data: swipedPets, error: swipeError } = await supabaseAdmin
      .from('swipes')
      .select('pet_id')
      .eq('adopter_id', adopterId);

    if (swipeError) throw swipeError;

    const excludedPetIds = (swipedPets || []).map((s) => s.pet_id);

    // 2. Consultar mascotas disponibles
    let query = supabaseAdmin
      .from('pets')
      .select('*')
      .eq('status', 'available')
      .order('created_at', { ascending: false })
      .limit(limit);

    if (options.species) {
      query = query.eq('species', options.species);
    }

    if (options.publisherType) {
      query = query.eq('publisher_type', options.publisherType);
    }

    if (excludedPetIds.length > 0) {
      query = query.not('id', 'in', `(${excludedPetIds.join(',')})`);
    }

    const { data, error } = await query;
    if (error) throw error;

    return (data || []) as PetRecord[];
  }

  static async create(pet: Omit<PetRecord, 'id' | 'created_at' | 'updated_at'>): Promise<PetRecord> {
    const { data, error } = await supabaseAdmin
      .from('pets')
      .insert(pet)
      .select()
      .single();

    if (error) throw error;
    return data as PetRecord;
  }

  static async updateStatus(
    id: string,
    shelterId: string,
    status: PetRecord['status']
  ): Promise<PetRecord> {
    const { data, error } = await supabaseAdmin
      .from('pets')
      .update({ status, updated_at: new Date().toISOString() })
      .eq('id', id)
      .eq('shelter_id', shelterId)
      .select()
      .single();

    if (error) throw error;
    return data as PetRecord;
  }

  static async findByShelterId(shelterId: string): Promise<PetRecord[]> {
    const { data, error } = await supabaseAdmin
      .from('pets')
      .select('*')
      .eq('shelter_id', shelterId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return (data || []) as PetRecord[];
  }
}
