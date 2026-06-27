# BCP Mobile Core 360 - Architecture Documentation

This document describes the high-level architecture, component communication, end-to-end data flows, and database relationships of the **BCP Mobile Core 360** ecosystem.

---

## 1. High-Level Component Architecture

The ecosystem consists of a multi-role Flutter application, an offline-first cache engine, a REST API built with FastAPI, and a database layer powered by PostgreSQL.

```mermaid
graph TD
    %% Frontend Components
    subgraph Frontend [Ecosistema de Cliente]
        UI[Flutter Presentation UI]
        RP[Riverpod State Managers]
        GR[GoRouter Router]
        DC[Dio Client with Auth Interceptor]
        SQ[SQLite Database / Offline Cache]
        CS[Connectivity Service]
        
        WA[React Web Admin Panel]
        AX[Axios REST Client]
    end

    %% Backend Services
    subgraph Backend [FastAPI core backend]
        API[FastAPI Router Endpoints]
        REP[Repository Layer]
        AM[French Amortization Service]
        PE[Preevaluation Engine]
        SU[Outbox Sync Service]
    end

    %% Database Layer
    subgraph Storage [Database]
        DB[(PostgreSQL Database)]
    end

    %% Flow Relations
    UI --> GR
    UI --> RP
    RP --> DC
    RP --> SQ
    CS --> SQ
    DC --> CS
    DC -- "HTTP REST / HTTPS" --> API
    
    WA --> AX
    AX -- "HTTP REST / HTTPS" --> API
    
    API --> PE
    API --> AM
    API --> SU
    API --> REP
    REP --> DB
```

---

## 2. End-to-End Credit Pipeline Sequence Flow

This sequence diagram illustrates the entire pipeline, from a credit request to automated advisor assignment, pre-evaluation, central risk scoring, committee review, disbursement, amortization schedule creation, and client payment.

```mermaid
sequenceDiagram
    autonumber
    actor C as Cliente
    actor A as Asesor de Negocios
    actor S as Supervisor / Comité
    participant APP as App Flutter (Offline/Online)
    participant API as FastAPI Backend
    participant DB as PostgreSQL DB

    %% Step 1: Client submits or Advisor submits request
    C->>APP: Solicitar Crédito (Banca Móvil)
    APP->>API: POST /cliente/solicitudes (monto, plazo, garantía)
    API->>DB: Insert Solicitud (estado=PENDIENTE)
    DB-->>API: Solicitud registrada
    Note over API,DB: Auto-Assignment Engine activates.<br/>Assigns nearest/available advisor to client.
    API-->>APP: Solicitud Creada (Asignado a Asesor)
    APP-->>C: Confirmación de envío

    %% Step 2: Advisor visits the business
    A->>APP: Ver Cartera de Hoy (Offline/Online)
    APP->>API: GET /fventas/cartera/hoy (if online)
    API->>DB: Fetch assigned portfolio
    DB-->>API: Portfolio data
    API-->>APP: Portfolio list
    Note over A, APP: If offline, advisor views cached<br/>portfolio in local SQLite database.
    A->>APP: Registrar Visita (GPS coordinates + Sign)
    APP->>API: POST /fventas/visitas (Online)
    Note over APP, API: If offline, saves to SQLite.<br/>Syncs automatically on network recovery.
    API->>DB: Insert Visita & Update Cartera (REALIZADA)
    API-->>APP: Visita Guardada

    %% Step 3: Originator Stepper (Preevaluation & Bureau)
    A->>APP: Iniciar Originación Stepper (monto, plazo)
    A->>APP: Trigger Preevaluación Financiera
    APP->>API: POST /fventas/solicitudes/{id}/preevaluar
    Note over API: Evaluates client business income vs expense.<br/>Applies 30% DTI (Debt-to-Income) check.
    API->>DB: Update Solicitud Score
    API-->>APP: Resultado: APTO / NO APTO (Cuota estim.)
    
    A->>APP: Trigger Consulta Central de Riesgo
    APP->>API: POST /fventas/solicitudes/{id}/buro
    Note over API: Queries simulated Credit Bureau.<br/>Blocks if score shows high defaults.
    API->>DB: Update Solicitud Buro score
    API-->>APP: Resultado: APROBADO / RECHAZADO

    A->>APP: Capture Client Digital Signature & Submit
    APP->>API: POST /fventas/solicitudes/{id}/enviar-comite (Signature Base64)
    API->>DB: Update Solicitud (estado=ENVIADO)
    API-->>APP: Expediente enviado a Comité

    %% Step 4: Committee Approval & Disbursement
    S->>APP: Ver Bandeja de Comité
    APP->>API: GET /comite/solicitudes
    API->>DB: Fetch requests (estado=ENVIADO)
    DB-->>API: Solicitudes list
    API-->>APP: Display bandeja
    S->>APP: Aprobar Crédito (Monto Aprobado)
    APP->>API: POST /comite/solicitudes/{id}/aprobar (monto_aprobado)
    API->>DB: Update Solicitud (estado=APROBADO, monto_aprobado)
    API-->>APP: Confirmación de aprobación
    
    S->>APP: Click Desembolsar
    APP->>API: POST /comite/solicitudes/{id}/desembolsar
    Note over API: Core banking logic runs:<br/>1. Credits approved funds to client's account.<br/>2. Generates French Amortization Schedule.<br/>3. Updates status to DESEMBOLSADO.<br/>4. Writes Sync Outbox event.
    API->>DB: Update Solicitud (DESEMBOLSADO), Insert Crédito, Cuotas, Movimiento
    API-->>APP: ¡Crédito Desembolsado Exitosamente!

    %% Step 5: Client views and pays
    C->>APP: Ver Cuentas y Cronograma de Crédito
    APP->>API: GET /cliente/creditos/{id}/cronograma
    API->>DB: Fetch amortization schedule (Cuotas)
    DB-->>API: Amortization schedule list
    API-->>APP: Display French Schedule
    C->>APP: Pagar Cuota 1
    APP->>API: POST /cliente/operaciones/pago-credito (monto, cuota#)
    Note over API: Debits savings account & credits loan account.<br/>Updates installment status to PAGADA.
    API->>DB: Update Cuota (PAGADA), Debit Account, Insert Movimiento
    API-->>APP: Pago registrado
    APP-->>C: Comprobante de pago exitoso
```

---

## 3. Database Entity-Relationship Diagram (ERD)

This section maps the relational design of the database. Primary keys are UUIDs, and foreign keys strictly enforce cascading rules.

```mermaid
erDiagram
    usuarios {
        uuid id_usuario PK
        string documento UK
        string codigo_empleado UK
        string correo UK
        string password_hash
        string rol
        string estado
        int intentos_fallidos
        timestamp bloqueado_hasta
        timestamp created_at
        timestamp updated_at
    }

    clientes {
        uuid id_cliente PK
        uuid id_usuario FK
        string documento UK
        string nombres
        string apellidos
        string telefono
        string correo
        string direccion
        string distrito
        string provincia
        string departamento
        date fecha_nacimiento
        string estado_civil
        string ocupacion
        string tipo_cliente
        timestamp created_at
    }

    negocios {
        uuid id_negocio PK
        uuid id_cliente FK
        string ruc
        string nombre_comercial
        string actividad_economica
        string direccion
        decimal ingreso_mensual
        decimal gasto_mensual
        timestamp created_at
    }

    asesores {
        uuid id_asesor PK
        uuid id_usuario FK
        string codigo_empleado UK
        string nombres
        string apellidos
        string agencia
        string estado
        timestamp created_at
    }

    cuentas_ahorro {
        uuid id_cuenta PK
        uuid id_cliente FK
        string numero_cuenta UK
        string cci UK
        string moneda
        decimal saldo_disponible
        decimal saldo_contable
        string estado
        timestamp created_at
    }

    tarjetas_debito {
        uuid id_tarjeta PK
        uuid id_cuenta FK
        string numero_enmascarado
        string token_seguridad
        string estado
        string fecha_vencimiento
        timestamp created_at
    }

    productos_credito {
        uuid id_producto_credito PK
        string codigo UK
        string nombre
        string tipo
        decimal tea_con_seguro
        decimal tea_sin_seguro
        decimal monto_minimo
        decimal monto_maximo
        int plazo_minimo
        int plazo_maximo
        string moneda
        string estado
        timestamp created_at
    }

    solicitudes_credito {
        uuid id_solicitud PK
        uuid id_cliente FK
        uuid id_negocio FK
        uuid id_producto_credito FK
        uuid id_asesor_asignado FK
        string numero_expediente UK
        decimal monto_solicitado
        decimal monto_aprobado
        int plazo_meses
        boolean con_seguro_desgravamen
        string garantia
        string destino_credito
        string estado
        string resultado_preevaluacion
        int puntaje_preevaluacion
        string resultado_buro
        string calificacion_buro
        string firma_cliente_base64
        decimal lat_captura
        decimal lng_captura
        string observacion_rechazo
        string condicion_aprobacion
        timestamp created_at
        timestamp updated_at
    }

    cartera_diaria {
        uuid id_cartera PK
        uuid id_asesor FK
        uuid id_cliente FK
        uuid id_solicitud FK
        timestamp fecha_asignacion
        string tipo_gestion
        string prioridad
        int score_prioridad
        string estado_visita
        string resultado_visita
        string observacion_visita
        decimal lat_visita
        decimal lng_visita
        timestamp timestamp_visita
        timestamp created_at
    }

    creditos {
        uuid id_credito PK
        uuid id_solicitud FK
        uuid id_cliente FK
        uuid id_cuenta_desembolso FK
        string numero_credito UK
        decimal monto_desembolsado
        decimal saldo_capital
        decimal tea
        int plazo_meses
        decimal cuota_mensual
        string estado
        timestamp created_at
        timestamp updated_at
    }

    cronograma_pagos {
        uuid id_cuota PK
        uuid id_credito FK
        int numero_cuota
        date fecha_pago
        decimal monto_cuota
        decimal amortizacion
        decimal interes
        decimal seguro_desgravamen
        decimal saldo_remanente
        string estado
        timestamp fecha_pagado
        timestamp created_at
    }

    movimientos_cuenta {
        uuid id_movimiento PK
        uuid id_cuenta FK
        string tipo_operacion
        decimal monto
        string descripcion
        timestamp fecha_movimiento
    }

    sync_outbox {
        uuid id_sync PK
        string tipo_evento
        string id_registro_referencia
        string payload
        string estado
        int reintentos
        timestamp created_at
        timestamp updated_at
    }

    sync_logs {
        uuid id_log PK
        timestamp fecha_sincronizacion
        string origen_datos
        boolean exito
        string mensaje_respuesta
    }

    usuarios ||--o| clientes : "tiene"
    usuarios ||--o| asesores : "tiene"
    clientes ||--o{ negocios : "posee"
    clientes ||--o{ cuentas_ahorro : "posee"
    cuentas_ahorro ||--o{ tarjetas_debito : "vincula"
    clientes ||--o{ solicitudes_credito : "solicita"
    negocios ||--o{ solicitudes_credito : "sustenta"
    productos_credito ||--o{ solicitudes_credito : "aplica"
    asesores ||--o{ solicitudes_credito : "evalúa"
    asesores ||--o{ cartera_diaria : "gestiona"
    clientes ||--o{ cartera_diaria : "visita"
    solicitudes_credito ||--o{ cartera_diaria : "origina"
    solicitudes_credito ||--o| creditos : "desembolsa"
    creditos ||--o{ cronograma_pagos : "genera"
    cuentas_ahorro ||--o{ movimientos_cuenta : "registra"
