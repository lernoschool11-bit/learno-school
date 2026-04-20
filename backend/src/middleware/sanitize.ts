import { Request, Response, NextFunction } from 'express';

/**
 * Input sanitization middleware to protect against XSS and injection.
 */
export const sanitizeInput = (req: Request, _res: Response, next: NextFunction) => {
    const sanitizeValue = (val: unknown): unknown => {
        if (typeof val === 'string') {
            return val
                .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '') // Remove <script>
                .replace(/on\w+="[^"]*"/gi, '') // Remove onmouseover, onclick, etc.
                .replace(/javascript:\S+/gi, '') // Remove javascript:
                .replace(/<[^>]*>?/gm, (match) => {
                    // Allow only safe tags if needed, otherwise strip all
                    const allowedTags = ['b', 'i', 'em', 'strong'];
                    const tag = match.replace(/[<>\/]/g, '').toLowerCase();
                    return allowedTags.includes(tag) ? match : '';
                })
                .trim();
        }
        if (Array.isArray(val)) {
            return val.map(v => sanitizeValue(v));
        }
        if (typeof val === 'object' && val !== null) {
            return sanitizeObject(val as Record<string, unknown>);
        }
        return val;
    };

    const sanitizeObject = (obj: Record<string, unknown>): Record<string, unknown> => {
        const result: Record<string, unknown> = {};
        for (const key of Object.keys(obj)) {
            result[key] = sanitizeValue(obj[key]);
        }
        return result;
    };

    if (req.body) req.body = sanitizeValue(req.body);
    if (req.query) req.query = sanitizeObject(req.query as Record<string, unknown>) as any;
    if (req.params) req.params = sanitizeObject(req.params as Record<string, unknown>) as any;

    next();
};
