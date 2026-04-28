import { Response } from 'express';
import prisma from '../lib/prisma';
import { Role } from "@prisma/client";
import { AuthRequest } from '../middleware/auth';

/**
 * Create a new online class (Teacher only).
 */
export const createOnlineClass = async (req: AuthRequest, res: Response) => {
    try {
        const user = req.user!;

        if (user.role !== Role.TEACHER && user.role !== Role.PRINCIPAL) {
            return res.status(403).json({ error: 'Only teachers or principals can start online classes' });
        }

        const { title, meetingUrl, grade, section, subject } = req.body;

        if (!title || !meetingUrl) {
            return res.status(400).json({ error: 'Title and Meeting URL are required' });
        }

        const onlineClass = await prisma.onlineClass.create({
            data: {
                title,
                meetingUrl,
                teacherId: user.id,
                schoolId: user.schoolId,
                grade: grade || null,
                section: section || null,
                subject: subject || null,
            },
            include: {
                teacher: {
                    select: { fullName: true, avatarUrl: true }
                }
            }
        });

        res.status(201).json(onlineClass);

    } catch (error) {
        console.error('Create Online Class Error:', error);
        res.status(500).json({ error: 'Failed to create online class' });
    }
};

/**
 * Get active online classes for the current user's school and grade/section.
 */
export const getActiveOnlineClasses = async (req: AuthRequest, res: Response) => {
    try {
        const user = req.user!;
        
        const where: any = {
            isActive: true,
            schoolId: user.schoolId,
        };

        // If student, filter by their grade and section to see classes relevant to them
        if (user.role === Role.STUDENT) {
            // We want to show classes that match their grade AND (section is null or matches their section)
            // Or maybe just matching grade is enough if section is not specified by teacher
            where.AND = [
                { OR: [{ grade: user.grade }, { grade: null }] },
                { OR: [{ section: user.section }, { section: null }] }
            ];
        }

        const classes = await prisma.onlineClass.findMany({
            where,
            orderBy: { startTime: 'desc' },
            include: {
                teacher: {
                    select: { fullName: true, avatarUrl: true, role: true }
                }
            }
        });

        res.status(200).json(classes);

    } catch (error) {
        console.error('Get Online Classes Error:', error);
        res.status(500).json({ error: 'Failed to fetch online classes' });
    }
};

/**
 * End an online class (Teacher only).
 */
export const endOnlineClass = async (req: AuthRequest, res: Response) => {
    try {
        const user = req.user!;
        const id = req.params.id as string;

        const onlineClass = await prisma.onlineClass.findUnique({
            where: { id }
        });

        if (!onlineClass) {
            return res.status(404).json({ error: 'Class not found' });
        }

        if (onlineClass.teacherId !== user.id && user.role !== Role.ADMIN && user.role !== Role.PRINCIPAL) {
            return res.status(403).json({ error: 'Not authorized to end this class' });
        }

        const updated = await prisma.onlineClass.update({
            where: { id },
            data: { isActive: false },
        });

        res.status(200).json(updated);

    } catch (error) {
        console.error('End Online Class Error:', error);
        res.status(500).json({ error: 'Failed to end online class' });
    }
};
