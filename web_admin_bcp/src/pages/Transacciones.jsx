// Transacciones.jsx — Admin: monitoreo global de transacciones bancarias
import React, { useEffect, useState } from 'react';

const TIPO_ICONS = {
  DEPOSITO: 'arrow_downward',
  RETIRO: 'arrow_upward',
  RETIRO_PLAZO: 'savings',
  TRANSFERENCIA: 'swap_horiz',
  PAGO_LUZ: 'bolt',
  PAGO_AGUA: 'water_drop',
  PAGO_INTERNET: 'wifi',
  PAGO_TELEFONO: 'phone',
  PAGO_GAS: 'local_fire_department',
};
const TIPO_COLORS = {
  DEPOSITO: '#1DB954',
  RETIRO: '#E53E3E',
  RETIRO_PLAZO: '#E53E3E',
  TRANSFERENCIA: '#00A3E0',
  DEFAULT: '#FF6B00',
};

function getIcon(tipo) { return TIPO_ICONS[tipo] || 'receipt_long'; }
function getColor(tipo) { return TIPO_COLORS[tipo] || TIPO_COLORS.DEFAULT; }

export default function Transacciones({ api }) {
  const [transacciones, setTransacciones] = useState([]);
  const [transferencias, setTransferencias] = useState([]);
  const [pagos, setPagos] = useState([]);
  const [recargas, setRecargas] = useState([]);
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('transacciones');
  const [filterTipo, setFilterTipo] = useState('TODOS');

  const fetchAll = async () => {
    setLoading(true);
    try {
      const [rTx, rTrf, rPag, rRec, rStats] = await Promise.allSettled([
        api.get('/banking/admin/transacciones'),
        api.get('/banking/admin/transferencias'),
        api.get('/banking/admin/pagos-servicios'),
        api.get('/banking/admin/recargas'),
        api.get('/banking/admin/stats'),
      ]);
      if (rTx.status === 'fulfilled') setTransacciones(rTx.value.data);
      if (rTrf.status === 'fulfilled') setTransferencias(rTrf.value.data);
      if (rPag.status === 'fulfilled') setPagos(rPag.value.data);
      if (rRec.status === 'fulfilled') setRecargas(rRec.value.data);
      if (rStats.status === 'fulfilled') setStats(rStats.value.data);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchAll(); }, []);

  const filteredTx = filterTipo === 'TODOS'
    ? transacciones
    : transacciones.filter(t => t.tipo === filterTipo);

  const totalMonto = (arr) => arr.reduce((s, t) => s + (t.monto || 0), 0);
  const fmt = (n) => `S/ ${Number(n).toLocaleString('es-PE', { minimumFractionDigits: 2 })}`;

  if (loading) return (
    <div className="loading-container">
      <div className="spinner" />
      <p>Cargando operaciones bancarias...</p>
    </div>
  );

  return (
    <div className="page-container fade-in">
      <div className="page-header">
        <div>
          <h1 className="page-title">📊 Monitor de Operaciones</h1>
          <p className="page-subtitle">Supervisión global de todas las transacciones bancarias del sistema.</p>
        </div>
        <button className="btn-secondary" onClick={fetchAll}>
          <span className="material-icons-round">refresh</span>
          Actualizar
        </button>
      </div>

      {/* Stats */}
      <div className="stats-grid">
        <div className="stat-card orange" onClick={() => setActiveTab('transacciones')}>
          <div className="stat-icon" style={{ background: 'rgba(255,107,0,0.12)' }}>
            <span className="material-icons-round" style={{ color: 'var(--bcp-orange)' }}>receipt_long</span>
          </div>
          <div className="stat-label">Transacciones</div>
          <div className="stat-value">{stats?.totales?.transacciones ?? transacciones.length}</div>
          <div className="stat-sub">{fmt(stats?.montos?.transacciones ?? totalMonto(transacciones))}</div>
        </div>
        <div className="stat-card sky" onClick={() => setActiveTab('transferencias')}>
          <div className="stat-icon" style={{ background: 'rgba(0,163,224,0.12)' }}>
            <span className="material-icons-round" style={{ color: '#00A3E0' }}>swap_horiz</span>
          </div>
          <div className="stat-label">Transferencias</div>
          <div className="stat-value">{stats?.totales?.transferencias ?? transferencias.length}</div>
          <div className="stat-sub">{fmt(stats?.montos?.transferencias ?? totalMonto(transferencias))}</div>
        </div>
        <div className="stat-card green" onClick={() => setActiveTab('pagos')}>
          <div className="stat-icon" style={{ background: 'rgba(29,185,84,0.12)' }}>
            <span className="material-icons-round" style={{ color: '#1DB954' }}>payment</span>
          </div>
          <div className="stat-label">Pagos Servicios</div>
          <div className="stat-value">{stats?.totales?.pagos_servicios ?? pagos.length}</div>
          <div className="stat-sub">{fmt(stats?.montos?.pagos_servicios ?? totalMonto(pagos))}</div>
        </div>
        <div className="stat-card navy" onClick={() => setActiveTab('recargas')}>
          <div className="stat-icon" style={{ background: 'rgba(0,42,84,0.3)' }}>
            <span className="material-icons-round" style={{ color: '#7FB3E0' }}>smartphone</span>
          </div>
          <div className="stat-label">Recargas</div>
          <div className="stat-value">{stats?.totales?.recargas ?? recargas.length}</div>
          <div className="stat-sub">{fmt(totalMonto(recargas))}</div>
        </div>
      </div>

      {/* Tabs */}
      <div className="tab-nav">
        {[
          { id: 'transacciones', label: 'Depósitos & Retiros', icon: 'receipt_long' },
          { id: 'transferencias', label: 'Transferencias', icon: 'swap_horiz' },
          { id: 'pagos', label: 'Pagos Servicios', icon: 'payment' },
          { id: 'recargas', label: 'Recargas', icon: 'smartphone' },
        ].map(t => (
          <button
            key={t.id}
            className={`tab-btn ${activeTab === t.id ? 'active' : ''}`}
            onClick={() => setActiveTab(t.id)}
          >
            <span className="material-icons-round" style={{ fontSize: '16px' }}>{t.icon}</span>
            {t.label}
          </button>
        ))}
      </div>

      {/* Transacciones Tab */}
      {activeTab === 'transacciones' && (
        <div className="slide-up">
          <div style={{ display: 'flex', gap: '8px', marginBottom: '20px', flexWrap: 'wrap' }}>
            {['TODOS', 'DEPOSITO', 'RETIRO', 'RETIRO_PLAZO'].map(f => (
              <button
                key={f}
                className={`chip ${filterTipo === f ? 'active' : ''}`}
                onClick={() => setFilterTipo(f)}
              >
                {f === 'TODOS' ? 'Todos' : f.replace('_', ' ')}
              </button>
            ))}
          </div>
          <div className="glass-panel" style={{ padding: '0', overflow: 'hidden' }}>
            {filteredTx.length === 0 ? (
              <div className="empty-state">
                <span className="material-icons-round">receipt_long</span>
                <p>No hay transacciones registradas aún.<br/>Los clientes deben realizar operaciones desde la app móvil.</p>
              </div>
            ) : (
              <div className="table-wrapper">
                <table className="data-table">
                  <thead>
                    <tr>
                      <th>Tipo</th>
                      <th>Monto</th>
                      <th>Cuenta</th>
                      <th>Fecha</th>
                      <th>Estado</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredTx.map(t => (
                      <tr key={t.id}>
                        <td>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                            <div style={{
                              width: 32, height: 32, borderRadius: '8px',
                              background: `rgba(${getColor(t.tipo) === '#1DB954' ? '29,185,84' : getColor(t.tipo) === '#E53E3E' ? '229,62,62' : '0,163,224'},0.12)`,
                              display: 'flex', alignItems: 'center', justifyContent: 'center',
                            }}>
                              <span className="material-icons-round" style={{ fontSize: '16px', color: getColor(t.tipo) }}>
                                {getIcon(t.tipo)}
                              </span>
                            </div>
                            <span style={{ fontWeight: 600 }}>{t.tipo?.replace(/_/g,' ')}</span>
                          </div>
                        </td>
                        <td>
                          <span style={{ fontWeight: 700, color: getColor(t.tipo), fontSize: '15px' }}>
                            {fmt(t.monto)}
                          </span>
                        </td>
                        <td style={{ color: 'var(--color-text-muted)', fontFamily: 'monospace', fontSize: '13px' }}>
                          {(t.cuenta_id || '—').substring(0, 12)}...
                        </td>
                        <td style={{ color: 'var(--color-text-muted)', fontSize: '13px' }}>
                          {t.fecha ? new Date(t.fecha).toLocaleString('es-PE') : '—'}
                        </td>
                        <td>
                          <span className="badge badge-success">{t.estado || 'COMPLETADA'}</span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Transferencias Tab */}
      {activeTab === 'transferencias' && (
        <div className="slide-up">
          <div className="glass-panel" style={{ padding: '0', overflow: 'hidden' }}>
            {transferencias.length === 0 ? (
              <div className="empty-state">
                <span className="material-icons-round">swap_horiz</span>
                <p>No hay transferencias registradas aún.</p>
              </div>
            ) : (
              <div className="table-wrapper">
                <table className="data-table">
                  <thead>
                    <tr><th>Tipo</th><th>Origen</th><th>Destino</th><th>Monto</th><th>Nº Operación</th><th>Fecha</th><th>Estado</th></tr>
                  </thead>
                  <tbody>
                    {transferencias.map(t => (
                      <tr key={t.id}>
                        <td><span className={`badge ${t.tipo === 'TERCERO' ? 'badge-orange' : 'badge-navy'}`}>{t.tipo}</span></td>
                        <td style={{ fontFamily: 'monospace', fontSize: '13px' }}>{(t.cuenta_origen || '').substring(0,10)}...</td>
                        <td style={{ fontFamily: 'monospace', fontSize: '13px' }}>{(t.cuenta_destino || '').substring(0,10)}...</td>
                        <td><span style={{ fontWeight: 700, color: '#E53E3E', fontSize: '15px' }}>{fmt(t.monto)}</span></td>
                        <td style={{ fontFamily: 'monospace', fontSize: '12px', color: '#FF6B00' }}>{t.numero_operacion || '—'}</td>
                        <td style={{ color: 'var(--color-text-muted)', fontSize: '13px' }}>{t.fecha ? new Date(t.fecha).toLocaleString('es-PE') : '—'}</td>
                        <td><span className="badge badge-success">{t.estado}</span></td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Pagos Servicios Tab */}
      {activeTab === 'pagos' && (
        <div className="slide-up">
          <div className="glass-panel" style={{ padding: '0', overflow: 'hidden' }}>
            {pagos.length === 0 ? (
              <div className="empty-state">
                <span className="material-icons-round">payment</span>
                <p>No hay pagos de servicios registrados aún.</p>
              </div>
            ) : (
              <div className="table-wrapper">
                <table className="data-table">
                  <thead>
                    <tr><th>Servicio</th><th>Proveedor</th><th>Referencia</th><th>Monto</th><th>Nº Operación</th><th>Fecha</th></tr>
                  </thead>
                  <tbody>
                    {pagos.map(p => (
                      <tr key={p.id}>
                        <td>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                            <span className="material-icons-round" style={{ fontSize: '18px', color: 'var(--bcp-orange)' }}>
                              {getIcon('PAGO_' + p.servicio)}
                            </span>
                            <span style={{ fontWeight: 600 }}>{p.servicio}</span>
                          </div>
                        </td>
                        <td style={{ color: 'var(--color-text-muted)' }}>{p.proveedor || p.operadora || p.empresa || '—'}</td>
                        <td style={{ fontFamily: 'monospace', fontSize: '13px' }}>{p.referencia}</td>
                        <td><span style={{ fontWeight: 700, color: 'var(--bcp-orange)' }}>{fmt(p.monto)}</span></td>
                        <td style={{ fontFamily: 'monospace', fontSize: '12px', color: '#FF6B00' }}>{p.numero_operacion || '—'}</td>
                        <td style={{ color: 'var(--color-text-muted)', fontSize: '13px' }}>{p.fecha ? new Date(p.fecha).toLocaleString('es-PE') : '—'}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Recargas Tab */}
      {activeTab === 'recargas' && (
        <div className="slide-up">
          <div className="glass-panel" style={{ padding: '0', overflow: 'hidden' }}>
            {recargas.length === 0 ? (
              <div className="empty-state">
                <span className="material-icons-round">smartphone</span>
                <p>No hay recargas registradas aún.</p>
              </div>
            ) : (
              <div className="table-wrapper">
                <table className="data-table">
                  <thead>
                    <tr><th>Operadora</th><th>Celular</th><th>Monto</th><th>Nº Operación</th><th>Fecha</th><th>Estado</th></tr>
                  </thead>
                  <tbody>
                    {recargas.map(r => (
                      <tr key={r.id}>
                        <td><span className="badge badge-navy">{r.operadora}</span></td>
                        <td style={{ fontFamily: 'monospace' }}>{r.celular_enmascarado || r.celular_destino}</td>
                        <td><span style={{ fontWeight: 700, color: '#1DB954' }}>{fmt(r.monto)}</span></td>
                        <td style={{ fontFamily: 'monospace', fontSize: '12px', color: '#FF6B00' }}>{r.numero_operacion || '—'}</td>
                        <td style={{ color: 'var(--color-text-muted)', fontSize: '13px' }}>{r.fecha ? new Date(r.fecha).toLocaleString('es-PE') : '—'}</td>
                        <td><span className="badge badge-success">{r.estado}</span></td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
