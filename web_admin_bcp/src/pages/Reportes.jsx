// Reportes.jsx — Panel de reportería de productividad mensual de la Fuerza de Ventas
import React, { useState, useEffect } from 'react';

export default function Reportes({ api }) {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const fetchProductividad = async () => {
    setLoading(true);
    try {
      const res = await api.get('/supervisor/reporte/productividad');
      setData(res.data);
      setError(null);
    } catch (err) {
      setError('Error al cargar la información de productividad.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProductividad();
  }, []);

  // Compute overall summary totals
  const summaryTotals = data.reduce((acc, item) => {
    acc.enviadas += item.solicitudes_enviadas;
    acc.aprobadas += item.solicitudes_aprobadas;
    acc.desembolsadas += item.solicitudes_desembolsadas;
    acc.monto += item.monto_total_approved || item.monto_total_aprobado || 0;
    return acc;
  }, { enviadas: 0, aprobadas: 0, desembolsadas: 0, monto: 0 });

  const maxMonto = Math.max(...data.map(item => item.monto_total_approved || item.monto_total_aprobado || 1000), 10000);

  return (
    <div className="page-container fade-in">
      <header className="page-header">
        <div>
          <h1 className="page-title">Reportes de Productividad</h1>
          <p className="page-subtitle">Desempeño mensual y volumen financiero originado por asesor</p>
        </div>
        <button className="btn-primary" onClick={fetchProductividad} disabled={loading}>
          <span className="material-icons-round">refresh</span> Actualizar
        </button>
      </header>

      {error && <div className="alert alert-error">{error}</div>}

      {/* Overview Cards */}
      <div className="stats-grid" style={{ marginBottom: '24px' }}>
        <div className="stat-card orange">
          <div className="stat-icon" style={{ background: 'rgba(255,107,0,0.1)' }}>
            <span className="material-icons-round" style={{ color: 'var(--bcp-orange)' }}>assignment_turned_in</span>
          </div>
          <div className="stat-label">Total Expedientes Aprobados</div>
          <div className="stat-value">{summaryTotals.aprobadas + summaryTotals.desembolsadas}</div>
          <div className="stat-sub">Este mes</div>
        </div>

        <div className="stat-card green">
          <div className="stat-icon" style={{ background: 'rgba(29,185,84,0.1)' }}>
            <span className="material-icons-round" style={{ color: 'var(--color-success)' }}>monetization_on</span>
          </div>
          <div className="stat-label">Monto Aprobado Acumulado</div>
          <div className="stat-value">S/ {summaryTotals.monto.toLocaleString()}</div>
          <div className="stat-sub">Volumen originado</div>
        </div>

        <div className="stat-card sky">
          <div className="stat-icon" style={{ background: 'rgba(0,163,224,0.1)' }}>
            <span className="material-icons-round" style={{ color: 'var(--color-info)' }}>handshake</span>
          </div>
          <div className="stat-label">Créditos Desembolsados</div>
          <div className="stat-value">{summaryTotals.desembolsadas}</div>
          <div className="stat-sub">Colocados en cartera</div>
        </div>
      </div>

      <div className="responsive-split-main">
        
        {/* Table summary of advisors */}
        <section className="glass-panel" style={{ padding: '24px' }}>
          <h3>Cuadro de Eficiencia</h3>
          <div style={{ marginTop: '16px' }}>
            {loading ? (
              <div className="loading-container"><div className="spinner"></div></div>
            ) : (
              <div className="table-wrapper">
                <table className="data-table">
                  <thead>
                    <tr>
                      <th>Asesor</th>
                      <th>Cód Empleado</th>
                      <th>Enviadas</th>
                      <th>Aprobadas</th>
                      <th>Desembolsadas</th>
                      <th>Monto Aprobado</th>
                      <th>Tasa Aprobación</th>
                    </tr>
                  </thead>
                  <tbody>
                    {data.map(item => {
                      const monto = item.monto_total_approved || item.monto_total_aprobado || 0;
                      return (
                        <tr key={item.id_asesor}>
                          <td style={{ fontWeight: 'bold' }}>{item.asesor_nombre}</td>
                          <td>{item.codigo_empleado}</td>
                          <td>{item.solicitudes_enviadas}</td>
                          <td>{item.solicitudes_aprobadas}</td>
                          <td style={{ color: 'var(--color-success)', fontWeight: 'bold' }}>{item.solicitudes_desembolsadas}</td>
                          <td>S/ {monto.toLocaleString()}</td>
                          <td>
                            <span style={{ fontWeight: 'bold', color: item.tasa_aprobacion > 75 ? 'var(--color-success)' : 'var(--bcp-sky)' }}>
                              {item.tasa_aprobacion}%
                            </span>
                          </td>
                        </tr>
                      );
                    })}
                    {data.length === 0 && (
                      <tr>
                        <td colSpan="7" className="empty-state">
                          <span className="material-icons-round">analytics</span>
                          <p>Sin datos de productividad disponibles.</p>
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </section>

        {/* SVG Productivity Chart */}
        <section className="glass-panel" style={{ padding: '24px', display: 'flex', flexDirection: 'column' }}>
          <h3>Comparativa de Volumen Aprobado</h3>
          <p style={{ fontSize: '12px', color: 'var(--color-text-muted)', marginBottom: '16px' }}>Monto monetario aprobado por asesor (S/)</p>
          
          <div style={{
            flex: 1,
            background: 'radial-gradient(circle, #0e1b30 0%, #060c16 100%)',
            border: '1px solid var(--color-border)',
            borderRadius: '12px',
            padding: '24px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            minHeight: '280px'
          }}>
            {loading ? (
              <div className="spinner"></div>
            ) : data.length === 0 ? (
              <span className="material-icons-round" style={{ fontSize: '32px', color: 'var(--color-text-dim)' }}>bar_chart</span>
            ) : (
              <svg width="100%" height="100%" viewBox="0 0 400 220" style={{ overflow: 'visible' }}>
                {data.map((item, idx) => {
                  const monto = item.monto_total_approved || item.monto_total_aprobado || 0;
                  const barH = maxMonto > 0 ? (monto / maxMonto) * 140 : 0;
                  const barW = 32;
                  const gap = 45;
                  const startX = 50;
                  const x = startX + idx * (barW + gap);
                  const y = 170 - barH;
                  
                  return (
                    <g key={item.id_asesor}>
                      {/* Bar shadow background */}
                      <rect x={x} y={20} width={barW} height="150" fill="rgba(255,255,255,0.01)" rx="4" />
                      
                      {/* Interactive Bar */}
                      <rect
                        x={x}
                        y={y}
                        width={barW}
                        height={barH}
                        fill="url(#barGrad)"
                        rx="4"
                        style={{ transition: 'all 0.3s' }}
                      />
                      
                      {/* Value atop bar */}
                      <text
                        x={x + barW / 2}
                        y={y - 6}
                        fill="#fff"
                        fontSize="9"
                        fontWeight="bold"
                        textAnchor="middle"
                      >
                        S/ {monto >= 1000 ? `${(monto / 1000).toFixed(1)}k` : monto}
                      </text>

                      {/* Label below bar */}
                      <text
                        x={x + barW / 2}
                        y="185"
                        fill="var(--color-text-muted)"
                        fontSize="9"
                        textAnchor="middle"
                        style={{ maxWidth: '60px' }}
                      >
                        {item.codigo_empleado}
                      </text>
                    </g>
                  );
                })}

                {/* SVG Definitions */}
                <defs>
                  <linearGradient id="barGrad" x1="0%" y1="0%" x2="0%" y2="100%">
                    <stop offset="0%" stopColor="var(--bcp-orange)" />
                    <stop offset="100%" stopColor="#ffb36b" stopOpacity="0.6" />
                  </linearGradient>
                </defs>

                {/* Base Axis Line */}
                <line x1="20" y1="170" x2="380" y2="170" stroke="var(--color-border)" strokeWidth="1" />
              </svg>
            )}
          </div>
        </section>
      </div>
    </div>
  );
}
