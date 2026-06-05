import React, { useState, useEffect } from 'react';
import { Users, Building2, Package, Inbox, FolderOpen, ArrowRight, CheckCircle2 } from 'lucide-react';

export default function Dashboard() {
  const [stats, setStats] = useState({
    users: 0,
    suppliers: 0,
    products: 0,
    leads: 0,
    categories: 0
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const token = localStorage.getItem('admin_token');
        const response = await fetch('http://localhost:5000/api/admin/overview', {
          headers: { 'Authorization': `Bearer ${token}` }
        });
        const data = await response.json();
        if (data.success) {
          setStats(data.stats);
        }
      } catch (err) {
        console.warn('API error, showing mock dashboard analytics.');
      } finally {
        setLoading(false);
      }
    };
    fetchStats();
  }, []);

  return (
    <div className="main-content">
      <div className="header-container">
        <div>
          <h1 className="page-title">Overview Dashboard</h1>
          <p className="page-subtitle">Real-time metrics and operational control for BuildMart B2B Marketplace.</p>
        </div>
        <div className="badge badge-success">Live Engine</div>
      </div>

      <div className="stats-grid">
        <div className="stats-card">
          <div className="stats-icon"><Users size={24} /></div>
          <div className="stats-info">
            <h3>Registered Users</h3>
            <p>{stats.users}</p>
          </div>
        </div>

        <div className="stats-card">
          <div className="stats-icon"><Building2 size={24} /></div>
          <div className="stats-info">
            <h3>Approved Suppliers</h3>
            <p>{stats.suppliers}</p>
          </div>
        </div>

        <div className="stats-card">
          <div className="stats-icon"><Package size={24} /></div>
          <div className="stats-info">
            <h3>Moderated Products</h3>
            <p>{stats.products}</p>
          </div>
        </div>

        <div className="stats-card">
          <div className="stats-icon"><Inbox size={24} /></div>
          <div className="stats-info">
            <h3>Total Leads Generated</h3>
            <p>{stats.leads}</p>
          </div>
        </div>

        <div className="stats-card">
          <div className="stats-icon"><FolderOpen size={24} /></div>
          <div className="stats-info">
            <h3>Active Categories</h3>
            <p>{stats.categories}</p>
          </div>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '30px', marginTop: '20px' }}>
        <div className="table-container" style={{ margin: 0 }}>
          <div className="table-header">
            <h2>Recent Marketplace Actions</h2>
          </div>
          <div className="table-wrapper">
            <table className="custom-table">
              <thead>
                <tr>
                  <th>Action</th>
                  <th>Target User/Business</th>
                  <th>Status</th>
                  <th>Time</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td colSpan="4" style={{ textAlign: 'center', color: 'var(--text-secondary)', padding: '20px' }}>
                    No recent actions recorded.
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <div className="table-container" style={{ margin: 0, padding: '24px' }}>
          <h2 style={{ fontSize: '18px', marginBottom: '20px', fontWeight: 700 }}>Quick Tasks</h2>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            <div style={{ background: 'rgba(255,255,255,0.03)', padding: '16px', borderRadius: '12px', border: '1px solid rgba(255,255,255,0.05)', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div>
                <h4 style={{ fontSize: '14px', fontWeight: '600' }}>Supplier Approval</h4>
                <p style={{ fontSize: '12px', color: 'var(--text-secondary)', marginTop: '2px' }}>1 new request pending</p>
              </div>
              <CheckCircle2 size={20} color="var(--warning-color)" />
            </div>

            <div style={{ background: 'rgba(255,255,255,0.03)', padding: '16px', borderRadius: '12px', border: '1px solid rgba(255,255,255,0.05)', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div>
                <h4 style={{ fontSize: '14px', fontWeight: '600' }}>Product Moderation</h4>
                <p style={{ fontSize: '12px', color: 'var(--text-secondary)', marginTop: '2px' }}>3 listing uploads pending</p>
              </div>
              <CheckCircle2 size={20} color="var(--warning-color)" />
            </div>

            <div style={{ background: 'rgba(255,255,255,0.03)', padding: '16px', borderRadius: '12px', border: '1px solid rgba(255,255,255,0.05)', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div>
                <h4 style={{ fontSize: '14px', fontWeight: '600' }}>System Health</h4>
                <p style={{ fontSize: '12px', color: 'var(--text-secondary)', marginTop: '2px' }}>All services operational</p>
              </div>
              <CheckCircle2 size={20} color="var(--success-color)" />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
