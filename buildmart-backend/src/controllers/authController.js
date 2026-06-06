const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/db');
const { JWT_SECRET } = require('../middlewares/auth');

// Simple cache for simulated OTPs
const otpCache = new Map();

// Helper to generate JWT token
const generateToken = (userId) => {
  return jwt.sign({ userId }, JWT_SECRET, { expiresIn: '7d' });
};

// 1. REGISTER USER & SEND MOCK OTP
exports.register = async (req, res) => {
  try {
    const { name, email, phone, password, roleId, companyName, location, gstNumber, materialsProviding } = req.body;

    if (!name || !phone || !password || !roleId) {
      return res.status(400).json({ success: false, message: 'Name, phone, password, and roleId are required' });
    }

    // Check if phone or email already exists
    const checkUser = await db.query(
      'SELECT id FROM users WHERE phone = $1 OR (email IS NOT NULL AND email = $2)',
      [phone, email]
    );

    if (checkUser.rows.length > 0) {
      return res.status(400).json({ success: false, message: 'User with this phone or email already exists' });
    }

    // Generate random 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Cache the registration payload and OTP
    otpCache.set(phone, {
      payload: { name, email, phone, password, roleId, companyName, location, gstNumber, materialsProviding },
      otp,
      expiresAt: Date.now() + 5 * 60 * 1000 // 5 minutes expiration
    });

    console.log(`[SMS-MOCK] OTP for ${phone}: ${otp}`);

    return res.status(200).json({
      success: true,
      message: 'OTP sent to mobile number',
      otp: otp // Send OTP back in response for easy testing/local dev
    });
  } catch (error) {
    console.error('Registration Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

// 2. VERIFY OTP & COMPLETE REGISTRATION
exports.verifyOtp = async (req, res) => {
  try {
    const { phone, otp } = req.body;

    if (!phone || !otp) {
      return res.status(400).json({ success: false, message: 'Phone and OTP are required' });
    }

    const cached = otpCache.get(phone);
    if (!cached) {
      return res.status(400).json({ success: false, message: 'OTP expired or not requested' });
    }

    if (cached.otp !== otp) {
      return res.status(400).json({ success: false, message: 'Invalid OTP' });
    }

    if (Date.now() > cached.expiresAt) {
      otpCache.delete(phone);
      return res.status(400).json({ success: false, message: 'OTP expired' });
    }

    const { name, email, password, roleId, companyName, location, gstNumber, materialsProviding } = cached.payload;
    const passwordHash = await bcrypt.hash(password, 10);
    const userId = require('crypto').randomUUID();
    const rId = Number(roleId);

    // Create User
    const userRes = await db.query(
      'INSERT INTO users (id, name, email, phone, password_hash, role_id) VALUES ($1, $2, $3, $4, $5, $6) RETURNING id, name, email, phone, role_id',
      [userId, name, email || null, phone, passwordHash, rId]
    );

    // Auto-create Buyer or Supplier profile skeleton
    if (rId === 2) {
      // Buyer
      await db.query('INSERT INTO buyers (user_id, location) VALUES ($1, $2)', [userId, 'India']);
    } else if (rId === 3) {
      // Supplier (Requires Admin Approval)
      await db.query(
        'INSERT INTO suppliers (user_id, company_name, business_type, location, gst_number, materials_providing, is_approved) VALUES ($1, $2, $3, $4, $5, $6, $7)',
        [userId, companyName || `${name}'s Enterprise`, 'Manufacturer', location || 'India', gstNumber || null, materialsProviding || null, false]
      );
    }

    // Clean up OTP cache
    otpCache.delete(phone);

    const token = generateToken(userId);

    return res.status(201).json({
      success: true,
      message: 'Account verified and created successfully',
      token,
      user: {
        id: userId,
        name,
        email,
        phone,
        roleId: rId,
        roleName: rId === 3 ? 'supplier' : (rId === 1 ? 'admin' : 'buyer')
      }
    });
  } catch (error) {
    console.error('OTP Verification Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

// 3. LOGIN (Supports email/phone + password)
exports.login = async (req, res) => {
  try {
    const { loginKey, password } = req.body; // loginKey can be email or phone

    if (!loginKey || !password) {
      return res.status(400).json({ success: false, message: 'Login key (email/phone) and password are required' });
    }

    // Lookup user
    const userRes = await db.query(
      'SELECT u.*, r.name as role_name FROM users u JOIN roles r ON u.role_id = r.id WHERE (u.phone = $1 OR u.email = $1) AND u.deleted_at IS NULL',
      [loginKey]
    );

    let user = userRes.rows[0];

    // Fallback search in mock store if query was mock/empty
    if (!user) {
      const mockUser = db.mockStore.users.find(u => u.phone === loginKey || u.email === loginKey);
      if (mockUser) {
        const role = db.mockStore.roles.find(r => r.id === mockUser.role_id) || {};
        user = { ...mockUser, role_name: role.name };
      }
    }

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    if (!user.is_active) {
      return res.status(403).json({ success: false, message: 'Your account has been suspended by administration' });
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return res.status(400).json({ success: false, message: 'Invalid password credentials' });
    }

    // Get supplementary profile details
    let profile = null;
    if (user.role_name === 'supplier') {
      const supRes = await db.query('SELECT * FROM suppliers WHERE user_id = $1', [user.id]);
      profile = supRes.rows[0] || db.mockStore.suppliers.find(s => s.user_id === user.id);
      if (profile && !profile.is_approved) {
        return res.status(403).json({ success: false, message: 'Your supplier account is pending administrator approval.' });
      }
    } else if (user.role_name === 'buyer') {
      const buyRes = await db.query('SELECT * FROM buyers WHERE user_id = $1', [user.id]);
      profile = buyRes.rows[0] || db.mockStore.buyers.find(b => b.user_id === user.id);
    }

    const token = generateToken(user.id);

    return res.status(200).json({
      success: true,
      message: 'Login successful',
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        roleId: user.role_id,
        roleName: user.role_name
      },
      profile
    });
  } catch (error) {
    console.error('Login Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

// 4. CONTINUE WITH GOOGLE (Mock Federated Auth)
exports.googleAuth = async (req, res) => {
  try {
    const { email, name, googleToken, roleId } = req.body;

    if (!email || !name) {
      return res.status(400).json({ success: false, message: 'Email and Name are required' });
    }

    // Check if user exists
    let userRes = await db.query(
      'SELECT u.*, r.name as role_name FROM users u JOIN roles r ON u.role_id = r.id WHERE u.email = $1',
      [email]
    );

    let user = userRes.rows[0];

    if (!user) {
      // Create a new user with Google Auth provider details
      const randomPhone = `+91000${Math.floor(1000000 + Math.random() * 9000000)}`;
      const randomPass = await bcrypt.hash(Math.random().toString(36), 10);
      const userId = require('crypto').randomUUID();

      const rId = Number(roleId || 2);
      const insertRes = await db.query(
        'INSERT INTO users (id, name, email, phone, password_hash, role_id) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
        [userId, name, email, randomPhone, randomPass, rId]
      );
      
      user = insertRes.rows[0];
      user.role_name = rId === 3 ? 'supplier' : 'buyer';

      if (rId === 3) {
        await db.query(
          'INSERT INTO suppliers (user_id, company_name, business_type, location, is_approved) VALUES ($1, $2, $3, $4, $5)',
          [userId, `${name}'s Store`, 'Retailer', 'India', false]
        );
      } else {
        await db.query('INSERT INTO buyers (user_id, location) VALUES ($1, $2)', [userId, 'India']);
      }
    }

    const token = generateToken(user.id);

    return res.status(200).json({
      success: true,
      message: 'Google authentication successful',
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        roleId: user.role_id,
        roleName: user.role_name
      }
    });
  } catch (error) {
    console.error('Google Auth Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};
