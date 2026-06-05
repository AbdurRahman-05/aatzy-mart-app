import React from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import { 
  LayoutDashboard, 
  Users, 
  Building2, 
  PackageCheck, 
  FolderTree, 
  LogOut 
} from 'lucide-react';

export default function Sidebar({ onLogout }) {
  const navigate = useNavigate();

  const handleLogout = () => {
    if (onLogout) onLogout();
    navigate('/login');
  };

  return (
    <div className="sidebar">
      <div className="sidebar-logo">
        <div className="logo-icon">BM</div>
        <span className="logo-text">BuildMart</span>
      </div>
      
      <ul className="sidebar-menu">
        <li>
          <NavLink to="/" className={({ isActive }) => `menu-item ${isActive ? 'active' : ''}`} end>
            <LayoutDashboard size={18} />
            Overview Dashboard
          </NavLink>
        </li>
        <li>
          <NavLink to="/users" className={({ isActive }) => `menu-item ${isActive ? 'active' : ''}`}>
            <Users size={18} />
            User Management
          </NavLink>
        </li>
        <li>
          <NavLink to="/suppliers" className={({ isActive }) => `menu-item ${isActive ? 'active' : ''}`}>
            <Building2 size={18} />
            Supplier Verification
          </NavLink>
        </li>
        <li>
          <NavLink to="/products" className={({ isActive }) => `menu-item ${isActive ? 'active' : ''}`}>
            <PackageCheck size={18} />
            Product Moderation
          </NavLink>
        </li>
        <li>
          <NavLink to="/categories" className={({ isActive }) => `menu-item ${isActive ? 'active' : ''}`}>
            <FolderTree size={18} />
            Category Management
          </NavLink>
        </li>
      </ul>

      <div className="sidebar-footer">
        <button onClick={handleLogout} className="logout-btn">
          <LogOut size={16} />
          Sign Out
        </button>
      </div>
    </div>
  );
}
