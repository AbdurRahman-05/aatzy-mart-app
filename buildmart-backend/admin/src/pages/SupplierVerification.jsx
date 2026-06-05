import React, { useState, useEffect } from 'react';
import { Check, X, Building2, MapPin } from 'lucide-react';

export default function SupplierVerification() {
  const [suppliers, setSuppliers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedSupplier, setSelectedSupplier] = useState(null);

  const fetchSuppliers = async () => {
    try {
      const token = localStorage.getItem('admin_token');
      const response = await fetch('http://localhost:5000/api/admin/suppliers', {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const data = await response.json();
      if (data.success) {
        setSuppliers(data.suppliers);
      }
    } catch (err) {
      console.warn('API error, showing mock supplier listings.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchSuppliers();
  }, []);

  const handleVerify = async (supplierId, approve) => {
    try {
      const token = localStorage.getItem('admin_token');
      const response = await fetch(`http://localhost:5000/api/admin/suppliers/${supplierId}/verify`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ isApproved: approve })
      });
      const data = await response.json();
      if (data.success) {
        setSuppliers(suppliers.map(s => s.id === supplierId ? { ...s, is_approved: approve } : s));
      }
    } catch (err) {
      // Offline fallback
      setSuppliers(suppliers.map(s => s.id === supplierId ? { ...s, is_approved: approve } : s));
    }
  };

  return (
    <div className="main-content">
      <div className="header-container">
        <div>
          <h1 className="page-title">Supplier Verification</h1>
          <p className="page-subtitle">Verify supplier business registration profiles, GST registrations, and store listings.</p>
        </div>
      </div>

      <div className="table-container">
        <div className="table-header">
          <h2>Business Profiles</h2>
        </div>
        <div className="table-wrapper">
          <table className="custom-table">
            <thead>
              <tr>
                <th>Company</th>
                <th>Owner Details</th>
                <th>Location</th>
                <th>GST Number</th>
                <th>Materials Providing</th>
                <th>Verification Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {suppliers.length === 0 ? (
                <tr>
                  <td colSpan="7" style={{ textAlign: 'center', color: 'var(--text-secondary)', padding: '40px' }}>
                    No supplier profiles registered.
                  </td>
                </tr>
              ) : (
                suppliers.map(sup => (
                  <tr key={sup.id}>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
                        <img
                          src={sup.logo_url || 'https://via.placeholder.com/60'}
                          alt={sup.company_name}
                          style={{ width: '48px', height: '48px', borderRadius: '8px', objectFit: 'cover', border: '1px solid var(--panel-border)' }}
                        />
                        <div>
                          <div style={{ fontWeight: 600, fontSize: '15px' }}>{sup.company_name}</div>
                          <div style={{ color: 'var(--text-secondary)', fontSize: '12px', marginTop: '2px' }}>
                            Type: <span className="font-semibold">{sup.business_type}</span>
                          </div>
                        </div>
                      </div>
                    </td>
                    <td>
                      <div>{sup.owner_name}</div>
                      <div style={{ color: 'var(--text-secondary)', fontSize: '12px', marginTop: '2px' }}>{sup.owner_phone}</div>
                    </td>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                        <MapPin size={14} color="var(--secondary-color)" />
                        {sup.location}
                      </div>
                    </td>
                    <td>
                      <code style={{ background: 'rgba(255,255,255,0.05)', padding: '4px 8px', borderRadius: '4px', fontSize: '12px' }}>
                        {sup.gst_number || 'N/A'}
                      </code>
                    </td>
                    <td>
                      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '4px', maxWidth: '200px' }}>
                        {sup.materials_providing ? (
                          sup.materials_providing.split(', ').map(mat => (
                            <span
                              key={mat}
                              style={{
                                fontSize: '11px',
                                background: 'rgba(37, 99, 235, 0.15)',
                                color: '#60a5fa',
                                padding: '2px 8px',
                                borderRadius: '4px',
                                fontWeight: 500,
                                border: '1px solid rgba(37, 99, 235, 0.3)'
                              }}
                            >
                              {mat}
                            </span>
                          ))
                        ) : (
                          <span style={{ color: 'var(--text-secondary)', fontSize: '12px' }}>None Specified</span>
                        )}
                      </div>
                    </td>
                    <td>
                      <span className={`badge ${sup.is_approved ? 'badge-success' : 'badge-warning'}`}>
                        {sup.is_approved ? 'Verified' : 'Pending Verification'}
                      </span>
                    </td>
                    <td>
                      <div className="btn-group" style={{ display: 'flex', gap: '6px' }}>
                        <button 
                          onClick={() => setSelectedSupplier(sup)} 
                          className="btn" 
                          style={{ 
                            padding: '6px 12px', 
                            fontSize: '13px', 
                            background: 'rgba(255,255,255,0.05)', 
                            border: '1px solid var(--panel-border)', 
                            color: 'var(--text-primary)',
                            cursor: 'pointer',
                            borderRadius: '6px'
                          }}
                        >
                          Details
                        </button>
                        {!sup.is_approved ? (
                          <button onClick={() => handleVerify(sup.id, true)} className="btn btn-success" style={{ padding: '6px 12px', fontSize: '13px' }}>
                            <Check size={14} />
                            Approve
                          </button>
                        ) : (
                          <button onClick={() => handleVerify(sup.id, false)} className="btn btn-danger" style={{ padding: '6px 12px', fontSize: '13px' }}>
                            <X size={14} />
                            Reject
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Supplier Profile Modal */}
      {selectedSupplier && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          backgroundColor: 'rgba(0, 0, 0, 0.7)',
          backdropFilter: 'blur(8px)',
          display: 'flex',
          justifyContent: 'center',
          alignItems: 'center',
          zIndex: 1000,
          padding: '20px'
        }}>
          <div style={{
            background: 'var(--panel-bg, #1e293b)',
            border: '1px solid var(--panel-border, #334155)',
            borderRadius: '16px',
            width: '100%',
            maxWidth: '600px',
            boxShadow: '0 20px 25px -5px rgb(0 0 0 / 0.5), 0 8px 10px -6px rgb(0 0 0 / 0.5)',
            overflow: 'hidden',
            color: 'var(--text-primary, #f8fafc)'
          }}>
            {/* Modal Header */}
            <div style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              padding: '18px 24px',
              borderBottom: '1px solid var(--panel-border, #334155)',
              background: 'rgba(255,255,255,0.02)'
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                <Building2 size={20} color="#3b82f6" />
                <h3 style={{ margin: 0, fontSize: '18px', fontWeight: 700 }}>Supplier Profile Details</h3>
              </div>
              <button 
                onClick={() => setSelectedSupplier(null)}
                style={{ background: 'none', border: 'none', color: '#94a3b8', cursor: 'pointer', padding: '4px' }}
              >
                <X size={20} />
              </button>
            </div>

            {/* Modal Body */}
            <div style={{ padding: '24px', display: 'flex', flexDirection: 'column', gap: '18px' }}>
              <div style={{ display: 'flex', gap: '16px', alignItems: 'center' }}>
                <img
                  src={selectedSupplier.logo_url || 'https://via.placeholder.com/80'}
                  alt={selectedSupplier.company_name}
                  style={{ width: '70px', height: '70px', borderRadius: '12px', objectFit: 'cover', border: '1px solid var(--panel-border)' }}
                />
                <div>
                  <h4 style={{ margin: 0, fontSize: '18px', fontWeight: 700 }}>{selectedSupplier.company_name}</h4>
                  <span className={`badge ${selectedSupplier.is_approved ? 'badge-success' : 'badge-warning'}`} style={{ marginTop: '6px', display: 'inline-block' }}>
                    {selectedSupplier.is_approved ? 'Verified Supplier' : 'Pending Verification'}
                  </span>
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', marginTop: '6px' }}>
                {/* Details list */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                  <div>
                    <label style={{ fontSize: '11px', color: '#94a3b8', display: 'block', marginBottom: '2px' }}>Owner Name</label>
                    <div style={{ fontWeight: 600, fontSize: '14px' }}>{selectedSupplier.owner_name}</div>
                  </div>
                  <div>
                    <label style={{ fontSize: '11px', color: '#94a3b8', display: 'block', marginBottom: '2px' }}>Contact Phone</label>
                    <div style={{ fontWeight: 600, fontSize: '14px' }}>{selectedSupplier.owner_phone}</div>
                  </div>
                  <div>
                    <label style={{ fontSize: '11px', color: '#94a3b8', display: 'block', marginBottom: '2px' }}>GST Number</label>
                    <code style={{ background: 'rgba(255,255,255,0.05)', padding: '3px 6px', borderRadius: '4px', fontSize: '12px', color: '#f59e0b', fontWeight: 600 }}>
                      {selectedSupplier.gst_number || 'N/A'}
                    </code>
                  </div>
                </div>

                <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                  <div>
                    <label style={{ fontSize: '11px', color: '#94a3b8', display: 'block', marginBottom: '2px' }}>Business Type</label>
                    <div style={{ fontWeight: 600, fontSize: '14px' }}>{selectedSupplier.business_type}</div>
                  </div>
                  <div>
                    <label style={{ fontSize: '11px', color: '#94a3b8', display: 'block', marginBottom: '4px' }}>Materials Providing</label>
                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '4px' }}>
                      {selectedSupplier.materials_providing ? (
                        selectedSupplier.materials_providing.split(', ').map(mat => (
                          <span
                            key={mat}
                            style={{
                              fontSize: '11px',
                              background: 'rgba(37, 99, 235, 0.15)',
                              color: '#60a5fa',
                              padding: '2px 8px',
                              borderRadius: '4px',
                              fontWeight: 500,
                              border: '1px solid rgba(37, 99, 235, 0.3)'
                            }}
                          >
                            {mat}
                          </span>
                        ))
                      ) : (
                        <span style={{ color: '#94a3b8', fontSize: '12px' }}>None Specified</span>
                      )}
                    </div>
                  </div>
                </div>
              </div>

              {/* Location Map View */}
              <div style={{ marginTop: '6px' }}>
                <label style={{ fontSize: '11px', color: '#94a3b8', display: 'block', marginBottom: '4px' }}>Business Location Map</label>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '8px' }}>
                  <MapPin size={14} color="red" />
                  <span style={{ fontSize: '12px', fontWeight: 500 }}>{selectedSupplier.location}</span>
                </div>
                <div style={{
                  height: '140px',
                  borderRadius: '12px',
                  border: '1px solid var(--panel-border)',
                  overflow: 'hidden',
                  position: 'relative'
                }}>
                  <img
                    src="https://images.unsplash.com/photo-1569336415962-a4bd9f69cd83?auto=format&fit=crop&w=800&q=80"
                    alt="Map"
                    style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                  />
                  <div style={{
                    position: 'absolute',
                    top: '50%',
                    left: '50%',
                    transform: 'translate(-50%, -100%)'
                  }}>
                    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                      <div style={{
                        background: 'rgba(0,0,0,0.85)',
                        color: 'white',
                        padding: '3px 6px',
                        borderRadius: '4px',
                        fontSize: '9px',
                        whiteSpace: 'nowrap',
                        marginBottom: '3px',
                        border: '1px solid #3b82f6'
                      }}>
                        {selectedSupplier.company_name}
                      </div>
                      <MapPin size={24} color="red" style={{ filter: 'drop-shadow(0px 2px 4px rgba(0,0,0,0.5))' }} />
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Modal Footer */}
            <div style={{
              display: 'flex',
              justifyContent: 'flex-end',
              gap: '12px',
              padding: '18px 24px',
              borderTop: '1px solid var(--panel-border, #334155)',
              background: 'rgba(255,255,255,0.02)'
            }}>
              <button 
                onClick={() => setSelectedSupplier(null)}
                style={{ 
                  padding: '8px 16px', 
                  fontSize: '13px', 
                  background: 'none', 
                  border: '1px solid var(--panel-border)', 
                  color: 'var(--text-primary)',
                  cursor: 'pointer',
                  borderRadius: '6px'
                }}
              >
                Close
              </button>
              {!selectedSupplier.is_approved ? (
                <button 
                  onClick={() => {
                    handleVerify(selectedSupplier.id, true);
                    setSelectedSupplier(null);
                  }} 
                  className="btn btn-success"
                  style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', padding: '8px 16px', fontSize: '13px' }}
                >
                  <Check size={14} />
                  Approve Supplier
                </button>
              ) : (
                <button 
                  onClick={() => {
                    handleVerify(selectedSupplier.id, false);
                    setSelectedSupplier(null);
                  }} 
                  className="btn btn-danger"
                  style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', padding: '8px 16px', fontSize: '13px' }}
                >
                  <X size={14} />
                  Reject Supplier
                </button>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
