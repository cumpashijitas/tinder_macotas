import express, { RequestHandler } from 'express';
import cors from 'cors';
import helmetImport from 'helmet';
import { ENV } from './config/env.js';
import { ResponseView } from './views/response.view.js';
import { apiRateLimiter } from './middlewares/rate_limit.middleware.js';
import { authRouter } from './routes/auth.routes.js';
import { adopterRouter } from './routes/adopter.routes.js';
import { petRouter } from './routes/pet.routes.js';
import { swipeRouter } from './routes/swipe.routes.js';
import { messageRouter } from './routes/message.routes.js';
import { visitRouter, visitStatusRouter } from './routes/visit.routes.js';
import { contractRouter } from './routes/contract.routes.js';
import { storyRouter } from './routes/story.routes.js';
import { notificationRouter } from './routes/notification.routes.js';

// El `exports` map de helmet (import→.mjs / require→.cjs con un único
// `types: index.d.cts`) resuelve el tipo del default export de forma
// inconsistente entre plataformas bajo moduleResolution NodeNext (funciona
// en Windows, falla el build en el Linux de Vercel) aunque el export real
// en runtime siempre es la función factory. Se fija el tipo a mano para no
// depender de ese resolver.
const helmet = helmetImport as unknown as (options?: Record<string, unknown>) => RequestHandler;

const app = express();

// El backend corre detrás del proxy de Vercel: sin esto, express-rate-limit
// no puede confiar en X-Forwarded-For para identificar al cliente real.
app.set('trust proxy', 1);

// Middlewares globales
app.use(helmet());
app.use(
  cors({
    origin: (origin, callback) => {
      // Sin header Origin (curl, apps móviles, server-to-server): se permite,
      // ya que CORS sólo protege contra el navegador de terceros sitios.
      // Un origen no permitido simplemente no recibe los headers de CORS
      // (el navegador bloquea la lectura de la respuesta); no hace falta
      // cortar la request con un error.
      callback(null, !origin || ENV.ALLOWED_ORIGINS.includes(origin));
    },
    credentials: true,
  })
);
app.use(express.json());

// Límite general de tasa para toda la API (protección básica contra abuso/fuerza bruta)
app.use('/api', apiRateLimiter);

// Endpoint de salud
app.get('/health', (_req, res) => {
  ResponseView.success(
    res,
    { status: 'healthy', timestamp: new Date().toISOString() },
    'API PetMatch funcionando correctamente'
  );
});

// Rutas de la API REST
app.use('/api/auth', authRouter);
app.use('/api/adopter', adopterRouter);
app.use('/api/pets', petRouter);
app.use('/api/swipes', swipeRouter);
app.use('/api/matches', messageRouter);
app.use('/api/matches', visitRouter);
app.use('/api/visits', visitStatusRouter);
app.use('/api/contracts', contractRouter);
app.use('/api/stories', storyRouter);
app.use('/api/notifications', notificationRouter);

// Manejo de rutas inexistentes (404)
app.use((_req, res) => {
  ResponseView.notFound(res, 'Ruta no encontrada');
});

// Inicio del servidor (se omite en tests y en el entorno serverless de Vercel,
// que invoca el export por request en lugar de mantener un puerto abierto)
if (process.env.NODE_ENV !== 'test' && !process.env.VERCEL) {
  app.listen(ENV.PORT, () => {
    console.log(`🐾 Servidor PetMatch Backend escuchando en http://localhost:${ENV.PORT}`);
    console.log(`🌍 Entorno: ${ENV.NODE_ENV}`);
  });
}

export default app;
