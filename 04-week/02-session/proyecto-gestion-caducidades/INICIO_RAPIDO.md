# 🚀 Guía de Inicio Rápido
## Sistema de Gestión de Inventario - Control de Caducidades

### ⚡ Inicio en 5 Minutos

Esta guía te permitirá tener el sistema funcionando en tu máquina local en menos de 5 minutos.

---

## 📋 Prerrequisitos

Antes de comenzar, asegúrate de tener instalado:

### Obligatorios
- **Docker Desktop** (v4.0+) - [Descargar](https://www.docker.com/products/docker-desktop/)
- **Git** - [Descargar](https://git-scm.com/)

### Opcionales (para desarrollo)
- **Java 17+** - [Descargar](https://adoptium.net/)
- **Node.js 18+** - [Descargar](https://nodejs.org/)
- **PostgreSQL** (si prefieres instalación local)

---

## 🛠️ Configuración Inicial

### 1. Clonar el Repositorio

```bash
git clone https://github.com/code-corhuila/sistemas-distribuidos-2025-b-g1.git
cd sistemas-distribuidos-2025-b-g1/04-week/02-session/proyecto-gestion-caducidades
```

### 2. Configurar Variables de Entorno

```bash
# Copiar archivo de ejemplo
cp .env.example .env

# Editar configuraciones si es necesario (opcional para inicio rápido)
# Los valores por defecto funcionan para desarrollo local
```

### 3. Levantar el Sistema con Docker

```bash
# Levantar solo la base de datos (mínimo)
docker-compose up -d db

# O levantar todo el stack (recomendado)
docker-compose --profile full-stack up -d
```

### 4. Verificar que Todo Esté Funcionando

```bash
# Verificar estado de contenedores
docker-compose ps

# Deberías ver algo como:
# gestion-caducidades-db    Up (healthy)
# gestion-caducidades-api   Up
# gestion-caducidades-web   Up
```

---

## 🌐 Acceder al Sistema

Una vez que los contenedores estén ejecutándose:

| Servicio | URL | Credenciales |
|----------|-----|--------------|
| **Frontend** | http://localhost:4200 | admin / admin123 |
| **API Backend** | http://localhost:8090 | - |
| **Swagger UI** | http://localhost:8090/swagger-ui.html | - |
| **pgAdmin** | http://localhost:8080 | admin@corhuila.edu.co / admin123 |

### Usuarios de Prueba

| Usuario | Contraseña | Rol | Permisos |
|---------|------------|-----|----------|
| `admin` | `admin123` | ADMIN | Acceso completo |
| `operador1` | `password123` | OPERATOR | CRUD, reportes |
| `visor1` | `password123` | VIEWER | Solo lectura |

---

## 🎯 Verificación Rápida

### 1. Probar el Dashboard
1. Ir a http://localhost:4200
2. Iniciar sesión como `admin`
3. Verificar que aparezcan productos y alertas de ejemplo

### 2. Probar la API
```bash
# Test de salud
curl http://localhost:8090/actuator/health

# Listar productos
curl http://localhost:8090/api/v1/products

# Ver alertas críticas
curl "http://localhost:8090/api/v1/alerts/near-expiry?priority=RED"
```

### 3. Verificar Base de Datos
1. Ir a http://localhost:8080 (pgAdmin)
2. Login: `admin@corhuila.edu.co` / `admin123`
3. Conectar al servidor PostgreSQL:
   - Host: `db`
   - Puerto: `5432`
   - Database: `gestion_caducidades`
   - Usuario: `admin_gestion`
   - Contraseña: `password123`

---

## 🔄 Comandos Útiles

### Docker Compose
```bash
# Levantar servicios
docker-compose up -d

# Ver logs
docker-compose logs -f [servicio]

# Parar servicios
docker-compose down

# Reconstruir y levantar
docker-compose up -d --build

# Limpiar todo (cuidado: borra datos)
docker-compose down -v --rmi all
```

### Desarrollo Local (Sin Docker)

#### Backend
```bash
cd backend

# Instalar dependencias
./mvnw dependency:resolve

# Ejecutar aplicación
./mvnw spring-boot:run

# Ejecutar tests
./mvnw test
```

#### Frontend
```bash
cd frontend

# Instalar dependencias
npm install

# Ejecutar en modo desarrollo
ng serve

# Compilar para producción
ng build --prod
```

---

## 📊 Datos de Prueba

El sistema viene precargado con datos de ejemplo:

### Productos
- **15 productos** en diferentes categorías (LACTEOS, CARNES, FRUTAS, etc.)
- **20 lotes** con fechas de vencimiento variadas
- **Distribución de alertas:** 5 rojas, 5 ámbar, 10 verdes

### Proveedores
- 5 proveedores de ejemplo con información completa

### Usuarios
- 1 administrador, 2 operadores, 1 visor

---

## 🚨 Solución de Problemas

### ❌ Error: Puerto ya en uso
```bash
# Verificar qué está usando el puerto
netstat -tulpn | grep :4200

# Cambiar puerto en docker-compose.yml
ports:
  - "4201:4200"  # Cambiar primer número
```

### ❌ Error: Contenedor de DB no inicia
```bash
# Ver logs detallados
docker-compose logs db

# Verificar espacio en disco
df -h

# Limpiar volúmenes Docker
docker volume prune
```

### ❌ Error: Backend no conecta a DB
```bash
# Verificar que DB esté saludable
docker-compose ps

# Reiniciar servicios en orden
docker-compose stop
docker-compose up -d db
# Esperar 30 segundos
docker-compose up -d app web
```

### ❌ Error: Frontend no carga
```bash
# Verificar logs del frontend
docker-compose logs web

# Verificar que el backend esté respondiendo
curl http://localhost:8090/actuator/health

# Limpiar cache del navegador
Ctrl + F5 (o Cmd + Shift + R en Mac)
```

---

## 🧪 Ejecutar Tests

### Tests Unitarios Backend
```bash
cd backend
./mvnw test

# Con cobertura
./mvnw test jacoco:report
```

### Tests Frontend
```bash
cd frontend
npm test

# Tests E2E
npm run e2e
```

### Tests de Integración
```bash
# Con Docker Compose
docker-compose -f docker-compose.test.yml up --build --abort-on-container-exit
```

---

## 📖 Próximos Pasos

### Para Desarrollo
1. **Leer documentación:** `docs/arquitectura_solucion.md`
2. **Revisar API:** http://localhost:8090/swagger-ui.html
3. **Configurar IDE:** Importar proyectos backend y frontend
4. **Crear rama:** `git checkout -b feature/nueva-funcionalidad`

### Para Testing
1. **Revisar plan:** `docs/plan_pruebas.md`
2. **Ejecutar tests:** Seguir comandos de arriba
3. **Crear tests:** Añadir casos para nuevas funcionalidades

### Para Producción
1. **Configurar entorno:** Copiar `.env.example` a `.env.prod`
2. **Revisar seguridad:** Cambiar contraseñas y secretos
3. **Configurar CI/CD:** Ver `.github/workflows/`

---

## 📞 Soporte

### Documentación
- **Arquitectura:** `docs/arquitectura_solucion.md`
- **Diagramas:** `docs/diagramas_arquitectura.md`
- **API:** `docs/api_specification.yaml`
- **Pruebas:** `docs/plan_pruebas.md`

### Contacto
- **Equipo:** [Nombres del equipo]
- **Email:** sistemas@corhuila.edu.co
- **Repositorio:** [URL del repositorio]

### Issues Comunes
- **FAQ:** Ver `docs/faq.md` (próximamente)
- **Known Issues:** Ver GitHub Issues
- **Logs:** `docker-compose logs [servicio]`

---

## ✅ Checklist de Verificación

### Configuración Inicial
- [ ] Docker Desktop instalado y ejecutándose
- [ ] Repositorio clonado
- [ ] Archivo `.env` configurado
- [ ] Contenedores ejecutándose sin errores

### Funcionalidad Básica
- [ ] Frontend accesible en http://localhost:4200
- [ ] Login exitoso con usuario `admin`
- [ ] Dashboard muestra datos de ejemplo
- [ ] API responde en http://localhost:8090
- [ ] Swagger UI accesible

### Desarrollo (Opcional)
- [ ] Backend corriendo en modo desarrollo
- [ ] Frontend corriendo con `ng serve`
- [ ] Tests unitarios pasando
- [ ] Hot reload funcionando

---

## 🎉 ¡Listo!

Si todos los servicios están ejecutándose y puedes acceder al dashboard, ¡felicitaciones! Ya tienes el Sistema de Gestión de Caducidades funcionando en tu máquina local.

### Próximos pasos sugeridos:

1. **Explorar el dashboard** y familiarizarte con la interfaz
2. **Probar las funcionalidades** principales (crear producto, lote, ver alertas)
3. **Revisar la documentación** técnica para entender la arquitectura
4. **Ejecutar los tests** para verificar que todo funciona correctamente
5. **Comenzar el desarrollo** de nuevas funcionalidades

¡Ahora puedes empezar a trabajar en el proyecto! 🚀
