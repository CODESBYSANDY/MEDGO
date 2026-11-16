require('dotenv').config();

const JWT_SECRET = process.env.JWT_SECRET || 'medgo_super_secret_jwt_key_2026';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';

module.exports = {
  JWT_SECRET,
  JWT_EXPIRES_IN,
};
