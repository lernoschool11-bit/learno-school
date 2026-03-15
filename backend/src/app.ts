import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import routes from './routes';
import { apiLimiter } from './middleware/rateLimiter';
import { sanitizeInput } from './middleware/sanitize';

const app = express();

// Security Middleware (SOP §11 Security Framework)
app.use(express.json());
app.use(cors({
    origin: true,
    credentials: true,
}));
app.use(helmet());
app.use(apiLimiter);          // Rate limiting
app.use(sanitizeInput);       // XSS input sanitization
app.use(morgan('dev'));

// API Routes
app.use('/api', routes);

// Basic Health Check Route
app.get('/api/health', (req, res) => {
    res.status(200).json({ status: 'OK', message: 'Educational Social Learning API is running' });
});

export default app;