import React, { useEffect, useState } from 'react';

export default function Cronogramas({ api }) {
  const [creditos, setCreditos] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selectedCredito, setSelectedCredito] = useState(null);
  const [cronograma, setCronograma] = useState([]);
  const [loadingCronograma, setLoadingCronograma] = useState(false);

  const fetchCreditos = async () => {
    setLoading(true);
    try {
      const response = await api.get('/banking/admin/prestamos');
      setCreditos(response.data);
    } catch (err) {
      setError('Error al obtener créditos.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchCreditos(); }, []);

  const verCronograma = async (credito) => {
    setSelectedCredito(credito);
    setLoadingCronograma(true);
    try {
      const response = await api.get(`/admin/creditos/${credito.id_credito}/cronograma`);
      setCronograma(response.data);
    } catch (err) {
      setError('Error al obtener cronograma.');
      setCronograma([]);
    } finally {
      setLoadingCronograma(false);
    }
  };

  const fmt = (n) => `S/ ${Number(n || 0).toLocaleString('es-PE', { minimumFractionDigits: 2 })}`;

  if (loading) {
    return <div className="loading-container"><div className="spinner" /><p>Cargando cronogramas...</p></div>;
  }

  return (
    <div className="page-container">
      <header className="responsive-page-header">
        <div>
          <h1 style={{ fontSize: '28px', color: '#fff', marginBottom: '8px' }}>Cronogramas de Pago</h1>
          <p style={{ color: '#8B949E' }}>Visualiza el cronograma de cuotas de los créditos activos.</p>
        </div>
      </header>

      {error && <div style={{ backgroundColor: 'rgba(248, 81, 73, 0.1)', color: '#F85149', padding: '12px 16px', borderRadius: '8px', marginBottom: '20px' }}>{error}</div>}

      <div className="responsive-split-grid">
        <div className="glass-panel" style={{ padding: '24px' }}>
          <h3 style={{ marginBottom: '16px', fontSize: '15px' }}>Créditos Activos</h3>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
            {creditos.filter(c => c.estado === 'VIGENTE' || c.estado === 'DESEMBOLSADO').map((c) => (
              <div
                key={c.id_credito}
                onClick={() => verCronograma(c)}
                style={{
                  padding: '14px 16px',
                  borderRadius: '10px',
                  cursor: 'pointer',
                  border: selectedCredito?.id_credito === c.id_credito ? '1px solid var(--bcp-orange)' : '1px solid var(--color-border)',
                  background: selectedCredito?.id_credito === c.id_credito ? 'rgba(255, 120, 0, 0.08)' : 'transparent',
                  transition: 'all 0.2s',
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>
                    <div style={{ fontWeight: '700', fontSize: '14px' }}>{c.numero_credito}</div>
                    <div style={{ fontSize: '12px', color: '#8B949E' }}>{c.producto}</div>
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <div style={{ fontWeight: '700', color: '#1DB954' }}>{fmt(c.monto_desembolsado)}</div>
                    <div style={{ fontSize: '12px', color: '#8B949E' }}>{c.plazo_meses} meses</div>
                  </div>
                </div>
              </div>
            ))}
            {creditos.filter(c => c.estado === 'VIGENTE' || c.estado === 'DESEMBOLSADO').length === 0 && (
              <div style={{ padding: '24px', textAlign: 'center', color: '#8B949E' }}>No hay créditos activos.</div>
            )}
          </div>
        </div>

        <div className="glass-panel" style={{ padding: '24px' }}>
          <h3 style={{ marginBottom: '16px', fontSize: '15px' }}>
            {selectedCredito ? `Cronograma — ${selectedCredito.numero_credito}` : 'Selecciona un crédito'}
          </h3>
          {loadingCronograma ? (
            <div style={{ padding: '40px', textAlign: 'center' }}><div className="spinner" /></div>
          ) : cronograma.length > 0 ? (
            <div style={{ overflowX: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '13px' }}>
                <thead>
                  <tr>
                    <th style={{ padding: '10px 8px', borderBottom: '1px solid var(--color-border)', color: '#8B949E', textAlign: 'left' }}>Cuota</th>
                    <th style={{ padding: '10px 8px', borderBottom: '1px solid var(--color-border)', color: '#8B949E', textAlign: 'left' }}>Fecha</th>
                    <th style={{ padding: '10px 8px', borderBottom: '1px solid var(--color-border)', color: '#8B949E', textAlign: 'right' }}>Capital</th>
                    <th style={{ padding: '10px 8px', borderBottom: '1px solid var(--color-border)', color: '#8B949E', textAlign: 'right' }}>Interés</th>
                    <th style={{ padding: '10px 8px', borderBottom: '1px solid var(--color-border)', color: '#8B949E', textAlign: 'right' }}>Cuota</th>
                    <th style={{ padding: '10px 8px', borderBottom: '1px solid var(--color-border)', color: '#8B949E', textAlign: 'right' }}>Saldo</th>
                    <th style={{ padding: '10px 8px', borderBottom: '1px solid var(--color-border)', color: '#8B949E', textAlign: 'center' }}>Estado</th>
                  </tr>
                </thead>
                <tbody>
                  {cronograma.map((cuota) => (
                    <tr key={cuota.id_cuota} style={{ borderBottom: '1px solid rgba(38, 44, 58, 0.3)' }}>
                      <td style={{ padding: '10px 8px', fontWeight: '600' }}>{cuota.numero_cuota}</td>
                      <td style={{ padding: '10px 8px' }}>{new Date(cuota.fecha_pago).toLocaleDateString('es-PE')}</td>
                      <td style={{ padding: '10px 8px', textAlign: 'right' }}>{fmt(cuota.capital)}</td>
                      <td style={{ padding: '10px 8px', textAlign: 'right' }}>{fmt(cuota.interes)}</td>
                      <td style={{ padding: '10px 8px', textAlign: 'right', fontWeight: '700' }}>{fmt(cuota.monto_cuota)}</td>
                      <td style={{ padding: '10px 8px', textAlign: 'right' }}>{fmt(cuota.saldo)}</td>
                      <td style={{ padding: '10px 8px', textAlign: 'center' }}>
                        <span style={{
                          padding: '2px 8px', borderRadius: '8px', fontSize: '11px', fontWeight: '600',
                          backgroundColor: cuota.estado === 'PAGADA' ? 'rgba(29, 185, 84, 0.1)' :
                                          cuota.estado === 'VENCIDA' ? 'rgba(248, 81, 73, 0.1)' :
                                          cuota.estado === 'PARCIAL' ? 'rgba(255, 120, 0, 0.1)' : 'rgba(139, 148, 158, 0.1)',
                          color: cuota.estado === 'PAGADA' ? '#1DB954' :
                                 cuota.estado === 'VENCIDA' ? '#F85149' :
                                 cuota.estado === 'PARCIAL' ? '#FF7800' : '#8B949E',
                        }}>{cuota.estado}</span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <div style={{ padding: '40px', textAlign: 'center', color: '#8B949E' }}>
              {selectedCredito ? 'No hay cuotas registradas.' : 'Selecciona un crédito para ver su cronograma.'}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
