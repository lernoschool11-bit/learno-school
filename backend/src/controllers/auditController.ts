import { Response } from 'express';
import prisma from '../lib/prisma';
import { AuthRequest } from '../middleware/auth';

// ═══════════════════════════════════════════════════════════════
// Audit Controller — عرض سجلات "الصندوق الأسود"
// ═══════════════════════════════════════════════════════════════

/**
 * GET /api/admin/audit-logs
 * 
 * Query params:
 *   - page (default: 1)
 *   - limit (default: 50, max: 200)
 *   - action (filter by action type, e.g. "UPDATE_GRADE")
 *   - entity (filter by entity, e.g. "grade")
 *   - userId (filter by specific user)
 *   - from (ISO date string — start date)
 *   - to (ISO date string — end date)
 */
export const getAuditLogs = async (req: AuthRequest, res: Response) => {
    try {
        const { schoolId } = req.user!;
        if (!schoolId) {
            return res.status(403).json({ error: 'مطلوب معرف المدرسة' });
        }

        // ── Pagination ────────────────────────────────────
        const page = Math.max(1, parseInt(req.query.page as string) || 1);
        const limit = Math.min(200, Math.max(1, parseInt(req.query.limit as string) || 50));
        const skip = (page - 1) * limit;

        // ── Filters ───────────────────────────────────────
        const where: any = { schoolId };

        if (req.query.action) {
            where.action = String(req.query.action);
        }
        if (req.query.entity) {
            where.entity = String(req.query.entity);
        }
        if (req.query.userId) {
            where.userId = String(req.query.userId);
        }
        if (req.query.from || req.query.to) {
            where.createdAt = {};
            if (req.query.from) {
                where.createdAt.gte = new Date(String(req.query.from));
            }
            if (req.query.to) {
                where.createdAt.lte = new Date(String(req.query.to));
            }
        }

        // ── Query ─────────────────────────────────────────
        const [logs, total] = await Promise.all([
            prisma.auditLog.findMany({
                where,
                orderBy: { createdAt: 'desc' },
                skip,
                take: limit,
            }),
            prisma.auditLog.count({ where }),
        ]);

        return res.json({
            logs,
            pagination: {
                page,
                limit,
                total,
                totalPages: Math.ceil(total / limit),
            },
        });
    } catch (error) {
        console.error('getAuditLogs error:', error);
        return res.status(500).json({ error: 'فشل في جلب سجلات التدقيق' });
    }
};

/**
 * GET /api/admin/audit-logs/stats
 * Returns summary statistics for the audit log.
 */
export const getAuditStats = async (req: AuthRequest, res: Response) => {
    try {
        const { schoolId } = req.user!;
        if (!schoolId) {
            return res.status(403).json({ error: 'مطلوب معرف المدرسة' });
        }

        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const weekAgo = new Date();
        weekAgo.setDate(weekAgo.getDate() - 7);

        const [totalLogs, todayLogs, weekLogs, actionBreakdown] = await Promise.all([
            prisma.auditLog.count({ where: { schoolId } }),
            prisma.auditLog.count({
                where: { schoolId, createdAt: { gte: today } },
            }),
            prisma.auditLog.count({
                where: { schoolId, createdAt: { gte: weekAgo } },
            }),
            prisma.auditLog.groupBy({
                by: ['action'],
                where: { schoolId },
                _count: { id: true },
                orderBy: { _count: { id: 'desc' } },
                take: 10,
            }),
        ]);

        return res.json({
            totalLogs,
            todayLogs,
            weekLogs,
            topActions: actionBreakdown.map((a) => ({
                action: a.action,
                count: a._count.id,
            })),
        });
    } catch (error) {
        console.error('getAuditStats error:', error);
        return res.status(500).json({ error: 'فشل في جلب إحصائيات التدقيق' });
    }
};
