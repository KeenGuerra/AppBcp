import React, { useEffect, useState } from 'react';

export default function Users({ api }) {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  
  // Modal states
  const [showModal, setShowModal] = useState(false);
  const [isEdit, setIsEdit] = useState(false);
  const [selectedUser, setSelectedUser] = useState(null);
  
  // Form states
  const [documento, setDocumento] = useState('');
  const [password, setPassword] = useState('');
  const [rol, setRol] = useState('CLIENTE');
  const [estado, setEstado] = useState('ACTIVO');
  const [codigoEmpleado, setCodigoEmpleado] = useState('');
  const [correo, setCorreo] = useState('');

  const fetchUsers = async () => {
    setLoading(true);
    try {
      const response = await api.get('/admin/usuarios');
      setUsers(response.data);
    } catch (err) {
      setError('Error al obtener la lista de usuarios.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  const openCreateModal = () => {
    setIsEdit(false);
    setSelectedUser(null);
    setDocumento('');
    setPassword('');
    setRol('CLIENTE');
    setEstado('ACTIVO');
    setCodigoEmpleado('');
    setCorreo('');
    setShowModal(true);
  };

  const openEditModal = (user) => {
    setIsEdit(true);
    setSelectedUser(user);
    // Note: The backend route response model has limited fields, but we query default parameters or match if needed
    setDocumento(user.documento || '');
    setPassword('');
    setRol(user.rol || 'CLIENTE');
    setEstado(user.estado || 'ACTIVO');
    setCodigoEmpleado(user.codigo_empleado || '');
    setCorreo(user.correo || '');
    setShowModal(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!documento) return;

    try {
      const data = {
        documento,
        rol,
        estado,
      };

      if (password) data.password = password;
      if (codigoEmpleado) data.codigo_empleado = codigoEmpleado;
      if (correo) data.correo = correo;

      if (isEdit) {
        await api.put(`/admin/usuarios/${selectedUser.id_usuario}`, data);
      } else {
        if (!password) {
          alert('Debe especificar una clave para un usuario nuevo.');
          return;
        }
        await api.post('/admin/usuarios', data);
      }

      setShowModal(false);
      fetchUsers();
    } catch (err) {
      alert(err.response?.data?.detail || 'Error al guardar el usuario.');
    }
  };

  const handleDelete = async (user) => {
    if (!window.confirm(`¿Estás seguro de eliminar el usuario con documento ${user.documento}?`)) {
      return;
    }

    try {
      await api.delete(`/admin/usuarios/${user.id_usuario}`);
      fetchUsers();
    } catch (err) {
      alert(err.response?.data?.detail || 'Error al eliminar el usuario.');
    }
  };

  if (loading) {
    return (
      <div className="loading-container">
        <div className="spinner" />
        <p>Cargando lista de usuarios...</p>
      </div>
    );
  }

  return (
    <div className="page-container">
      <header className="responsive-page-header">
        <div>
          <h1 style={styles.title}>Gestión de Usuarios</h1>
          <p style={styles.subtitle}>Crea, edita o elimina usuarios del ecosistema transaccional.</p>
        </div>
        <button className="btn-primary" onClick={openCreateModal}>
          <span className="material-icons-round">person_add</span>
          Nuevo Usuario
        </button>
      </header>

      {error && <div style={styles.error}>{error}</div>}

      <div className="glass-panel" style={styles.tableCard}>
        <table style={styles.table}>
          <thead>
            <tr>
              <th style={styles.th}>Nombre / Detalle</th>
              <th style={styles.th}>Documento / DNI</th>
              <th style={styles.th}>Rol de Usuario</th>
              <th style={styles.th}>Acciones</th>
            </tr>
          </thead>
          <tbody>
            {users.map((u) => (
              <tr key={u.id_usuario} style={styles.tr}>
                <td style={styles.td}>
                  <div style={styles.userCell}>
                    <span className="material-icons-round" style={styles.userIcon}>account_circle</span>
                    <div>
                      <div style={{ fontWeight: '600' }}>{u.nombre}</div>
                      <div style={{ fontSize: '11px', color: '#8B949E' }}>{u.id_usuario}</div>
                    </div>
                  </div>
                </td>
                <td style={styles.td}>{u.documento}</td>
                <td style={styles.td}>
                  <span style={{ ...styles.badge, ...getBadgeStyle(u.rol) }}>{u.rol}</span>
                </td>
                <td style={styles.td}>
                  <div style={styles.actions}>
                    <button className="btn-icon" onClick={() => openEditModal(u)} title="Editar Usuario">
                      <span className="material-icons-round" style={{ color: '#4d8df7' }}>edit</span>
                    </button>
                    <button className="btn-icon" onClick={() => handleDelete(u)} title="Eliminar Usuario">
                      <span className="material-icons-round" style={{ color: '#f85149' }}>delete</span>
                    </button>
                  </div>
                </td>
              </tr>
            ))}
            {users.length === 0 && (
              <tr>
                <td colSpan="4" style={{ textAlign: 'center', padding: '32px', color: '#8B949E' }}>
                  No se encontraron usuarios registrados.
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
              <h2>{isEdit ? 'Editar Usuario' : 'Nuevo Usuario'}</h2>
              <button className="btn-icon" onClick={() => setShowModal(false)}>
                <span className="material-icons-round">close</span>
              </button>
            </div>
            <form onSubmit={handleSubmit}>
              <div className="form-group">
                <label className="form-label">Documento (DNI)</label>
                <input
                  type="text"
                  className="form-control"
                  value={documento}
                  onChange={(e) => setDocumento(e.target.value)}
                  placeholder="DNI del usuario"
                  required
                />
              </div>

              <div className="form-group">
                <label className="form-label">Clave de Internet {isEdit && '(Dejar en blanco para conservar)'}</label>
                <input
                  type="password"
                  className="form-control"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Nueva contraseña"
                  required={!isEdit}
                />
              </div>

              <div className="form-group">
                <label className="form-label">Rol del Usuario</label>
                <select className="form-control" value={rol} onChange={(e) => setRol(e.target.value)}>
                  <option value="CLIENTE">CLIENTE</option>
                  <option value="ASESOR">ASESOR</option>
                  <option value="SUPERVISOR">SUPERVISOR</option>
                  <option value="ADMIN">ADMIN</option>
                </select>
              </div>

              <div className="form-group">
                <label className="form-label">Código de Empleado (Opcional)</label>
                <input
                  type="text"
                  className="form-control"
                  value={codigoEmpleado}
                  onChange={(e) => setCodigoEmpleado(e.target.value)}
                  placeholder="Ej: A001"
                />
              </div>

              <div className="form-group">
                <label className="form-label">Correo Electrónico (Opcional)</label>
                <input
                  type="email"
                  className="form-control"
                  value={correo}
                  onChange={(e) => setCorreo(e.target.value)}
                  placeholder="ejemplo@bcp.com.pe"
                />
              </div>

              {isEdit && (
                <div className="form-group">
                  <label className="form-label">Estado de Cuenta</label>
                  <select className="form-control" value={estado} onChange={(e) => setEstado(e.target.value)}>
                    <option value="ACTIVO">ACTIVO</option>
                    <option value="BLOQUEADO">BLOQUEADO</option>
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

const getBadgeStyle = (rol) => {
  switch (rol) {
    case 'ADMIN':
      return { backgroundColor: 'rgba(248, 81, 73, 0.1)', color: '#F85149' };
    case 'SUPERVISOR':
      return { backgroundColor: 'rgba(255, 120, 0, 0.1)', color: '#FF7800' };
    case 'ASESOR':
      return { backgroundColor: 'rgba(77, 141, 247, 0.1)', color: '#4d8df7' };
    default:
      return { backgroundColor: 'rgba(139, 148, 158, 0.1)', color: '#8B949E' };
  }
};

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
  userCell: {
    display: 'flex',
    alignItems: 'center',
    gap: '12px',
  },
  userIcon: {
    fontSize: '36px',
    color: '#8B949E',
  },
  badge: {
    padding: '4px 10px',
    borderRadius: '12px',
    fontSize: '12px',
    fontWeight: '700',
  },
  actions: {
    display: 'flex',
    gap: '8px',
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
