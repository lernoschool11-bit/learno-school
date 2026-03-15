import { Response } from 'express';
import prisma from '../lib/prisma';
import { AuthRequest } from '../middleware/auth';
import { createNotification } from './notificationController';

// ==================== GET USER PROFILE ====================
export const getUserProfile = async (req: AuthRequest, res: Response) => {
  try {
    const currentUserId = req.user!.id;
    const targetUserId = String(req.params.userId);

    const user = await prisma.user.findUnique({
      where: { id: targetUserId },
      select: {
        id: true,
        fullName: true,
        username: true,
        role: true,
        school: true,
        grade: true,
        section: true,
        subjects: true,
        avatarUrl: true,
        createdAt: true,
        posts: {
          where: {
            OR: [
              { expiresAt: null },
              { expiresAt: { gt: new Date() } }
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
            likes: { select: { userId: true } },
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
          },
          orderBy: { createdAt: 'desc' }
        },
        _count: {
          select: {
            posts: true,
            followers: true,
            following: true,
          }
        },
        followers: {
          select: {
            followerId: true,
            follower: {
              select: {
                id: true,
                fullName: true,
                username: true,
                role: true,
                avatarUrl: true,
              }
            }
          }
        },
        following: {
          select: {
            followingId: true,
            following: {
              select: {
                id: true,
                fullName: true,
                username: true,
                role: true,
                avatarUrl: true,
              }
            }
          }
        },
      }
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const isFollowing = user.followers.some(
      (f: any) => f.followerId === currentUserId
    );

    const postsWithLiked = user.posts.map(post => ({
      ...post,
      isLiked: post.likes.some((like: { userId: string }) => like.userId === currentUserId),
      likesCount: post.likes.length,
      commentsCount: post.comments.length,
    }));

    const followersList = user.followers.map((f: any) => f.follower);
    const followingList = user.following.map((f: any) => f.following);

    return res.status(200).json({
      ...user,
      posts: postsWithLiked,
      isFollowing,
      followersCount: user._count.followers,
      followingCount: user._count.following,
      postsCount: user._count.posts,
      followers: followersList,
      following: followingList,
    });
  } catch (error) {
    console.error('getUserProfile error:', error);
    return res.status(500).json({ error: 'Failed to get user profile' });
  }
};

// ==================== FOLLOW / UNFOLLOW ====================
export const toggleFollow = async (req: AuthRequest, res: Response) => {
  try {
    const followerId = req.user!.id;
    const followingId = String(req.params.userId);

    if (followerId === followingId) {
      return res.status(400).json({ error: 'Cannot follow yourself' });
    }

    const targetUser = await prisma.user.findUnique({ where: { id: followingId } });
    if (!targetUser) {
      return res.status(404).json({ error: 'User not found' });
    }

    const existingFollow = await prisma.follow.findUnique({
      where: {
        followerId_followingId: { followerId, followingId }
      }
    });

    if (existingFollow) {
      await prisma.follow.delete({
        where: {
          followerId_followingId: { followerId, followingId }
        }
      });

      const followersCount = await prisma.follow.count({ where: { followingId } });
      return res.json({ isFollowing: false, followersCount });
    } else {
      await prisma.follow.create({
        data: { followerId, followingId }
      });

      const followersCount = await prisma.follow.count({ where: { followingId } });

      const actor = await prisma.user.findUnique({
        where: { id: followerId },
        select: { fullName: true }
      });
      await createNotification({
        userId: followingId,
        actorId: followerId,
        type: 'FOLLOW',
        message: `${actor?.fullName} بدأ بمتابعتك`,
      });

      return res.json({ isFollowing: true, followersCount });
    }
  } catch (error) {
    console.error('toggleFollow error:', error);
    return res.status(500).json({ error: 'Failed to toggle follow' });
  }
};

// ==================== GET FOLLOWERS ====================
export const getFollowers = async (req: AuthRequest, res: Response) => {
  try {
    const userId = String(req.params.userId);

    const followers = await prisma.follow.findMany({
      where: { followingId: userId },
      include: {
        follower: {
          select: {
            id: true,
            fullName: true,
            username: true,
            role: true,
            school: true,
            avatarUrl: true,
          }
        }
      }
    });

    return res.status(200).json(followers.map((f: any) => f.follower));
  } catch (error) {
    console.error('getFollowers error:', error);
    return res.status(500).json({ error: 'Failed to get followers' });
  }
};

// ==================== GET FOLLOWING ====================
export const getFollowing = async (req: AuthRequest, res: Response) => {
  try {
    const userId = String(req.params.userId);

    const following = await prisma.follow.findMany({
      where: { followerId: userId },
      include: {
        following: {
          select: {
            id: true,
            fullName: true,
            username: true,
            role: true,
            school: true,
            avatarUrl: true,
          }
        }
      }
    });

    return res.status(200).json(following.map((f: any) => f.following));
  } catch (error) {
    console.error('getFollowing error:', error);
    return res.status(500).json({ error: 'Failed to get following' });
  }
};