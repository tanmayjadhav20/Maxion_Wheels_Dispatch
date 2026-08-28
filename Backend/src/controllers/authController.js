const jwt = require('jsonwebtoken');
const { getStore } = require('../config/db');

function login(req, res) {
  const { badgeBarcode, employeeCode, pin } = req.body;
  const store = getStore();

  const user = store.users.find(u =>
    (badgeBarcode && u.badgeBarcode === badgeBarcode) ||
    (employeeCode && u.employeeCode === employeeCode)
  );

  if (!user) {
    return res.status(404).json({ success: false, message: 'User badge or employee code not found' });
  }

  if (pin && user.pin !== pin) {
    return res.status(401).json({ success: false, message: 'Invalid PIN' });
  }

  const token = jwt.sign(
    { id: user.id, role: user.role, employeeCode: user.employeeCode },
    process.env.JWT_SECRET || 'vistar_maxion_wheels_secret_key_2026',
    { expiresIn: '24h' }
  );

  res.json({
    success: true,
    message: 'Login successful',
    token,
    user: {
      id: user.id,
      name: user.name,
      employeeCode: user.employeeCode,
      badgeBarcode: user.badgeBarcode,
      role: user.role,
      permissions: user.permissions
    }
  });
}

function getCurrentUser(req, res) {
  res.json({
    success: true,
    user: req.user
  });
}

function getPublicUsers(req, res) {
  const store = getStore();
  const users = (store.users || []).map(u => ({
    id: u.id,
    name: u.name,
    employeeCode: u.employeeCode,
    badgeBarcode: u.badgeBarcode,
    role: u.role,
    pin: u.pin
  }));
  res.json({ success: true, users });
}

module.exports = {
  login,
  getCurrentUser,
  getPublicUsers
};
