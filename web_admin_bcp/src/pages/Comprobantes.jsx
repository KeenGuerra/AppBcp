// Comprobantes.jsx — Admin: historial de comprobantes y gastos personales
import React, { useEffect, useState } from 'react';

const TIPO_META = {
  DEPOSITO: { icon: 'arrow_downward', color: '#1DB954', badge: 'badge-success' },
  RETIRO: { icon: 'arrow_upward', color: '#E53E3E', badge: 'badge-error' },
  TRANSFERENCIA: { icon: 'swap_horiz', color: '#00A3E0', badge: 'badge-info' },
  PAGO_LUZ: { icon: 'bolt', color: '#F6C90E', badge: 'badge-warning' },
  PAGO_AGUA: { icon: 'water_drop', color: '#00A3E0', badge: 'badge-info' },
  PAGO_INTERNET: { icon: 'wifi', color: '#7FB3E0', badge: 'badge-navy' },
  PAGO_TELEFONO: { icon: 'phone', color: '#1DB954', badge: 'badge-success' },
  PAGO_GAS: { icon: 'local_fire_department', color: '#FF6B00', badge: 'badge-orange' },
};

function getMetaFor(tipo) {
  for (const key of Object.keys(TIPO_META)) {
    if (tipo?.includes(key)) return TIPO_META[key];
  }
  return { icon: 'receipt_long', color: '#FF6B00', badge: 'badge-orange' };
}

export default function Comprobantes({ api }) {
  const [comprobantes, setComprobantes] = useState([]);
  const [gastos, setGastos] = useState([]);
  const [simulaciones, setSimulaciones] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('comprobantes');
  const [filterTipo, setFilterTipo] = useState('TODOS');

  const fetchData = async () => {
    setLoading(true);
    try {
      const [rC, rG, rS] = await Promise.allSettled([
        api.get('/banking/admin/comprobantes'),
        api.get('/banking/admin/gastos'),
        api.get('/banking/admin/simulaciones'),
      ]);
      if (rC.status === 'fulfilled') setComprobantes(rC.value.data);
      if (rG.status === 'fulfilled') setGastos(rG.value.data);
      if (rS.status === 'fulfilled') setSimulaciones(rS.value.data);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchData(); }, []);

  const fmt = (n) => `S/ ${Number(n || 0).toLocaleString('es-PE', { minimumFractionDigits: 2 })}`;

  const tiposUnicos = ['TODOS', ...new Set(comprobantes.map(c => c.tipo))];
  const filteredC = filterTipo === 'TODOS'
    ? comprobantes
    : comprobantes.filter(c => c.tipo === filterTipo);

  const gastosPorCategoria = gastos.reduce((acc, g) => {
    acc[g.categoria] = (acc[g.categoria] || 0) + g.monto;
    return acc;
  }, {});

  if (loading) return (
    <div className="loading-container">
      <div className="spinner" />
      <p>Cargando comprobantes y reportes...</p>
    </div>
  );

  return (
    <div className="page-container fade-in">
      <div className="page-header">
        <div>
          <h1 className="page-title">🧾 Comprobantes & Gastos</h1>
          <p className="page-subtitle">Historial de comprobantes generados, gastos personales y simulaciones de crédito.</p>
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
            <span className="material-icons-round" style={{ color: 'var(--bcp-orange)' }}>receipt_long</span>
          </div>
          <div className="stat-label">Comprobantes Emitidos</div>
          <div className="stat-value">{comprobantes.length}</div>
          <div className="stat-sub">Total de operaciones documentadas</div>
        </div>
        <div className="stat-card green">
          <div className="stat-icon" style={{ background: 'rgba(29,185,84,0.12)' }}>
            <span className="material-icons-round" style={{ color: '#1DB954' }}>category</span>
          </div>
          <div className="stat-label">Gastos Personales</div>
          <div className="stat-value">{gastos.length}</div>
          <div className="stat-sub">{fmt(gastos.reduce((s, g) => s + g.monto, 0))} total registrado</div>
        </div>
        <div className="stat-card navy">
          <div className="stat-icon" style={{ background: 'rgba(0,42,84,0.3)' }}>
            <span className="material-icons-round" style={{ color: '#7FB3E0' }}>calculate</span>
          </div>
          <div className="stat-label">Simulaciones</div>
          <div className="stat-value">{simulaciones.length}</div>
          <div className="stat-sub">Consultas de cuota realizadas</div>
        </div>
        <div className="stat-card sky">
          <div className="stat-icon" style={{ background: 'rgba(0,163,224,0.12)' }}>
            <span className="material-icons-round" style={{ color: '#00A3E0' }}>analytics</span>
          </div>
          <div className="stat-label">Categorías de Gasto</div>
          <div className="stat-value">{Object.keys(gastosPorCategoria).length}</div>
          <div className="stat-sub">Categorías activas</div>
        </div>
      </div>

      {/* Tabs */}
      <div className="tab-nav">
        <button className={`tab-btn ${activeTab === 'comprobantes' ? 'active' : ''}`} onClick={() => setActiveTab('comprobantes')}>
          <span className="material-icons-round" style={{ fontSize: '16px' }}>receipt_long</span>
          Comprobantes ({comprobantes.length})
        </button>
        <button className={`tab-btn ${activeTab === 'gastos' ? 'active' : ''}`} onClick={() => setActiveTab('gastos')}>
          <span className="material-icons-round" style={{ fontSize: '16px' }}>category</span>
          Gastos ({gastos.length})
        </button>
        <button className={`tab-btn ${activeTab === 'simulaciones' ? 'active' : ''}`} onClick={() => setActiveTab('simulaciones')}>
          <span className="material-icons-round" style={{ fontSize: '16px' }}>calculate</span>
          Simulaciones ({simulaciones.length})
        </button>
      </div>

      {/* Comprobantes */}
      {activeTab === 'comprobantes' && (
        <div className="slide-up">
          <div style={{ display: 'flex', gap: '8px', marginBottom: '20px', flexWrap: 'wrap' }}>
            {tiposUnicos.map(t => (
              <button
                key={t}
                className={`chip ${filterTipo === t ? 'active' : ''}`}
                onClick={() => setFilterTipo(t)}
              >
                {t === 'TODOS' ? 'Todos' : t.replace(/_/g, ' ')}
              </button>
            ))}
          </div>
          {filteredC.length === 0 ? (
            <div className="glass-panel">
              <div className="empty-state">
                <span className="material-icons-round">receipt_long</span>
                <p>No hay comprobantes emitidos aún.<br/>Los comprobantes se generan automáticamente en cada operación exitosa (Casuística 28).</p>
              </div>
            </div>
          ) : (
            <div className="glass-panel" style={{ padding: '0', overflow: 'hidden' }}>
              <div className="table-wrapper">
                <table className="data-table">
                  <thead>
                    <tr><th>Tipo</th><th>Monto</th><th>Referencia UUID</th><th>Usuario</th><th>Fecha</th></tr>
                  </thead>
                  <tbody>
                    {filteredC.map(c => {
                      const meta = getMetaFor(c.tipo);
                      return (
                        <tr key={c.id}>
                          <td>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                              <div style={{
                                width: 32, height: 32, borderRadius: '8px',
                                background: `${meta.color}18`,
                                display: 'flex', alignItems: 'center', justifyContent: 'center',
                              }}>
                                <span className="material-icons-round" style={{ fontSize: '16px', color: meta.color }}>
                                  {meta.icon}
                                </span>
                              </div>
                              <span className={`badge ${meta.badge}`}>{c.tipo?.replace(/_/g,' ')}</span>
                            </div>
                          </td>
                          <td><span style={{ fontWeight: 700, fontSize: '15px' }}>{fmt(c.monto)}</span></td>
                          <td style={{ fontFamily: 'monospace', fontSize: '11px', color: 'var(--color-text-muted)' }}>
                            {c.referencia_uuid?.substring(0, 16)}...
                          </td>
                          <td style={{ fontFamily: 'monospace', fontSize: '12px' }}>
                            {c.user_id?.substring(0, 12)}...
                          </td>
                          <td style={{ color: 'var(--color-text-muted)', fontSize: '13px' }}>
                            {c.fecha ? new Date(c.fecha).toLocaleString('es-PE') : '—'}
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

      {/* Gastos */}
      {activeTab === 'gastos' && (
        <div className="slide-up responsive-split-grid" style={{ alignItems: 'start' }}>
          <div className="glass-panel" style={{ padding: '0', overflow: 'hidden' }}>
            {gastos.length === 0 ? (
              <div className="empty-state">
                <span className="material-icons-round">category</span>
                <p>No hay gastos personales registrados.<br/>Los clientes los registran desde la app (Casuística 26).</p>
              </div>
            ) : (
              <div className="table-wrapper">
                <table className="data-table">
                  <thead>
                    <tr><th>Descripción</th><th>Monto</th><th>Categoría</th><th>Fecha</th></tr>
                  </thead>
                  <tbody>
                    {gastos.map(g => (
                      <tr key={g.id}>
                        <td>{g.descripcion}</td>
                        <td style={{ fontWeight: 600, color: '#E53E3E' }}>{fmt(g.monto)}</td>
                        <td><span className="badge badge-orange">{g.categoria}</span></td>
                        <td style={{ color: 'var(--color-text-muted)', fontSize: '13px' }}>
                          {g.fecha ? new Date(g.fecha).toLocaleDateString('es-PE') : '—'}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>

          {/* Category totals */}
          <div className="glass-panel" style={{ padding: '24px' }}>
            <h3 style={{ marginBottom: '20px', fontSize: '15px' }}>Gasto por Categoría</h3>
            {Object.entries(gastosPorCategoria).length === 0 ? (
              <p style={{ color: 'var(--color-text-muted)', fontSize: '14px' }}>Sin gastos aún</p>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                {Object.entries(gastosPorCategoria).map(([cat, total]) => {
                  const maxGasto = Math.max(...Object.values(gastosPorCategoria));
                  return (
                    <div key={cat}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px', fontSize: '14px' }}>
                        <span style={{ fontWeight: 600 }}>{cat}</span>
                        <span style={{ color: 'var(--bcp-orange)', fontWeight: 700 }}>{fmt(total)}</span>
                      </div>
                      <div className="progress-track">
                        <div className="progress-fill" style={{ width: `${(total / maxGasto) * 100}%` }} />
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </div>
      )}

      {/* Simulaciones */}
      {activeTab === 'simulaciones' && (
        <div className="slide-up">
          {simulaciones.length === 0 ? (
            <div className="glass-panel">
              <div className="empty-state">
                <span className="material-icons-round">calculate</span>
                <p>No hay simulaciones registradas.<br/>Las simulaciones se guardan desde la app (Casuística 7 & 8).</p>
              </div>
            </div>
          ) : (
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '20px' }}>
              {simulaciones.map(s => {
                const totalPagar = s.cuota_calculada * s.plazo;
                const totalIntereses = totalPagar - s.monto;
                return (
                  <div key={s.id} className="card" style={{ border: '1px solid var(--color-border)' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
                      <span className="material-icons-round" style={{ fontSize: '24px', color: 'var(--bcp-orange)' }}>calculate</span>
                      <span style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>
                        {s.fecha ? new Date(s.fecha).toLocaleDateString('es-PE') : '—'}
                      </span>
                    </div>
                    <div className="responsive-two-cols" style={{ gap: '12px' }}>
                      <div>
                        <div style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginBottom: '2px' }}>MONTO</div>
                        <div style={{ fontWeight: 700, fontSize: '16px' }}>{fmt(s.monto)}</div>
                      </div>
                      <div>
                        <div style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginBottom: '2px' }}>PLAZO</div>
                        <div style={{ fontWeight: 600 }}>{s.plazo} meses</div>
                      </div>
                      <div>
                        <div style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginBottom: '2px' }}>CUOTA MENSUAL</div>
                        <div style={{ fontWeight: 700, color: 'var(--bcp-orange)', fontSize: '16px' }}>{fmt(s.cuota_calculada)}</div>
                      </div>
                      <div>
                        <div style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginBottom: '2px' }}>TEA</div>
                        <div style={{ fontWeight: 600, color: '#1DB954' }}>{s.tea}%</div>
                      </div>
                      <div style={{ gridColumn: '1 / -1' }}>
                        <div style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginBottom: '2px' }}>TOTAL A PAGAR</div>
                        <div style={{ fontWeight: 700, fontSize: '16px' }}>{fmt(totalPagar)}</div>
                        <div style={{ fontSize: '11px', color: '#E53E3E' }}>Intereses: {fmt(totalIntereses)}</div>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
