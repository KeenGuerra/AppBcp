// Prestamos.jsx — Admin: gestión de préstamos y solicitudes
import React, { useEffect, useState } from 'react';

const ESTADO_BADGE = {
  PENDIENTE: 'badge-warning',
  APROBADO: 'badge-success',
  RECHAZADO: 'badge-error',
  ACTIVO: 'badge-success',
  CANCELADO: 'badge-error',
};

export default function Prestamos({ api }) {
  const [solicitudes, setSolicitudes] = useState([]);
  const [prestamos, setPrestamos] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('solicitudes');
  const [actionLoading, setActionLoading] = useState('');

  const fetchData = async () => {
    setLoading(true);
    try {
      const [rSol, rPre] = await Promise.allSettled([
        api.get('/banking/admin/solicitudes-prestamo'),
        api.get('/banking/admin/prestamos'),
      ]);
      if (rSol.status === 'fulfilled') setSolicitudes(rSol.value.data);
      if (rPre.status === 'fulfilled') setPrestamos(rPre.value.data);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchData(); }, []);

  const handleUpdateEstado = async (id, estado) => {
    setActionLoading(id);
    try {
      await api.patch(`/banking/solicitudes-prestamo/${id}/estado?estado=${estado}`);
      fetchData();
    } catch (e) {
      alert(e.response?.data?.detail || 'Error al actualizar estado');
    } finally {
      setActionLoading('');
    }
  };

  const fmt = (n) => `S/ ${Number(n).toLocaleString('es-PE', { minimumFractionDigits: 2 })}`;

  const totalSolicitudPendiente = solicitudes.filter(s => s.estado === 'PENDIENTE').length;
  const totalMontoSolicitudes = solicitudes.reduce((s, r) => s + (r.monto || 0), 0);
  const totalMontoPrestamos = prestamos.reduce((s, r) => s + (r.saldo_pendiente || 0), 0);

  if (loading) return (
    <div className="loading-container">
      <div className="spinner" />
      <p>Cargando módulo de préstamos...</p>
    </div>
  );

  return (
    <div className="page-container fade-in">
      <div className="page-header">
        <div>
          <h1 className="page-title">🏦 Préstamos & Solicitudes</h1>
          <p className="page-subtitle">Revisión y aprobación de solicitudes de crédito personal de los clientes.</p>
        </div>
        <button className="btn-secondary" onClick={fetchData}>
          <span className="material-icons-round">refresh</span>
          Actualizar
        </button>
      </div>

      {/* Stats */}
      <div className="stats-grid">
        <div className="stat-card orange">
          <div className="stat-icon" style={{ background: 'rgba(255,107,0,0.12)' }}>
            <span className="material-icons-round" style={{ color: 'var(--bcp-orange)' }}>pending_actions</span>
          </div>
          <div className="stat-label">Solicitudes Pendientes</div>
          <div className="stat-value">{totalSolicitudPendiente}</div>
          <div className="stat-sub">Requieren revisión</div>
        </div>
        <div className="stat-card green">
          <div className="stat-icon" style={{ background: 'rgba(29,185,84,0.12)' }}>
            <span className="material-icons-round" style={{ color: '#1DB954' }}>check_circle</span>
          </div>
          <div className="stat-label">Total Solicitudes</div>
          <div className="stat-value">{solicitudes.length}</div>
          <div className="stat-sub">{fmt(totalMontoSolicitudes)} en solicitudes</div>
        </div>
        <div className="stat-card navy">
          <div className="stat-icon" style={{ background: 'rgba(0,42,84,0.3)' }}>
            <span className="material-icons-round" style={{ color: '#7FB3E0' }}>account_balance</span>
          </div>
          <div className="stat-label">Préstamos Activos</div>
          <div className="stat-value">{prestamos.filter(p => p.estado === 'ACTIVO').length}</div>
          <div className="stat-sub">{fmt(totalMontoPrestamos)} saldo pendiente</div>
        </div>
        <div className="stat-card sky">
          <div className="stat-icon" style={{ background: 'rgba(0,163,224,0.12)' }}>
            <span className="material-icons-round" style={{ color: '#00A3E0' }}>payments</span>
          </div>
          <div className="stat-label">TEA Promedio</div>
          <div className="stat-value">38.4%</div>
          <div className="stat-sub">Tasa efectiva anual BCP</div>
        </div>
      </div>

      {/* Tabs */}
      <div className="tab-nav">
        <button className={`tab-btn ${activeTab === 'solicitudes' ? 'active' : ''}`} onClick={() => setActiveTab('solicitudes')}>
          <span className="material-icons-round" style={{ fontSize: '16px' }}>pending_actions</span>
          Solicitudes ({solicitudes.length})
        </button>
        <button className={`tab-btn ${activeTab === 'prestamos' ? 'active' : ''}`} onClick={() => setActiveTab('prestamos')}>
          <span className="material-icons-round" style={{ fontSize: '16px' }}>account_balance</span>
          Préstamos Activos ({prestamos.length})
        </button>
      </div>

      {/* Solicitudes Tab */}
      {activeTab === 'solicitudes' && (
        <div className="slide-up">
          {solicitudes.length === 0 ? (
            <div className="glass-panel">
              <div className="empty-state">
                <span className="material-icons-round">pending_actions</span>
                <p>No hay solicitudes de préstamo registradas.<br/>Las solicitudes aparecerán cuando los clientes las envíen desde la app móvil.</p>
              </div>
            </div>
          ) : (
            <div className="glass-panel" style={{ padding: '0', overflow: 'hidden' }}>
              <div className="table-wrapper">
                <table className="data-table">
                  <thead>
                    <tr>
                      <th>Cliente</th>
                      <th>DNI / ID Usuario</th>
                      <th>Monto</th>
                      <th>Plazo</th>
                      <th>Cuota Mensual</th>
                      <th>TEA</th>
                      <th>Estado</th>
                      <th>Acciones</th>
                    </tr>
                  </thead>
                  <tbody>
                    {solicitudes.map(s => (
                      <tr key={s.id}>
                        <td>
                          <div style={{ fontWeight: 600 }}>{s.cliente_nombre || 'Cliente BCP'}</div>
                          <div style={{ fontSize: '10px', color: 'var(--color-text-muted)' }}>ID Solicitud: {s.id?.substring(0, 8)}...</div>
                        </td>
                        <td>
                          <div style={{ fontWeight: 600 }}>{s.documento || '—'}</div>
                          <div style={{ fontSize: '10px', color: 'var(--color-text-muted)', fontFamily: 'monospace' }}>
                            {s.user_id?.substring(0, 8)}...
                          </div>
                        </td>
                        <td><span style={{ fontWeight: 700, fontSize: '15px' }}>{`S/ ${Number(s.monto).toLocaleString('es-PE', { minimumFractionDigits: 2 })}`}</span></td>
                        <td>{s.plazo} meses</td>
                        <td style={{ color: 'var(--bcp-orange)', fontWeight: 600 }}>{`S/ ${Number(s.cuota_calculada).toLocaleString('es-PE', { minimumFractionDigits: 2 })}`}</td>
                        <td>{s.tea}%</td>
                        <td>
                          <span className={`badge ${ESTADO_BADGE[s.estado] || 'badge-navy'}`}>
                            {s.estado}
                          </span>
                        </td>
                        <td>
                          {s.estado === 'PENDIENTE' && (
                            <div style={{ display: 'flex', gap: '8px' }}>
                              <button
                                className="btn-primary"
                                style={{ padding: '6px 12px', fontSize: '12px', borderRadius: '8px' }}
                                disabled={actionLoading === s.id}
                                onClick={() => handleUpdateEstado(s.id, 'APROBADO')}
                              >
                                <span className="material-icons-round" style={{ fontSize: '14px' }}>check</span>
                                Aprobar
                              </button>
                              <button
                                className="btn-danger"
                                style={{ padding: '6px 12px', fontSize: '12px' }}
                                disabled={actionLoading === s.id}
                                onClick={() => handleUpdateEstado(s.id, 'RECHAZADO')}
                              >
                                <span className="material-icons-round" style={{ fontSize: '14px' }}>close</span>
                                Rechazar
                              </button>
                            </div>
                          )}
                          {s.estado !== 'PENDIENTE' && (
                            <span style={{ color: 'var(--color-text-dim)', fontSize: '12px' }}>Procesado</span>
                          )}
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

      {/* Préstamos Activos Tab */}
      {activeTab === 'prestamos' && (
        <div className="slide-up">
          {prestamos.length === 0 ? (
            <div className="glass-panel">
              <div className="empty-state">
                <span className="material-icons-round">account_balance</span>
                <p>No hay préstamos activos registrados.</p>
              </div>
            </div>
          ) : (
            <div className="glass-panel" style={{ padding: '0', overflow: 'hidden' }}>
              <div className="table-wrapper">
                <table className="data-table">
                  <thead>
                    <tr>
                      <th>Cliente</th>
                      <th>DNI / ID Usuario</th>
                      <th>Monto Original</th>
                      <th>Saldo Pendiente</th>
                      <th>Cuota</th>
                      <th>Cuotas Restantes</th>
                      <th>Progreso</th>
                      <th>Estado</th>
                    </tr>
                  </thead>
                  <tbody>
                    {prestamos.map(p => {
                      const progreso = p.monto_original
                        ? Math.min(100, ((p.monto_original - p.saldo_pendiente) / p.monto_original) * 100)
                        : 0;
                      return (
                        <tr key={p.id}>
                          <td>
                            <div style={{ fontWeight: 600 }}>{p.cliente_nombre || 'Cliente BCP'}</div>
                            <div style={{ fontSize: '10px', color: 'var(--color-text-muted)' }}>ID Préstamo: {p.id?.substring(0, 8)}...</div>
                          </td>
                          <td>
                            <div style={{ fontWeight: 600 }}>{p.documento || '—'}</div>
                            <div style={{ fontSize: '10px', color: 'var(--color-text-muted)', fontFamily: 'monospace' }}>
                              {p.user_id?.substring(0, 8)}...
                            </div>
                          </td>
                          <td style={{ fontWeight: 600 }}>{`S/ ${Number(p.monto_original || 0).toLocaleString('es-PE', { minimumFractionDigits: 2 })}`}</td>
                          <td style={{ color: '#E53E3E', fontWeight: 700 }}>{`S/ ${Number(p.saldo_pendiente || 0).toLocaleString('es-PE', { minimumFractionDigits: 2 })}`}</td>
                          <td style={{ color: 'var(--bcp-orange)' }}>{`S/ ${Number(p.cuota_mensual || 0).toLocaleString('es-PE', { minimumFractionDigits: 2 })}`}</td>
                          <td>{p.cuotas_restantes ?? '—'}</td>
                          <td style={{ minWidth: '120px' }}>
                            <div className="progress-track">
                              <div className="progress-fill" style={{ width: `${progreso}%` }} />
                            </div>
                            <span style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>{progreso.toFixed(0)}% pagado</span>
                          </td>
                          <td>
                            <span className={`badge ${ESTADO_BADGE[p.estado] || 'badge-navy'}`}>{p.estado}</span>
                          </td>
                        </tr>
                      );
                    })}
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
