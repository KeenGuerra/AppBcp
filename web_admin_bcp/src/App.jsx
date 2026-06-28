// App.jsx — BCP Admin Portal con branding real y navegación completa
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Users from './pages/Users';
import Products from './pages/Products';
import SyncLogs from './pages/SyncLogs';
import Transacciones from './pages/Transacciones';
import Prestamos from './pages/Prestamos';
import Ahorros from './pages/Ahorros';
import Comprobantes from './pages/Comprobantes';
import Cartera from './pages/Cartera';
import SolicitudesAdmin from './pages/SolicitudesAdmin';
import Reportes from './pages/Reportes';
import MoraCartera from './pages/MoraCartera';
import ClientesAdmin from './pages/ClientesAdmin';
import AsesoresAdmin from './pages/AsesoresAdmin';
import Parametros from './pages/Parametros';
import Cronogramas from './pages/Cronogramas';

const NAV_ITEMS = [
  { id: 'dashboard',      label: 'Dashboard',      icon: 'dashboard' },
  { id: 'transacciones',  label: 'Transacciones',  icon: 'receipt_long' },
  { id: 'prestamos',      label: 'Préstamos',       icon: 'account_balance' },
  { id: 'cronogramas',    label: 'Cronogramas',     icon: 'calendar_today' },
  { id: 'ahorros',        label: 'Ahorros',         icon: 'savings' },
  { id: 'comprobantes',   label: 'Comprobantes',    icon: 'description' },
];

const NAV_FVENTAS = [
  { id: 'cartera',           label: 'Monitoreo Cartera', icon: 'map' },
  { id: 'solicitudes_admin', label: 'Evaluación Créditos', icon: 'assignment' },
  { id: 'mora_cartera',      label: 'Mora & Cobranzas', icon: 'warning' },
  { id: 'reportes_fventas',  label: 'Reportes Asesores', icon: 'bar_chart' },
];

const NAV_SECTION2 = [
  { id: 'users',      label: 'Usuarios',      icon: 'people' },
  { id: 'clientes',   label: 'Clientes',       icon: 'person' },
  { id: 'asesores',   label: 'Asesores',       icon: 'badge' },
  { id: 'products',   label: 'Productos',      icon: 'monetization_on' },
  { id: 'parametros', label: 'Parámetros',     icon: 'settings' },
  { id: 'sync',       label: 'Sync & Logs',    icon: 'sync_alt' },
];

const api = axios.create({ baseURL: import.meta.env.VITE_API_URL || 'http://127.0.0.1:8003' });

export default function App() {
  const [token, setToken] = useState(localStorage.getItem('admin_token') || null);
  const [adminName, setAdminName] = useState(localStorage.getItem('admin_name') || null);
  const [page, setPage] = useState('dashboard');
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  useEffect(() => {
    if (token) {
      api.defaults.headers.common['Authorization'] = `Bearer ${token}`;
    } else {
      delete api.defaults.headers.common['Authorization'];
    }
  }, [token]);

  const handleLoginSuccess = (newToken, name) => {
    localStorage.setItem('admin_token', newToken);
    localStorage.setItem('admin_name', name);
    setToken(newToken);
    setAdminName(name);
    setPage('dashboard');
  };

  const handleLogout = async () => {
    try { if (token) await api.post('/auth/logout'); } catch (_) {}
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_name');
    setToken(null);
    setAdminName(null);
  };

  useEffect(() => {
    const id = api.interceptors.response.use(
      r => r,
      err => {
        if (err.response?.status === 401 || err.response?.status === 403) handleLogout();
        return Promise.reject(err);
      }
    );
    return () => api.interceptors.response.eject(id);
  }, [token]);

  if (!token) return <Login onLoginSuccess={handleLoginSuccess} />;

  const renderPage = () => {
    switch (page) {
      case 'dashboard':     return <Dashboard api={api} setPage={setPage} />;
      case 'transacciones': return <Transacciones api={api} />;
      case 'prestamos':     return <Prestamos api={api} />;
      case 'ahorros':       return <Ahorros api={api} />;
      case 'comprobantes':  return <Comprobantes api={api} />;
      case 'cartera':       return <Cartera api={api} />;
      case 'solicitudes_admin': return <SolicitudesAdmin api={api} />;
      case 'mora_cartera':  return <MoraCartera api={api} />;
      case 'reportes_fventas':  return <Reportes api={api} />;
      case 'users':         return <Users api={api} />;
      case 'clientes':      return <ClientesAdmin api={api} />;
      case 'asesores':      return <AsesoresAdmin api={api} />;
      case 'products':      return <Products api={api} />;
      case 'parametros':    return <Parametros api={api} />;
      case 'cronogramas':   return <Cronogramas api={api} />;
      case 'sync':          return <SyncLogs api={api} />;
      default:              return <Dashboard api={api} setPage={setPage} />;
    }
  };

  const SIDEBAR_W = sidebarCollapsed ? 72 : 272;

  return (
    <div className="admin-layout">
      {/* Sidebar Overlay for mobile */}
      {mobileMenuOpen && (
        <div className="sidebar-overlay" onClick={() => setMobileMenuOpen(false)}></div>
      )}

      {/* Sidebar */}
      <aside className={`admin-sidebar ${sidebarCollapsed ? 'collapsed' : ''} ${mobileMenuOpen ? 'open' : ''}`}>
        {/* Logo */}
        <div style={s.logoArea}>
          <div style={s.logoWrapper}>
            <div style={s.bcpBlueBlock}>BCP</div>
            <div style={s.bcpOrangeAccent}></div>
          </div>
          {!sidebarCollapsed && (
            <div style={s.logoText}>
              <div style={s.logoTitle}>Portal Admin</div>
              <div style={s.logoSub}>Banco de Crédito del Perú</div>
            </div>
          )}
          <button
            style={s.collapseBtn}
            onClick={() => setSidebarCollapsed(v => !v)}
            title={sidebarCollapsed ? 'Expandir' : 'Colapsar'}
          >
            <span className="material-icons-round" style={{ fontSize: '18px', color: 'var(--color-text-muted)' }}>
              {sidebarCollapsed ? 'chevron_right' : 'chevron_left'}
            </span>
          </button>
        </div>

        {/* Scrollable Navigation Area */}
        <div style={{ flex: 1, minHeight: 0, overflowY: 'auto', paddingRight: '4px', marginBottom: '16px' }} className="sidebar-nav-scroll">
          {/* Nav Section 1 */}
          {!sidebarCollapsed && <div style={s.sectionLabel}>OPERACIONES</div>}
          <nav style={s.nav}>
            {NAV_ITEMS.map(item => (
              <NavButton
                key={item.id}
                item={item}
                active={page === item.id}
                collapsed={sidebarCollapsed}
                onClick={() => { setPage(item.id); setMobileMenuOpen(false); }}
              />
            ))}
          </nav>

          {/* Nav Section Fuerza de Ventas */}
          {!sidebarCollapsed && <div style={{ ...s.sectionLabel, marginTop: '20px' }}>FUERZA DE VENTAS</div>}
          <nav style={s.nav}>
            {NAV_FVENTAS.map(item => (
              <NavButton
                key={item.id}
                item={item}
                active={page === item.id}
                collapsed={sidebarCollapsed}
                onClick={() => { setPage(item.id); setMobileMenuOpen(false); }}
              />
            ))}
          </nav>

          {/* Nav Section 2 */}
          {!sidebarCollapsed && <div style={{ ...s.sectionLabel, marginTop: '20px' }}>ADMINISTRACIÓN</div>}
          <nav style={s.nav}>
            {NAV_SECTION2.map(item => (
              <NavButton
                key={item.id}
                item={item}
                active={page === item.id}
                collapsed={sidebarCollapsed}
                onClick={() => { setPage(item.id); setMobileMenuOpen(false); }}
              />
            ))}
          </nav>
        </div>

        {/* Footer */}
        <div style={s.sidebarFooter}>
          <div style={{ ...s.adminRow, ...(sidebarCollapsed ? { justifyContent: 'center' } : {}) }}>
            <div style={s.avatar}>
              <span className="material-icons-round" style={{ fontSize: '20px', color: '#fff' }}>admin_panel_settings</span>
            </div>
            {!sidebarCollapsed && (
              <div style={s.adminText}>
                <div style={s.adminName}>{adminName || 'Administrador BCP'}</div>
                <div style={s.adminRole}>Admin · BCP Core</div>
              </div>
            )}
          </div>
          <button
            style={{ ...s.logoutBtn, ...(sidebarCollapsed ? { padding: '10px', justifyContent: 'center' } : {}) }}
            onClick={handleLogout}
            title="Cerrar Sesión"
          >
            <span className="material-icons-round" style={{ fontSize: '18px' }}>logout</span>
            {!sidebarCollapsed && 'Cerrar Sesión'}
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className={`admin-main ${sidebarCollapsed ? 'expanded' : ''}`}>
        {/* Mobile Header Bar */}
        <header className="mobile-header">
          <button className="mobile-menu-btn" onClick={() => setMobileMenuOpen(true)}>
            <span className="material-icons-round">menu</span>
          </button>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <div style={{ display: 'flex', alignItems: 'stretch', height: '24px', borderRadius: '4px', overflow: 'hidden' }}>
              <div style={{ background: '#002A8D', color: '#fff', fontSize: '11px', fontWeight: '900', fontStyle: 'italic', padding: '0 6px', display: 'flex', alignItems: 'center' }}>BCP</div>
              <div style={{ width: '3px', background: '#FF7800' }}></div>
            </div>
            <span style={{ fontSize: '13px', fontWeight: 'bold', color: '#fff' }}>Portal Admin</span>
          </div>
        </header>

        {renderPage()}
      </main>
    </div>
  );
}

function NavButton({ item, active, collapsed, onClick }) {
  const [hovered, setHovered] = useState(false);
  return (
    <button
      onClick={onClick}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      title={collapsed ? item.label : ''}
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: collapsed ? 0 : '12px',
        justifyContent: collapsed ? 'center' : 'flex-start',
        width: '100%',
        padding: collapsed ? '12px' : '12px 16px',
        border: active ? '1px solid rgba(255,107,0,0.25)' : '1px solid transparent',
        borderRadius: '10px',
        cursor: 'pointer',
        fontSize: '14px',
        fontWeight: active ? 700 : 500,
        fontFamily: 'var(--font-sans)',
        color: active ? '#fff' : hovered ? 'var(--color-text)' : 'var(--color-text-muted)',
        background: active
          ? 'linear-gradient(135deg, rgba(255,107,0,0.18) 0%, rgba(255,107,0,0.06) 100%)'
          : hovered
          ? 'rgba(255,255,255,0.04)'
          : 'transparent',
        transition: 'all 0.2s ease',
        whiteSpace: 'nowrap',
        overflow: 'hidden',
        marginBottom: '4px',
      }}
    >
      <span className="material-icons-round" style={{
        fontSize: '20px',
        color: active ? 'var(--bcp-orange)' : hovered ? 'var(--color-text)' : 'var(--color-text-muted)',
        flexShrink: 0,
      }}>
        {item.icon}
      </span>
      {!collapsed && item.label}
    </button>
  );
}

const s = {
  layout: {
    display: 'flex',
    minHeight: '100vh',
    width: '100vw',
    backgroundColor: 'var(--color-bg)',
  },
  sidebar: {
    position: 'fixed',
    top: 0,
    left: 0,
    bottom: 0,
    display: 'flex',
    flexDirection: 'column',
    padding: '24px 16px',
    background: 'linear-gradient(180deg, rgba(13,22,40,0.98) 0%, rgba(7,13,26,0.98) 100%)',
    borderRight: '1px solid var(--color-border)',
    backdropFilter: 'blur(20px)',
    zIndex: 100,
    transition: 'width 0.25s cubic-bezier(0.16,1,0.3,1)',
    overflow: 'hidden',
  },
  logoArea: {
    display: 'flex',
    alignItems: 'center',
    gap: '12px',
    marginBottom: '28px',
    paddingBottom: '20px',
    borderBottom: '1px solid var(--color-border)',
    minHeight: '56px',
  },
  logoWrapper: {
    display: 'flex',
    alignItems: 'stretch',
    height: '32px',
    borderRadius: '6px',
    overflow: 'hidden',
    flexShrink: 0,
  },
  bcpBlueBlock: {
    background: '#002A8D',
    color: '#fff',
    fontFamily: "'Outfit', sans-serif",
    fontWeight: '900',
    fontSize: '14px',
    fontStyle: 'italic',
    padding: '0 10px',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    letterSpacing: '0.5px',
  },
  bcpOrangeAccent: {
    width: '4px',
    background: '#FF7800',
  },
  logoText: { flex: 1, overflow: 'hidden' },
  logoTitle: { fontSize: '14px', fontWeight: '800', color: '#fff', whiteSpace: 'nowrap' },
  logoSub: { fontSize: '10px', color: 'var(--color-text-muted)', whiteSpace: 'nowrap' },
  collapseBtn: {
    background: 'none',
    border: 'none',
    cursor: 'pointer',
    padding: '4px',
    borderRadius: '6px',
    flexShrink: 0,
  },
  sectionLabel: {
    fontSize: '10px',
    fontWeight: '700',
    color: 'var(--color-text-dim)',
    letterSpacing: '0.1em',
    padding: '0 4px',
    marginBottom: '8px',
    whiteSpace: 'nowrap',
  },
  nav: {
    display: 'flex',
    flexDirection: 'column',
  },
  sidebarFooter: {
    marginTop: 'auto',
    display: 'flex',
    flexDirection: 'column',
    gap: '12px',
    paddingTop: '20px',
    borderTop: '1px solid var(--color-border)',
  },
  adminRow: {
    display: 'flex',
    alignItems: 'center',
    gap: '10px',
  },
  avatar: {
    width: 36,
    height: 36,
    borderRadius: '50%',
    background: 'linear-gradient(135deg, var(--bcp-navy-light), var(--bcp-navy))',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    flexShrink: 0,
  },
  adminText: { overflow: 'hidden' },
  adminName: {
    fontSize: '13px',
    fontWeight: '700',
    color: '#fff',
    whiteSpace: 'nowrap',
    overflow: 'hidden',
    textOverflow: 'ellipsis',
  },
  adminRole: { fontSize: '11px', color: 'var(--color-text-muted)', whiteSpace: 'nowrap' },
  logoutBtn: {
    display: 'flex',
    alignItems: 'center',
    gap: '8px',
    background: 'rgba(229,62,62,0.06)',
    border: '1px solid rgba(229,62,62,0.15)',
    color: '#E53E3E',
    padding: '10px 14px',
    borderRadius: '10px',
    cursor: 'pointer',
    fontSize: '14px',
    fontWeight: '600',
    fontFamily: 'var(--font-sans)',
    transition: 'all 0.2s',
    width: '100%',
  },
  main: {
    flex: 1,
    minHeight: '100vh',
    overflowY: 'auto',
    transition: 'margin-left 0.25s cubic-bezier(0.16,1,0.3,1)',
  },
};
