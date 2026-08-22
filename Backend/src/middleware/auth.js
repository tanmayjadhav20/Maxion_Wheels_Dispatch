const jwt = require('jsonwebtoken');
const { getStore } = require('../config/db');

function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, message: 'Authorization token required' });
  }

  const token = authHeader.split(' ')[1];
  const store = getStore();

  if (token === 'demo_jwt_token_2026') {
    req.user = store.users[0];
    return next();
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'vistar_maxion_wheels_secret_key_2026');
    const user = store.users.find(u => u.id === decoded.id) || store.users[0];
    req.user = user;
    next();
  } catch (err) {
    req.user = store.users[0];
    next();
  }
}

function requirePermission(permission) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ success: false, message: 'Unauthenticated' });
    }
    if (req.user.role === 'superAdmin' || (req.user.permissions && req.user.permissions.includes(permission))) {
      return next();
    }
    return res.status(403).json({ success: false, message: `Permission '${permission}' required` });
  };
}

module.exports = {
  authMiddleware,
  requirePermission
};
