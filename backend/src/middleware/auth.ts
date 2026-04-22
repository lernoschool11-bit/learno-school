import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { Role } from '@prisma/client';
import prisma from "../lib/prisma";

const JWT_SECRET = process.env.JWT_SECRET || 'fallback-secret-for-dev';

// Extend Express Request to hold the authenticated user context
export interface AuthRequest extends Request {
    user?: {
        id: string;
        role: Role;
        nationalId: string;
        schoolId?: string | null;
        school?: string | null;
    };
}

/**
 * Validates the JWT and ensures the user exists.
 */
export const requireAuth = async (req: AuthRequest, res: Response, next: NextFunction) => {
    try {
        const token = req.header('Authorization')?.replace('Bearer ', '');
        if (!token) return res.status(401).json({ error: 'Authentication token is required' });

        const decoded = jwt.verify(token, JWT_SECRET) as any;

        // Quick validation via DB to ensure user hasn't been revoked
        const user = await prisma.user.findUnique({
            where: { id: decoded.id },
            select: { id: true, role: true, nationalId: true, schoolId: true, school: true, isActive: true }
        });

        if (!user) return res.status(401).json({ error: 'User not found or access revoked' });
        if (!user.isActive) return res.status(403).json({ error: 'تم تجميد حسابك، يرجى مراجعة إدارة المدرسة' });

        req.user = user;
        next();
    } catch (error) {
        res.status(401).json({ error: 'Invalid or expired token' });
    }
};

/**
 * Middleware factory to enforce specific roles according to the SOP.
 * (e.g. only TEACHER can upload long videos or moderate comments)
 */
export const requireRole = (allowedRoles: Role[]) => {
    return (req: AuthRequest, res: Response, next: NextFunction) => {
        if (!req.user) {
            return res.status(401).json({ error: 'Authentication required' });
        }

        if (!allowedRoles.includes(req.user.role)) {
            return res.status(403).json({
                error: 'Forbidden: You do not have the required permissions for this action'
            });
        }

        next();
    };
};

export const authMiddleware = requireAuth;
