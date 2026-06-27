// Ahorros.jsx — Admin: supervisión de ahorros, depósitos a plazo y metas
import React, { useEffect, useState } from 'react';

export default function Ahorros({ api }) {
  const [ahorros, setAhorros] = useState([]);
  const [metas, setMetas] = useState([]);
  const [depositos, setDepositos] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('ahorros');

  const fetchData = async () => {
    setLoading(true);
    try {
      const [rA, rM, rD] = await Promise.allSettled([
        api.get('/banking/admin/ahorros'),
        api.get('/banking/admin/metas-ahorro'),
        api.get('/banking/admin/depositos-plazo'),
      ]);
      if (rA.status === 'fulfilled') setAhorros(rA.value.data);
      if (rM.status === 'fulfilled') setMetas(rM.value.data);
      if (rD.status === 'fulfilled') setDepositos(rD.value.data);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchData(); }, []);

  const fmt = (n) => `S/ ${Number(n || 0).toLocaleString('es-PE', { minimumFractionDigits: 2 })}`;
  const totalAhorrado = ahorros.reduce((s, a) => s + (a.monto_actual || 0), 0);
  const totalMeta = metas.reduce((s, m) => s + (m.monto_objetivo || 0), 0);
  const totalDepositos = depositos.reduce((s, d) => s + (d.monto || 0), 0);

  const FRECUENCIA_BADGE = {
    Diario: 'badge-success',
    Semanal: 'badge-info',
    Mensual: 'badge-navy',
  };

  const CATEGORIA_ICON = {
    Viaje: 'flight',
    Educación: 'school',
    Emergencia: 'local_hospital',
    Otro: 'savings',
  };

  if (loading) return (
    <div className="loading-container">
      <div className="spinner" />
      <p>Cargando módulo de ahorros...</p>
    </div>
  );

  return (
    <div className="page-container fade-in">
      <div className="page-header">
        <div>
          <h1 className="page-title">💰 Ahorros & Depósitos</h1>
          <p className="page-subtitle">Supervisión de ahorros programados, metas y depósitos a plazo fijo de los clientes.</p>
        </div>
        <button className="btn-secondary" onClick={fetchData}>
          <span className="material-icons-round">refresh</span>
          Actualizar
        </button>
      </div>

      {/* Stats */}
      <div className="stats-grid">
        <div className="stat-card green">
          <div className="stat-icon" style={{ background: 'rgba(29,185,84,0.12)' }}>
            <span className="material-icons-round" style={{ color: '#1DB954' }}>savings</span>
          </div>
          <div className="stat-label">Ahorros Activos</div>
          <div className="stat-value">{ahorros.filter(a => a.activo !== false).length}</div>
          <div className="stat-sub">{fmt(totalAhorrado)} ahorrado</div>
        </div>
        <div className="stat-card orange">
          <div className="stat-icon" style={{ background: 'rgba(255,107,0,0.12)' }}>
            <span className="material-icons-round" style={{ color: 'var(--bcp-orange)' }}>flag</span>
          </div>
          <div className="stat-label">Metas de Ahorro</div>
          <div className="stat-value">{metas.length}</div>
          <div className="stat-sub">{fmt(totalMeta)} objetivo total</div>
        </div>
        <div className="stat-card navy">
          <div className="stat-icon" style={{ background: 'rgba(0,42,84,0.3)' }}>
            <span className="material-icons-round" style={{ color: '#7FB3E0' }}>account_balance</span>
          </div>
          <div className="stat-label">Depósitos a Plazo</div>
          <div className="stat-value">{depositos.filter(d => d.estado === 'ACTIVO').length}</div>
          <div className="stat-sub">{fmt(totalDepositos)} comprometido</div>
        </div>
        <div className="stat-card sky">
          <div className="stat-icon" style={{ background: 'rgba(0,163,224,0.12)' }}>
            <span className="material-icons-round" style={{ color: '#00A3E0' }}>trending_up</span>
          </div>
          <div className="stat-label">Metas Completadas</div>
          <div className="stat-value">{metas.filter(m => m.estado === 'COMPLETADA').length}</div>
          <div className="stat-sub">de {metas.length} metas totales</div>
        </div>
      </div>

      {/* Tabs */}
      <div className="tab-nav">
        <button className={`tab-btn ${activeTab === 'ahorros' ? 'active' : ''}`} onClick={() => setActiveTab('ahorros')}>
          <span className="material-icons-round" style={{ fontSize: '16px' }}>savings</span>
          Ahorros Programados ({ahorros.length})
        </button>
        <button className={`tab-btn ${activeTab === 'metas' ? 'active' : ''}`} onClick={() => setActiveTab('metas')}>
          <span className="material-icons-round" style={{ fontSize: '16px' }}>flag</span>
          Metas de Ahorro ({metas.length})
        </button>
        <button className={`tab-btn ${activeTab === 'depositos' ? 'active' : ''}`} onClick={() => setActiveTab('depositos')}>
          <span className="material-icons-round" style={{ fontSize: '16px' }}>account_balance</span>
          Depósitos a Plazo ({depositos.length})
        </button>
      </div>

      {/* Ahorros Tab */}
      {activeTab === 'ahorros' && (
        <div className="slide-up">
          {ahorros.length === 0 ? (
            <div className="glass-panel">
              <div className="empty-state">
                <span className="material-icons-round">savings</span>
                <p>No hay ahorros programados registrados.<br/>Los clientes podrán crear ahorros desde la app móvil (Casuística 13).</p>
              </div>
            </div>
          ) : (
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '20px' }}>
              {ahorros.map(a => {
                const progreso = a.monto_meta ? Math.min(100, (a.monto_actual / a.monto_meta) * 100) : 0;
                return (
                  <div key={a.id} className="card" style={{ border: '1px solid var(--color-border)' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '16px' }}>
                      <div>
                        <h3 style={{ fontSize: '16px', marginBottom: '4px' }}>{a.nombre}</h3>
                        <span className={`badge ${FRECUENCIA_BADGE[a.frecuencia] || 'badge-navy'}`}>{a.frecuencia}</span>
                      </div>
                      <span className={`badge ${a.activo !== false ? 'badge-success' : 'badge-warning'}`}>
                        {a.activo !== false ? 'ACTIVO' : a.estado || 'COMPLETADO'}
                      </span>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '12px' }}>
                      <div>
                        <div style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>Ahorrado</div>
                        <div style={{ fontWeight: 700, color: '#1DB954' }}>{fmt(a.monto_actual)}</div>
                      </div>
                      <div style={{ textAlign: 'right' }}>
                        <div style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>Meta</div>
                        <div style={{ fontWeight: 600 }}>{fmt(a.monto_meta)}</div>
                      </div>
                    </div>
                    <div className="progress-track" style={{ marginBottom: '8px' }}>
                      <div className="progress-fill" style={{ width: `${progreso}%` }} />
                    </div>
                    <div style={{ fontSize: '12px', color: 'var(--color-text-muted)', textAlign: 'right' }}>
                      {progreso.toFixed(0)}% completado
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      )}

      {/* Metas Tab */}
      {activeTab === 'metas' && (
        <div className="slide-up">
          {metas.length === 0 ? (
            <div className="glass-panel">
              <div className="empty-state">
                <span className="material-icons-round">flag</span>
                <p>No hay metas de ahorro registradas.<br/>Los clientes podrán crear metas desde la app móvil (Casuística 21).</p>
              </div>
            </div>
          ) : (
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '20px' }}>
              {metas.map(m => {
                const progreso = m.monto_objetivo ? Math.min(100, (m.monto_actual / m.monto_objetivo) * 100) : 0;
                const diasFaltantes = m.fecha_limite
                  ? Math.ceil((new Date(m.fecha_limite) - new Date()) / 86400000)
                  : null;
                return (
                  <div key={m.id} className="card" style={{ border: '1px solid var(--color-border)' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '16px' }}>
                      <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
                        <div style={{
                          background: 'rgba(255,107,0,0.12)', borderRadius: '8px',
                          padding: '8px', display: 'flex', alignItems: 'center',
                        }}>
                          <span className="material-icons-round" style={{ fontSize: '18px', color: 'var(--bcp-orange)' }}>
                            {CATEGORIA_ICON[m.categoria] || 'savings'}
                          </span>
                        </div>
                        <div>
                          <h3 style={{ fontSize: '15px', marginBottom: '2px' }}>{m.nombre}</h3>
                          <span style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>{m.categoria}</span>
                        </div>
                      </div>
                      <span className={`badge ${m.estado === 'COMPLETADA' ? 'badge-success' : 'badge-warning'}`}>
                        {m.estado}
                      </span>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '12px' }}>
                      <div>
                        <div style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>Aportado</div>
                        <div style={{ fontWeight: 700, color: '#1DB954' }}>{fmt(m.monto_actual)}</div>
                      </div>
                      <div style={{ textAlign: 'right' }}>
                        <div style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>Objetivo</div>
                        <div style={{ fontWeight: 600 }}>{fmt(m.monto_objetivo)}</div>
                      </div>
                    </div>
                    <div className="progress-track" style={{ marginBottom: '8px' }}>
                      <div className="progress-fill" style={{ width: `${progreso}%` }} />
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', color: 'var(--color-text-muted)' }}>
                      <span>{progreso.toFixed(0)}% completado</span>
                      {diasFaltantes !== null && (
                        <span style={{ color: diasFaltantes < 30 ? '#E53E3E' : 'inherit' }}>
                          {diasFaltantes > 0 ? `${diasFaltantes} días restantes` : 'Vencida'}
                        </span>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      )}

      {/* Depósitos Tab */}
      {activeTab === 'depositos' && (
        <div className="slide-up">
          {depositos.length === 0 ? (
            <div className="glass-panel">
              <div className="empty-state">
                <span className="material-icons-round">account_balance</span>
                <p>No hay depósitos a plazo fijo registrados.<br/>Los clientes podrán crearlos desde la app móvil (Casuística 15).</p>
              </div>
            </div>
          ) : (
            <div className="glass-panel" style={{ padding: '0', overflow: 'hidden' }}>
              <div className="table-wrapper">
                <table className="data-table">
                  <thead>
                    <tr><th>Usuario</th><th>Monto</th><th>Plazo</th><th>Tasa</th><th>Monto Final</th><th>Vencimiento</th><th>Estado</th></tr>
                  </thead>
                  <tbody>
                    {depositos.map(d => (
                      <tr key={d.id}>
                        <td style={{ fontFamily: 'monospace', fontSize: '12px' }}>{d.user_id?.substring(0,12)}...</td>
                        <td style={{ fontWeight: 600 }}>{fmt(d.monto)}</td>
                        <td>{d.plazo_dias} días</td>
                        <td><span style={{ color: '#1DB954', fontWeight: 600 }}>{d.tasa}%</span></td>
                        <td style={{ fontWeight: 700, color: 'var(--bcp-orange)' }}>{fmt(d.monto_final)}</td>
                        <td style={{ color: 'var(--color-text-muted)', fontSize: '13px' }}>
                          {d.fecha_vencimiento ? new Date(d.fecha_vencimiento).toLocaleDateString('es-PE') : '—'}
                        </td>
                        <td>
                          <span className={`badge ${d.estado === 'ACTIVO' ? 'badge-success' : d.estado === 'RETIRADO' ? 'badge-error' : 'badge-navy'}`}>
                            {d.estado}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
