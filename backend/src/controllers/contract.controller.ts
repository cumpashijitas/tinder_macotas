import { Response } from 'express';
import { AuthenticatedRequest } from '../middlewares/auth.middleware.js';
import { ContractModel } from '../models/contract.model.js';
import { AuditLogModel } from '../models/audit_log.model.js';
import { ResponseView } from '../views/response.view.js';
import { parsePagination } from '../utils/pagination.js';

export class ContractController {
  /**
   * Historial consolidado: todos los contratos donde el usuario participa
   */
  static async listAll(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user?.id;
    if (!userId) {
      ResponseView.unauthorized(res);
      return;
    }

    try {
      const { limit, offset } = parsePagination(req.query as Record<string, unknown>, 50);
      const { items, hasMore } = await ContractModel.listForUser(userId, { limit, offset });
      ResponseView.success(res, items, 'Contratos recuperados', 200, { limit, offset, hasMore });
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }

  /**
   * Obtener el contrato de un match (si existe)
   */
  static async get(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user?.id;
    const matchId = Array.isArray(req.params.matchId) ? req.params.matchId[0] : req.params.matchId;

    if (!userId || !matchId) {
      ResponseView.error(res, 'ID de match requerido', 400);
      return;
    }

    try {
      const match = await ContractModel.getMatch(matchId);
      if (!match || (match.adopter_id !== userId && match.shelter_id !== userId)) {
        ResponseView.forbidden(res, 'No participás de este match');
        return;
      }

      const contract = await ContractModel.findByMatchId(matchId);
      ResponseView.success(res, contract, 'Contrato recuperado');
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }

  /**
   * Crear el contrato de adopción para un match (lo inicia el refugio)
   */
  static async create(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user?.id;
    const matchId = Array.isArray(req.params.matchId) ? req.params.matchId[0] : req.params.matchId;

    if (!userId || !matchId) {
      ResponseView.error(res, 'ID de match requerido', 400);
      return;
    }

    try {
      const match = await ContractModel.getMatch(matchId);
      if (!match) {
        ResponseView.notFound(res, 'Match no encontrado');
        return;
      }

      if (match.shelter_id !== userId) {
        ResponseView.forbidden(res, 'Solo el refugio/publicador puede iniciar el contrato');
        return;
      }

      if (!['interview_scheduled', 'adoption_finalized', 'approved_for_chat'].includes(match.status)) {
        ResponseView.error(res, 'El match debe estar aprobado antes de generar el contrato', 422);
        return;
      }

      const existing = await ContractModel.findByMatchId(matchId);
      if (existing) {
        ResponseView.error(res, 'El contrato para este match ya existe', 409);
        return;
      }

      const contract = await ContractModel.create(matchId, match.adopter_id, match.shelter_id);
      ResponseView.success(res, contract, 'Contrato de adopción creado', 201);
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }

  /**
   * Firmar el contrato con la identidad del usuario autenticado
   */
  static async sign(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user?.id;
    const matchId = Array.isArray(req.params.matchId) ? req.params.matchId[0] : req.params.matchId;

    if (!userId || !matchId) {
      ResponseView.error(res, 'ID de match requerido', 400);
      return;
    }

    try {
      const contract = await ContractModel.findByMatchId(matchId);
      if (!contract) {
        ResponseView.notFound(res, 'Contrato no encontrado');
        return;
      }

      if (contract.adopter_id !== userId && contract.shelter_id !== userId) {
        ResponseView.forbidden(res, 'No participás de este match');
        return;
      }

      const updated = await ContractModel.sign(contract, userId);
      await AuditLogModel.record(userId, 'contract_signed', 'adoption_contracts', contract.id, { matchId });
      ResponseView.success(res, updated, 'Contrato firmado correctamente');
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }
}
