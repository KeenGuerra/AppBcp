// Dashboard.jsx — BCP Admin Portal: panel principal con métricas en tiempo real
import React, { useEffect, useState } from 'react';

const MOCK_OP_ICONS = {
  'DEPOSITO': { desc: 'Depósito en Efectivo', color: '#1DB954', icon: 'arrow_downward' },
  'RETIRO': { desc: 'Retiro en Efectivo', color: '#E53E3E', icon: 'arrow_upward' },
  'RETIRO_PLAZO': { desc: 'Retiro Plazo Fijo', color: '#E53E3E', icon: 'money_off' },
  'TRANSFERENCIA': { desc: 'Transferencia Bancaria', color: '#00A3E0', icon: 'swap_horiz' },
  'PAGO_LUZ': { desc: 'Pago Luz (Enel/Luz del Sur)', color: '#F6C90E', icon: 'bolt' },
  'PAGO_AGUA': { desc: 'Pago Agua (Sedapal)', color: '#00A3E0', icon: 'water_drop' },
  'PAGO_INTERNET': { desc: 'Pago Internet/Cable', color: '#FF6B00', icon: 'wifi' },
  'PAGO_TELEFONO': { desc: 'Pago Telefonía Móvil', color: '#1DB954', icon: 'smartphone' },
  'PAGO_GAS': { desc: 'Pago Gas Cálidda', color: '#FF6B00', icon: 'local_fire_department' },
  'RECARGA': { desc: 'Recarga Celular', color: '#FF6B00', icon: 'phone_android' },
  'PRESTAMO': { desc: 'Desembolso Préstamo', color: '#7FB3E0', icon: 'account_balance' },
};

export default function Dashboard({ api, setPage }) {
  const [coreStats, setCoreStats] = useState({ usuarios: 0, productos: 0, outbox: 0, successRate: '—' });
  const [bankingStats, setBankingStats] = useState(null);
  const [recentOps, setRecentOps] = useState([]);
  const [solicitudesCount, setSolicitudesCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [serverOk, setServerOk] = useState(false);

  const fetchAll = async (isSilent = false) => {
    if (!isSilent) setLoading(true);
    try {
      const [rUsers, rProds, rOutbox, rLogs, rBanking, rRecent, rSols] = await Promise.allSettled([
        api.get('/admin/usuarios'),
        api.get('/admin/productos-creditos'),
        api.get('/sync/outbox'),
        api.get('/sync/log'),
        api.get('/banking/admin/stats'),
        api.get('/banking/admin/transacciones?limit=5'),
        api.get('/supervisor/solicitudes'),
      ]);

      if (rUsers.status === 'fulfilled') {
        setServerOk(true);
        const logs = rLogs.status === 'fulfilled' ? rLogs.value.data : [];
        const outbox = rOutbox.status === 'fulfilled' ? rOutbox.value.data : [];
        const successLogs = logs.filter(l => l.exito).length;
        setCoreStats({
          usuarios: rUsers.value.data.length,
          productos: rProds.status === 'fulfilled' ? rProds.value.data.length : 0,
          outbox: outbox.length,
          successRate: logs.length > 0 ? `${Math.round((successLogs / logs.length) * 100)}%` : '100%',
        });
      }

      if (rBanking.status === 'fulfilled') {
        setBankingStats(rBanking.value.data);
      }

      if (rRecent.status === 'fulfilled') {
        setRecentOps(rRecent.value.data);
      }

      if (rSols.status === 'fulfilled') {
        setSolicitudesCount(rSols.value.data.length);
      }
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAll();
    
    // Auto-refresh stats every 30 seconds for real-time visualization
    const timer = setInterval(() => fetchAll(true), 30000);
    return () => clearInterval(timer);
  }, [api]);


  const fmt = (n) => `S/ ${Number(n || 0).toLocaleString('es-PE', { minimumFractionDigits: 2 })}`;

  return (
    <div className="page-container fade-in">
      {/* Header */}
      <div style={{ marginBottom: '32px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '8px' }}>
          <div style={{
            background: 'rgba(29,185,84,0.12)',
            borderRadius: '50%',
            padding: '4px 8px',
            display: 'flex',
            alignItems: 'center',
            gap: '6px',
          }}>
            <div className={`pulse-dot ${serverOk ? 'pulse-green' : 'pulse-orange'}`} />
            <span style={{ fontSize: '12px', color: serverOk ? '#1DB954' : '#FF6B00', fontWeight: 600 }}>
              {loading ? 'Conectando...' : serverOk ? 'Sistema Activo' : 'Modo Demo'}
            </span>
          </div>
        </div>
        <h1 className="page-title" style={{ fontSize: '2.2rem' }}>
          Panel General <span style={{ color: 'var(--bcp-orange)' }}>BCP</span>
        </h1>
        <p className="page-subtitle">
          Supervisión integral del ecosistema bancario — operaciones en tiempo real.
        </p>
      </div>

      {/* Core Stats */}
      <div className="responsive-stats-grid">
        <div className="stat-card orange" onClick={() => setPage('users')} style={{ cursor: 'pointer' }}>
          <div className="stat-icon" style={{ background: 'rgba(255,107,0,0.12)' }}>
            <span className="material-icons-round" style={{ color: 'var(--bcp-orange)' }}>people</span>
          </div>
          <div className="stat-label">Usuarios del Sistema</div>
          <div className="stat-value">{loading ? '—' : coreStats.usuarios}</div>
          <div className="stat-sub">Clientes, asesores y admins</div>
        </div>
        <div className="stat-card navy" onClick={() => setPage('products')} style={{ cursor: 'pointer' }}>
          <div className="stat-icon" style={{ background: 'rgba(0,42,84,0.3)' }}>
            <span className="material-icons-round" style={{ color: '#7FB3E0' }}>monetization_on</span>
          </div>
          <div className="stat-label">Productos Crediticios</div>
          <div className="stat-value">{loading ? '—' : coreStats.productos}</div>
          <div className="stat-sub">Tipos de crédito microempresa</div>
        </div>
        <div className="stat-card green" onClick={() => setPage('transacciones')} style={{ cursor: 'pointer' }}>
          <div className="stat-icon" style={{ background: 'rgba(29,185,84,0.12)' }}>
            <span className="material-icons-round" style={{ color: '#1DB954' }}>receipt_long</span>
          </div>
          <div className="stat-label">Transacciones Bancarias</div>
          <div className="stat-value">{bankingStats?.totales?.transacciones ?? '0'}</div>
          <div className="stat-sub">{fmt(bankingStats?.montos?.transacciones)} procesado</div>
        </div>
        <div className="stat-card sky" onClick={() => setPage('sync')} style={{ cursor: 'pointer' }}>
          <div className="stat-icon" style={{ background: 'rgba(0,163,224,0.12)' }}>
            <span className="material-icons-round" style={{ color: '#00A3E0' }}>sync_alt</span>
          </div>
          <div className="stat-label">Tasa Sincronización</div>
          <div className="stat-value">{loading ? '—' : coreStats.successRate}</div>
          <div className="stat-sub">{coreStats.outbox} eventos en cola</div>
        </div>
      </div>

      {/* Banking Operations Grid */}
      {bankingStats && (
        <div style={{ marginBottom: '32px' }}>
          <h2 style={{ fontSize: '1.1rem', marginBottom: '16px', color: 'var(--color-text)' }}>
            Resumen de Operaciones Bancarias (35 Casuísticas)
          </h2>
          <div className="responsive-banking-grid">
            {[
              { label: 'Transferencias', val: bankingStats.totales.transferencias, monto: bankingStats.montos.transferencias, icon: 'swap_horiz', color: '#00A3E0', page: 'transacciones' },
              { label: 'Pagos Servicios', val: bankingStats.totales.pagos_servicios, monto: bankingStats.montos.pagos_servicios, icon: 'payment', color: '#1DB954', page: 'transacciones' },
              { label: 'Recargas', val: bankingStats.totales.recargas, monto: null, icon: 'smartphone', color: '#FF6B00', page: 'transacciones' },
              { label: 'Préstamos', val: bankingStats.totales.prestamos, monto: null, icon: 'account_balance', color: '#7FB3E0', page: 'prestamos' },
              { label: 'Ahorros', val: bankingStats.totales.ahorros, monto: null, icon: 'savings', color: '#F6C90E', page: 'ahorros' },
              { label: 'Solicitudes', val: solicitudesCount, monto: null, icon: 'pending_actions', color: '#E53E3E', page: 'solicitudes_admin' },
            ].map((item, i) => (
              <div
                key={i}
                onClick={() => setPage(item.page)}
                style={{
                  background: 'var(--grad-card)',
                  border: '1px solid var(--color-border)',
                  borderRadius: '12px',
                  padding: '20px',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '16px',
                  transition: 'all 0.2s',
                }}
                onMouseEnter={e => { e.currentTarget.style.borderColor = 'var(--color-border-light)'; e.currentTarget.style.transform = 'translateY(-2px)'; }}
                onMouseLeave={e => { e.currentTarget.style.borderColor = 'var(--color-border)'; e.currentTarget.style.transform = 'translateY(0)'; }}
              >
                <div style={{
                  width: 44, height: 44, borderRadius: '10px',
                  background: `${item.color}18`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
                }}>
                  <span className="material-icons-round" style={{ fontSize: '22px', color: item.color }}>{item.icon}</span>
                </div>
                <div>
                  <div style={{ fontSize: '12px', color: 'var(--color-text-muted)', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em' }}>{item.label}</div>
                  <div style={{ fontSize: '24px', fontWeight: 800, color: '#fff' }}>{item.val ?? '0'}</div>
                  {item.monto != null && (
                    <div style={{ fontSize: '12px', color: item.color }}>{fmt(item.monto)}</div>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Bottom Two Columns */}
      <div className="responsive-split-grid">
        {/* Recent Activity */}
        <div className="glass-panel" style={{ padding: '24px' }}>
          <h3 style={{ marginBottom: '20px', fontSize: '15px' }}>
            Últimas Operaciones del Sistema
          </h3>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0' }}>
            {recentOps.length === 0 ? (
              <div style={{ padding: '24px 0', textAlign: 'center', color: 'var(--color-text-muted)', fontSize: '14px' }}>
                No hay operaciones registradas en el sistema.
              </div>
            ) : (
              recentOps.map((op, i) => {
                const conf = MOCK_OP_ICONS[op.tipo] || { desc: op.descripcion || op.tipo, color: '#00A3E0', icon: 'receipt_long' };
                const isPositive = op.tipo === 'DEPOSITO';
                const sign = isPositive ? '+' : '-';
                const color = conf.color;
                
                let timeStr = 'Hace un momento';
                try {
                  const opDate = new Date(op.fecha);
                  const diffMs = new Date() - opDate;
                  const diffMin = Math.round(diffMs / 60000);
                  if (diffMin > 0) {
                    timeStr = diffMin < 60 ? `hace ${diffMin} min` : diffMin < 1440 ? `hace ${Math.round(diffMin/60)} h` : opDate.toLocaleDateString();
                  }
                } catch(err) {}
                
                return (
                  <div key={op.id || i} style={{
                    display: 'flex', alignItems: 'center', gap: '14px',
                    padding: '14px 0',
                    borderBottom: i < recentOps.length - 1 ? '1px solid var(--color-border)' : 'none',
                  }}>
                    <div style={{
                      width: 38, height: 38, borderRadius: '10px',
                      background: `${color}15`,
                      display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
                    }}>
                      <span className="material-icons-round" style={{ fontSize: '18px', color: color }}>{conf.icon}</span>
                    </div>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontWeight: 600, fontSize: '14px' }}>{conf.desc}</div>
                      <div style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>{timeStr} · {op.cuenta_id || 'BCP'}</div>
                    </div>
                    <div style={{ fontWeight: 700, color: color, fontSize: '14px', whiteSpace: 'nowrap' }}>
                      {sign}{fmt(op.monto)}
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </div>

        {/* System Status */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          <div className="glass-panel" style={{ padding: '24px' }}>
            <h3 style={{ marginBottom: '20px', fontSize: '15px' }}>Estado del Core Banking</h3>
            {[
              { label: 'FastAPI Core Server', detail: 'Puerto 8003 · PostgreSQL OK', ok: serverOk },
              { label: 'Banking Operations API', detail: '35 casuísticas activas', ok: true },
              { label: 'Sync Outbox Service', detail: `${coreStats.outbox} eventos en cola`, ok: true },
            ].map((item, i) => (
              <div key={i} style={{
                display: 'flex', alignItems: 'center', gap: '12px',
                padding: '12px 0',
                borderBottom: i < 2 ? '1px solid var(--color-border)' : 'none',
              }}>
                <div className={`pulse-dot ${item.ok ? 'pulse-green' : 'pulse-orange'}`} />
                <div>
                  <div style={{ fontWeight: 600, fontSize: '14px' }}>{item.label}</div>
                  <div style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>{item.detail}</div>
                </div>
              </div>
            ))}
          </div>

          {/* Quick Actions */}
          <div className="glass-panel" style={{ padding: '24px' }}>
            <h3 style={{ marginBottom: '16px', fontSize: '15px' }}>Acciones Rápidas</h3>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
              {[
                { label: 'Ver Transacciones', page: 'transacciones', icon: 'receipt_long' },
                { label: 'Aprobar Préstamos', page: 'prestamos', icon: 'account_balance' },
                { label: 'Gestionar Usuarios', page: 'users', icon: 'people' },
                { label: 'Procesar Sync', page: 'sync', icon: 'sync_alt' },
              ].map(a => (
                <button
                  key={a.page}
                  className="btn-secondary"
                  style={{ justifyContent: 'flex-start', padding: '10px 14px' }}
                  onClick={() => setPage(a.page)}
                >
                  <span className="material-icons-round" style={{ fontSize: '18px', color: 'var(--bcp-orange)' }}>{a.icon}</span>
                  {a.label}
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
