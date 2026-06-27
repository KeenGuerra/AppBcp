import React, { useEffect, useState } from 'react';

export default function Parametros({ api }) {
  const [productos, setProductos] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [isEdit, setIsEdit] = useState(false);
  const [selected, setSelected] = useState(null);
  const [form, setForm] = useState({ codigo: '', nombre: '', tipo: 'MICROEMPRESA', tea_con_seguro: '', tea_sin_seguro: '', monto_minimo: '', monto_maximo: '', plazo_minimo: '', plazo_maximo: '', moneda: 'PEN' });

  const fetchProductos = async () => {
    setLoading(true);
    try {
      const response = await api.get('/admin/productos-creditos');
      setProductos(response.data);
    } catch (err) {
      setError('Error al obtener productos.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchProductos(); }, []);

  const openCreate = () => {
    setIsEdit(false);
    setSelected(null);
    setForm({ codigo: '', nombre: '', tipo: 'MICROEMPRESA', tea_con_seguro: '', tea_sin_seguro: '', monto_minimo: '', monto_maximo: '', plazo_minimo: '', plazo_maximo: '', moneda: 'PEN' });
    setShowModal(true);
  };

  const openEdit = (prod) => {
    setIsEdit(true);
    setSelected(prod);
    setForm({
      codigo: prod.codigo || '',
      nombre: prod.nombre || '',
      tipo: prod.tipo || 'MICROEMPRESA',
      tea_con_seguro: prod.tea_con_seguro || '',
      tea_sin_seguro: prod.tea_sin_seguro || '',
      monto_minimo: prod.monto_minimo || '',
      monto_maximo: prod.monto_maximo || '',
      plazo_minimo: prod.plazo_minimo || '',
      plazo_maximo: prod.plazo_maximo || '',
      moneda: prod.moneda || 'PEN',
    });
    setShowModal(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const data = {
        ...form,
        tea_con_seguro: parseFloat(form.tea_con_seguro),
        tea_sin_seguro: parseFloat(form.tea_sin_seguro),
        monto_minimo: parseFloat(form.monto_minimo),
        monto_maximo: parseFloat(form.monto_maximo),
        plazo_minimo: parseInt(form.plazo_minimo),
        plazo_maximo: parseInt(form.plazo_maximo),
      };
      if (isEdit) {
        await api.put(`/admin/productos-creditos/${selected.id_producto_credito}`, data);
      } else {
        await api.post('/admin/productos-creditos', data);
      }
      setShowModal(false);
      fetchProductos();
    } catch (err) {
      alert(err.response?.data?.detail || 'Error al guardar.');
    }
  };

  const handleDelete = async (prod) => {
    if (!window.confirm(`¿Eliminar el producto "${prod.nombre}"?`)) return;
    try {
      await api.delete(`/admin/productos-creditos/${prod.id_producto_credito}`);
      fetchProductos();
    } catch (err) {
      alert(err.response?.data?.detail || 'Error al eliminar.');
    }
  };

  if (loading) {
    return <div className="loading-container"><div className="spinner" /><p>Cargando parámetros...</p></div>;
  }

  return (
    <div className="page-container">
      <header className="responsive-page-header">
        <div>
          <h1 style={{ fontSize: '28px', color: '#fff', marginBottom: '8px' }}>Parámetros del Sistema</h1>
          <p style={{ color: '#8B949E' }}>Configuración de productos crediticios, tasas y límites del banco.</p>
        </div>
        <button className="btn-primary" onClick={openCreate}>
          <span className="material-icons-round">add</span>
          Nuevo Producto
        </button>
      </header>

      {error && <div style={{ backgroundColor: 'rgba(248, 81, 73, 0.1)', color: '#F85149', padding: '12px 16px', borderRadius: '8px', marginBottom: '20px' }}>{error}</div>}

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(340px, 1fr))', gap: '20px', marginBottom: '32px' }}>
        {productos.map((p) => (
          <div key={p.id_producto_credito} className="glass-panel" style={{ padding: '24px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '16px' }}>
              <div>
                <div style={{ fontSize: '11px', color: '#8B949E', marginBottom: '4px' }}>{p.codigo}</div>
                <div style={{ fontSize: '16px', fontWeight: '700', color: '#fff' }}>{p.nombre}</div>
                <span style={{ padding: '2px 8px', borderRadius: '8px', fontSize: '11px', fontWeight: '600', backgroundColor: 'rgba(255, 120, 0, 0.1)', color: '#FF7800', marginTop: '4px', display: 'inline-block' }}>{p.tipo}</span>
              </div>
              <div style={{ display: 'flex', gap: '4px' }}>
                <button className="btn-icon" onClick={() => openEdit(p)} title="Editar">
                  <span className="material-icons-round" style={{ color: '#4d8df7', fontSize: '18px' }}>edit</span>
                </button>
                <button className="btn-icon" onClick={() => handleDelete(p)} title="Eliminar">
                  <span className="material-icons-round" style={{ color: '#f85149', fontSize: '18px' }}>delete</span>
                </button>
              </div>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
              <div>
                <div style={{ fontSize: '11px', color: '#8B949E' }}>TEA con Seguro</div>
                <div style={{ fontSize: '18px', fontWeight: '700', color: '#1DB954' }}>{p.tea_con_seguro}%</div>
              </div>
              <div>
                <div style={{ fontSize: '11px', color: '#8B949E' }}>TEA sin Seguro</div>
                <div style={{ fontSize: '18px', fontWeight: '700', color: '#00A3E0' }}>{p.tea_sin_seguro}%</div>
              </div>
              <div>
                <div style={{ fontSize: '11px', color: '#8B949E' }}>Monto Mínimo</div>
                <div style={{ fontSize: '14px', fontWeight: '600' }}>S/ {Number(p.monto_minimo).toLocaleString()}</div>
              </div>
              <div>
                <div style={{ fontSize: '11px', color: '#8B949E' }}>Monto Máximo</div>
                <div style={{ fontSize: '14px', fontWeight: '600' }}>S/ {Number(p.monto_maximo).toLocaleString()}</div>
              </div>
              <div>
                <div style={{ fontSize: '11px', color: '#8B949E' }}>Plazo Mínimo</div>
                <div style={{ fontSize: '14px', fontWeight: '600' }}>{p.plazo_minimo} meses</div>
              </div>
              <div>
                <div style={{ fontSize: '11px', color: '#8B949E' }}>Plazo Máximo</div>
                <div style={{ fontSize: '14px', fontWeight: '600' }}>{p.plazo_maximo} meses</div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {showModal && (
        <div className="modal-overlay">
          <div className="modal-content glass-panel" style={{ backgroundColor: '#151922', maxWidth: '500px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
              <h2>{isEdit ? 'Editar Producto' : 'Nuevo Producto'}</h2>
              <button className="btn-icon" onClick={() => setShowModal(false)}>
                <span className="material-icons-round">close</span>
              </button>
            </div>
            <form onSubmit={handleSubmit}>
              <div className="form-group">
                <label className="form-label">Código</label>
                <input className="form-control" value={form.codigo} onChange={e => setForm({...form, codigo: e.target.value})} required />
              </div>
              <div className="form-group">
                <label className="form-label">Nombre</label>
                <input className="form-control" value={form.nombre} onChange={e => setForm({...form, nombre: e.target.value})} required />
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                <div className="form-group">
                  <label className="form-label">TEA con Seguro (%)</label>
                  <input type="number" step="0.01" className="form-control" value={form.tea_con_seguro} onChange={e => setForm({...form, tea_con_seguro: e.target.value})} required />
                </div>
                <div className="form-group">
                  <label className="form-label">TEA sin Seguro (%)</label>
                  <input type="number" step="0.01" className="form-control" value={form.tea_sin_seguro} onChange={e => setForm({...form, tea_sin_seguro: e.target.value})} required />
                </div>
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                <div className="form-group">
                  <label className="form-label">Monto Mínimo (S/)</label>
                  <input type="number" step="0.01" className="form-control" value={form.monto_minimo} onChange={e => setForm({...form, monto_minimo: e.target.value})} required />
                </div>
                <div className="form-group">
                  <label className="form-label">Monto Máximo (S/)</label>
                  <input type="number" step="0.01" className="form-control" value={form.monto_maximo} onChange={e => setForm({...form, monto_maximo: e.target.value})} required />
                </div>
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                <div className="form-group">
                  <label className="form-label">Plazo Mínimo (meses)</label>
                  <input type="number" className="form-control" value={form.plazo_minimo} onChange={e => setForm({...form, plazo_minimo: e.target.value})} required />
                </div>
                <div className="form-group">
                  <label className="form-label">Plazo Máximo (meses)</label>
                  <input type="number" className="form-control" value={form.plazo_maximo} onChange={e => setForm({...form, plazo_maximo: e.target.value})} required />
                </div>
              </div>
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '24px', paddingTop: '20px', borderTop: '1px solid var(--color-border)' }}>
                <button type="button" className="btn-secondary" onClick={() => setShowModal(false)}>Cancelar</button>
                <button type="submit" className="btn-primary">Guardar</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
