import { Response, NextFunction } from 'express';
import { AuthRequest } from './auth';

// ═══════════════════════════════════════════════════════════════
// Tenant Guard — "مفتاح الغرفة"
// ═══════════════════════════════════════════════════════════════
// Ensures that every authenticated request stays within its own
// school (tenant) boundary. If a user from School A tries to
// access resources belonging to School B, the guard rejects the
// request BEFORE it ever reaches the database.
//
// How it works:
//   1. Checks that the authenticated user has a schoolId.
//   2. If the request includes a :schoolId param OR a schoolId
//      in the body/query, it compares it to the user's own
//      schoolId extracted from the JWT-verified DB lookup.
//   3. Mismatch → 403 Forbidden. No exceptions.
// ═══════════════════════════════════════════════════════════════

export const tenantGuard = (req: AuthRequest, res: Response, next: NextFunction) => {
    // The user must be authenticated first (requireAuth runs before this)
    if (!req.user) {
        return res.status(401).json({ error: 'Authentication required before tenant check' });
    }

    const userSchoolId = req.user.schoolId;
    const userSchoolName = req.user.school;

    // User has no school context at all — block everything except public routes
    if (!userSchoolId && !userSchoolName) {
        return res.status(403).json({
            error: 'ليس لديك صلاحية الوصول — حسابك غير مرتبط بمدرسة',
            code: 'NO_TENANT',
        });
    }

    // ── Check route param (:schoolId) ─────────────────────────
    const paramSchoolId = req.params.schoolId;
    if (paramSchoolId && userSchoolId && paramSchoolId !== userSchoolId) {
        console.warn(
            `[TENANT-GUARD] ⛔ Blocked cross-tenant access: user ${req.user.id} ` +
            `(school: ${userSchoolId}) tried to access school ${paramSchoolId}`
        );
        return res.status(403).json({
            error: 'ممنوع — لا يمكنك الوصول إلى بيانات مدرسة أخرى',
            code: 'TENANT_MISMATCH',
        });
    }

    // ── Check body payload ────────────────────────────────────
    const bodySchoolId = req.body?.schoolId;
    if (bodySchoolId && userSchoolId && bodySchoolId !== userSchoolId) {
        console.warn(
            `[TENANT-GUARD] ⛔ Blocked body injection: user ${req.user.id} ` +
            `sent schoolId=${bodySchoolId} but belongs to ${userSchoolId}`
        );
        return res.status(403).json({
            error: 'ممنوع — محاولة تزوير معرف المدرسة',
            code: 'TENANT_BODY_MISMATCH',
        });
    }

    // ── Check query string ────────────────────────────────────
    const querySchoolId = req.query?.schoolId;
    if (querySchoolId && userSchoolId && querySchoolId !== userSchoolId) {
        console.warn(
            `[TENANT-GUARD] ⛔ Blocked query injection: user ${req.user.id} ` +
            `sent query schoolId=${querySchoolId} but belongs to ${userSchoolId}`
        );
        return res.status(403).json({
            error: 'ممنوع — محاولة تزوير معرف المدرسة',
            code: 'TENANT_QUERY_MISMATCH',
        });
    }

    // All checks passed — proceed
    next();
};

// ═══════════════════════════════════════════════════════════════
// Helper: Inject school filter into Prisma queries
// ═══════════════════════════════════════════════════════════════
// Use this in controllers to automatically scope queries to the
// user's school, so you never forget the WHERE clause.
//
// Example:
//   const where = buildTenantFilter(req);
//   const users = await prisma.user.findMany({ where });
// ═══════════════════════════════════════════════════════════════

export const buildTenantFilter = (req: AuthRequest) => {
    const { schoolId, school } = req.user!;

    if (schoolId) {
        return {
            OR: [
                { schoolId },
                ...(school ? [{ school: { contains: school, mode: 'insensitive' as const } }] : []),
            ],
        };
    }

    if (school) {
        return { school: { contains: school, mode: 'insensitive' as const } };
    }

    // Should never reach here if tenantGuard ran first, but fail-safe
    throw new Error('Cannot build tenant filter: no school context');
};
