import { supabaseAdmin } from '../config/supabase.js';

export class AuditLogModel {
  /**
   * Registra una acción sensible (moderación, cambio de estado de match,
   * firma de contrato). Es "fire and forget" a propósito: si falla el log,
   * no debe tumbar la operación real que lo originó — sólo se avisa por
   * consola para no perder la traza silenciosamente.
   */
  static async record(
    actorId: string,
    action: string,
    targetTable: string,
    targetId: string | null,
    metadata?: Record<string, unknown>
  ): Promise<void> {
    const { error } = await supabaseAdmin.from('audit_logs').insert({
      actor_id: actorId,
      action,
      target_table: targetTable,
      target_id: targetId,
      metadata: metadata || null,
    });

    if (error) {
      console.error('No se pudo registrar en audit_logs:', error);
    }
  }
}
