import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import routes from './routes';
import { apiLimiter } from './middleware/rateLimiter';
import { sanitizeInput } from './middleware/sanitize';

const app = express();
app.set('trust proxy', 1); 

app.use(express.json({ limit: '200mb' }));
app.use(express.urlencoded({ limit: '200mb', extended: true }));

app.use(cors({
    origin: true,
    credentials: true,
}));
app.use(helmet({
    crossOriginResourcePolicy: { policy: 'cross-origin' },
}));
app.use(apiLimiter);
app.use(sanitizeInput);
app.use(morgan('dev'));

app.use('/api', routes);

app.get('/api/health', (req, res) => {
    res.status(200).json({ status: 'OK', message: 'Educational Social Learning API is running' });
});

export default app;