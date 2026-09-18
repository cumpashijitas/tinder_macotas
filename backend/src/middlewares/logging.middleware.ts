import { Request, Response, NextFunction } from 'express';
import { AuthenticatedRequest } from './auth.middleware.js';

/**
 * Log estructurado (JSON, una línea por request) de método, ruta, status,
 * duración y usuario autenticado si lo hay. Vercel captura stdout/stderr de
 * las funciones serverless, así que esto ya queda disponible en sus logs
 * sin necesitar un servicio externo.
 */
export function requestLogger(req: Request, res: Response, next: NextFunction): void {
  const start = Date.now();

  res.on('finish', () => {
    const entry = {
      timestamp: new Date().toISOString(),
      method: req.method,
      path: req.originalUrl,
      status: res.statusCode,
      durationMs: Date.now() - start,
      userId: (req as AuthenticatedRequest).user?.id ?? null,
    };

    const line = JSON.stringify(entry);
    if (res.statusCode >= 500) {
      console.error(line);
    } else if (res.statusCode >= 400) {
      console.warn(line);
    } else {
      console.log(line);
    }
  });

  next();
}
