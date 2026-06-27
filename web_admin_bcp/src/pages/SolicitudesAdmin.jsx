// SolicitudesAdmin.jsx — Panel de evaluación de solicitudes de crédito
import React, { useState, useEffect } from 'react';

export default function SolicitudesAdmin({ api }) {
  const [solicitudes, setSolicitudes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [activeTab, setActiveTab] = useState('ENVIADO'); // ENVIADO, EN_EVALUACION, APROBADO, CONDICIONADO, RECHAZADO, DESEMBOLSADO
  const [selectedSol, setSelectedSol] = useState(null);
  const [notes, setNotes] = useState([]);
  const [newNote, setNewNote] = useState('');
  
  // Decision Form States
  const [showApproveModal, setShowApproveModal] = useState(false);
  const [showRejectModal, setShowRejectModal] = useState(false);
  const [showConditionModal, setShowConditionModal] = useState(false);
  const [montoAprobado, setMontoAprobado] = useState('');
  const [motivoRechazo, setMotivoRechazo] = useState('');
  const [condicionAdicional, setCondicionAdicional] = useState('');
  const [actionLoading, setActionLoading] = useState(false);

  const fetchSolicitudes = async () => {
    setLoading(true);
    try {
      const res = await api.get('/supervisor/solicitudes');
      setSolicitudes(res.data);
      setError(null);
    } catch (err) {
      setError('Error al obtener el listado de solicitudes.');
    } finally {
      setLoading(false);
    }
  };

  const fetchNotes = async (idSol) => {
    try {
      const res = await api.get(`/fventas/solicitudes/${idSol}/notas`);
      setNotes(res.data);
    } catch (_) {
      setNotes([]);
    }
  };

  useEffect(() => {
    fetchSolicitudes();
  }, []);

  const handleSelectSol = (sol) => {
    setSelectedSol(sol);
    fetchNotes(sol.id_solicitud);
    setMontoAprobado(sol.monto_solicitado);
  };

  const handleAddNote = async (e) => {
    e.preventDefault();
    if (!newNote.trim()) return;
    try {
      await api.post(`/fventas/solicitudes/${selectedSol.id_solicitud}/notas`, {
        contenido: newNote
      });
      setNewNote('');
      fetchNotes(selectedSol.id_solicitud);
    } catch (_) {
      alert('Error al agregar nota interna.');
    }
  };

  const handleUpdateEstado = async (estado, payload = {}) => {
    setActionLoading(true);
    try {
      await api.patch(`/supervisor/solicitudes/${selectedSol.id_solicitud}/estado`, {
        estado,
        ...payload
      });
      setShowApproveModal(false);
      setShowRejectModal(false);
      setShowConditionModal(false);
      setSelectedSol(null);
      fetchSolicitudes();
      alert(`Solicitud actualizada con éxito a estado: ${estado}`);
    } catch (err) {
      alert(err.response?.data?.detail || 'Error al actualizar el estado de la solicitud.');
    } finally {
      setActionLoading(false);
    }
  };

  const filteredSols = solicitudes.filter(s => {
    if (activeTab === 'ENVIADO') {
      return s.estado === 'ENVIADO' || s.estado === 'RECIBIDO_COMITE' || s.estado === 'EN_EVALUACION';
    }
    return s.estado === activeTab;
  });

  const getTimelineStep = (estado) => {
    switch (estado) {
      case 'BORRADOR': return 1;
      case 'ENVIADO':
      case 'RECIBIDO_COMITE':
      case 'EN_EVALUACION': return 2;
      case 'APROBADO':
      case 'CONDICIONADO': return 3;
      case 'DESEMBOLSADO': return 4;
      case 'RECHAZADO': return -1;
      default: return 1;
    }
  };

  return (
    <div className="page-container fade-in">
      <header className="page-header">
        <div>
          <h1 className="page-title">Gestión de Solicitudes</h1>
          <p className="page-subtitle">Evaluación, dictámenes del Buró y aprobaciones del Comité</p>
        </div>
        <button className="btn-secondary" onClick={fetchSolicitudes} disabled={loading}>
          <span className="material-icons-round">sync</span> Recargar
        </button>
      </header>

      {error && <div className="alert alert-error">{error}</div>}

      {/* Tabs */}
      <div className="tab-nav">
        <button className={`tab-btn ${activeTab === 'ENVIADO' ? 'active' : ''}`} onClick={() => { setActiveTab('ENVIADO'); setSelectedSol(null); }}>
          <span className="material-icons-round">hourglass_empty</span> Pendientes / En Evaluación
        </button>
        <button className={`tab-btn ${activeTab === 'APROBADO' ? 'active' : ''}`} onClick={() => { setActiveTab('APROBADO'); setSelectedSol(null); }}>
          <span className="material-icons-round">verified</span> Aprobadas
        </button>
        <button className={`tab-btn ${activeTab === 'CONDICIONADO' ? 'active' : ''}`} onClick={() => { setActiveTab('CONDICIONADO'); setSelectedSol(null); }}>
          <span className="material-icons-round">rule</span> Condicionadas
        </button>
        <button className={`tab-btn ${activeTab === 'DESEMBOLSADO' ? 'active' : ''}`} onClick={() => { setActiveTab('DESEMBOLSADO'); setSelectedSol(null); }}>
          <span className="material-icons-round">payments</span> Desembolsadas
        </button>
        <button className={`tab-btn ${activeTab === 'RECHAZADO' ? 'active' : ''}`} onClick={() => { setActiveTab('RECHAZADO'); setSelectedSol(null); }}>
          <span className="material-icons-round">cancel</span> Rechazadas
        </button>
      </div>

      <div className={selectedSol ? "responsive-split-solicitudes" : ""} style={{ display: selectedSol ? 'grid' : 'block' }}>
        
        {/* Left Side: Requests List */}
        <section className="glass-panel" style={{ padding: '24px' }}>
          <h3>Solicitudes ({filteredSols.length})</h3>
          <div style={{ marginTop: '16px' }}>
            {loading ? (
              <div className="loading-container"><div className="spinner"></div></div>
            ) : (
              <div className="table-wrapper">
                <table className="data-table">
                  <thead>
                    <tr>
                      <th>Expediente</th>
                      <th>Cliente</th>
                      <th>Asesor</th>
                      <th>Monto</th>
                      <th>Plazo</th>
                      <th>Dictamen Buró</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredSols.map(s => {
                      const isSelected = selectedSol?.id_solicitud === s.id_solicitud;
                      let buroClass = "badge-success";
                      if (s.resultado_buro === 'CPP') buroClass = "badge-warning";
                      if (s.resultado_buro === 'DEFICIENTE' || s.resultado_buro === 'PERDIDA' || s.resultado_buro === 'DUDOSO') buroClass = "badge-error";
                      
                      return (
                        <tr
                          key={s.id_solicitud}
                          onClick={() => handleSelectSol(s)}
                          style={{ cursor: 'pointer', background: isSelected ? 'rgba(255,255,255,0.03)' : 'transparent' }}
                        >
                          <td style={{ fontWeight: 'bold' }}>{s.numero_expediente}</td>
                          <td>{s.cliente_nombre}</td>
                          <td>{s.asesor_nombre}</td>
                          <td>S/ {s.monto_solicitado}</td>
                          <td>{s.plazo_meses} meses</td>
                          <td>
                            <span className={`badge ${buroClass}`}>
                              {s.resultado_buro || 'NORMAL'}
                            </span>
                          </td>
                        </tr>
                      );
                    })}
                    {filteredSols.length === 0 && (
                      <tr>
                        <td colSpan="6" className="empty-state">
                          <span className="material-icons-round">folder_open</span>
                          <p>No hay solicitudes en esta sección.</p>
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </section>

        {/* Right Side: Detailed evaluation panel */}
        {selectedSol && (
          <section className="glass-panel slide-up" style={{ padding: '24px', alignSelf: 'start' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
              <div>
                <h2>Expediente {selectedSol.numero_expediente}</h2>
                <p style={{ color: 'var(--color-text-muted)', fontSize: '13px' }}>Ingresada el {new Date(selectedSol.created_at).toLocaleString()}</p>
              </div>
              <span className={`badge ${selectedSol.estado === 'DESEMBOLSADO' ? 'badge-success' : selectedSol.estado === 'RECHAZADO' ? 'badge-error' : 'badge-orange'}`}>
                {selectedSol.estado}
              </span>
            </div>

            {/* Timeline progress indicator */}
            <div style={{ margin: '24px 0', background: 'rgba(255,255,255,0.01)', padding: '16px', borderRadius: '12px', border: '1px solid var(--color-border)' }}>
              <h4 style={{ marginBottom: '12px', fontSize: '13px', color: 'var(--color-text-muted)' }}>Flujo de Originación</h4>
              {getTimelineStep(selectedSol.estado) === -1 ? (
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--color-error)' }}>
                  <span className="material-icons-round">cancel</span>
                  <strong>Solicitud Rechazada por el Comité / Buró</strong>
                </div>
              ) : (
                <div style={{ display: 'flex', justifyContent: 'space-between', position: 'relative' }}>
                  {['Borrador', 'Evaluación', 'Aprobado', 'Desembolso'].map((step, idx) => {
                    const currentStep = getTimelineStep(selectedSol.estado);
                    const isActive = idx + 1 <= currentStep;
                    return (
                      <div key={step} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', flex: 1, position: 'relative', zIndex: 2 }}>
                        <div style={{
                          width: '24px',
                          height: '24px',
                          borderRadius: '50%',
                          background: isActive ? 'var(--bcp-orange)' : 'var(--color-border)',
                          color: '#fff',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          fontSize: '11px',
                          fontWeight: 'bold',
                          boxShadow: isActive ? '0 0 10px rgba(255,107,0,0.5)' : 'none'
                        }}>
                          {idx + 1}
                        </div>
                        <span style={{ fontSize: '11px', marginTop: '6px', color: isActive ? 'var(--color-text)' : 'var(--color-text-muted)', fontWeight: isActive ? 'bold' : 'normal' }}>
                          {step}
                        </span>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>

            {/* Financial and scoring details */}
            <div className="responsive-two-cols" style={{ marginBottom: '24px' }}>
              <div className="card" style={{ padding: '16px' }}>
                <h4 style={{ color: 'var(--bcp-sky)', marginBottom: '8px' }}>Solicitud Financiera</h4>
                <div style={{ fontSize: '13px', display: 'flex', flexDirection: 'column', gap: '6px' }}>
                  <div>Monto Solicitado: <strong>S/ {selectedSol.monto_solicitado}</strong></div>
                  {selectedSol.monto_aprobado && (
                    <div style={{ color: 'var(--color-success)' }}>Monto Aprobado: <strong>S/ {selectedSol.monto_aprobado}</strong></div>
                  )}
                  <div>Plazo sugerido: <strong>{selectedSol.plazo_meses} meses</strong></div>
                  <div>Destino de Crédito: <strong>{selectedSol.destino_credito}</strong></div>
                </div>
              </div>

              <div className="card" style={{ padding: '16px' }}>
                <h4 style={{ color: 'var(--bcp-orange)', marginBottom: '8px' }}>Scoring & Riesgo</h4>
                <div style={{ fontSize: '13px', display: 'flex', flexDirection: 'column', gap: '6px' }}>
                  <div>Resultado Pre-eval: <strong>{selectedSol.resultado_preevaluacion}</strong></div>
                  <div>Puntaje Pre-eval: <strong>{selectedSol.puntaje_preevaluacion} pts</strong></div>
                  <div>Semáforo SBS: <strong style={{ color: selectedSol.resultado_buro === 'NORMAL' ? 'var(--color-success)' : 'var(--color-error)' }}>{selectedSol.resultado_buro || 'NORMAL'}</strong></div>
                </div>
              </div>
            </div>

            {/* Internal Notes Section */}
            <div style={{ marginBottom: '24px' }}>
              <h4 style={{ marginBottom: '8px' }}>Notas de Campo e Internas</h4>
              <div style={{
                maxHeight: '150px',
                overflowY: 'auto',
                border: '1px solid var(--color-border)',
                borderRadius: '8px',
                padding: '10px',
                background: 'rgba(255,255,255,0.01)',
                marginBottom: '12px'
              }}>
                {notes.map(n => (
                  <div key={n.id_nota} style={{ padding: '8px', borderBottom: '1px solid rgba(255,255,255,0.04)', fontSize: '12px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', color: 'var(--color-text-muted)', marginBottom: '2px' }}>
                      <strong>{n.asesor_nombre}</strong>
                      <span>{new Date(n.created_at).toLocaleTimeString()}</span>
                    </div>
                    <div>{n.contenido}</div>
                  </div>
                ))}
                {notes.length === 0 && <div style={{ color: 'var(--color-text-muted)', textAlign: 'center', padding: '12px', fontSize: '12px' }}>Sin notas registradas.</div>}
              </div>

              <form onSubmit={handleAddNote} style={{ display: 'flex', gap: '8px' }}>
                <input
                  type="text"
                  className="form-control"
                  placeholder="Agregar instrucción o nota interna..."
                  value={newNote}
                  onChange={e => setNewNote(e.target.value)}
                />
                <button type="submit" className="btn-primary" style={{ padding: '8px 16px' }}>Enviar</button>
              </form>
            </div>

            {/* Decisions Actions */}
            {['ENVIADO', 'RECIBIDO_COMITE', 'EN_EVALUACION', 'CONDICIONADO'].includes(selectedSol.estado) && (
              <div>
                {/* Show condition banner if CONDICIONADO */}
                {selectedSol.estado === 'CONDICIONADO' && selectedSol.condicion_adicional && (
                  <div style={{
                    background: 'rgba(255, 160, 0, 0.1)',
                    border: '1px solid var(--color-warning)',
                    borderRadius: '8px',
                    padding: '12px 16px',
                    marginBottom: '14px',
                    fontSize: '13px'
                  }}>
                    <strong style={{ color: 'var(--color-warning)' }}>⚠️ Condición pendiente:</strong>
                    <p style={{ marginTop: '6px', color: 'var(--color-text)' }}>{selectedSol.condicion_adicional}</p>
                    <p style={{ marginTop: '4px', color: 'var(--color-text-muted)', fontSize: '12px' }}>Una vez subsanada la condición, proceda a aprobar o rechazar.</p>
                  </div>
                )}
                <div style={{ display: 'flex', gap: '10px' }}>
                  <button className="btn-primary" style={{ flex: 1 }} onClick={() => setShowApproveModal(true)}>Aprobar</button>
                  {selectedSol.estado !== 'CONDICIONADO' && (
                    <button className="btn-secondary" style={{ flex: 1, borderColor: 'var(--color-warning)', color: 'var(--color-warning)' }} onClick={() => setShowConditionModal(true)}>Condicionar</button>
                  )}
                  <button className="btn-danger" style={{ flex: 1 }} onClick={() => setShowRejectModal(true)}>Rechazar</button>
                </div>
              </div>
            )}

            {selectedSol.estado === 'APROBADO' && (
              <div style={{ display: 'flex', gap: '10px' }}>
                <button
                  className="btn-primary"
                  style={{ flex: 1, background: 'linear-gradient(135deg, #1DB954 0%, #17a34a 100%)', boxShadow: '0 4px 15px rgba(29,185,84,0.3)' }}
                  onClick={() => handleUpdateEstado('DESEMBOLSADO')}
                  disabled={actionLoading}
                >
                  <span className="material-icons-round">payments</span> Desembolsar Crédito
                </button>
              </div>
            )}
          </section>
        )}
      </div>

      {/* Approve Modal */}
      {showApproveModal && (
        <div className="modal-overlay">
          <div className="modal-content glass-panel">
            <header className="modal-header">
              <h2>Aprobar Solicitud</h2>
              <button className="btn-icon" onClick={() => setShowApproveModal(false)}>
                <span className="material-icons-round">close</span>
              </button>
            </header>
            <div className="form-group">
              <label className="form-label">Monto Aprobado (S/)</label>
              <input
                type="number"
                className="form-control"
                value={montoAprobado}
                onChange={e => setMontoAprobado(e.target.value)}
              />
            </div>
            <div className="form-group">
              <label className="form-label">Condiciones Adicionales (Opcional)</label>
              <textarea
                className="form-control"
                rows="2"
                placeholder="Indicar si hay alguna instrucción o garantía complementaria..."
                value={condicionAdicional}
                onChange={e => setCondicionAdicional(e.target.value)}
              />
            </div>
            <footer className="modal-footer">
              <button className="btn-secondary" onClick={() => setShowApproveModal(false)}>Cancelar</button>
              <button className="btn-primary" onClick={() => handleUpdateEstado('APROBADO', { monto_aprobado: parseFloat(montoAprobado), condicion_adicional: condicionAdicional })} disabled={actionLoading}>
                {actionLoading ? 'Procesando...' : 'Confirmar Aprobación'}
              </button>
            </footer>
          </div>
        </div>
      )}

      {/* Condition Modal */}
      {showConditionModal && (
        <div className="modal-overlay">
          <div className="modal-content glass-panel">
            <header className="modal-header">
              <h2>Condicionar Solicitud</h2>
              <button className="btn-icon" onClick={() => setShowConditionModal(false)}>
                <span className="material-icons-round">close</span>
              </button>
            </header>
            <div className="form-group">
              <label className="form-label">Especificar Condición (Requerido)</label>
              <textarea
                className="form-control"
                rows="3"
                placeholder="Ejemplo: Presentar aval solidario con sustento de ingresos..."
                value={condicionAdicional}
                onChange={e => setCondicionAdicional(e.target.value)}
              />
            </div>
            <footer className="modal-footer">
              <button className="btn-secondary" onClick={() => setShowConditionModal(false)}>Cancelar</button>
              <button className="btn-primary" onClick={() => handleUpdateEstado('CONDICIONADO', { condicion_adicional: condicionAdicional })} disabled={actionLoading || !condicionAdicional.trim()}>
                {actionLoading ? 'Procesando...' : 'Confirmar Condicionamiento'}
              </button>
            </footer>
          </div>
        </div>
      )}

      {/* Reject Modal */}
      {showRejectModal && (
        <div className="modal-overlay">
          <div className="modal-content glass-panel">
            <header className="modal-header">
              <h2>Rechazar Solicitud</h2>
              <button className="btn-icon" onClick={() => setShowRejectModal(false)}>
                <span className="material-icons-round">close</span>
              </button>
            </header>
            <div className="form-group">
              <label className="form-label">Motivo de Rechazo (Requerido)</label>
              <textarea
                className="form-control"
                rows="3"
                placeholder="Detalle el motivo técnico por el cual se deniega el crédito..."
                value={motivoRechazo}
                onChange={e => setMotivoRechazo(e.target.value)}
              />
            </div>
            <footer className="modal-footer">
              <button className="btn-secondary" onClick={() => setShowRejectModal(false)}>Cancelar</button>
              <button className="btn-primary" style={{ background: 'var(--color-error)' }} onClick={() => handleUpdateEstado('RECHAZADO', { motivo_rechazo: motivoRechazo })} disabled={actionLoading || !motivoRechazo.trim()}>
                {actionLoading ? 'Procesando...' : 'Confirmar Rechazo'}
              </button>
            </footer>
          </div>
        </div>
      )}
    </div>
  );
}
