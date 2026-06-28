// Login.jsx — BCP Admin Portal login con branding real BCP (Premium Redesign)
import React, { useState } from 'react';
import axios from 'axios';

export default function Login({ onLoginSuccess }) {
  const [documento, setDocumento] = useState('admin@bcp.com.pe');
  const [password, setPassword] = useState('123456');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [showPass, setShowPass] = useState(false);
  const [isFocusedDoc, setIsFocusedDoc] = useState(false);
  const [isFocusedPass, setIsFocusedPass] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!documento || !password) {
      setError('Por favor, ingresa tus credenciales.');
      return;
    }
    setIsLoading(true);
    setError('');
    try {
      const isNumeric = /^\d+$/.test(documento);
      const response = await axios.post(`${import.meta.env.VITE_API_URL || 'http://127.0.0.1:8003'}/auth/login`, {
        documento: isNumeric ? documento : null,
        codigo_empleado: isNumeric ? null : documento,
        password,
      });
      const { access_token, usuario } = response.data;
      if (usuario.rol !== 'ADMIN') {
        setError('Acceso denegado. Este portal es de uso exclusivo para Administradores BCP.');
        setIsLoading(false);
        return;
      }
      onLoginSuccess(access_token, usuario.nombre, usuario.documento);
    } catch (err) {
      const msg = err.response?.data?.detail || 'Error de conexión con el servidor BCP.';
      setError(msg);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div style={s.root}>
      {/* Dynamic Keyframe Styles */}
      <style>{`
        @keyframes float-blob-1 {
          0% { transform: translate(0, 0) scale(1); }
          50% { transform: translate(60px, 40px) scale(1.1); }
          100% { transform: translate(-30px, -20px) scale(0.9); }
        }
        @keyframes float-blob-2 {
          0% { transform: translate(0, 0) scale(1); }
          50% { transform: translate(-50px, 30px) scale(0.95); }
          100% { transform: translate(40px, -40px) scale(1.05); }
        }
        @keyframes float-blob-3 {
          0% { transform: translate(0, 0) scale(1); }
          50% { transform: translate(30px, -60px) scale(1.15); }
          100% { transform: translate(-40px, 20px) scale(0.9); }
        }
        .bcp-input {
          background: rgba(255, 255, 255, 0.03) !important;
          border: 1px solid rgba(255, 255, 255, 0.08) !important;
          color: #fff !important;
          border-radius: 12px !important;
          padding: 14px 16px 14px 44px !important;
          width: 100% !important;
          font-size: 14px !important;
          transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1) !important;
          outline: none !important;
        }
        .bcp-input:focus {
          border-color: #00A3E0 !important;
          background: rgba(255, 255, 255, 0.06) !important;
          box-shadow: 0 0 0 4px rgba(0, 163, 224, 0.15) !important;
        }
        .bcp-input::placeholder {
          color: rgba(255, 255, 255, 0.25) !important;
        }
        .bcp-btn {
          background: linear-gradient(135deg, #FF6B00 0%, #FF8C33 100%) !important;
          color: #fff !important;
          border: none !important;
          padding: 15px !important;
          font-size: 15px !important;
          font-weight: 700 !important;
          border-radius: 12px !important;
          cursor: pointer !important;
          display: inline-flex !important;
          align-items: center !important;
          gap: 10px !important;
          justify-content: center !important;
          transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1) !important;
          box-shadow: 0 6px 20px rgba(255,107,0,0.2) !important;
          width: 100% !important;
        }
        .bcp-btn:hover:not(:disabled) {
          background: linear-gradient(135deg, #FF8C33 0%, #FFA35C 100%) !important;
          transform: translateY(-2px) !important;
          box-shadow: 0 8px 25px rgba(255,107,0,0.35) !important;
        }
        .bcp-btn:active:not(:disabled) {
          transform: translateY(0) !important;
        }
        .bcp-btn:disabled {
          opacity: 0.6 !important;
          cursor: not-allowed !important;
        }
      `}</style>

      {/* Floating ambient background elements */}
      <div style={s.blob1} />
      <div style={s.blob2} />
      <div style={s.blob3} />

      {/* Soft backglow behind the card */}
      <div style={s.cardGlow} />

      {/* Glassmorphic card */}
      <div style={s.formCard}>
        {/* Header Branding */}
        <div style={s.formHeader}>
          <div style={s.formLogoRow}>
            <div style={s.formBcpBadge}>BCP</div>
            <div style={s.formBcpLabel}>
              <div style={s.formBcpName}>Banco de Crédito</div>
              <div style={s.formBcpSub}>del Perú</div>
            </div>
          </div>
          <h2 style={s.formTitle}>Portal Administrativo</h2>
          <p style={s.formSubtitle}>Ingresa con tu Correo, Código de Asesor o DNI</p>
        </div>

        {/* Error Notification */}
        {error && (
          <div style={s.errorAlert}>
            <span className="material-icons-round" style={{ fontSize: '20px', color: '#FF4A4A' }}>error_outline</span>
            <span style={{ fontSize: '13px', color: '#FFD1D1', fontWeight: '500' }}>{error}</span>
          </div>
        )}

        {/* Credentials Form */}
        <form onSubmit={handleSubmit}>
          <div style={s.formGroup}>
            <label style={s.formLabel}>Usuario de Colaborador</label>
            <div style={s.inputWrapper}>
              <span 
                className="material-icons-round" 
                style={{ 
                  ...s.inputIcon, 
                  color: isFocusedDoc ? '#00A3E0' : 'rgba(255, 255, 255, 0.4)' 
                }}
              >
                alternate_email
              </span>
              <input
                id="login-documento"
                type="text"
                className="bcp-input"
                value={documento}
                onChange={e => setDocumento(e.target.value)}
                onFocus={() => setIsFocusedDoc(true)}
                onBlur={() => setIsFocusedDoc(false)}
                placeholder="ej: admin@bcp.com.pe o ADM001"
                autoComplete="username"
                required
              />
            </div>
          </div>

          <div style={s.formGroup}>
            <label style={s.formLabel}>Clave de Acceso</label>
            <div style={s.inputWrapper}>
              <span 
                className="material-icons-round" 
                style={{ 
                  ...s.inputIcon, 
                  color: isFocusedPass ? '#00A3E0' : 'rgba(255, 255, 255, 0.4)' 
                }}
              >
                lock
              </span>
              <input
                id="login-password"
                type={showPass ? 'text' : 'password'}
                className="bcp-input"
                style={{ paddingRight: '48px' }}
                value={password}
                onChange={e => setPassword(e.target.value)}
                onFocus={() => setIsFocusedPass(true)}
                onBlur={() => setIsFocusedPass(false)}
                placeholder="••••••••"
                autoComplete="current-password"
                required
              />
              <button
                type="button"
                onClick={() => setShowPass(v => !v)}
                style={s.eyeBtn}
              >
                <span className="material-icons-round" style={{ fontSize: '18px', color: 'rgba(255, 255, 255, 0.4)' }}>
                  {showPass ? 'visibility_off' : 'visibility'}
                </span>
              </button>
            </div>
          </div>

          <button
            id="login-submit"
            type="submit"
            className="bcp-btn"
            disabled={isLoading}
          >
            {isLoading ? (
              <>
                <div style={s.spinner} />
                <span>Verificando credenciales...</span>
              </>
            ) : (
              <>
                <span className="material-icons-round" style={{ fontSize: '20px' }}>security</span>
                <span>Ingresar al Portal BCP</span>
              </>
            )}
          </button>
        </form>

        {/* Divider */}
        <div style={s.divider} />

        {/* Demo credentials hint */}
        <div style={s.demoHint}>
          <div style={s.demoHintHeader}>
            <span className="material-icons-round" style={{ fontSize: '16px', color: '#FF6B00' }}>lightbulb</span>
            <span style={{ fontWeight: '600', color: 'rgba(255,255,255,0.7)' }}>Credenciales Demo:</span>
          </div>
          <div style={s.demoCredsGrid}>
            <div style={s.demoCredRow}>
              <span style={s.demoLabel}>Admin (Email):</span>
              <code style={s.demoCode} onClick={() => setDocumento('admin@bcp.com.pe')}>admin@bcp.com.pe</code>
            </div>
            <div style={s.demoCredRow}>
              <span style={s.demoLabel}>Admin (Código):</span>
              <code style={s.demoCode} onClick={() => setDocumento('ADM001')}>ADM001</code>
            </div>
            <div style={s.demoCredRow}>
              <span style={s.demoLabel}>Clave:</span>
              <code style={s.demoCode}>123456</code>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

const s = {
  root: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: '100vh',
    width: '100vw',
    overflow: 'hidden',
    position: 'relative',
    backgroundColor: '#030814', // Sleek ultra-dark BCP navy base
    fontFamily: "'Inter', sans-serif",
  },
  blob1: {
    position: 'absolute',
    width: '600px',
    height: '600px',
    top: '-150px',
    left: '-100px',
    background: 'radial-gradient(circle, rgba(0, 42, 84, 0.3) 0%, transparent 70%)',
    borderRadius: '50%',
    zIndex: 0,
    pointerEvents: 'none',
    animation: 'float-blob-1 25s infinite alternate ease-in-out',
  },
  blob2: {
    position: 'absolute',
    width: '500px',
    height: '500px',
    bottom: '-100px',
    right: '-100px',
    background: 'radial-gradient(circle, rgba(255, 107, 0, 0.12) 0%, transparent 70%)',
    borderRadius: '50%',
    zIndex: 0,
    pointerEvents: 'none',
    animation: 'float-blob-2 20s infinite alternate ease-in-out',
  },
  blob3: {
    position: 'absolute',
    width: '400px',
    height: '400px',
    top: '30%',
    left: '50%',
    background: 'radial-gradient(circle, rgba(0, 163, 224, 0.1) 0%, transparent 60%)',
    borderRadius: '50%',
    zIndex: 0,
    pointerEvents: 'none',
    animation: 'float-blob-3 30s infinite alternate ease-in-out',
  },
  cardGlow: {
    position: 'absolute',
    width: '460px',
    height: '580px',
    background: 'linear-gradient(135deg, rgba(0, 61, 122, 0.15) 0%, rgba(255, 107, 0, 0.05) 100%)',
    borderRadius: '32px',
    filter: 'blur(50px)',
    zIndex: 1,
    pointerEvents: 'none',
  },
  formCard: {
    width: '100%',
    maxWidth: '450px',
    background: 'rgba(13, 23, 42, 0.65)', // Glassmorphism layer
    backdropFilter: 'blur(30px)',
    WebkitBackdropFilter: 'blur(30px)',
    border: '1px solid rgba(255, 255, 255, 0.08)',
    borderRadius: '24px',
    padding: '44px 38px',
    boxShadow: '0 24px 60px rgba(0, 0, 0, 0.45), inset 0 1px 0 rgba(255, 255, 255, 0.06)',
    zIndex: 2,
  },
  formHeader: { 
    marginBottom: '32px', 
    textAlign: 'center',
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
  },
  formLogoRow: {
    display: 'flex',
    alignItems: 'center',
    gap: '12px',
    marginBottom: '20px',
  },
  formBcpBadge: {
    background: '#FF6B00',
    color: '#fff',
    fontFamily: "'Outfit', sans-serif",
    fontWeight: '900',
    fontSize: '18px',
    padding: '6px 14px',
    borderRadius: '8px',
    letterSpacing: '1px',
    boxShadow: '0 4px 12px rgba(255,107,0,0.3)',
  },
  formBcpLabel: { 
    textAlign: 'left' 
  },
  formBcpName: { 
    fontSize: '15px', 
    fontWeight: '700', 
    color: '#fff', 
    lineHeight: 1.2 
  },
  formBcpSub: { 
    fontSize: '12px', 
    color: '#637899',
    fontWeight: '500',
  },
  formTitle: { 
    fontSize: '1.6rem', 
    color: '#fff', 
    marginBottom: '6px',
    fontFamily: "'Outfit', sans-serif",
    fontWeight: '700',
    letterSpacing: '-0.02em',
  },
  formSubtitle: { 
    fontSize: '13px', 
    color: 'rgba(255,255,255,0.4)',
    fontWeight: '400',
    lineHeight: '1.4',
    maxWidth: '300px',
  },
  formGroup: {
    marginBottom: '22px',
  },
  formLabel: {
    display: 'block',
    fontSize: '12px',
    fontWeight: '600',
    color: 'rgba(255, 255, 255, 0.65)',
    marginBottom: '8px',
    textTransform: 'uppercase',
    letterSpacing: '0.05em',
  },
  inputWrapper: { 
    position: 'relative', 
    display: 'flex', 
    alignItems: 'center',
    width: '100%',
  },
  inputIcon: {
    position: 'absolute',
    left: '14px',
    fontSize: '20px',
    zIndex: 1,
    pointerEvents: 'none',
    transition: 'color 0.25s ease',
  },
  eyeBtn: {
    position: 'absolute',
    right: '12px',
    background: 'none',
    border: 'none',
    cursor: 'pointer',
    padding: '4px',
    display: 'flex',
    alignItems: 'center',
    zIndex: 1,
    borderRadius: '4px',
    transition: 'background 0.2s',
  },
  spinner: {
    width: '18px',
    height: '18px',
    border: '2px solid rgba(255, 255, 255, 0.2)',
    borderTop: '2px solid #fff',
    borderRadius: '50%',
    animation: 'spin 0.8s linear infinite',
  },
  errorAlert: {
    background: 'rgba(255, 74, 74, 0.1)',
    border: '1px solid rgba(255, 74, 74, 0.2)',
    borderRadius: '12px',
    padding: '12px 16px',
    display: 'flex',
    alignItems: 'center',
    gap: '12px',
    marginBottom: '24px',
  },
  divider: {
    height: '1px',
    background: 'rgba(255, 255, 255, 0.08)',
    margin: '28px 0',
  },
  demoHint: {
    background: 'rgba(255, 255, 255, 0.02)',
    border: '1px solid rgba(255, 255, 255, 0.05)',
    borderRadius: '12px',
    padding: '16px',
  },
  demoHintHeader: {
    display: 'flex',
    alignItems: 'center',
    gap: '8px',
    fontSize: '13px',
    marginBottom: '12px',
  },
  demoCredsGrid: {
    display: 'flex',
    flexDirection: 'column',
    gap: '8px',
  },
  demoCredRow: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    fontSize: '12px',
  },
  demoLabel: {
    color: 'rgba(255, 255, 255, 0.45)',
  },
  demoCode: {
    fontFamily: "monospace",
    color: '#00A3E0',
    background: 'rgba(0, 163, 224, 0.1)',
    padding: '3px 8px',
    borderRadius: '6px',
    cursor: 'pointer',
    fontWeight: 'bold',
    transition: 'all 0.2s',
  },
};
