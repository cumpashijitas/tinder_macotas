import express from 'express';
import cors from 'cors';
import { ENV } from './config/env.js';
import { ResponseView } from './views/response.view.js';
import { authRouter } from './routes/auth.routes.js';
import { adopterRouter } from './routes/adopter.routes.js';
import { petRouter } from './routes/pet.routes.js';
import { swipeRouter } from './routes/swipe.routes.js';

const app = express();

// Middlewares globales
app.use(cors());
app.use(express.json());

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

// Manejo de rutas inexistentes (404)
app.use((_req, res) => {
  ResponseView.notFound(res, 'Ruta no encontrada');
});

// Inicio del servidor
if (process.env.NODE_ENV !== 'test') {
  app.listen(ENV.PORT, () => {
    console.log(`🐾 Servidor PetMatch Backend escuchando en http://localhost:${ENV.PORT}`);
    console.log(`🌍 Entorno: ${ENV.NODE_ENV}`);
  });
}

export default app;
