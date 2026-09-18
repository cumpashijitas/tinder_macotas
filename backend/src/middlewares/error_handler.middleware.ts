import { Request, Response, NextFunction } from 'express';
import { ResponseView } from '../views/response.view.js';

/**
 * Red de seguridad final: todos los controllers ya atrapan sus propios
 * errores con try/catch, pero si algo se escapa (un throw sincrónico en un
 * middleware, por ejemplo) esto evita que Express devuelva su página HTML
 * de error por defecto y rompa el contrato JSON de la API.
 * Debe registrarse último, después de las rutas y del handler de 404.
 */
export function errorHandler(err: unknown, _req: Request, res: Response, _next: NextFunction): void {
  console.error('Error no controlado:', err);
  if (res.headersSent) return;
  ResponseView.internalError(res, err);
}
