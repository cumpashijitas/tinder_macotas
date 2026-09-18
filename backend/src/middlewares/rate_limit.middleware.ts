import rateLimit from 'express-rate-limit';
import { ResponseView } from '../views/response.view.js';

/**
 * Límite general para toda la API: protege contra fuerza bruta y abuso
 * básico sin afectar el uso normal de la app.
 */
export const apiRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 300,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (_req, res) => {
    ResponseView.error(res, 'Demasiadas solicitudes. Probá de nuevo en unos minutos.', 429);
  },
});

/**
 * Límite estricto para el envío de OTP: sin esto, nada impide pedir
 * códigos en loop hacia el mismo correo (abuso del servicio de email de
 * Supabase, o enumeración de cuentas registradas).
 */
export const otpRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 5,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (_req, res) => {
    ResponseView.error(
      res,
      'Pediste demasiados códigos de verificación. Esperá unos minutos antes de volver a intentar.',
      429
    );
  },
});
