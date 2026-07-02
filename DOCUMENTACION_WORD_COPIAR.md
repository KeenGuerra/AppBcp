# DOCUMENTACIÓN COMPLETA DEL PROYECTO: ECOSISTEMA BANCARIO INTEGRADO BCP

Este documento consolidado contiene toda la información de despliegue, arquitectura, flujos, credenciales e interfaz técnica del proyecto. Está estructurado y formateado para ser copiado y pegado directamente en un documento de Microsoft Word.

---

## 1. DATOS GENERALES Y ENLACES DE DESPLIEGUE

### Enlaces de Aplicaciones y Servicios
* **URL_FRONT_CORE (Portal Administrativo Web):** https://bcp-mobile-core-webadmin.onrender.com
* **URL_BACK_CORE (FastAPI Backend Core):** https://bcp-mobile-core-backend.onrender.com
* **LINK_DOCUMENTACION:** https://github.com/KeenGuerra/AppBcp/blob/main/README.md
* **APP_FVENTAS_APK_LINK (APK Único Multirrol):** *[Insertar enlace de Google Drive aquí tras subir el archivo "app-release.apk"]*
* **APP_CLIENTES_APK_LINK (APK Único Multirrol):** *[Insertar enlace de Google Drive aquí tras subir el archivo "app-release.apk"]*

*Nota: La aplicación móvil (App Clientes y App Fuerza de Ventas) está consolidada en un único APK multirrol que cambia su interfaz y permisos dinámicamente según el rol del usuario que inicia sesión.*

### Enlaces de Repositorios GitHub
* **GITHUB_FRONT_CORE (Módulo Web Admin):** https://github.com/KeenGuerra/AppBcp/tree/main/web_admin_bcp
* **GITHUB_BACK_CORE (Módulo FastAPI Backend):** https://github.com/KeenGuerra/AppBcp/tree/main/backend_core_mobile
* **APP_FVENTAS_LINK_GITHUB (Módulo Mobile Flutter):** https://github.com/KeenGuerra/AppBcp/tree/main/mobile_app_bcp
* **APP_CLIENTES_LINK_GITHUB (Módulo Mobile Flutter):** https://github.com/KeenGuerra/AppBcp/tree/main/mobile_app_bcp

---

## 2. CREDENCIALES DE PRUEBA POR ROL

El sistema cuenta con datos semilla de demostración precargados en la base de datos de Supabase. A continuación se presentan las credenciales para probar los distintos flujos y portales:

| Rol de Usuario | Código de Usuario / DNI | Contraseña de Demo | Permisos y Pantallas |
| :--- | :--- | :--- | :--- |
| **Cliente** | `41884031` (o `40118120`) | `123456` | Homebanking, Cuentas, Transferencias, Solicitar Créditos, Visualizar Cronogramas de Pago. |
| **Asesor (Fuerza de Ventas)** | `A001` (o `A002`) | `123456` | Cartera diaria de clientes, Registro de Visitas con GPS, Preevaluación financiera, Buró simulación, Carga de documentos, Firma digital y Envío a comité. |
| **Supervisor (Comité)** | `SUP001` | `123456` | Bandeja del Comité de Crédito, Evaluación detallada de expedientes, Aprobación, Condicionamiento, Rechazo y Desembolso financiero. |
| **Administrador** | `ADM001` | `123456` | Gestión completa de usuarios y roles, visualización del historial de sincronización (Sync Log), administración de productos de crédito. |

---

## 3. ARQUITECTURA GENERAL DEL SISTEMA

El ecosistema está construido bajo un enfoque **monorepo** y estructurado en capas para garantizar la escalabilidad, la seguridad y el soporte sin conexión.

```
                  ┌──────────────────────────────┐
                  │   Aplicación Móvil Flutter   │
                  │ (Cliente / Asesor / Superv.) │
                  └──────────────┬───────────────┘
                                 │
                                 ▼ (Llamadas API REST cifradas con JWT)
                  ┌──────────────────────────────┐
                  │      Core Backend FastAPI    │
                  │   (Lógica central, Reglas)   │
                  └──────────────┬───────────────┘
                                 │
                                 ▼ (Supabase SDK Client / REST HTTPS)
                  ┌──────────────────────────────┐
                  │    Supabase Cloud Database   │
                  │  (Tablas core, mirror, sync) │
                  └──────────────┬───────────────┘
                                 │
                                 ▼ (Sincronización Transaccional)
                  ┌──────────────────────────────┐
                  │     Portal Web React Admin   │
                  │  (Supervisores y Admins)     │
                  └──────────────────────────────┘
```

### Componentes de Software
1. **Frontend Móvil (Flutter):** Una sola aplicación nativa estructurada por "Features" (Clean Architecture). Implementa persistencia local en **SQLite** para trabajar en modalidad offline-first en zonas de baja conectividad.
2. **Core Backend (FastAPI):** Expone endpoints RESTful protegidos por tokens JWT. Gestiona la lógica de negocio, las consultas simuladas a la central de riesgo (Buró) y los cálculos del cronograma de pagos mediante amortización francesa.
3. **Base de Datos (Supabase PostgreSQL):** Base de datos en la nube. Cuenta con tablas principales, vistas agregadas para dashboards y tablas espejo (`cr_*`) integradas con un motor de eventos de sincronización (`sync_outbox` y `sync_log`).
4. **Portal Administrativo Web (React + Vite):** Panel administrativo de escritorio optimizado para la gestión del comité de créditos, supervisores de campo y administradores de TI.

---

## 4. FLUJO DE CRÉDITO END-TO-END (PASO A PASO)

El flujo integrado de originación, evaluación y desembolso de créditos sigue la siguiente secuencia de eventos:

```
[Cliente]           [FastAPI Core]         [Asesor]          [Supervisor/Comité]        [Core / DB]
   │                      │                    │                      │                     │
   ├─► Solicita Crédito──►│                    │                      │                     │
   │   (S/ 1,000 / 12m)   │                    │                      │                     │
   │                      ├─► Asigna Asesor ──►│                      │                     │
   │                      │   en Cartera Hoy   │                      │                     │
   │                      │                    ├─► Registra Visita ──►│                     │
   │                      │                    │   GPS, Buró, Firma   │                     │
   │                      │                    │   y Envía a Comité   │                     │
   │                      │                    │                      ├─► Aprueba Crédito ──┤
   │                      │                    │                      │   y Desembolsa      │
   │                      │                    │                      │                     ├─► Genera crédito,
   │                      │                    │                      │                     │   cronograma, movs.
   │                      │                    │                      │                     │   y notifica cliente
   │◄─────────────────────┴────────────────────┴──────────────────────┴─────────────────────┤
   │
   ├─► Visualiza Crédito Desembolsado
   ├─► Consulta Cronograma de Cuotas (Amortización Francesa)
   └─► Visualiza Movimiento en Cuenta de Ahorros
```

### Descripción del Flujo Operativo
1. **Registro:** El cliente ingresa a su dashboard móvil de Homebanking y completa una solicitud de crédito comercial (Monto: S/ 1,000, Plazo: 12 meses). Se genera un expediente con código único en estado `ENVIADO`.
2. **Asignación:** El backend FastAPI recibe la solicitud, escribe en `sync_outbox` y la asigna automáticamente a la cartera diaria del asesor correspondiente.
3. **Evaluación de Campo:** El asesor ingresa con sus credenciales y ve la solicitud en su lista de tareas. Registra la visita de verificación física capturando la ubicación GPS, ejecuta una preevaluación financiera en el dispositivo y consulta la simulación de buró de crédito. Si todo es conforme, captura la firma digital del cliente y envía el expediente al comité.
4. **Comité:** El supervisor de riesgos visualiza el expediente completo desde su portal y decide **Aprobar** y luego **Desembolsar** el crédito.
5. **Desembolso Central:** La API de desembolso actualiza el estado del expediente a `DESEMBOLSADO`, crea el crédito en las tablas financieras del core (`cr_creditos`), genera el cronograma de pagos correspondiente y deposita el capital en la cuenta de ahorros del cliente creando un movimiento bancario tipo `DESEMBOLSO_CREDITO`.
6. **Consulta:** El cliente recibe una notificación en su teléfono y puede visualizar inmediatamente su nuevo saldo en cuenta de ahorros, el movimiento del desembolso y el cronograma detallado de cuotas mensuales.

---

## 5. DISEÑO DE BASE DE DATOS Y TABLAS CLAVE

El modelo de datos relacional asegura la integridad transaccional mediante llaves foráneas y consistencia referencial:

* **`usuarios`**: Almacena los registros de autenticación del sistema (DNI/código, nombres, hash de clave con bcrypt, estado, rol).
* **`clientes`**: Información personal y corporativa de los clientes, vinculada a su cuenta de ahorros.
* **`asesores`**: Registro de la fuerza de ventas y asesores comerciales de campo.
* **`solicitudes_credito`**: Almacena los datos de originación (código expediente, monto, plazo, estado actual).
* **`visitas`**: Registro georreferenciado de las visitas de campo efectuadas por los asesores (latitud, longitud, comentarios).
* **`documentos_credito` / `firmas_credito`**: Enlaces de almacenamiento de expedientes, firmas y PDFs.
* **`cr_creditos`**: Información del producto financiero activo tras el desembolso (monto desembolsado, tasa TEA, saldo pendiente).
* **`cr_cronograma_pagos`**: Plan de cuotas generado con amortización francesa.
* **`cr_movimientos`**: Registro contable de abonos, cargos y transferencias.
* **`sync_outbox` / `sync_log`**: Cola transaccional para el mantenimiento del flujo offline-first y la auditoría de eventos de sincronización del Core.

---

## 6. TASAS DE INTERÉS Y FÓRMULAS FINANCIERAS

El sistema gestiona tanto operaciones activas (créditos) como pasivas (ahorros/depósitos a plazo) aplicando las siguientes tasas y metodologías de cálculo financiero:

### 6.1. Tasas de Interés Aplicadas por Producto

1. **Crédito Empresarial Microempresa:**
   * **TEA con Seguro de Desgravamen:** 40.92% (Tasa Efectiva Anual)
   * **TEA sin Seguro de Desgravamen:** 43.90% (según base de datos demo / referenciado como 43.92% en documentación técnica)
2. **Crédito Consumo Personal:**
   * **TEA con Seguro de Desgravamen:** 45.00%
   * **TEA sin Seguro de Desgravamen:** 42.00%
3. **Depósito a Plazo Fijo (Ahorro):**
   * **Plazo 30 días:** 3.00% (TEA)
   * **Plazo 60 días:** 4.00% (TEA)
   * **Plazo 90 días:** 5.00% (TEA)
   * **Plazo 180 días:** 6.50% (TEA)
   * **Plazo 360 días:** 8.00% (TEA)

### 6.2. Metodología de Créditos (Sistema de Amortización Francesa)

Las cuotas estimadas de preevaluación y los cronogramas reales generados en el desembolso emplean las siguientes fórmulas matemáticas:

* **Conversión de TEA a TEM (Tasa Efectiva Mensual):**
  $$TEM = (1 + TEA)^{1/12} - 1$$
  *Fórmula en código Python:* `tem_f = math.pow(1.0 + tea_f, 1.0 / 12.0) - 1.0`

* **Cálculo de Cuota Mensual Constante (Método Francés):**
  $$Cuota = \frac{Monto \times TEM}{1 - (1 + TEM)^{-Plazo}}$$
  *Fórmula en código Python:* `cuota_f = (monto_f * tem_f) / (1.0 - math.pow(1.0 + tem_f, -plazo_meses))`

* **Desglose de cada Cuota (Amortización mensual):**
  * **Interés del periodo:** $Interés = SaldoActual \times TEM$
  * **Amortización de Capital:** $Capital = Cuota - Interés$
  * **Nuevo Saldo Pendiente:** $SaldoNuevo = SaldoActual - Capital$

### 6.3. Metodología de Depósitos a Plazo Fijo (Interés Simple)

Para los depósitos a plazo fijo, el cálculo de intereses al vencimiento se efectúa mediante la siguiente relación:

* **Interés Estimado al Vencimiento:**
  $$Interés = Monto \times \left(\frac{Tasa}{100}\right) \times \left(\frac{PlazoDías}{365}\right)$$

* **Monto Total a Recibir:**
  $$MontoFinal = Monto + Interés$$

---
*Fin del documento de documentación del sistema.*
