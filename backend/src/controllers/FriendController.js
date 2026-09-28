import { Op } from 'sequelize';
import { Friend, User } from '../models/index.js';

class FriendController {
  /**
   * POST /friends (or /users/:id/friends)
   * Sends a friend request to another user.
   */
  async sendRequest(req, res) {
    try {
      const userId = req.user.id;
      const { friendId } = req.body;

      if (!friendId) {
        return res.status(400).json({
          success: false,
          error: 'friendId is required.',
        });
      }

      if (userId === friendId) {
        return res.status(400).json({
          success: false,
          error: 'You cannot send a friend request to yourself.',
        });
      }

      // Check if target user exists
      const targetUser = await User.findByPk(friendId, {
        attributes: ['id', 'username', 'level', 'streak'],
      });
      if (!targetUser) {
        return res.status(404).json({
          success: false,
          error: 'Target user not found.',
        });
      }

      // Check for existing connection in either direction
      const existing = await Friend.findOne({
        where: {
          [Op.or]: [
            { userId, friendId },
            { userId: friendId, friendId: userId },
          ],
        },
      });

      if (existing) {
        if (existing.status === 'BLOCKED') {
          return res.status(403).json({
            success: false,
            error: 'Unable to send friend request to this user.',
          });
        }
        if (existing.status === 'ACCEPTED') {
          return res.status(409).json({
            success: false,
            error: 'You are already friends with this user.',
          });
        }
        if (existing.userId === userId && existing.status === 'PENDING') {
          return res.status(409).json({
            success: false,
            error: 'Friend request already sent and pending acceptance.',
          });
        }
        // If the other user sent a pending request, auto-accept it!
        if (existing.userId === friendId && existing.status === 'PENDING') {
          existing.status = 'ACCEPTED';
          await existing.save();
          return res.status(200).json({
            success: true,
            message: 'Mutual friend request detected. Friendship accepted!',
            data: existing,
          });
        }
      }

      const newFriendship = await Friend.create({
        userId,
        friendId,
        status: 'PENDING',
      });

      return res.status(201).json({
        success: true,
        message: 'Friend request sent successfully.',
        data: newFriendship,
      });
    } catch (error) {
      console.error('[FriendController.sendRequest] Error:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to send friend request.',
        details: error.message,
      });
    }
  }

  /**
   * GET /friends (or /users/:id/friends)
   * Lists user's friends with filtering by status and pagination.
   */
  async listFriends(req, res) {
    try {
      const userId = req.user.id;
      const statusFilter = (req.query.status || 'ACCEPTED').toUpperCase();
      const page = Math.max(1, parseInt(req.query.page, 10) || 1);
      const limit = Math.min(100, Math.max(1, parseInt(req.query.limit, 10) || 20));
      const offset = (page - 1) * limit;

      let whereClause;
      if (statusFilter === 'PENDING') {
        // Return incoming requests by default, or all pending involving user
        whereClause = {
          friendId: userId,
          status: 'PENDING',
        };
      } else {
        whereClause = {
          status: statusFilter,
          [Op.or]: [{ userId }, { friendId: userId }],
        };
      }

      const { count, rows } = await Friend.findAndCountAll({
        where: whereClause,
        limit,
        offset,
        order: [['createdAt', 'DESC']],
        include: [
          {
            model: User,
            as: 'user',
            attributes: ['id', 'username', 'level', 'streak'],
          },
          {
            model: User,
            as: 'friend',
            attributes: ['id', 'username', 'level', 'streak'],
          },
        ],
      });

      // Count pending requests waiting for current user
      const pendingCount = await Friend.count({
        where: {
          friendId: userId,
          status: 'PENDING',
        },
      });

      // Format response so client easily gets friend details
      const formatted = rows.map((row) => {
        const friendUser = row.userId === userId ? row.friend : row.user;
        return {
          id: row.id,
          friendshipId: row.id,
          status: row.status,
          createdAt: row.createdAt,
          friend: friendUser,
          isIncomingRequest: row.friendId === userId && row.status === 'PENDING',
        };
      });

      return res.status(200).json({
        success: true,
        data: {
          total: count,
          pendingCount,
          page,
          limit,
          totalPages: Math.ceil(count / limit),
          friends: formatted,
        },
      });
    } catch (error) {
      console.error('[FriendController.listFriends] Error:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to retrieve friends list.',
        details: error.message,
      });
    }
  }

  /**
   * PUT /friends/:friendId (or /users/:id/friends/:friendId)
   * Accept, reject, or block friend connection.
   */
  async respondToRequest(req, res) {
    try {
      const userId = req.user.id;
      const { friendId } = req.params;
      const { action } = req.body;

      if (!action || !['accept', 'reject', 'block'].includes(action.toLowerCase())) {
        return res.status(400).json({
          success: false,
          error: "Action must be one of 'accept', 'reject', or 'block'.",
        });
      }

      const act = action.toLowerCase();

      // Find the connection
      const friendship = await Friend.findOne({
        where: {
          [Op.or]: [
            { userId, friendId },
            { userId: friendId, friendId: userId },
          ],
        },
      });

      if (!friendship) {
        return res.status(404).json({
          success: false,
          error: 'Friend request or relationship not found.',
        });
      }

      if (act === 'accept') {
        friendship.status = 'ACCEPTED';
        await friendship.save();
        return res.status(200).json({
          success: true,
          message: 'Friend request accepted.',
          data: friendship,
        });
      }

      if (act === 'reject') {
        await friendship.destroy();
        return res.status(200).json({
          success: true,
          message: 'Friend request rejected.',
        });
      }

      if (act === 'block') {
        friendship.status = 'BLOCKED';
        await friendship.save();
        return res.status(200).json({
          success: true,
          message: 'User blocked.',
          data: friendship,
        });
      }
    } catch (error) {
      console.error('[FriendController.respondToRequest] Error:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to update friend status.',
        details: error.message,
      });
    }
  }

  /**
   * DELETE /friends/:friendId (or /users/:id/friends/:friendId)
   * Removes friend connection.
   */
  async removeFriend(req, res) {
    try {
      const userId = req.user.id;
      const { friendId } = req.params;

      const friendship = await Friend.findOne({
        where: {
          [Op.or]: [
            { userId, friendId },
            { userId: friendId, friendId: userId },
          ],
        },
      });

      if (!friendship) {
        return res.status(404).json({
          success: false,
          error: 'Friend connection not found.',
        });
      }

      await friendship.destroy();

      return res.status(200).json({
        success: true,
        message: 'Friend removed successfully.',
      });
    } catch (error) {
      console.error('[FriendController.removeFriend] Error:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to remove friend.',
        details: error.message,
      });
    }
  }
}

export default new FriendController();
