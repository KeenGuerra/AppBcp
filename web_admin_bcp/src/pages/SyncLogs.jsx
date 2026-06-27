import React, { useEffect, useState } from 'react';

export default function SyncLogs({ api }) {
  const [outbox, setOutbox] = useState([]);
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [syncing, setSyncing] = useState(false);
  const [activeTab, setActiveTab] = useState('outbox'); // outbox | logs

  const fetchData = async () => {
    try {
      const [resOutbox, resLogs] = await Promise.all([
        api.get('/sync/outbox'),
        api.get('/sync/log'),
      ]);
      setOutbox(resOutbox.data);
      setLogs(resLogs.data);
    } catch (err) {
      console.error('Error fetching sync details:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleProcesarOutbox = async () => {
    setSyncing(true);
    try {
      const res = await api.post('/sync/procesar');
      alert(`Procesamiento exitoso:\n${res.data.mensaje}\nEventos procesados: ${res.data.procesados}`);
      fetchData();
    } catch (err) {
      alert(err.response?.data?.detail || 'Error al procesar la cola de outbox.');
    } finally {
      setSyncing(false);
    }
  };

  if (loading) {
    return (
      <div className="loading-container">
        <div className="spinner" />
        <p>Cargando registros de sincronización...</p>
      </div>
    );
  }

  return (
    <div style={styles.container}>
      <header style={styles.header}>
        <div>
          <h1 style={styles.title}>Auditoría e Integración (Sync)</h1>
          <p style={styles.subtitle}>Supervisa la cola de sincronización transaccional (Sync Outbox) y logs de auditoría.</p>
        </div>
        <button
          className="btn-primary"
          style={{ backgroundColor: '#FF7800' }}
          onClick={handleProcesarOutbox}
          disabled={syncing}
        >
          <span className="material-icons-round">{syncing ? 'hourglass_empty' : 'play_arrow'}</span>
          {syncing ? 'Procesando...' : 'Procesar Outbox'}
        </button>
      </header>

      {/* Tabs navigation */}
      <div style={styles.tabNav}>
        <button
          style={{ ...styles.tabButton, ...(activeTab === 'outbox' ? styles.activeTab : {}) }}
          onClick={() => setActiveTab('outbox')}
        >
          <span className="material-icons-round" style={styles.tabIcon}>hourglass_full</span>
          Cola Transaccional Outbox ({outbox.length})
        </button>
        <button
          style={{ ...styles.tabButton, ...(activeTab === 'logs' ? styles.activeTab : {}) }}
          onClick={() => setActiveTab('logs')}
        >
          <span className="material-icons-round" style={styles.tabIcon}>receipt_long</span>
          Historial de Logs ({logs.length})
        </button>
      </div>

      <div className="glass-panel" style={styles.tableCard}>
        {activeTab === 'outbox' ? (
          <table style={styles.table}>
            <thead>
              <tr>
                <th style={styles.th}>ID Evento</th>
                <th style={styles.th}>Tipo Evento</th>
                <th style={styles.th}>Referencia Registro</th>
                <th style={styles.th}>Reintentos</th>
                <th style={styles.th}>Estado</th>
              </tr>
            </thead>
            <tbody>
              {outbox.map((item) => (
                <tr key={item.id_sync} style={styles.tr}>
                  <td style={styles.td}>{item.id_sync}</td>
                  <td style={styles.td}>
                    <span style={styles.eventText}>{item.tipo_evento}</span>
                  </td>
                  <td style={styles.td}>{item.id_registro_referencia}</td>
                  <td style={styles.td}>{item.reintentos}</td>
                  <td style={styles.td}>
                    <span style={{
                      ...styles.badge,
                      ...getOutboxBadgeStyle(item.estado)
                    }}>
                      {item.estado}
                    </span>
                  </td>
                </tr>
              ))}
              {outbox.length === 0 && (
                <tr>
                  <td colSpan="5" style={{ textAlign: 'center', padding: '32px', color: '#8B949E' }}>
                    No hay eventos pendientes en la cola outbox.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        ) : (
          <table style={styles.table}>
            <thead>
              <tr>
                <th style={styles.th}>Fecha y Hora</th>
                <th style={styles.th}>Origen de Datos</th>
                <th style={styles.th}>Resultado</th>
                <th style={styles.th}>Mensaje Respuesta</th>
              </tr>
            </thead>
            <tbody>
              {logs.map((log) => (
                <tr key={log.id_log} style={styles.tr}>
                  <td style={styles.td}>
                    {new Date(log.fecha_sincronizacion).toLocaleString('es-PE')}
                  </td>
                  <td style={styles.td}>{log.origen_datos}</td>
                  <td style={styles.td}>
                    <span style={{
                      ...styles.badge,
                      backgroundColor: log.exito ? 'rgba(46, 160, 67, 0.1)' : 'rgba(248, 81, 73, 0.1)',
                      color: log.exito ? '#2ea043' : '#F85149'
                    }}>
                      {log.exito ? 'EXITO' : 'FALLIDO'}
                    </span>
                  </td>
                  <td style={styles.td}>{log.mensaje_respuesta || 'Sincronizado OK'}</td>
                </tr>
              ))}
              {logs.length === 0 && (
                <tr>
                  <td colSpan="4" style={{ textAlign: 'center', padding: '32px', color: '#8B949E' }}>
                    No se registran logs de sincronización aún.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}

const getOutboxBadgeStyle = (estado) => {
  switch (estado) {
    case 'PROCESADO':
      return { backgroundColor: 'rgba(46, 160, 67, 0.1)', color: '#2ea043' };
    case 'FALLIDO':
      return { backgroundColor: 'rgba(248, 81, 73, 0.1)', color: '#F85149' };
    default:
      return { backgroundColor: 'rgba(255, 120, 0, 0.1)', color: '#FF7800' };
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
  tabNav: {
    display: 'flex',
    gap: '8px',
    marginBottom: '24px',
    borderBottom: '1px solid var(--color-border)',
    paddingBottom: '8px',
  },
  tabButton: {
    background: 'none',
    border: 'none',
    color: '#8B949E',
    padding: '10px 16px',
    cursor: 'pointer',
    fontSize: '14px',
    fontWeight: '600',
    display: 'flex',
    alignItems: 'center',
    gap: '8px',
    borderRadius: '6px 6px 0 0',
    transition: 'all 0.2s',
  },
  activeTab: {
    color: '#fff',
    backgroundColor: 'rgba(255, 255, 255, 0.05)',
    borderBottom: '2px solid #FF7800',
  },
  tabIcon: {
    fontSize: '18px',
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
    fontSize: '14px',
    verticalAlign: 'middle',
    color: '#c9d1d9',
  },
  eventText: {
    fontWeight: '600',
    color: '#4d8df7',
  },
  badge: {
    padding: '4px 10px',
    borderRadius: '12px',
    fontSize: '12px',
    fontWeight: '700',
    display: 'inline-block',
  },
  loadingContainer: {
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'center',
    alignItems: 'center',
    minHeight: '400px',
    gap: '16px',
    color: '#8B949E',
  }
};
