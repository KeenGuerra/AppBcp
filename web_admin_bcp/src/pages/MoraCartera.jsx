// MoraCartera.jsx — Admin: supervisión de la cartera en mora y gestiones de cobranza
import React, { useEffect, useState } from 'react';

export default function MoraCartera({ api }) {
  const [moraList, setMoraList] = useState([]);
  const [totalVencido, setTotalVencido] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedAsesor, setSelectedAsesor] = useState('TODOS');
  const [selectedPrioridad, setSelectedPrioridad] = useState('TODOS');

  const fetchMora = async () => {
    setLoading(true);
    try {
      const res = await api.get('/admin/fventas/mora');
      setMoraList(res.data.mora_list || []);
      setTotalVencido(res.data.monto_total_vencido || 0);
      setError(null);
    } catch (err) {
      console.error(err);
      setError('Error al cargar la información de mora y cobranzas.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchMora();
    const interval = setInterval(fetchMora, 30000); // 30s auto-refresh
    return () => clearInterval(interval);
  }, []);

  const asesores = Array.from(new Set(moraList.map(item => item.asesor_nombre).filter(Boolean)));

  const filteredMora = moraList.filter(item => {
    const nameMatch = item.cliente_nombre.toLowerCase().includes(searchTerm.toLowerCase()) || 
                      item.documento.includes(searchTerm);
    const asesorMatch = selectedAsesor === 'TODOS' || item.asesor_nombre === selectedAsesor;
    const prioridadMatch = selectedPrioridad === 'TODOS' || item.prioridad === selectedPrioridad;
    return nameMatch && asesorMatch && prioridadMatch;
  });

  const getSemaphoreColor = (dias) => {
    if (dias === 0) return '#1DB954'; // Green
    if (dias <= 8) return '#F6C90E';  // Yellow
    if (dias <= 30) return '#FF6B00'; // Orange
    return '#E53E3E';                  // Red
  };

  const getPrioridadBadge = (prio) => {
    if (prio === 'ALTA') return 'badge-error';
    if (prio === 'MEDIA') return 'badge-warning';
    return 'badge-navy';
  };

  const fmt = (n) => `S/ ${Number(n || 0).toLocaleString('es-PE', { minimumFractionDigits: 2 })}`;

  if (loading && moraList.length === 0) return (
    <div className="loading-container">
      <div className="spinner" />
      <p>Cargando cartera de mora...</p>
    </div>
  );

  return (
    <div className="page-container fade-in">
      <div className="page-header">
        <div>
          <h1 className="page-title">⚠️ Mora & Cobranzas</h1>
          <p className="page-subtitle">Monitoreo y recuperación de créditos vencidos de la fuerza de ventas.</p>
        </div>
        <button className="btn-secondary" onClick={fetchMora}>
          <span className="material-icons-round">refresh</span>
          Actualizar
        </button>
      </div>

      {error && <div className="alert alert-error">{error}</div>}

      {/* Stats Cards */}
      <div className="stats-grid">
        <div className="stat-card red">
          <div className="stat-icon" style={{ background: 'rgba(229,62,62,0.12)' }}>
            <span className="material-icons-round" style={{ color: '#E53E3E' }}>warning</span>
          </div>
          <div className="stat-label">Monto Total en Mora</div>
          <div className="stat-value">{fmt(totalVencido)}</div>
          <div className="stat-sub">Cartera vencida activa</div>
        </div>

        <div className="stat-card orange">
          <div className="stat-icon" style={{ background: 'rgba(255,107,0,0.12)' }}>
            <span className="material-icons-round" style={{ color: 'var(--bcp-orange)' }}>people_outline</span>
          </div>
          <div className="stat-label">Clientes en Default</div>
          <div className="stat-value">{moraList.length}</div>
          <div className="stat-sub">{moraList.filter(m => m.prioridad === 'ALTA').length} de alta prioridad</div>
        </div>

        <div className="stat-card navy">
          <div className="stat-icon" style={{ background: 'rgba(0,42,84,0.3)' }}>
            <span className="material-icons-round" style={{ color: '#7FB3E0' }}>schedule</span>
          </div>
          <div className="stat-label">Mora Promedio</div>
          <div className="stat-value">
            {moraList.length > 0 
              ? `${Math.round(moraList.reduce((acc, m) => acc + m.dias_mora, 0) / moraList.length)} días`
              : '0 días'}
          </div>
          <div className="stat-sub">Tiempo de retraso promedio</div>
        </div>

        <div className="stat-card green">
          <div className="stat-icon" style={{ background: 'rgba(29,185,84,0.12)' }}>
            <span className="material-icons-round" style={{ color: '#1DB954' }}>contact_phone</span>
          </div>
          <div className="stat-label">Últimos Contactos</div>
          <div className="stat-value">{moraList.filter(m => m.fecha_ultimo_contacto).length}</div>
          <div className="stat-sub">Clientes gestionados en campo</div>
        </div>
      </div>

      {/* Filters and List */}
      <section className="glass-panel" style={{ padding: '24px', marginTop: '24px' }}>
        <div style={{ display: 'flex', gap: '16px', marginBottom: '20px', flexWrap: 'wrap', alignItems: 'center' }}>
          <div style={{ flex: '1 1 300px' }}>
            <input
              type="text"
              placeholder="Buscar por cliente o DNI..."
              className="form-control"
              value={searchTerm}
              onChange={e => setSearchTerm(e.target.value)}
              style={{ width: '100%' }}
            />
          </div>
          
          <div style={{ flex: '0 0 200px' }}>
            <select
              className="form-control"
              value={selectedAsesor}
              onChange={e => setSelectedAsesor(e.target.value)}
              style={{ width: '100%' }}
            >
              <option value="TODOS">Todos los asesores</option>
              {asesores.map(a => (
                <option key={a} value={a}>{a}</option>
              ))}
            </select>
          </div>

          <div style={{ flex: '0 0 200px' }}>
            <select
              className="form-control"
              value={selectedPrioridad}
              onChange={e => setSelectedPrioridad(e.target.value)}
              style={{ width: '100%' }}
            >
              <option value="TODOS">Todas las prioridades</option>
              <option value="ALTA">Alta</option>
              <option value="MEDIA">Media</option>
              <option value="BAJA">Baja</option>
            </select>
          </div>
        </div>

        <div className="table-wrapper">
          <table className="data-table">
            <thead>
              <tr>
                <th>Semáforo</th>
                <th>Cliente</th>
                <th>DNI</th>
                <th>Asesor Asignado</th>
                <th>Prioridad</th>
                <th>Días de Atraso</th>
                <th>Monto Vencido</th>
                <th>Último Contacto</th>
              </tr>
            </thead>
            <tbody>
              {filteredMora.map(item => (
                <tr key={item.id_cartera}>
                  <td style={{ textAlign: 'center', width: '60px' }}>
                    <div style={{
                      width: 14, height: 14, borderRadius: '50%',
                      background: getSemaphoreColor(item.dias_mora),
                      boxShadow: `0 0 8px ${getSemaphoreColor(item.dias_mora)}`,
                      display: 'inline-block'
                    }} />
                  </td>
                  <td style={{ fontWeight: 'bold' }}>{item.cliente_nombre}</td>
                  <td style={{ fontFamily: 'monospace' }}>{item.documento}</td>
                  <td>{item.asesor_nombre}</td>
                  <td>
                    <span className={`badge ${getPrioridadBadge(item.prioridad)}`}>
                      {item.prioridad}
                    </span>
                  </td>
                  <td style={{ fontWeight: 700 }}>
                    {item.dias_mora} {item.dias_mora === 1 ? 'día' : 'días'}
                  </td>
                  <td style={{ color: '#E53E3E', fontWeight: 800, fontSize: '15px' }}>
                    {fmt(item.monto_vencido)}
                  </td>
                  <td style={{ color: 'var(--color-text-muted)', fontSize: '13px' }}>
                    {item.fecha_ultimo_contacto 
                      ? new Date(item.fecha_ultimo_contacto).toLocaleString('es-PE')
                      : <span style={{ color: 'var(--color-text-dim)' }}>Sin contacto</span>}
                  </td>
                </tr>
              ))}
              {filteredMora.length === 0 && (
                <tr>
                  <td colSpan="8" className="empty-state">
                    <span className="material-icons-round">warning_amber</span>
                    <p>No se encontraron clientes en mora bajo los filtros especificados.</p>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}
