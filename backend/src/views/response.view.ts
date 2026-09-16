import { Response } from 'express';

export interface ApiResponse<T = unknown> {
  success: boolean;
  message?: string;
  data?: T;
  errors?: unknown;
}

export class ResponseView {
  static success<T>(res: Response, data: T, message?: string, statusCode = 200): Response {
    const payload: ApiResponse<T> = {
      success: true,
      message,
      data,
    };
    return res.status(statusCode).json(payload);
  }

  static error(res: Response, message: string, statusCode = 400, errors?: unknown): Response {
    const payload: ApiResponse = {
      success: false,
      message,
      errors,
    };
    return res.status(statusCode).json(payload);
  }

  static unauthorized(res: Response, message = 'Acceso no autorizado'): Response {
    return this.error(res, message, 401);
  }

  static forbidden(res: Response, message = 'No tienes permisos para realizar esta acción'): Response {
    return this.error(res, message, 403);
  }

  static notFound(res: Response, message = 'Recurso no encontrado'): Response {
    return this.error(res, message, 404);
  }

  static internalError(res: Response, error?: unknown): Response {
    console.error('API Internal Error:', error);
    return this.error(res, 'Error interno del servidor', 500, error instanceof Error ? error.message : undefined);
  }
}
