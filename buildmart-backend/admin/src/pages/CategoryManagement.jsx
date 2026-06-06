import React, { useState, useEffect } from 'react';
import { Plus, Edit3, Trash2, FolderPlus } from 'lucide-react';
import { API_BASE_URL } from '../config';

export default function CategoryManagement() {
  const [categories, setCategories] = useState([
    { id: 1, name: 'Construction Materials', description: 'Cement, bricks, sand, concrete, and structural steel.', slug: 'construction-materials', image_url: 'https://images.unsplash.com/photo-1590069261209-f8e9b8642343?auto=format&fit=crop&q=80&w=400' },
    { id: 2, name: 'Electrical', description: 'Wires, cables, switches, switchgears, and industrial panels.', slug: 'electrical', image_url: 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?auto=format&fit=crop&q=80&w=400' },
    { id: 3, name: 'Plumbing', description: 'Pipes, fittings, valves, water tanks, and sanitary ware.', slug: 'plumbing', image_url: 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&q=80&w=400' },
    { id: 4, name: 'Interior Design', description: 'Decorative items, wallpapers, wall paneling, and acoustic panels.', slug: 'interior-design', image_url: 'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?auto=format&fit=crop&q=80&w=400' },
    { id: 5, name: 'Machinery', description: 'Heavy industrial machines, concrete mixers, generators, and excavators.', slug: 'machinery', image_url: 'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?auto=format&fit=crop&q=80&w=400' }
  ]);

  const [showModal, setShowModal] = useState(false);
  const [isEditing, setIsEditing] = useState(null); // id of editing cat, or null
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [imageUrl, setImageUrl] = useState('');

  const fetchCategories = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/buyer/categories`);
      const data = await response.json();
      if (data.success) {
        setCategories(data.categories);
      }
    } catch (err) {
      console.warn('API connection failed, loaded mock B2B categories.');
    }
  };

  useEffect(() => {
    fetchCategories();
  }, []);

  const handleOpenAdd = () => {
    setIsEditing(null);
    setName('');
    setDescription('');
    setImageUrl('https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&q=80&w=400');
    setShowModal(true);
  };

  const handleOpenEdit = (cat) => {
    setIsEditing(cat.id);
    setName(cat.name);
    setDescription(cat.description);
    setImageUrl(cat.image_url);
    setShowModal(true);
  };

  const handleSave = async (e) => {
    e.preventDefault();
    const token = localStorage.getItem('admin_token');
    
    if (isEditing) {
      // Edit
      try {
        const response = await fetch(`${API_BASE_URL}/admin/categories/${isEditing}`, {
          method: 'PUT',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
          body: JSON.stringify({ name, description, image_url: imageUrl })
        });
        const data = await response.json();
        if (data.success) {
          setCategories(categories.map(c => c.id === isEditing ? data.category : c));
        }
      } catch (err) {
        setCategories(categories.map(c => c.id === isEditing ? { ...c, name, description, image_url: imageUrl } : c));
      }
    } else {
      // Add
      try {
        const response = await fetch(`${API_BASE_URL}/admin/categories`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
          body: JSON.stringify({ name, description, image_url: imageUrl })
        });
        const data = await response.json();
        if (data.success) {
          setCategories([...categories, data.category]);
        }
      } catch (err) {
        setCategories([...categories, {
          id: categories.length + 1,
          name,
          description,
          slug: name.toLowerCase().replace(/[^a-z0-9]+/g, '-'),
          image_url: imageUrl
        }]);
      }
    }
    setShowModal(false);
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this category? All products under it will be uncategorized.')) return;
    
    const token = localStorage.getItem('admin_token');
    try {
      const response = await fetch(`${API_BASE_URL}/admin/categories/${id}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const data = await response.json();
      if (data.success) {
        setCategories(categories.filter(c => c.id !== id));
      }
    } catch (err) {
      setCategories(categories.filter(c => c.id !== id));
    }
  };

  return (
    <div className="main-content">
      <div className="header-container">
        <div>
          <h1 className="page-title">Category Management</h1>
          <p className="page-subtitle">Add, edit, or delete categories for products and services browsing.</p>
        </div>
        <button onClick={handleOpenAdd} className="btn btn-primary">
          <Plus size={16} />
          Create Category
        </button>
      </div>

      <div className="categories-admin-grid">
        {categories.map(cat => (
          <div key={cat.id} className="category-admin-card">
            <img src={cat.image_url || 'https://via.placeholder.com/60'} alt={cat.name} className="cat-thumb" />
            <div className="cat-info">
              <h3>{cat.name}</h3>
              <p>{cat.description}</p>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              <button onClick={() => handleOpenEdit(cat)} className="btn btn-secondary" style={{ padding: '6px' }}>
                <Edit3 size={14} />
              </button>
              <button onClick={() => handleDelete(cat.id)} className="btn btn-secondary" style={{ padding: '6px', color: 'var(--danger-color)' }}>
                <Trash2 size={14} />
              </button>
            </div>
          </div>
        ))}
      </div>

      {showModal && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
              <h2 style={{ fontSize: '18px', fontWeight: '700' }}>{isEditing ? 'Edit Category' : 'Create New Category'}</h2>
              <button onClick={() => setShowModal(false)} className="modal-close">&times;</button>
            </div>

            <form onSubmit={handleSave}>
              <div className="form-group">
                <label className="form-label">Category Name</label>
                <input
                  type="text"
                  className="form-control"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="e.g. Electrical Panels"
                  required
                />
              </div>

              <div className="form-group">
                <label className="form-label">Description</label>
                <textarea
                  className="form-control"
                  style={{ minHeight: '80px', resize: 'vertical' }}
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  placeholder="Describe what items fit here..."
                  required
                />
              </div>

              <div className="form-group">
                <label className="form-label">Image URL</label>
                <input
                  type="text"
                  className="form-control"
                  value={imageUrl}
                  onChange={(e) => setImageUrl(e.target.value)}
                  placeholder="https://images.unsplash.com/..."
                />
              </div>

              <button type="submit" className="btn btn-primary" style={{ width: '100%', padding: '12px', justifyContent: 'center', marginTop: '10px' }}>
                {isEditing ? 'Save Changes' : 'Create Category'}
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
