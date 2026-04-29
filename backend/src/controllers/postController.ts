import { Response } from 'express';
import { PostType, Role } from '@prisma/client';
import prisma from '../lib/prisma';
import { AuthRequest } from '../middleware/auth';
import { createNotification } from './notificationController';

// ==================== FEED ====================
export const getFeed = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user!.id;

    const posts = await prisma.post.findMany({
      where: {
        AND: [
          { author: { school: req.user?.school } },
          {
            OR: [
              { expiresAt: null },
              { expiresAt: { gt: new Date() } }
            ]
          }
        ]
      },

      include: {
        author: {
          select: {
            id: true,
            fullName: true,
            username: true,
            role: true,
            school: true,
            grade: true,
            section: true,
            avatarUrl: true,
          }
        },
        comments: {
          include: {
            author: {
              select: {
                id: true,
                fullName: true,
                username: true,
                role: true,
                avatarUrl: true,
              }
            }
          },
          orderBy: { createdAt: 'asc' }
        },
        likes: {
          select: {
            userId: true,
          }
        },
      },
      orderBy: { createdAt: 'desc' }
    });

    const postsWithLiked = (posts as any[]).map(post => ({
      ...post,
      isLiked: post.likes.some((like: { userId: string }) => like.userId === userId),
      likesCount: post.likes.length,
      commentsCount: post.comments.length,
    }));

    return res.status(200).json(postsWithLiked);
  } catch (error) {
    console.error('getFeed error:', error);
    return res.status(500).json({ error: 'Failed to get feed' });
  }
};

// ==================== CREATE POST ====================
export const createPost = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const user = req.user!;
    const { content, title, mediaUrl, type, expiresAt } = req.body;

    if (!content || !type) {
      return res.status(400).json({ error: 'Content and type are required' });
    }

    if (!Object.values(PostType).includes(type)) {
      return res.status(400).json({ error: 'Invalid post type' });
    }

    if (type === PostType.VIDEO && user.role !== Role.TEACHER) {
      return res.status(403).json({ error: 'Only teachers can upload educational videos' });
    }

    const postExpiresAt =
      type === PostType.STORY
        ? new Date(Date.now() + 24 * 60 * 60 * 1000)
        : expiresAt
        ? new Date(expiresAt)
        : null;

    const post = await prisma.post.create({
      data: {
        content,
        title,
        mediaUrl,
        type: type || 'TEXT',
        expiresAt: postExpiresAt,
        authorId: userId,
        schoolId: req.user!.schoolId,
      },
      include: {
        author: {
          select: {
            id: true,
            fullName: true,
            username: true,
            role: true,
            avatarUrl: true,
          }
        },
      }
    });

    return res.status(201).json({
      ...post,
      likes: [],
      comments: [],
      isLiked: false,
      likesCount: 0,
      commentsCount: 0,
    });
  } catch (error) {
    console.error('createPost error:', error);
    return res.status(500).json({ error: 'Failed to create post' });
  }
};

// ==================== LIKE / UNLIKE ====================
export const toggleLike = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const postId = String(req.params.id);

    const post = await prisma.post.findUnique({ where: { id: postId } });
    if (!post) {
      return res.status(404).json({ error: 'Post not found' });
    }

    const existingLike = await prisma.like.findUnique({
      where: {
        postId_userId: { postId, userId }
      }
    });

    if (existingLike) {
      await prisma.like.delete({
        where: {
          postId_userId: { postId, userId }
        }
      });

      const likesCount = await prisma.like.count({ where: { postId: postId } });
      return res.json({ isLiked: false, likesCount });
    } else {
      await prisma.like.create({
        data: { postId: postId, userId: userId }
      });

      const likesCount = await prisma.like.count({ where: { postId: postId } });

      const actor = await prisma.user.findUnique({
        where: { id: userId },
        select: { fullName: true }
      });
      await createNotification({
        userId: post.authorId,
        actorId: userId,
        type: 'LIKE',
        message: `${actor?.fullName} أعجب بمنشورك`,
        postId: postId,
      });

      return res.json({ isLiked: true, likesCount });
    }
  } catch (error) {
    console.error('toggleLike error:', error);
    return res.status(500).json({ error: 'Failed to toggle like' });
  }
};

// ==================== GET COMMENTS ====================
export const getComments = async (req: AuthRequest, res: Response) => {
  try {
    const postId = String(req.params.id);

    const comments = await prisma.comment.findMany({
      where: { postId: postId },
      include: {
        author: {
          select: {
            id: true,
            fullName: true,
            username: true,
            role: true,
            avatarUrl: true,
          }
        }
      },
      orderBy: { createdAt: 'asc' }
    });

    return res.status(200).json(comments);
  } catch (error) {
    console.error('getComments error:', error);
    return res.status(500).json({ error: 'Failed to get comments' });
  }
};

// ==================== ADD COMMENT ====================
export const addComment = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const postId = String(req.params.id);
    const { content } = req.body;

    if (!content || content.trim() === '') {
      return res.status(400).json({ error: 'Comment content is required' });
    }

    const post = await prisma.post.findUnique({ where: { id: postId } });
    if (!post) {
      return res.status(404).json({ error: 'Post not found' });
    }

    const comment = await prisma.comment.create({
      data: {
        content: content.trim(),
        postId: postId,
        authorId: userId,
      },
      include: {
        author: {
          select: {
            id: true,
            fullName: true,
            username: true,
            role: true,
            avatarUrl: true,
          }
        }
      }
    });

    await createNotification({
      userId: post.authorId,
      actorId: userId,
      type: 'COMMENT',
      message: `${comment.author.fullName} علّق على منشورك: "${content.trim().substring(0, 30)}${content.length > 30 ? '...' : ''}"`,
      postId: postId,
    });

    return res.status(201).json(comment);
  } catch (error) {
    console.error('addComment error:', error);
    return res.status(500).json({ error: 'Failed to add comment' });
  }
};

// ==================== DELETE COMMENT ====================
export const deleteComment = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const commentId = String(req.params.commentId);

    const comment = await prisma.comment.findUnique({
      where: { id: commentId }
    });

    if (!comment) {
      return res.status(404).json({ error: 'Comment not found' });
    }

    if (comment.authorId !== userId) {
      return res.status(403).json({ error: 'Not authorized' });
    }

    await prisma.comment.delete({ where: { id: commentId } });

    return res.status(200).json({ message: 'Comment deleted successfully' });
  } catch (error) {
    console.error('deleteComment error:', error);
    return res.status(500).json({ error: 'Failed to delete comment' });
  }
};

// ==================== DELETE POST ====================
export const deletePost = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const postId = String(req.params.id);

    const post = await prisma.post.findUnique({ where: { id: postId } });

    if (!post) {
      return res.status(404).json({ error: 'Post not found' });
    }

    if (post.authorId !== userId && req.user!.role !== Role.PRINCIPAL) {
      return res.status(403).json({ error: 'Not authorized' });
    }

    if (req.user!.role === Role.PRINCIPAL && post.schoolId !== req.user!.schoolId) {
      return res.status(403).json({ error: 'Not authorized for this school' });
    }

    await prisma.post.delete({ where: { id: postId } });

    return res.status(200).json({ message: 'Post deleted successfully' });
  } catch (error) {
    console.error('deletePost error:', error);
    return res.status(500).json({ error: 'Failed to delete post' });
  }
};