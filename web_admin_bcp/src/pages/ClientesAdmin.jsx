import React, { useEffect, useState } from 'react';

export default function ClientesAdmin({ api }) {
  const [clientes, setClientes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [selectedCliente, setSelectedCliente] = useState(null);
  const [showModal, setShowModal] = useState(false);

  const fetchClientes = async () => {
    setLoading(true);
    try {
      const response = await api.get('/admin/clientes');
      setClientes(response.data);
    } catch (err) {
      setError('Error al obtener la lista de clientes.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchClientes(); }, []);

  const filtered = clientes.filter(c =>
    (c.nombres || '').toLowerCase().includes(search.toLowerCase()) ||
    (c.apellidos || '').toLowerCase().includes(search.toLowerCase()) ||
    (c.documento || '').includes(search)
  );

  const openDetail = (cliente) => {
    setSelectedCliente(cliente);
    setShowModal(true);
  };

  if (loading) {
    return (
      <div className="loading-container">
        <div className="spinner" />
        <p>Cargando clientes...</p>
      </div>
    );
  }

  return (
    <div className="page-container">
      <header className="responsive-page-header">
        <div>
          <h1 style={{ fontSize: '28px', color: '#fff', marginBottom: '8px' }}>Gestión de Clientes</h1>
          <p style={{ color: '#8B949E' }}>Consulta y administra los clientes del sistema bancario.</p>
        </div>
        <div style={{ display: 'flex', gap: '12px', alignItems: 'center' }}>
          <div style={{ position: 'relative' }}>
            <span className="material-icons-round" style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: '#8B949E', fontSize: '20px' }}>search</span>
            <input
              type="text"
              className="form-control"
              placeholder="Buscar por nombre o DNI..."
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
              <th style={{ padding: '16px', borderBottom: '1px solid var(--color-border)', color: '#8B949E', fontWeight: '600', fontSize: '14px' }}>Cliente</th>
              <th style={{ padding: '16px', borderBottom: '1px solid var(--color-border)', color: '#8B949E', fontWeight: '600', fontSize: '14px' }}>Documento</th>
              <th style={{ padding: '16px', borderBottom: '1px solid var(--color-border)', color: '#8B949E', fontWeight: '600', fontSize: '14px' }}>Teléfono</th>
              <th style={{ padding: '16px', borderBottom: '1px solid var(--color-border)', color: '#8B949E', fontWeight: '600', fontSize: '14px' }}>Distrito</th>
              <th style={{ padding: '16px', borderBottom: '1px solid var(--color-border)', color: '#8B949E', fontWeight: '600', fontSize: '14px' }}>Estado</th>
              <th style={{ padding: '16px', borderBottom: '1px solid var(--color-border)', color: '#8B949E', fontWeight: '600', fontSize: '14px' }}>Acciones</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((c) => (
              <tr key={c.id_cliente} style={{ borderBottom: '1px solid rgba(38, 44, 58, 0.5)' }}>
                <td style={{ padding: '16px', fontSize: '15px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                    <span className="material-icons-round" style={{ fontSize: '36px', color: '#8B949E' }}>person</span>
                    <div>
                      <div style={{ fontWeight: '600' }}>{c.nombres} {c.apellidos}</div>
                      <div style={{ fontSize: '11px', color: '#8B949E' }}>{c.id_cliente}</div>
                    </div>
                  </div>
                </td>
                <td style={{ padding: '16px', fontSize: '15px' }}>{c.documento}</td>
                <td style={{ padding: '16px', fontSize: '15px' }}>{c.telefono}</td>
                <td style={{ padding: '16px', fontSize: '15px' }}>{c.distrito}</td>
                <td style={{ padding: '16px', fontSize: '15px' }}>
                  <span style={{
                    padding: '4px 10px', borderRadius: '12px', fontSize: '12px', fontWeight: '700',
                    backgroundColor: c.estado === 'ACTIVO' ? 'rgba(29, 185, 84, 0.1)' : 'rgba(139, 148, 158, 0.1)',
                    color: c.estado === 'ACTIVO' ? '#1DB954' : '#8B949E'
                  }}>{c.estado}</span>
                </td>
                <td style={{ padding: '16px', fontSize: '15px' }}>
                  <button className="btn-icon" onClick={() => openDetail(c)} title="Ver Detalle">
                    <span className="material-icons-round" style={{ color: '#4d8df7' }}>visibility</span>
                  </button>
                </td>
              </tr>
            ))}
            {filtered.length === 0 && (
              <tr><td colSpan="6" style={{ textAlign: 'center', padding: '32px', color: '#8B949E' }}>No se encontraron clientes.</td></tr>
            )}
          </tbody>
        </table>
      </div>

      {showModal && selectedCliente && (
        <div className="modal-overlay">
          <div className="modal-content glass-panel" style={{ backgroundColor: '#151922', maxWidth: '600px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
              <h2>Detalle del Cliente</h2>
              <button className="btn-icon" onClick={() => setShowModal(false)}>
                <span className="material-icons-round">close</span>
              </button>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
              {[
                { label: 'Nombres', value: selectedCliente.nombres },
                { label: 'Apellidos', value: selectedCliente.apellidos },
                { label: 'Documento', value: selectedCliente.documento },
                { label: 'Teléfono', value: selectedCliente.telefono },
                { label: 'Correo', value: selectedCliente.correo },
                { label: 'Distrito', value: selectedCliente.distrito },
                { label: 'Provincia', value: selectedCliente.provincia },
                { label: 'Departamento', value: selectedCliente.departamento },
                { label: 'Estado Civil', value: selectedCliente.estado_civil },
                { label: 'Ocupación', value: selectedCliente.ocupacion },
                { label: 'Tipo Cliente', value: selectedCliente.tipo_cliente },
                { label: 'Estado', value: selectedCliente.estado },
              ].map((item, i) => (
                <div key={i}>
                  <div style={{ fontSize: '12px', color: '#8B949E', marginBottom: '4px' }}>{item.label}</div>
                  <div style={{ fontSize: '14px', fontWeight: '600' }}>{item.value || '—'}</div>
                </div>
              ))}
            </div>
            <div style={{ marginTop: '24px', paddingTop: '20px', borderTop: '1px solid var(--color-border)', display: 'flex', justifyContent: 'flex-end' }}>
              <button className="btn-secondary" onClick={() => setShowModal(false)}>Cerrar</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
