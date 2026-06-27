# README_IMPLEMENTACION_BCP_ECOSISTEMA

# BCP Ecosistema Bancario Integrado

**Proyecto End-to-End: Core Mobile + App Clientes + App Fuerza de Ventas + Web Administrativa**

---

# Objetivo General

Desarrollar un ecosistema bancario integrado para BCP que permita gestionar de forma completa el ciclo de vida de un crédito empresarial:

1. El cliente registra una solicitud desde su aplicación móvil.
2. El asesor recibe la solicitud en su cartera de trabajo.
3. El asesor realiza la visita y evaluación en campo.
4. El comité evalúa el expediente.
5. El Core genera el crédito y el desembolso.
6. El cliente visualiza su crédito, cronograma y movimientos en su aplicación.

Todo el ecosistema debe funcionar como un solo sistema compartiendo una única base de datos transaccional en Supabase.

---

# Arquitectura General

```text
Cliente / Asesor / Supervisor / Administrador
                    │
                    ▼
        App Móvil Flutter Única
                    │
                    ▼
        API REST FastAPI + Uvicorn
                    │
                    ▼
       Supabase PostgreSQL (Única BD)
                    │
                    ▼
Tablas Core + Tablas Espejo cr_* + Sync
                    │
                    ▼
          Web Administrativa React
```

---

# Tecnologías Obligatorias

## Backend

* Python 3.11+
* FastAPI
* Uvicorn
* Supabase Python SDK
* Pydantic
* Python-Jose
* Passlib + bcrypt
* Python-dotenv
* Python Multipart

---

## Frontend Web

* React
* Vite
* Axios
* React Router DOM
* Context API o Zustand

---

## Aplicación Móvil

* Flutter
* Dio o HTTP
* Flutter Secure Storage
* Provider o Riverpod
* SQLite local para soporte offline

---

## Base de Datos

* Supabase PostgreSQL
* Row Level Security (si aplica)
* Integridad referencial
* Índices optimizados
* Triggers y funciones SQL si es necesario

---

# Variables de Entorno Requeridas

Crear:

```text
backend/.env
```

Contenido:

```env
SUPABASE_URL=https://kawalgwszhtclarijjqg.supabase.co

SUPABASE_ANON_KEY=
COLOCAR_ANON_KEY

SUPABASE_SERVICE_ROLE_KEY=
COLOCAR_SERVICE_ROLE_KEY

JWT_SECRET_KEY=
GENERAR_CLAVE_SEGURA

JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=120

APP_NAME=BCP Core Mobile
ENVIRONMENT=development
```

---

# IMPORTANTE

El SERVICE ROLE jamás debe existir en:

* React
* Flutter
* Repositorio público
* Variables públicas

Debe utilizarse exclusivamente dentro del backend FastAPI.

Si la clave fue expuesta anteriormente:

1. Revocarla.
2. Generar una nueva.
3. Actualizar el .env.

---

# Estructura del Proyecto

```text
bcp-ecosistema-bancario/

backend/
│
├── app/
│   ├── main.py
│   ├── config.py
│   ├── database/
│   │   └── supabase_client.py
│   │
│   ├── auth/
│   ├── routes/
│   ├── services/
│   ├── repositories/
│   ├── schemas/
│   ├── middleware/
│   └── utils/
│
├── requirements.txt
└── .env


web-admin-react/
│
├── src/
│   ├── api/
│   ├── components/
│   ├── pages/
│   ├── hooks/
│   ├── context/
│   ├── routes/
│   └── assets/
│
└── .env


mobile-app-flutter/
│
├── lib/
│   ├── core/
│   ├── data/
│   ├── domain/
│   ├── presentation/
│   ├── routes/
│   ├── services/
│   ├── widgets/
│   └── main.dart


database/
│
├── schema_supabase.sql
├── seed_demo.sql
├── indexes.sql
├── triggers.sql
└── rls_policies.sql
```

---

# Instalación Backend

## Crear entorno virtual

```bash
python -m venv venv
```

Windows:

```bash
venv\Scripts\activate
```

Linux:

```bash
source venv/bin/activate
```

---

## Instalar dependencias

```bash
pip install fastapi
pip install uvicorn
pip install supabase
pip install python-dotenv
pip install python-jose
pip install passlib
pip install bcrypt
pip install pydantic
pip install email-validator
pip install python-multipart
```

Guardar:

```bash
pip freeze > requirements.txt
```

---

# Ejecución del Backend

```bash
uvicorn app.main:app --reload --port 8000
```

Documentación:

```text
http://localhost:8000/docs
```

---

# Base de Datos Supabase

Crear las siguientes tablas:

## Seguridad

usuarios
roles
permisos
usuarios_roles

---

## Personas

clientes
asesores
administradores
supervisores

---

## Productos Bancarios

cuentas
movimientos
tarjetas
productos_credito

---

## Créditos

solicitudes_credito
evaluaciones_credito
buro_consultas
visitas
documentos_credito
firmas_credito
comite_credito
creditos
cronograma_pagos
pagos_credito

---

## Notificaciones

notificaciones

---

## Sincronización

sync_outbox
sync_log

---

## Tablas espejo

cr_clientes
cr_cuentas
cr_creditos
cr_cronograma
cr_movimientos

---

# Roles del Sistema

## CLIENTE

Puede:

* Iniciar sesión
* Ver perfil
* Ver cuentas
* Ver movimientos
* Ver créditos
* Ver cronograma
* Simular cuotas
* Solicitar crédito
* Pagar cuotas
* Ver notificaciones

---

## ASESOR

Puede:

* Iniciar sesión
* Ver cartera del día
* Ver ficha del cliente
* Registrar visitas
* Registrar coordenadas GPS
* Ejecutar preevaluación
* Consultar buró
* Adjuntar documentos
* Capturar firma
* Enviar expediente al comité

---

## SUPERVISOR

Puede:

* Ver expedientes
* Aprobar solicitudes
* Condicionar solicitudes
* Rechazar solicitudes
* Ver reportes

---

## ADMINISTRADOR

Puede:

* Gestionar usuarios
* Gestionar clientes
* Gestionar asesores
* Gestionar productos
* Gestionar créditos
* Ver dashboard
* Ver reportes
* Configuración del sistema

---

# Seguridad Obligatoria

Implementar:

* JWT
* Hash de contraseñas
* Refresh Token opcional
* RBAC
* Protección por roles
* Protección de endpoints
* Expiración de token
* Bloqueo por 5 intentos fallidos
* CORS
* Validación de propiedad del recurso
* Middleware de autenticación

---

# Estados del Expediente

```text
BORRADOR
ENVIADO
RECIBIDO_COMITE
EN_EVALUACION
APROBADO
CONDICIONADO
RECHAZADO
DESEMBOLSADO
```

---

# Flujo End-to-End

## Paso 1

Cliente inicia sesión.

---

## Paso 2

Cliente registra solicitud:

* monto
* plazo
* destino
* garantía
* seguro

Sistema:

* genera expediente
* genera número de operación
* estado ENVIADO

---

## Paso 3

Backend:

* registra solicitud
* registra sync_outbox
* asigna asesor
* genera notificación

---

## Paso 4

Asesor:

* inicia sesión
* visualiza cartera
* abre ficha del cliente
* registra visita
* guarda GPS
* realiza preevaluación
* consulta buró
* adjunta documentos
* captura firma
* envía a comité

---

## Paso 5

Supervisor:

* revisa expediente
* aprueba
* condiciona
* rechaza

---

## Paso 6

Core:

* genera crédito
* genera cronograma
* genera movimientos
* actualiza cuenta
* actualiza tablas espejo
* registra sync_log
* notifica al cliente

---

## Paso 7

Cliente:

* visualiza crédito
* visualiza cronograma
* visualiza movimientos
* paga cuotas

---

# Fórmulas Financieras

## Crédito Empresarial

TEA con seguro:

40.92%

TEA sin seguro:

43.92%

---

## TEM

```text
TEM = (1 + TEA)^(1/12) - 1
```

---

## Cuota Francesa

```text
cuota =
monto * TEM /
(1 - (1 + TEM)^(-plazo))
```

---

## Cronograma

```text
interes = saldo * TEM
capital = cuota - interes
saldo_final = saldo - capital
```

---

# Endpoints

## Auth

POST /auth/login
POST /auth/logout
GET /auth/me

---

## Clientes

GET /clientes
POST /clientes
GET /clientes/{id}
PUT /clientes/{id}
DELETE /clientes/{id}

---

## Cuentas

GET /cuentas
GET /cuentas/{id}
POST /cuentas
PUT /cuentas/{id}

---

## Movimientos

GET /movimientos
POST /movimientos

---

## Solicitudes

POST /solicitudes
GET /solicitudes
GET /solicitudes/{id}
PUT /solicitudes/{id}/estado

---

## Asesor

GET /asesor/cartera
POST /asesor/visitas
POST /asesor/preevaluacion
POST /asesor/buro
POST /asesor/documentos
POST /asesor/firma
POST /asesor/enviar-comite

---

## Comité

GET /comite/expedientes
POST /comite/decidir

---

## Créditos

POST /creditos/desembolsar
GET /creditos
GET /creditos/{id}
GET /creditos/{id}/cronograma

---

## Pagos

POST /pagos
GET /pagos/cliente/{id}

---

## Reportes

GET /reportes/dashboard
GET /reportes/creditos
GET /reportes/mora
GET /reportes/asesores

---

# Aplicación Flutter

Una sola aplicación.

Después del login:

CLIENTE → Homebanking

ASESOR → Fuerza de Ventas

SUPERVISOR → Panel Supervisor

ADMINISTRADOR → Panel Administrativo

---

# Módulos Cliente

* Dashboard
* Perfil
* Cuentas
* Movimientos
* Créditos
* Cronograma
* Solicitud de Crédito
* Pago de Cuotas
* Notificaciones

---

# Módulos Asesor

* Dashboard
* Cartera
* Ficha Cliente
* Registro de Visita
* Preevaluación
* Buró
* Documentos
* Firma Digital
* Enviar Comité

---

# Módulos Supervisor/Admin

* Dashboard
* Expedientes
* Comité
* Usuarios
* Reportes
* Configuración

---

# Web React

Páginas:

* Login
* Dashboard
* Usuarios
* Clientes
* Asesores
* Solicitudes
* Créditos
* Cronogramas
* Pagos
* Reportes
* Configuración

Componentes:

* Sidebar
* Topbar
* ProtectedRoute
* RoleGuard
* DataTable
* SearchBar
* Pagination
* Cards
* Modales
* Badges

---

# Datos Demo

Crear:

1 Administrador
1 Supervisor
5 Asesores
30 Clientes
30 Solicitudes
10 Créditos Aprobados
10 Créditos Rechazados
10 Créditos Condicionados

Generar cronogramas y movimientos de prueba.

---

# Checklist Final

Backend FastAPI funcionando.

Supabase conectado.

React funcionando.

Flutter funcionando.

JWT funcionando.

RBAC funcionando.

Solicitudes funcionando.

Cartera funcionando.

Comité funcionando.

Desembolso funcionando.

Cronograma funcionando.

Movimientos funcionando.

Pagos funcionando.

Notificaciones funcionando.

Reportes funcionando.

Datos demo funcionando.

Sin claves expuestas.

Sin service role en frontend.

Sin datos quemados innecesarios.

Sin errores de compilación.

Sin errores de dependencias.

Sistema probado end-to-end.

---

# Instrucción Final para Antigravity

1. Analizar primero el proyecto actual.
2. Detectar qué componentes ya existen.
3. Reutilizar código útil.
4. No eliminar funcionalidades sin justificación.
5. Crear únicamente lo faltante.
6. Corregir inconsistencias.
7. Generar scripts SQL.
8. Generar seeds.
9. Generar documentación.
10. Ejecutar pruebas de integración.
11. Entregar el ecosistema completamente funcional y listo para producción académica.
