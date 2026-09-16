import { describe, it, expect } from 'vitest';
import { AdopterFormModel, AdopterFormInput } from '../models/adopter_form.model.js';

function baseInput(overrides: Partial<AdopterFormInput> = {}): AdopterFormInput {
  return {
    housing_type: 'house',
    housing_status: 'owned',
    has_yard: true,
    has_protective_netting: false,
    household_members: 'couple',
    all_members_agree: true,
    has_allergies: false,
    hours_pet_alone_per_day: 4,
    has_other_pets: false,
    other_pets_details: null,
    previous_pet_experience: 'Varios años con perros',
    monthly_budget_confirmed: true,
    emergency_fund_available: true,
    agrees_to_follow_up: true,
    agrees_to_mandatory_neutering: true,
    ...overrides,
  };
}

describe('AdopterFormModel.calculateSuitabilityScore', () => {
  it('aprueba a un adoptante ideal (vivienda propia, patio, poca soledad, compromiso total)', () => {
    const result = AdopterFormModel.calculateSuitabilityScore(baseInput());
    expect(result.status).toBe('approved');
    expect(result.score).toBeGreaterThanOrEqual(70);
  });

  it('rechaza automáticamente si no todo el hogar está de acuerdo, sin importar el resto', () => {
    const result = AdopterFormModel.calculateSuitabilityScore(
      baseInput({ all_members_agree: false, housing_status: 'owned', has_yard: true })
    );
    expect(result.status).toBe('rejected');
    expect(result.score).toBe(10);
  });

  it('rechaza automáticamente si no acepta seguimiento o castración obligatoria', () => {
    const result = AdopterFormModel.calculateSuitabilityScore(
      baseInput({ agrees_to_mandatory_neutering: false })
    );
    expect(result.status).toBe('rejected');
    expect(result.score).toBe(15);
  });

  it('penaliza fuertemente el alquiler con permiso pendiente (riesgo de desalojo)', () => {
    const result = AdopterFormModel.calculateSuitabilityScore(
      baseInput({ housing_status: 'rented_pending_permission', has_yard: false })
    );
    expect(result.score).toBeLessThan(50);
  });

  it('penaliza más de 10 horas de soledad diaria', () => {
    const withHighAlone = AdopterFormModel.calculateSuitabilityScore(
      baseInput({ hours_pet_alone_per_day: 12 })
    );
    const withLowAlone = AdopterFormModel.calculateSuitabilityScore(
      baseInput({ hours_pet_alone_per_day: 3 })
    );
    expect(withHighAlone.score).toBeLessThan(withLowAlone.score);
  });

  it('marca requires_interview para puntajes intermedios (40-69)', () => {
    const result = AdopterFormModel.calculateSuitabilityScore(
      baseInput({
        housing_status: 'rented_allowed',
        has_yard: false,
        has_allergies: true,
        hours_pet_alone_per_day: 7,
      })
    );
    expect(result.status).toBe('requires_interview');
    expect(result.score).toBeGreaterThanOrEqual(40);
    expect(result.score).toBeLessThan(70);
  });

  it('nunca devuelve un puntaje fuera del rango 0-100', () => {
    const worst = AdopterFormModel.calculateSuitabilityScore(
      baseInput({
        housing_status: 'rented_pending_permission',
        has_yard: false,
        has_allergies: true,
        hours_pet_alone_per_day: 15,
        monthly_budget_confirmed: false,
        emergency_fund_available: false,
      })
    );
    expect(worst.score).toBeGreaterThanOrEqual(0);
    expect(worst.score).toBeLessThanOrEqual(100);
  });
});
