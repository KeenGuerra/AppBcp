// Cartera.jsx — Monitor de visitas de asesores en tiempo real
import React, { useState, useEffect } from 'react';

export default function Cartera({ api }) {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [selectedAsesor, setSelectedAsesor] = useState('TODOS');
  const [selectedStatus, setSelectedStatus] = useState('TODOS');
  const [hoveredClient, setHoveredClient] = useState(null);

  const fetchCartera = async () => {
    setLoading(true);
    try {
      const res = await api.get('/supervisor/cartera/hoy');
      setData(res.data);
      setError(null);
    } catch (err) {
      setError('Error al cargar la información de la cartera de campo.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCartera();
    const interval = setInterval(fetchCartera, 30000); // Poll every 30s
    return () => clearInterval(interval);
  }, []);

  const asesores = Array.from(new Set(data.map(item => item.asesor_nombre)));

  const filteredData = data.filter(item => {
    const matchAsesor = selectedAsesor === 'TODOS' || item.asesor_nombre === selectedAsesor;
    const matchStatus = selectedStatus === 'TODOS' || item.estado_visita === selectedStatus;
    return matchAsesor && matchStatus;
  });

  // Calculate advisor stats
  const advisorStats = data.reduce((acc, item) => {
    const name = item.asesor_nombre;
    if (!acc[name]) acc[name] = { total: 0, visited: 0 };
    acc[name].total += 1;
    if (item.estado_visita === 'REALIZADA') acc[name].visited += 1;
    return acc;
  }, {});

  // Coordinates mapping to SVG box (width=500, height=350)
  // Lat range: -12.00 to -12.10, Lng range: -77.00 to -77.10
  const mapCoordinates = (lat, lng) => {
    if (!lat || !lng) return { x: 250, y: 175 };
    const minLat = -12.10, maxLat = -12.00;
    const minLng = -77.10, maxLng = -77.00;
    
    // Scale to SVG bounds [30, 470] for X, [30, 320] for Y
    const x = 30 + ((lng - minLng) / (maxLng - minLng)) * 440;
    const y = 320 - ((lat - minLat) / (maxLat - minLat)) * 290; // Y is inverted in screen coords
    return { x, y };
  };

  return (
    <div className="page-container fade-in">
      <header className="page-header">
        <div>
          <h1 className="page-title">Monitor de Visitas en Tiempo Real</h1>
          <p className="page-subtitle">Progreso y ubicación de la fuerza de ventas en campo</p>
        </div>
        <button className="btn-primary" onClick={fetchCartera} disabled={loading}>
          <span className="material-icons-round">refresh</span> Actualizar
        </button>
      </header>

      {error && <div className="alert alert-error">{error}</div>}

      {/* Stats Summary Grid */}
      <div className="stats-grid">
        <div className="stat-card orange" onClick={() => setSelectedStatus('TODOS')}>
          <div className="stat-icon" style={{ background: 'rgba(255,107,0,0.1)' }}>
            <span className="material-icons-round" style={{ color: 'var(--bcp-orange)' }}>people</span>
          </div>
          <div className="stat-label">Total Clientes Asignados</div>
          <div className="stat-value">{data.length}</div>
          <div className="stat-sub">Hoy</div>
        </div>

        <div className="stat-card green" onClick={() => setSelectedStatus('REALIZADA')}>
          <div className="stat-icon" style={{ background: 'rgba(29,185,84,0.1)' }}>
            <span className="material-icons-round" style={{ color: 'var(--color-success)' }}>check_circle</span>
          </div>
          <div className="stat-label">Visitas Realizadas</div>
          <div className="stat-value">
            {data.filter(i => i.estado_visita === 'REALIZADA').length}
          </div>
          <div className="stat-sub">
            {data.length ? Math.round((data.filter(i => i.estado_visita === 'REALIZADA').length / data.length) * 100) : 0}% de avance
          </div>
        </div>

        <div className="stat-card sky" onClick={() => setSelectedStatus('PENDIENTE')}>
          <div className="stat-icon" style={{ background: 'rgba(0,163,224,0.1)' }}>
            <span className="material-icons-round" style={{ color: 'var(--color-info)' }}>pending_actions</span>
          </div>
          <div className="stat-label">Visitas Pendientes</div>
          <div className="stat-value">
            {data.filter(i => i.estado_visita === 'PENDIENTE').length}
          </div>
          <div className="stat-sub">Por visitar hoy</div>
        </div>
      </div>

      <div className="responsive-split-main" style={{ marginTop: '24px' }}>
        
        {/* Left Side: Advisor Progress List */}
        <section className="glass-panel" style={{ padding: '24px' }}>
          <h3 style={{ marginBottom: '16px' }}>Progreso de Asesores</h3>
          
          <div style={{ display: 'flex', gap: '12px', marginBottom: '20px' }}>
            <select
              className="form-control"
              style={{ flex: 1 }}
              value={selectedAsesor}
              onChange={e => setSelectedAsesor(e.target.value)}
            >
              <option value="TODOS">Todos los asesores</option>
              {asesores.map(name => (
                <option key={name} value={name}>{name}</option>
              ))}
            </select>

            <select
              className="form-control"
              style={{ flex: 1 }}
              value={selectedStatus}
              onChange={e => setSelectedStatus(e.target.value)}
            >
              <option value="TODOS">Todos los estados</option>
              <option value="PENDIENTE">Pendiente</option>
              <option value="REALIZADA">Realizada</option>
            </select>
          </div>

          {loading ? (
            <div className="loading-container"><div className="spinner"></div></div>
          ) : (
            <div className="table-wrapper">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Asesor</th>
                    <th>Asignados</th>
                    <th>Visitas</th>
                    <th>Progreso</th>
                  </tr>
                </thead>
                <tbody>
                  {Object.keys(advisorStats).map(name => {
                    const stats = advisorStats[name];
                    const pct = Math.round((stats.visited / stats.total) * 100);
                    return (
                      <tr
                        key={name}
                        onClick={() => setSelectedAsesor(name)}
                        style={{ cursor: 'pointer', background: selectedAsesor === name ? 'rgba(255,255,255,0.03)' : 'transparent' }}
                      >
                        <td style={{ fontWeight: 'bold' }}>{name}</td>
                        <td>{stats.total}</td>
                        <td>{stats.visited}</td>
                        <td>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                            <div className="progress-track" style={{ width: '80px' }}>
                              <div className="progress-fill" style={{ width: `${pct}%` }}></div>
                            </div>
                            <span style={{ fontSize: '12px', fontWeight: 'bold' }}>{pct}%</span>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </section>

        {/* Right Side: Geocenter SVG Map */}
        <section className="glass-panel" style={{ padding: '24px', display: 'flex', flexDirection: 'column', position: 'relative' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
            <h3>Zona de Distribución Geográfica</h3>
            <div style={{ display: 'flex', gap: '12px', fontSize: '11px' }}>
              <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                <span style={{ width: 8, height: 8, borderRadius: '50%', background: 'var(--color-success)' }}></span> Realizada
              </span>
              <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                <span style={{ width: 8, height: 8, borderRadius: '50%', background: 'var(--color-warning)' }}></span> Pendiente
              </span>
            </div>
          </div>

          <div style={{
            flex: 1,
            background: 'radial-gradient(circle, #0e1b30 0%, #060c16 100%)',
            borderRadius: '12px',
            border: '1px solid var(--color-border)',
            position: 'relative',
            minHeight: '350px',
            overflow: 'hidden'
          }}>
            {/* SVG Interactive Map */}
            <svg width="100%" height="100%" viewBox="0 0 500 350" style={{ pointerEvents: 'auto' }}>
              {/* Grid Lines */}
              <defs>
                <pattern id="grid" width="30" height="30" patternUnits="userSpaceOnUse">
                  <path d="M 30 0 L 0 0 0 30" fill="none" stroke="rgba(255, 255, 255, 0.02)" strokeWidth="1" />
                </pattern>
              </defs>
              <rect width="100%" height="100%" fill="url(#grid)" />

              {/* Geofence boundaries outline */}
              <polygon
                points="40,40 460,40 460,310 40,310"
                fill="rgba(0, 163, 224, 0.03)"
                stroke="rgba(0, 163, 224, 0.15)"
                strokeWidth="1.5"
                strokeDasharray="4,4"
              />

              {/* Render Clients pins */}
              {filteredData.map((item, idx) => {
                const isRealized = item.estado_visita === 'REALIZADA';
                const { x, y } = mapCoordinates(item.lat_visita, item.lng_visita);
                // Shift coordinates slightly based on index to avoid total overlap
                const rx = x + (idx % 5) * 4 - 8;
                const ry = y + (idx % 3) * 4 - 6;

                return (
                  <g
                    key={item.id_cartera}
                    onMouseEnter={() => setHoveredClient(item)}
                    onMouseLeave={() => setHoveredClient(null)}
                    style={{ cursor: 'pointer' }}
                  >
                    {/* Glowing pulse ring if hovered */}
                    {hoveredClient?.id_cartera === item.id_cartera && (
                      <circle
                        cx={rx}
                        cy={ry}
                        r="12"
                        fill="none"
                        stroke={isRealized ? 'var(--color-success)' : 'var(--color-warning)'}
                        strokeWidth="2"
                        opacity="0.8"
                        style={{ transformOrigin: `${rx}px ${ry}px`, animation: 'spin 1.5s linear infinite' }}
                      />
                    )}
                    
                    {/* Pin shadow */}
                    <circle cx={rx} cy={ry + 2} r="4" fill="rgba(0,0,0,0.4)" />
                    
                    {/* Marker circle */}
                    <circle
                      cx={rx}
                      cy={ry}
                      r="6"
                      fill={isRealized ? 'var(--color-success)' : 'var(--color-warning)'}
                      stroke="#070D1A"
                      strokeWidth="1.5"
                    />
                  </g>
                );
              })}
            </svg>

            {/* Hover Tooltip inside map */}
            {hoveredClient && (
              <div style={{
                position: 'absolute',
                bottom: '12px',
                left: '12px',
                right: '12px',
                background: 'rgba(13, 22, 40, 0.95)',
                border: '1px solid var(--bcp-orange)',
                borderRadius: '8px',
                padding: '12px',
                color: '#fff',
                fontSize: '12px',
                zIndex: 10,
                backdropFilter: 'blur(10px)',
                boxShadow: '0 4px 20px rgba(0,0,0,0.5)'
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '4px' }}>
                  <span style={{ fontWeight: 'bold', fontSize: '13px' }}>{hoveredClient.cliente_nombre}</span>
                  <span className={`badge ${hoveredClient.estado_visita === 'REALIZADA' ? 'badge-success' : 'badge-warning'}`}>
                    {hoveredClient.estado_visita}
                  </span>
                </div>
                <div style={{ color: 'var(--color-text-muted)' }}>DNI: {hoveredClient.cliente_documento}</div>
                <div style={{ marginTop: '4px' }}>Asesor: <strong>{hoveredClient.asesor_nombre}</strong></div>
                {hoveredClient.observacion_visita && (
                  <div style={{ marginTop: '6px', borderTop: '1px solid rgba(255,255,255,0.06)', paddingTop: '6px', fontStyle: 'italic', color: '#ffb36b' }}>
                    {hoveredClient.observacion_visita}
                  </div>
                )}
              </div>
            )}
          </div>
        </section>
      </div>

      {/* Clients detailed list */}
      <section className="glass-panel" style={{ padding: '24px', marginTop: '24px' }}>
        <h3 style={{ marginBottom: '16px' }}>Detalle de Gestiones en Ruta</h3>
        
        {loading ? (
          <div className="loading-container"><div className="spinner"></div></div>
        ) : (
          <div className="table-wrapper">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Cliente</th>
                  <th>DNI</th>
                  <th>Asesor Asignado</th>
                  <th>Prioridad</th>
                  <th>Gestión</th>
                  <th>Estado Visita</th>
                  <th>Fecha/Hora Visita</th>
                  <th>Resultado</th>
                </tr>
              </thead>
              <tbody>
                {filteredData.map(item => (
                  <tr key={item.id_cartera}>
                    <td style={{ fontWeight: 'bold' }}>{item.cliente_nombre}</td>
                    <td>{item.cliente_documento}</td>
                    <td>{item.asesor_nombre}</td>
                    <td>
                      <span className={`badge ${item.prioridad === 'ALTA' ? 'badge-error' : item.prioridad === 'MEDIA' ? 'badge-warning' : 'badge-navy'}`}>
                        {item.prioridad}
                      </span>
                    </td>
                    <td>{item.tipo_gestion}</td>
                    <td>
                      <span className={`badge ${item.estado_visita === 'REALIZADA' ? 'badge-success' : 'badge-warning'}`}>
                        {item.estado_visita}
                      </span>
                    </td>
                    <td>
                      {item.timestamp_visita
                        ? new Date(item.timestamp_visita).toLocaleString()
                        : '—'}
                    </td>
                    <td style={{ fontSize: '13px', color: 'var(--color-text-muted)', maxWidth: '200px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                      {item.resultado_visita || 'Sin visita'}
                    </td>
                  </tr>
                ))}
                {filteredData.length === 0 && (
                  <tr>
                    <td colSpan="8" className="empty-state">
                      <span className="material-icons-round">search_off</span>
                      <p>No se encontraron registros que coincidan con los filtros seleccionados.</p>
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </section>
    </div>
  );
}
