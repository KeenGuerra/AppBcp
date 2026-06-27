# BCP Mobile Core 360 - User Stories, Testing & Rubric Checklist

This document details the user stories, automated/manual test scenarios, and the evaluation rubric checklist confirming the requirements of the BCP Mobile Core 360 system.

---

## 1. User Stories by Role

### Cliente (Homebanking Channel)
*   **US-1.1: Visualizar Cuentas y Saldos:** Como cliente, quiero ver mis cuentas de ahorro activas, códigos CCI y saldos actualizados en soles desde la pantalla de inicio, para llevar control de mis finanzas.
*   **US-1.2: Solicitar Préstamo Instantáneo:** Como cliente, quiero enviar una solicitud de crédito especificando monto y plazo desde mi banca móvil, para que sea evaluada y asignada a un asesor.
*   **US-1.3: Visualizar Cronograma Francés:** Como cliente, quiero ver el cronograma de cuotas (interés, amortización, seguro) de mis préstamos vigentes y descargar/ver el cronograma detallado para planificar mis pagos.
*   **US-1.4: Realizar Operaciones (Transferencias y Pago de Deuda):** Como cliente, quiero transferir dinero a otras cuentas BCP y pagar mis cuotas mensuales directamente debitando mi saldo disponible.

### Asesor de Negocios (Fuerza de Ventas)
*   **US-2.1: Gestión de Cartera Diaria (Offline-First):** Como asesor, quiero poder visualizar en mi celular los clientes asignados para visita de hoy, incluso si estoy en zonas sin cobertura de internet (cargado desde SQLite).
*   **US-2.2: Captura GPS y Reporte de Visitas:** Como asesor, quiero registrar el resultado de mis visitas de campo capturando la ubicación GPS y las observaciones del local comercial.
*   **US-2.3: Originación Stepper Digital:** Como asesor, quiero guiar al cliente por un flujo estructurado de pasos (stepper) que evalúe la solicitud (pre-evaluación DTI de 30% y consulta central de riesgo), cargue fotografías y recopile la firma táctil de conformidad.
*   **US-2.4: Cola de Sincronización Automática:** Como asesor, quiero que las visitas y solicitudes guardadas en el modo offline de mi celular se transmitan al Core del banco de forma transparente cuando el dispositivo recupere la señal.

### Supervisor (Comité y Desembolso)
*   **US-3.1: Bandeja de Evaluación del Comité:** Como supervisor, quiero revisar el expediente de solicitudes enviadas por los asesores, incluyendo los estados financieros, la calificación del buró de crédito, los documentos cargados y la firma del cliente.
*   **US-3.2: Aprobación y Rechazo de Expedientes:** Como supervisor, puedo aprobar el crédito definiendo un monto aprobado y condiciones, o rechazarlo especificando el motivo del descarte.
*   **US-3.3: Desembolso Automático:** Como supervisor, quiero desembolsar las solicitudes aprobadas con un solo botón, depositando los fondos en la cuenta de ahorros del cliente y creando el crédito activo.

### Administrador (Configuración y Monitoreo)
*   **US-4.1: Gestión de Usuarios:** Como administrador, quiero crear, actualizar y bloquear/desbloquear usuarios para controlar el acceso a la plataforma según sus roles.
*   **US-4.2: Gestión de Productos Financieros:** Como administrador, quiero registrar nuevos productos de crédito configurando los límites de monto, plazo y tasas de interés (TEA).
*   **US-4.3: Auditoría y Control del Sync Outbox:** Como administrador, quiero ver la lista de eventos en cola (Outbox) y los registros de logs para verificar que la información se sincronice correctamente entre sistemas y forzar el procesamiento manual de ser necesario.

---

## 2. End-to-End Verification Scenarios

This testing checklist guides the manual walkthrough of the complete loan lifecycle.

### Escenario E2E: Flujo de Crédito de Negocios BCP

| Paso | Rol / Actor | Operación / Pantalla | Datos de Entrada | Resultado Esperado | Endpoints Afectados |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | Administrador | Crear Producto de Crédito | Código: `PROD_MICRO_SOL`<br>TEA: 45.0%<br>Monto: S/ 1,000 - S/ 50,000 | El producto queda guardado en la base de datos y disponible en el catálogo. | `POST /admin/productos-creditos` |
| **2** | Cliente | Iniciar sesión y Crear Solicitud | DNI: `40118120`<br>Clave: `123456`<br>Monto: S/ 5,000<br>Plazo: 12 meses | Solicitud se registra en estado `PENDIENTE`. El sistema de auto-asignación asigna automáticamente al Asesor A001. | `POST /auth/login`<br>`POST /cliente/solicitudes` |
| **3** | Asesor | Ver Cartera y Registrar Visita | Código Asesor: `A001`<br>Clave: `123456`<br>Registrar Visita GPS | Observación: "Negocio con buena mercadería. Ubicación verificada." | `GET /fventas/cartera/hoy`<br>`POST /fventas/visitas` |
| **4** | Asesor | Ejecutar Originación Stepper | Seleccionar Cliente `40118120`<br>Monto: S/ 5,000<br>Plazo: 12 meses | **Preevaluación**: Resultado `APTO`, calcula cuota mensual estimada.<br>**Buró**: Calificación `NORMAL`, Dictamen `APROBADO`. | `POST /fventas/solicitudes/{id}/preevaluar`<br>`POST /fventas/solicitudes/{id}/buro` |
| **5** | Asesor | Cargar Documentos, Firmar y Enviar | Simular fotos de DNI/Local.<br>Dibujar firma táctil.<br>Enviar a Comité. | El expediente se completa y pasa a estado `ENVIADO`. Firma guardada en Base64. | `POST /fventas/solicitudes/{id}/firma`<br>`POST /fventas/solicitudes/{id}/enviar-comite` |
| **6** | Supervisor | Evaluar y Aprobar Expediente | Código Supervisor: `SUP001`<br>Clave: `123456`<br>Ver Bandeja Comité | Aprobar con monto: S/ 5,000 | La solicitud pasa a estado `APROBADO` con monto y condiciones registradas. | `GET /comite/solicitudes`<br>`POST /comite/solicitudes/{id}/aprobar` |
| **7** | Supervisor | Desembolsar Crédito | Click en botón "Desembolsar" | Se realizan 3 acciones automáticas:<br>1. Dinero transferido a cuenta del cliente.<br>2. Se genera el cronograma francés.<br>3. Pasa a estado `DESEMBOLSADO`. | `POST /comite/solicitudes/{id}/desembolsar` |
| **8** | Cliente | Verificar Saldo y Cronograma | DNI: `40118120`<br>Ver Saldo de Cuenta e Historial | Saldo se incrementa en S/ 5,000. El cronograma muestra 12 cuotas amortizables con desglose correcto. | `GET /cliente/cuentas`<br>`GET /cliente/creditos/{id}/cronograma` |
| **9** | Cliente | Pagar Primera Cuota | Pagar Cuota 1 debitando S/ 478.00 (monto cuota aprox.) | Saldo disponible se reduce. La cuota 1 se marca como `PAGADA` con fecha del día. | `POST /cliente/operaciones/pago-credito` |

---

## 3. Rubric & Evaluation Checklist

This checklist confirms compliance with all constraints specified in the system requirement specification.

*   [x] **Role Separation & State Management**: Authentication separates `CLIENTE`, `ASESOR`, `SUPERVISOR`, and `ADMIN`. Handled dynamically via Riverpod `authProvider` and secured routes on GoRouter.
*   [x] **Security / Attempt-Based Lockout**: Backend limits password trials, locking after 5 failures for 30 minutes. Flutter auth_provider mirrors this lock local-side using SharedPreferences.
*   [x] **JWT Core Architecture**: All api calls go through a customized Dio client interceptor adding the Bearer token in headers. Unauthorized requests trigger redirect to login.
*   [x] **Offline-First Storage Engine**: SQLite tables handle daily portfolios, pending visits, pending credit files, and sync queue. Geolocation is simulated with local capture.
*   [x] **French Amortization Schedule Calculation**: Computed using the standard French formulas (constant annuity), with support for insurance (seguro desgravamen), monthly division of interests, and exact remaining balances.
*   [x] **Auditable Sync Logging**: `sync_outbox` captures transactional database triggers and outputs, while `sync_logs` writes sync events audit log visible to the administrator.
*   [x] **Python 3.14/Native Bcrypt Compatibility**: Backend bypassed `passlib` to secure compatibility with Python 3.14 by invoking native `bcrypt` calls.
*   [x] **Independent Web Admin App**: A dedicated React web portal was built in `web_admin_bcp` for managing the ecosystem without embedding administration screens in the client mobile app.

---

## 4. Testing the React Web Admin Portal

To launch and verify the separate Web Admin portal:
1. Open a new terminal inside the directory `d:\appbcp\web_admin_bcp`.
2. Start the local Vite development server:
   ```bash
   npm run dev
   ```
3. Open your browser to `http://localhost:5173`.
4. Log in with the credentials:
   * **Código de Empleado**: `ADM001`
   * **Clave**: `123456`
5. Test adding users, modifying credit products, and triggering manual outbox syncs.

