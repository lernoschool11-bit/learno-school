import { Response, NextFunction } from 'express';
import { Role } from '@prisma/client';
import { AuthRequest } from './auth';

// ═══════════════════════════════════════════════════════════════
// RBAC — Role-Based Access Control  ("نظام الرتب")
// ═══════════════════════════════════════════════════════════════
//
// Permission Hierarchy:
//   PRINCIPAL  → Master Key (full access to their school)
//   ADMIN      → System administrator
//   TEACHER    → Grades, assignments, class management
//   STUDENT    → Read-only + own submissions
//
// Usage in routes:
//   router.get('/sensitive',
//     requireAuth,
//     tenantGuard,
//     rbac('MANAGE_GRADES'),      // ← checks specific permission
//     controller.handler
//   );
// ═══════════════════════════════════════════════════════════════

/**
 * Fine-grained permission map.
 * Each permission lists the roles that are allowed.
 */
const PERMISSIONS: Record<string, Role[]> = {
    // ── School Management ────────────────────────────────
    MANAGE_SCHOOL:        [Role.PRINCIPAL, Role.ADMIN],
    VIEW_SCHOOL_STATS:    [Role.PRINCIPAL, Role.ADMIN, Role.TEACHER],
    MANAGE_USERS:         [Role.PRINCIPAL, Role.ADMIN],
    FREEZE_USER:          [Role.PRINCIPAL, Role.ADMIN],
    DELETE_USER:          [Role.PRINCIPAL],

    // ── Academic ─────────────────────────────────────────
    MANAGE_GRADES:        [Role.PRINCIPAL, Role.TEACHER],
    VIEW_CLASS_GRADES:    [Role.PRINCIPAL, Role.ADMIN, Role.TEACHER],
    VIEW_OWN_GRADES:      [Role.STUDENT],

    // ── Content ──────────────────────────────────────────
    CREATE_POST:          [Role.PRINCIPAL, Role.ADMIN, Role.TEACHER, Role.STUDENT],
    DELETE_ANY_POST:      [Role.PRINCIPAL, Role.ADMIN],
    MODERATE_COMMENTS:    [Role.PRINCIPAL, Role.ADMIN, Role.TEACHER],

    // ── Communication ────────────────────────────────────
    MANAGE_ONLINE_CLASS:  [Role.PRINCIPAL, Role.TEACHER],
    SEND_DM:             [Role.PRINCIPAL, Role.ADMIN, Role.TEACHER, Role.STUDENT],

    // ── Audit & Security ─────────────────────────────────
    VIEW_AUDIT_LOGS:      [Role.PRINCIPAL, Role.ADMIN],
    EXPORT_AUDIT_LOGS:    [Role.PRINCIPAL],

    // ── Settings ─────────────────────────────────────────
    UPDATE_TEACHER_CODE:  [Role.PRINCIPAL],
    CHANGE_PASSWORD:      [Role.PRINCIPAL, Role.ADMIN, Role.TEACHER, Role.STUDENT],
};

/**
 * Middleware factory that checks if the user's role has a specific permission.
 *
 * @param permission — key from the PERMISSIONS map
 *
 * @example
 *   router.delete('/users/:id', requireAuth, rbac('DELETE_USER'), controller.delete);
 */
export const rbac = (permission: string) => {
    return (req: AuthRequest, res: Response, next: NextFunction) => {
        if (!req.user) {
            return res.status(401).json({ error: 'Authentication required' });
        }

        const allowedRoles = PERMISSIONS[permission];

        if (!allowedRoles) {
            console.error(`[RBAC] ❌ Unknown permission: "${permission}"`);
            return res.status(500).json({ error: 'Internal permission configuration error' });
        }

        if (!allowedRoles.includes(req.user.role)) {
            console.warn(
                `[RBAC] ⛔ Denied: user ${req.user.id} (role: ${req.user.role}) ` +
                `tried action "${permission}" — allowed roles: [${allowedRoles.join(', ')}]`
            );
            return res.status(403).json({
                error: 'ليس لديك الصلاحية للقيام بهذا الإجراء',
                code: 'INSUFFICIENT_PERMISSIONS',
                required: permission,
            });
        }

        next();
    };
};

/**
 * Check multiple permissions (user must have ALL of them).
 *
 * @example
 *   router.post('/action', requireAuth, rbacAll('MANAGE_GRADES', 'VIEW_AUDIT_LOGS'), handler);
 */
export const rbacAll = (...permissions: string[]) => {
    return (req: AuthRequest, res: Response, next: NextFunction) => {
        if (!req.user) {
            return res.status(401).json({ error: 'Authentication required' });
        }

        for (const perm of permissions) {
            const allowedRoles = PERMISSIONS[perm];
            if (!allowedRoles || !allowedRoles.includes(req.user.role)) {
                return res.status(403).json({
                    error: 'ليس لديك الصلاحية للقيام بهذا الإجراء',
                    code: 'INSUFFICIENT_PERMISSIONS',
                    required: perm,
                });
            }
        }

        next();
    };
};

/**
 * Check multiple permissions (user needs at least ONE).
 *
 * @example
 *   router.get('/data', requireAuth, rbacAny('MANAGE_GRADES', 'VIEW_CLASS_GRADES'), handler);
 */
export const rbacAny = (...permissions: string[]) => {
    return (req: AuthRequest, res: Response, next: NextFunction) => {
        if (!req.user) {
            return res.status(401).json({ error: 'Authentication required' });
        }

        const hasAny = permissions.some((perm) => {
            const allowedRoles = PERMISSIONS[perm];
            return allowedRoles && allowedRoles.includes(req.user!.role);
        });

        if (!hasAny) {
            return res.status(403).json({
                error: 'ليس لديك الصلاحية للقيام بهذا الإجراء',
                code: 'INSUFFICIENT_PERMISSIONS',
                required: permissions,
            });
        }

        next();
    };
};

export { PERMISSIONS };
