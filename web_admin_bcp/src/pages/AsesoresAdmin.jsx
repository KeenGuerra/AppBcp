import React, { useEffect, useState } from 'react';

export default function AsesoresAdmin({ api }) {
  const [asesores, setAsesores] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');

  const fetchAsesores = async () => {
    setLoading(true);
    try {
      const response = await api.get('/admin/asesores');
      setAsesores(response.data);
    } catch (err) {
      setError('Error al obtener la lista de asesores.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchAsesores(); }, []);

  const filtered = asesores.filter(a =>
    (a.nombres || '').toLowerCase().includes(search.toLowerCase()) ||
    (a.apellidos || '').toLowerCase().includes(search.toLowerCase()) ||
    (a.codigo_empleado || '').toLowerCase().includes(search.toLowerCase())
  );

  if (loading) {
    return (
      <div className="loading-container">
        <div className="spinner" />
        <p>Cargando asesores...</p>
      </div>
    );
  }

  return (
    <div className="page-container">
      <header className="responsive-page-header">
        <div>
          <h1 style={{ fontSize: '28px', color: '#fff', marginBottom: '8px' }}>Gestión de Asesores</h1>
          <p style={{ color: '#8B949E' }}>Consulta y administra la fuerza de ventas del banco.</p>
        </div>
        <div style={{ display: 'flex', gap: '12px', alignItems: 'center' }}>
          <div style={{ position: 'relative' }}>
            <span className="material-icons-round" style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: '#8B949E', fontSize: '20px' }}>search</span>
            <input
              type="text"
              className="form-control"
              placeholder="Buscar por nombre o código..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              style={{ paddingLeft: '40px', minWidth: '260px' }}
            />
          </div>
        </div>
      </header>

      {error && <div style={{ backgroundColor: 'rgba(248, 81, 73, 0.1)', color: '#F85149', padding: '12px 16px', borderRadius: '8px', marginBottom: '20px' }}>{error}</div>}

      <div className="glass-panel" style={{ padding: '16px', overflowX: 'auto' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
          <thead>
            <tr>
              <th style={{ padding: '16px', borderBottom: '1px solid var(--color-border)', color: '#8B949E', fontWeight: '600', fontSize: '14px' }}>Asesor</th>
              <th style={{ padding: '16px', borderBottom: '1px solid var(--color-border)', color: '#8B949E', fontWeight: '600', fontSize: '14px' }}>Código</th>
              <th style={{ padding: '16px', borderBottom: '1px solid var(--color-border)', color: '#8B949E', fontWeight: '600', fontSize: '14px' }}>Teléfono</th>
              <th style={{ padding: '16px', borderBottom: '1px solid var(--color-border)', color: '#8B949E', fontWeight: '600', fontSize: '14px' }}>Cargo</th>
              <th style={{ padding: '16px', borderBottom: '1px solid var(--color-border)', color: '#8B949E', fontWeight: '600', fontSize: '14px' }}>Agencia</th>
              <th style={{ padding: '16px', borderBottom: '1px solid var(--color-border)', color: '#8B949E', fontWeight: '600', fontSize: '14px' }}>Estado</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((a) => (
              <tr key={a.id_asesor} style={{ borderBottom: '1px solid rgba(38, 44, 58, 0.5)' }}>
                <td style={{ padding: '16px', fontSize: '15px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                    <span className="material-icons-round" style={{ fontSize: '36px', color: '#FF7800' }}>badge</span>
                    <div>
                      <div style={{ fontWeight: '600' }}>{a.nombres} {a.apellidos}</div>
                      <div style={{ fontSize: '11px', color: '#8B949E' }}>{a.id_asesor}</div>
                    </div>
                  </div>
                </td>
                <td style={{ padding: '16px', fontSize: '15px' }}>
                  <span style={{ padding: '4px 10px', borderRadius: '12px', fontSize: '12px', fontWeight: '700', backgroundColor: 'rgba(255, 120, 0, 0.1)', color: '#FF7800' }}>
                    {a.codigo_empleado}
                  </span>
                </td>
                <td style={{ padding: '16px', fontSize: '15px' }}>{a.telefono}</td>
                <td style={{ padding: '16px', fontSize: '15px' }}>{a.cargo}</td>
                <td style={{ padding: '16px', fontSize: '15px' }}>{a.agencia?.nombre || '—'}</td>
                <td style={{ padding: '16px', fontSize: '15px' }}>
                  <span style={{
                    padding: '4px 10px', borderRadius: '12px', fontSize: '12px', fontWeight: '700',
                    backgroundColor: a.estado === 'ACTIVO' ? 'rgba(29, 185, 84, 0.1)' : 'rgba(139, 148, 158, 0.1)',
                    color: a.estado === 'ACTIVO' ? '#1DB954' : '#8B949E'
                  }}>{a.estado}</span>
                </td>
              </tr>
            ))}
            {filtered.length === 0 && (
              <tr><td colSpan="6" style={{ textAlign: 'center', padding: '32px', color: '#8B949E' }}>No se encontraron asesores.</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
