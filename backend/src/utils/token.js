import jwt from 'jsonwebtoken';

/**
 * Generate Access and Refresh JWT tokens for a user
 * @param {Object} user 
 * @returns {{ accessToken: string, refreshToken: string }}
 */
export const generateTokens = (user) => {
  const payload = {
    id: user.id,
    email: user.email,
    username: user.username,
  };

  const accessToken = jwt.sign(payload, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '15m',
  });

  const refreshToken = jwt.sign(payload, process.env.JWT_REFRESH_SECRET, {
    expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
  });

  return { accessToken, refreshToken };
};

/**
 * Verify Access Token
 * @param {string} token 
 * @returns {Object} decoded payload
 */
export const verifyAccessToken = (token) => {
  return jwt.verify(token, process.env.JWT_SECRET);
};

/**
 * Verify Refresh Token
 * @param {string} token 
 * @returns {Object} decoded payload
 */
export const verifyRefreshToken = (token) => {
  return jwt.verify(token, process.env.JWT_REFRESH_SECRET);
};
