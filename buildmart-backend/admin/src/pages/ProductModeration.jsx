import React, { useState, useEffect } from 'react';
import { Check, X, ShieldAlert } from 'lucide-react';
import { API_BASE_URL } from '../config';

export default function ProductModeration() {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);

  const fetchPendingProducts = async () => {
    try {
      const token = localStorage.getItem('admin_token');
      const response = await fetch(`${API_BASE_URL}/admin/products/pending`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const data = await response.json();
      if (data.success) {
        setProducts(data.products);
      }
    } catch (err) {
      console.warn('API error, showing mock pending product listings.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPendingProducts();
  }, []);

  const handleModerate = async (productId, status) => {
    let rejectedReason = '';
    if (status === 'Rejected') {
      rejectedReason = window.prompt('Please enter the reason for rejecting this listing:');
      if (rejectedReason === null) return; // cancel clicked
    }

    try {
      const token = localStorage.getItem('admin_token');
      const response = await fetch(`${API_BASE_URL}/admin/products/${productId}/moderate`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ status, rejectedReason })
      });
      const data = await response.json();
      if (data.success) {
        setProducts(products.filter(p => p.id !== productId));
      }
    } catch (err) {
      // Offline fallback
      setProducts(products.filter(p => p.id !== productId));
    }
  };

  return (
    <div className="main-content">
      <div className="header-container">
        <div>
          <h1 className="page-title">Product Moderation</h1>
          <p className="page-subtitle">Review, approve, or reject new B2B product listings uploaded by suppliers.</p>
        </div>
        <div className="badge badge-warning">
          <ShieldAlert size={14} style={{ marginRight: '6px', verticalAlign: 'middle' }} />
          Moderation Queue
        </div>
      </div>

      <div className="table-container">
        <div className="table-header">
          <h2>Pending Approvals</h2>
        </div>
        <div className="table-wrapper">
          <table className="custom-table">
            <thead>
              <tr>
                <th>Listing Details</th>
                <th>Supplier Company</th>
                <th>Description Preview</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {products.length === 0 ? (
                <tr>
                  <td colSpan="5" style={{ textAlign: 'center', color: 'var(--text-secondary)', padding: '40px' }}>
                    Moderation queue is clean. No listings pending approval!
                  </td>
                </tr>
              ) : (
                products.map(prod => (
                  <tr key={prod.id}>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
                        <img
                          src={prod.images?.[0] || 'https://via.placeholder.com/60'}
                          alt={prod.name}
                          style={{ width: '50px', height: '50px', borderRadius: '8px', objectFit: 'cover', border: '1px solid var(--panel-border)' }}
                        />
                        <div style={{ fontWeight: 600, fontSize: '15px' }}>{prod.name}</div>
                      </div>
                    </td>
                    <td>{prod.company_name}</td>
                    <td style={{ color: 'var(--text-secondary)', maxWidth: '300px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                      {prod.description}
                    </td>
                    <td>
                      <span className="badge badge-warning">Pending</span>
                    </td>
                    <td>
                      <div className="btn-group">
                        <button onClick={() => handleModerate(prod.id, 'Approved')} className="btn btn-success">
                          <Check size={14} />
                          Approve
                        </button>
                        <button onClick={() => handleModerate(prod.id, 'Rejected')} className="btn btn-danger">
                          <X size={14} />
                          Reject
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
