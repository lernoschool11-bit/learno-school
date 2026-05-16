import prisma from '../lib/prisma';
import { AuthRequest } from '../middleware/auth';

// ═══════════════════════════════════════════════════════════════
// Audit Service — "الصندوق الأسود"
// ═══════════════════════════════════════════════════════════════
// Central logging service for all sensitive operations.
// Call writeAudit() from any controller after a mutation.
//
// Example:
//   await writeAudit(req, {
//     action: 'UPDATE_GRADE',
//     entity: 'grade',
//     entityId: gradeId,
//     oldValue: { score: 15 },
//     newValue: { score: 20 },
//     description: 'المعلم أحمد عدّل علامة الطالب محمد من 15 إلى 20',
//   });
// ═══════════════════════════════════════════════════════════════

export interface AuditPayload {
    action: string;
    entity: string;
    entityId: string;
    oldValue?: Record<string, any> | null;
    newValue?: Record<string, any> | null;
    description?: string;
}

/**
 * Write an audit log entry.
 * This runs asynchronously and does NOT throw on failure
 * (we never want audit logging to break the main operation).
 */
export const writeAudit = async (req: AuthRequest, payload: AuditPayload): Promise<void> => {
    try {
        const user = req.user;
        if (!user) {
            console.warn('[AUDIT] ⚠ Cannot write audit: no user context');
            return;
        }

        const schoolId = user.schoolId || 'unknown';

        await prisma.auditLog.create({
            data: {
                userId: user.id,
                userRole: user.role,
                userName: undefined, // Will be filled below
                action: payload.action,
                entity: payload.entity,
                entityId: payload.entityId,
                oldValue: payload.oldValue ?? undefined,
                newValue: payload.newValue ?? undefined,
                description: payload.description ?? null,
                schoolId,
                ipAddress: getClientIp(req),
                userAgent: req.headers['user-agent'] || null,
            },
        });

        console.log(
            `[AUDIT] ✅ ${payload.action} on ${payload.entity}:${payload.entityId} ` +
            `by user ${user.id} (${user.role}) from ${getClientIp(req)}`
        );
    } catch (error) {
        // Never let audit failure crash the main flow
        console.error('[AUDIT] ❌ Failed to write audit log:', error);
    }
};

/**
 * Write audit for a batch of changes (e.g. bulk grade update).
 */
export const writeAuditBatch = async (
    req: AuthRequest,
    payloads: AuditPayload[]
): Promise<void> => {
    try {
        const user = req.user;
        if (!user) return;

        const schoolId = user.schoolId || 'unknown';
        const ip = getClientIp(req);
        const ua = req.headers['user-agent'] || null;

        await prisma.auditLog.createMany({
            data: payloads.map((p) => ({
                userId: user.id,
                userRole: user.role,
                action: p.action,
                entity: p.entity,
                entityId: p.entityId,
                oldValue: p.oldValue ?? undefined,
                newValue: p.newValue ?? undefined,
                description: p.description ?? null,
                schoolId,
                ipAddress: ip,
                userAgent: ua,
            })),
        });
    } catch (error) {
        console.error('[AUDIT] ❌ Failed to write batch audit:', error);
    }
};

/**
 * Extract the real client IP, respecting proxies (X-Forwarded-For).
 */
function getClientIp(req: AuthRequest): string {
    const forwarded = req.headers['x-forwarded-for'];
    if (typeof forwarded === 'string') {
        return forwarded.split(',')[0].trim();
    }
    if (Array.isArray(forwarded)) {
        return forwarded[0];
    }
    return req.ip || req.socket?.remoteAddress || 'unknown';
}
