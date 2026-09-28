import bcrypt from 'bcryptjs';
import { Op } from 'sequelize';
import { User } from '../models/index.js';
import { generateTokens, verifyRefreshToken } from '../utils/token.js';

class AuthController {
  /**
   * Register a new user
   * POST /auth/register
   */
  static async register(req, res) {
    try {
      const { email, username, password } = req.body;

      // Validation
      if (!email || !username || !password) {
        return res.status(400).json({
          success: false,
          error: 'Email, username, and password are required',
        });
      }

      const emailTrimmed = email.trim().toLowerCase();
      const usernameTrimmed = username.trim();

      if (usernameTrimmed.length < 3) {
        return res.status(400).json({
          success: false,
          error: 'Username must be at least 3 characters long',
        });
      }

      if (password.length < 6) {
        return res.status(400).json({
          success: false,
          error: 'Password must be at least 6 characters long',
        });
      }

      // Check if email or username already exists
      const existingUser = await User.findOne({
        where: {
          [Op.or]: [
            { email: emailTrimmed },
            { username: usernameTrimmed },
          ],
        },
      });

      if (existingUser) {
        if (existingUser.email.toLowerCase() === emailTrimmed) {
          return res.status(409).json({
            success: false,
            error: 'An account with this email already exists',
          });
        }
        if (existingUser.username.toLowerCase() === usernameTrimmed.toLowerCase()) {
          return res.status(409).json({
            success: false,
            error: 'Username is already taken',
          });
        }
      }

      // Hash password
      const saltRounds = 10;
      const hashedPassword = await bcrypt.hash(password, saltRounds);

      // Create User
      const newUser = await User.create({
        email: emailTrimmed,
        username: usernameTrimmed,
        password: hashedPassword,
        level: 1,
        currentXp: 0,
        totalXp: 0,
        streak: 0,
        lastActiveAt: new Date(),
      });

      // Generate JWT tokens
      const { accessToken, refreshToken } = generateTokens(newUser);

      // Sanitize user output (remove password)
      const userResponse = {
        id: newUser.id,
        username: newUser.username,
        email: newUser.email,
        level: newUser.level,
        currentXp: newUser.currentXp,
        totalXp: newUser.totalXp,
        streak: newUser.streak,
        lastActiveAt: newUser.lastActiveAt,
        createdAt: newUser.createdAt,
      };

      return res.status(201).json({
        success: true,
        message: 'User registered successfully',
        data: {
          user: userResponse,
          accessToken,
          refreshToken,
        },
      });
    } catch (error) {
      console.error('[AuthController.register] Error:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to register user',
        details: error.message,
      });
    }
  }

  /**
   * Log in an existing user
   * POST /auth/login
   */
  static async login(req, res) {
    try {
      const { email, password } = req.body;

      if (!email || !password) {
        return res.status(400).json({
          success: false,
          error: 'Email and password are required',
        });
      }

      const emailTrimmed = email.trim().toLowerCase();

      // Find user by email
      const user = await User.findOne({
        where: { email: emailTrimmed },
      });

      if (!user) {
        return res.status(401).json({
          success: false,
          error: 'Invalid email or password',
        });
      }

      // Verify password
      const isPasswordValid = await bcrypt.compare(password, user.password);
      if (!isPasswordValid) {
        return res.status(401).json({
          success: false,
          error: 'Invalid email or password',
        });
      }

      // Update lastActiveAt
      await user.update({ lastActiveAt: new Date() });

      // Generate JWT tokens
      const { accessToken, refreshToken } = generateTokens(user);

      const userResponse = {
        id: user.id,
        username: user.username,
        email: user.email,
        level: user.level,
        currentXp: user.currentXp,
        totalXp: user.totalXp,
        streak: user.streak,
        lastActiveAt: user.lastActiveAt,
        createdAt: user.createdAt,
      };

      return res.status(200).json({
        success: true,
        message: 'Login successful',
        data: {
          user: userResponse,
          accessToken,
          refreshToken,
        },
      });
    } catch (error) {
      console.error('[AuthController.login] Error:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to log in',
        details: error.message,
      });
    }
  }

  /**
   * Refresh access token
   * POST /auth/refresh
   */
  static async refreshToken(req, res) {
    try {
      const { refreshToken } = req.body;

      if (!refreshToken) {
        return res.status(400).json({
          success: false,
          error: 'Refresh token is required',
        });
      }

      let decoded;
      try {
        decoded = verifyRefreshToken(refreshToken);
      } catch (err) {
        if (err.name === 'TokenExpiredError') {
          return res.status(401).json({
            success: false,
            error: 'Refresh token expired. Please login again.',
            code: 'REFRESH_TOKEN_EXPIRED',
          });
        }
        return res.status(401).json({
          success: false,
          error: 'Invalid refresh token',
          code: 'REFRESH_TOKEN_INVALID',
        });
      }

      const user = await User.findByPk(decoded.id);
      if (!user) {
        return res.status(401).json({
          success: false,
          error: 'User not found or deactivated',
        });
      }

      // Generate fresh token pair
      const tokens = generateTokens(user);

      return res.status(200).json({
        success: true,
        message: 'Token refreshed successfully',
        data: {
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
        },
      });
    } catch (error) {
      console.error('[AuthController.refreshToken] Error:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to refresh token',
        details: error.message,
      });
    }
  }

  /**
   * Logout user
   * POST /auth/logout
   */
  static async logout(_req, res) {
    return res.status(200).json({
      success: true,
      message: 'Logged out successfully',
    });
  }

  /**
   * Get current authenticated user profile
   * GET /auth/me (Protected route)
   */
  static async getMe(req, res) {
    return res.status(200).json({
      success: true,
      data: {
        user: req.user,
      },
    });
  }
}

export default AuthController;
