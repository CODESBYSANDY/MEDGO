const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const { supabase } = require('../config/supabase');
const { generateToken } = require('../utils/generateToken');

class AuthService {
  /**
   * Register a new user
   */
  async register({ name, email, phone, password, role }) {
    if (!supabase) {
      const err = new Error('Database client is not initialized');
      err.statusCode = 500;
      throw err;
    }

    const normalizedEmail = email.toLowerCase().trim();

    // Check email uniqueness
    const { data: existingUser, error: checkError } = await supabase
      .from('users')
      .select('id')
      .eq('email', normalizedEmail)
      .maybeSingle();

    if (checkError) {
      throw checkError;
    }

    if (existingUser) {
      const error = new Error('Email is already registered');
      error.statusCode = 409;
      throw error;
    }

    // Hash password
    const saltRounds = 10;
    const password_hash = await bcrypt.hash(password, saltRounds);

    const newUser = {
      id: uuidv4(),
      name: name.trim(),
      email: normalizedEmail,
      phone: phone.trim(),
      password_hash,
      role,
      created_at: new Date().toISOString(),
    };

    const { data: createdUser, error: insertError } = await supabase
      .from('users')
      .insert([newUser])
      .select('id, name, email, phone, role')
      .single();

    if (insertError) {
      throw insertError;
    }

    return {
      user: {
        id: createdUser.id,
        name: createdUser.name,
        email: createdUser.email,
        phone: createdUser.phone,
        role: createdUser.role,
      },
    };
  }

  /**
   * Login user and generate JWT
   */
  async login({ email, password }) {
    if (!supabase) {
      const err = new Error('Database client is not initialized');
      err.statusCode = 500;
      throw err;
    }

    const normalizedEmail = email.toLowerCase().trim();

    const { data: user, error: findError } = await supabase
      .from('users')
      .select('id, name, email, phone, password_hash, role')
      .eq('email', normalizedEmail)
      .maybeSingle();

    if (findError) {
      throw findError;
    }

    if (!user) {
      const error = new Error('Invalid email or password');
      error.statusCode = 401;
      throw error;
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      const error = new Error('Invalid email or password');
      error.statusCode = 401;
      throw error;
    }

    const token = generateToken(user);

    return {
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
      },
    };
  }

  /**
   * Get current authenticated user profile
   */
  async getCurrentUser(userId) {
    if (!supabase) {
      const err = new Error('Database client is not initialized');
      err.statusCode = 500;
      throw err;
    }

    const { data: user, error } = await supabase
      .from('users')
      .select('id, name, email, phone, role')
      .eq('id', userId)
      .maybeSingle();

    if (error) {
      throw error;
    }

    if (!user) {
      const err = new Error('User not found');
      err.statusCode = 404;
      throw err;
    }

    return {
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
      },
    };
  }
}

module.exports = new AuthService();
