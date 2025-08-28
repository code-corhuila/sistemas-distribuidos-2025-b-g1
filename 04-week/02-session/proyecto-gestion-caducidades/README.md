# Sistema de Gestión de Inventario - Control de Caducidades

## Descripción del Proyecto

Sistema web para la gestión de inventario enfocado en el control de productos próximos a vencer, desarrollado como proyecto académico para el curso de Sistemas Distribuidos.

## Objetivo

Reducir el stock vencido al menos ≥20% mediante un sistema de priorización y alertas con exactitud ≥95% y rendimiento p95 < 1s para hasta 5,000 ítems.

## Tecnologías

- **Backend:** Spring Boot (Java 17), JPA/Hibernate, PostgreSQL
- **Frontend:** Angular 17+, RxJS, Angular Material
- **Base de Datos:** PostgreSQL con índices optimizados
- **DevOps:** Docker Compose para desarrollo local

## Arquitectura

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │    Backend      │    │   Database      │
│   Angular 17+   │◄──►│  Spring Boot    │◄──►│  PostgreSQL     │
│   Material UI   │    │   REST API      │    │   + Índices     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Funcionalidades MVP

- ✅ CRUD de productos y lotes
- ✅ Sistema de semáforos (rojo/ámbar/verde) por días de vencimiento
- ✅ Importación masiva CSV con validaciones
- ✅ Reportes PDF semanales
- ✅ Roles básicos (operador, visor)
- ✅ Auditoría básica

## Estructura del Proyecto

```
├── docs/                   # Documentación y diagramas
├── database/              # Scripts DDL y seeds
├── backend/               # API Spring Boot
├── frontend/              # Aplicación Angular
├── docker-compose.yml     # Orquestación local
└── README.md             # Este archivo
```

## Roadmap por Épicas

### ÉPICA 1 - Descubrimiento y Arquitectura (Semana 1)
- [x] Setup de repositorios y estructura
- [x] Modelado de base de datos (DER)
- [x] Diagramas de dominio y casos de uso
- [x] Especificación de API (OpenAPI)
- [x] Docker Compose setup

### ÉPICA 2 - Fundaciones y Catálogos (Semana 2)
- [ ] CRUD de productos y proveedores (Backend)
- [ ] Módulo de catálogos (Frontend)
- [ ] Validaciones y tests unitarios

### ÉPICA 3 - Lotes y Semáforos (Semana 3)
- [ ] Gestión de lotes con fechas de vencimiento
- [ ] Implementación de reglas de semáforo
- [ ] Tablero de control con filtros

### ÉPICA 4 - Importación CSV (Semana 4)
- [ ] Endpoint de importación masiva
- [ ] Validación de plantillas CSV
- [ ] Wizard de importación (Frontend)

### ÉPICA 5 - Reportería (Semana 5)
- [ ] Generación de reportes PDF
- [ ] Optimizaciones de rendimiento
- [ ] Filtros avanzados

### ÉPICA 6 - Calidad y Demo Final (Semana 6)
- [ ] Cobertura de tests ≥70%
- [ ] Seguridad básica y logging
- [ ] Manual de usuario y demo

## Inicio Rápido

### Prerrequisitos
- Java 17+
- Node.js 18+
- Docker y Docker Compose
- PostgreSQL (via Docker)

### Desarrollo Local

1. **Clonar el repositorio**
```bash
git clone <repository-url>
cd proyecto-gestion-caducidades
```

2. **Levantar la base de datos**
```bash
docker-compose up -d db
```

3. **Ejecutar backend**
```bash
cd backend
./mvnw spring-boot:run
```

4. **Ejecutar frontend**
```bash
cd frontend
npm install
ng serve
```

5. **Acceder a la aplicación**
- Frontend: http://localhost:4200
- Backend API: http://localhost:8080
- Swagger UI: http://localhost:8080/swagger-ui.html

## Criterios de Aceptación

- ✅ CA1: Regla de semáforo implementada (rojo/ámbar/verde)
- ✅ CA2: Importación CSV con validación y reporte de errores
- ✅ CA3: Reporte PDF semanal Top 20
- ✅ CA4: p95 < 1s con 5,000 registros
- ✅ CA5: Cobertura tests ≥70% backend
- ✅ CA6: Manual de usuario y demo

## Contribución

1. Crear branch desde `main`
2. Implementar funcionalidad
3. Tests unitarios y de integración
4. Pull Request con revisión de código
5. Demo funcional por épica

## Licencia

Proyecto académico - Universidad CORHUILA
Sistemas Distribuidos 2025-B

## Contacto

- **Equipo:** [Nombres del equipo]
- **Profesor:** [Nombre del profesor]
- **Curso:** Sistemas Distribuidos 2025-B G1
