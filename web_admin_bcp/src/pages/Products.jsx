import React, { useEffect, useState } from 'react';

export default function Products({ api }) {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  // Modal states
  const [showModal, setShowModal] = useState(false);
  const [isEdit, setIsEdit] = useState(false);
  const [selectedProduct, setSelectedProduct] = useState(null);

  // Form states
  const [codigo, setCodigo] = useState('');
  const [nombre, setNombre] = useState('');
  const [tipo, setTipo] = useState('MICROEMPRESA');
  const [teaConSeguro, setTeaConSeguro] = useState(45.0);
  const [teaSinSeguro, setTeaSinSeguro] = useState(40.0);
  const [montoMinimo, setMontoMinimo] = useState(1000);
  const [montoMaximo, setMontoMaximo] = useState(50000);
  const [plazoMinimo, setPlazoMinimo] = useState(6);
  const [plazoMaximo, setPlazoMaximo] = useState(36);
  const [estado, setEstado] = useState('ACTIVO');

  const fetchProducts = async () => {
    setLoading(true);
    try {
      const response = await api.get('/admin/productos-creditos');
      setProducts(response.data);
    } catch (err) {
      setError('Error al obtener el catálogo de productos.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProducts();
  }, []);

  const openCreateModal = () => {
    setIsEdit(false);
    setSelectedProduct(null);
    setCodigo('');
    setNombre('');
    setTipo('MICROEMPRESA');
    setTeaConSeguro(45.0);
    setTeaSinSeguro(40.0);
    setMontoMinimo(1000);
    setMontoMaximo(50000);
    setPlazoMinimo(6);
    setPlazoMaximo(36);
    setEstado('ACTIVO');
    setShowModal(true);
  };

  const openEditModal = (p) => {
    setIsEdit(true);
    setSelectedProduct(p);
    setCodigo(p.codigo || '');
    setNombre(p.nombre || '');
    setTipo(p.tipo || 'MICROEMPRESA');
    setTeaConSeguro(p.tea_con_seguro || 45.0);
    setTeaSinSeguro(p.tea_sin_seguro || 40.0);
    setMontoMinimo(p.monto_minimo || 1000);
    setMontoMaximo(p.monto_maximo || 50000);
    setPlazoMinimo(p.plazo_minimo || 6);
    setPlazoMaximo(p.plazo_maximo || 36);
    setEstado(p.estado || 'ACTIVO');
    setShowModal(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!codigo || !nombre) return;

    try {
      const data = {
        codigo: codigo.trim(),
        nombre: nombre.trim(),
        tipo: tipo.trim(),
        tea_con_seguro: parseFloat(teaConSeguro),
        tea_sin_seguro: parseFloat(teaSinSeguro),
        monto_minimo: parseFloat(montoMinimo),
        monto_maximo: parseFloat(montoMaximo),
        plazo_minimo: parseInt(plazoMinimo),
        plazo_maximo: parseInt(plazoMaximo),
        moneda: 'PEN',
      };

      if (isEdit) {
        data.estado = estado;
        await api.put(`/admin/productos-creditos/${selectedProduct.id_producto_credito}`, data);
      } else {
        await api.post('/admin/productos-creditos', data);
      }

      setShowModal(false);
      fetchProducts();
    } catch (err) {
      alert(err.response?.data?.detail || 'Error al guardar el producto.');
    }
  };

  if (loading) {
    return (
      <div className="loading-container">
        <div className="spinner" />
        <p>Cargando catálogo de productos...</p>
      </div>
    );
  }

  return (
    <div className="page-container">
      <header className="responsive-page-header">
        <div>
          <h1 style={styles.title}>Catálogo de Productos</h1>
          <p style={styles.subtitle}>Configura tasas de interés (TEA), montos y plazos de préstamos.</p>
        </div>
        <button className="btn-primary" onClick={openCreateModal}>
          <span className="material-icons-round">add_box</span>
          Nuevo Producto
        </button>
      </header>

      {error && <div style={styles.error}>{error}</div>}

      <div className="glass-panel" style={styles.tableCard}>
        <table style={styles.table}>
          <thead>
            <tr>
              <th style={styles.th}>Producto / Código</th>
              <th style={styles.th}>Tasas TEA (Con/Sin)</th>
              <th style={styles.th}>Límites Monto</th>
              <th style={styles.th}>Plazos (Meses)</th>
              <th style={styles.th}>Estado</th>
              <th style={styles.th}>Acciones</th>
            </tr>
          </thead>
          <tbody>
            {products.map((p) => (
              <tr key={p.id_producto_credito} style={styles.tr}>
                <td style={styles.td}>
                  <div style={{ fontWeight: '600' }}>{p.nombre}</div>
                  <div style={{ fontSize: '12px', color: '#8B949E' }}>Cód: {p.codigo} | Tipo: {p.tipo}</div>
                </td>
                <td style={styles.td}>
                  <div style={{ color: '#2ea043', fontWeight: '600' }}>{p.tea_con_seguro}% <span style={{ fontSize: '11px', color: '#8B949E' }}>(c/seg)</span></div>
                  <div style={{ color: '#8B949E', fontSize: '13px' }}>{p.tea_sin_seguro}% <span style={{ fontSize: '11px' }}>(s/seg)</span></div>
                </td>
                <td style={styles.td}>S/ {p.monto_minimo} - S/ {p.monto_maximo}</td>
                <td style={styles.td}>{p.plazo_minimo} - {p.plazo_maximo}</td>
                <td style={styles.td}>
                  <span style={{
                    ...styles.badge,
                    backgroundColor: p.estado === 'ACTIVO' ? 'rgba(46, 160, 67, 0.1)' : 'rgba(139, 148, 158, 0.1)',
                    color: p.estado === 'ACTIVO' ? '#2ea043' : '#8B949E'
                  }}>
                    {p.estado}
                  </span>
                </td>
                <td style={styles.td}>
                  <button className="btn-icon" onClick={() => openEditModal(p)} title="Editar Producto">
                    <span className="material-icons-round" style={{ color: '#4d8df7' }}>edit</span>
                  </button>
                </td>
              </tr>
            ))}
            {products.length === 0 && (
              <tr>
                <td colSpan="6" style={{ textAlign: 'center', padding: '32px', color: '#8B949E' }}>
                  No se encontraron productos configurados.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {showModal && (
        <div className="modal-overlay">
          <div className="modal-content glass-panel" style={styles.modal}>
            <div style={styles.modalHeader}>
              <h2>{isEdit ? 'Editar Producto' : 'Nuevo Producto'}</h2>
              <button className="btn-icon" onClick={() => setShowModal(false)}>
                <span className="material-icons-round">close</span>
              </button>
            </div>
            <form onSubmit={handleSubmit}>
              <div className="form-group">
                <label className="form-label">Código de Producto</label>
                <input
                  type="text"
                  className="form-control"
                  value={codigo}
                  onChange={(e) => setCodigo(e.target.value)}
                  placeholder="Ej: PROD_CRED_SOL"
                  disabled={isEdit}
                  required
                />
              </div>

              <div className="form-group">
                <label className="form-label">Nombre del Producto</label>
                <input
                  type="text"
                  className="form-control"
                  value={nombre}
                  onChange={(e) => setNombre(e.target.value)}
                  placeholder="Ej: Crédito Microempresa Soles"
                  required
                />
              </div>

              <div className="form-group">
                <label className="form-label">Tipo de Crédito</label>
                <input
                  type="text"
                  className="form-control"
                  value={tipo}
                  onChange={(e) => setTipo(e.target.value)}
                  placeholder="Ej: MICROEMPRESA"
                  required
                />
              </div>

              <div className="responsive-two-cols">
                <div className="form-group">
                  <label className="form-label">TEA con Seguro (%)</label>
                  <input
                    type="number"
                    step="0.01"
                    className="form-control"
                    value={teaConSeguro}
                    onChange={(e) => setTeaConSeguro(e.target.value)}
                    required
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">TEA sin Seguro (%)</label>
                  <input
                    type="number"
                    step="0.01"
                    className="form-control"
                    value={teaSinSeguro}
                    onChange={(e) => setTeaSinSeguro(e.target.value)}
                    required
                  />
                </div>
              </div>

              <div className="responsive-two-cols">
                <div className="form-group">
                  <label className="form-label">Monto Mínimo (S/)</label>
                  <input
                    type="number"
                    className="form-control"
                    value={montoMinimo}
                    onChange={(e) => setMontoMinimo(e.target.value)}
                    required
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">Monto Máximo (S/)</label>
                  <input
                    type="number"
                    className="form-control"
                    value={montoMaximo}
                    onChange={(e) => setMontoMaximo(e.target.value)}
                    required
                  />
                </div>
              </div>

              <div className="responsive-two-cols">
                <div className="form-group">
                  <label className="form-label">Plazo Mínimo (Meses)</label>
                  <input
                    type="number"
                    className="form-control"
                    value={plazoMinimo}
                    onChange={(e) => setPlazoMinimo(e.target.value)}
                    required
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">Plazo Máximo (Meses)</label>
                  <input
                    type="number"
                    className="form-control"
                    value={plazoMaximo}
                    onChange={(e) => setPlazoMaximo(e.target.value)}
                    required
                  />
                </div>
              </div>

              {isEdit && (
                <div className="form-group">
                  <label className="form-label">Estado</label>
                  <select className="form-control" value={estado} onChange={(e) => setEstado(e.target.value)}>
                    <option value="ACTIVO">ACTIVO</option>
                    <option value="INACTIVO">INACTIVO</option>
                  </select>
                </div>
              )}

              <div style={styles.modalFooter}>
                <button type="button" className="btn-secondary" onClick={() => setShowModal(false)}>Cancelar</button>
                <button type="submit" className="btn-primary">Guardar Cambios</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

const styles = {
  container: {
    padding: '32px',
    maxWidth: '1200px',
    margin: '0 auto',
  },
  header: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: '32px',
  },
  title: {
    fontSize: '28px',
    color: '#fff',
    marginBottom: '8px',
  },
  subtitle: {
    color: '#8B949E',
  },
  tableCard: {
    padding: '16px',
    overflowX: 'auto',
  },
  table: {
    width: '100%',
    borderCollapse: 'collapse',
    textAlign: 'left',
  },
  th: {
    padding: '16px',
    borderBottom: '1px solid var(--color-border)',
    color: '#8B949E',
    fontWeight: '600',
    fontSize: '14px',
  },
  tr: {
    borderBottom: '1px solid rgba(38, 44, 58, 0.5)',
    transition: 'background-color 0.2s',
  },
  td: {
    padding: '16px',
    fontSize: '15px',
    verticalAlign: 'middle',
  },
  badge: {
    padding: '4px 10px',
    borderRadius: '12px',
    fontSize: '12px',
    fontWeight: '700',
  },
  error: {
    backgroundColor: 'rgba(248, 81, 73, 0.1)',
    color: '#F85149',
    padding: '12px 16px',
    borderRadius: '8px',
    marginBottom: '20px',
  },
  loadingContainer: {
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'center',
    alignItems: 'center',
    minHeight: '400px',
    gap: '16px',
    color: '#8B949E',
  },
  row: {
    display: 'flex',
  },
  modal: {
    backgroundColor: '#151922',
  },
  modalHeader: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: '24px',
  },
  modalFooter: {
    display: 'flex',
    justifyContent: 'flex-end',
    gap: '12px',
    marginTop: '28px',
    paddingTop: '20px',
    borderTop: '1px solid var(--color-border)',
  }
};
