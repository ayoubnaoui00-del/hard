import { verifyAccessToken } from '../utils/token.js';
import { User } from '../models/index.js';

/**
 * Middleware to authenticate requests using JWT Access Token
 */
export const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        error: 'Access denied. No token provided.',
      });
    }
    // ["Bearer", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6NSwiaWF0IjoxNzg1MzM3NjgyLCJleHAiOjE3ODU5NDI0ODJ9.-s8v4st3HA5s7JmdiN1qsrwapFY6oQKP9LmV1V4T3OQ"][1]
    const token = authHeader.split(' ')[1];

    let decoded;
    try {
      decoded = verifyAccessToken(token);
    } catch (err) {
      if (err.name === 'TokenExpiredError') {
        return res.status(401).json({
          success: false,
          error: 'Access token expired',
          code: 'TOKEN_EXPIRED',
        });
      }
      return res.status(401).json({
        success: false,
        error: 'Invalid access token',
        code: 'TOKEN_INVALID',
      });
    }

    const user = await User.findByPk(decoded.id, {
      attributes: { exclude: ['password'] },
    });

    if (!user) {
      return res.status(401).json({
        success: false,
        error: 'User not found or deactivated.',
        code: 'USER_NOT_FOUND',
      });
    }

    req.user = user;
    next();
  } catch (error) {
    return res.status(500).json({
      success: false,
      error: 'Authentication failed',
      details: error.message,
    });
  }
};

export default authenticate;




