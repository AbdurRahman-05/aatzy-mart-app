import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Lock, Mail } from 'lucide-react';
import { API_BASE_URL } from '../config';

export default function Login({ onLoginSuccess }) {
  const [email, setEmail] = useState('admin@buildmart.com');
  const [password, setPassword] = useState('password');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      // Mock login validation for out-of-the-box local use
      if (email === 'admin@buildmart.com' && password === 'password') {
        localStorage.setItem('admin_token', 'mock_admin_jwt_token_123');
        localStorage.setItem('admin_user', JSON.stringify({
          name: 'BuildMart Admin',
          email: 'admin@buildmart.com',
          role: 'admin'
        }));
        if (onLoginSuccess) onLoginSuccess();
        navigate('/');
      } else {
        // Attempt actual API check if backend is running, otherwise alert
        const response = await fetch(`${API_BASE_URL}/auth/login`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ loginKey: email, password })
        });
        const data = await response.json();
        
        if (data.success && data.user.roleName === 'admin') {
          localStorage.setItem('admin_token', data.token);
          localStorage.setItem('admin_user', JSON.stringify(data.user));
          if (onLoginSuccess) onLoginSuccess();
          navigate('/');
        } else {
          setError(data.message || 'Invalid admin credentials');
        }
      }
    } catch (err) {
      console.warn('Backend API connection failed, using local mock auth instead.');
      // Fallback: accept default admin mock credentials anyway for seamless offline use
      if (email === 'admin@buildmart.com' && password === 'password') {
        localStorage.setItem('admin_token', 'mock_admin_jwt_token_123');
        localStorage.setItem('admin_user', JSON.stringify({
          name: 'BuildMart Admin',
          email: 'admin@buildmart.com',
          role: 'admin'
        }));
        if (onLoginSuccess) onLoginSuccess();
        navigate('/');
      } else {
        setError('Network error or invalid admin credentials');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-wrapper">
      <div className="login-card">
        <div className="login-header">
          <div className="logo-icon" style={{ margin: '0 auto', width: '50px', height: '50px', fontSize: '26px' }}>BM</div>
          <h1>BuildMart Portal</h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '14px', marginTop: '6px' }}>
            B2B Admin Control Center
          </p>
        </div>

        {error && (
          <div className="badge badge-danger" style={{ width: '100%', padding: '12px', borderRadius: '8px', marginBottom: '20px', textAlign: 'center' }}>
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label className="form-label">Admin Email</label>
            <div style={{ position: 'relative' }}>
              <input
                type="email"
                className="form-control"
                style={{ paddingLeft: '40px' }}
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
              <Mail size={16} style={{ position: 'absolute', left: '14px', top: '15px', color: 'var(--text-secondary)' }} />
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">Password</label>
            <div style={{ position: 'relative' }}>
              <input
                type="password"
                className="form-control"
                style={{ paddingLeft: '40px' }}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
              <Lock size={16} style={{ position: 'absolute', left: '14px', top: '15px', color: 'var(--text-secondary)' }} />
            </div>
          </div>

          <button type="submit" className="btn btn-primary" style={{ width: '100%', padding: '14px', justifyContent: 'center', marginTop: '10px' }} disabled={loading}>
            {loading ? 'Authenticating...' : 'Sign In to Dashboard'}
          </button>
        </form>
      </div>
    </div>
  );
}
