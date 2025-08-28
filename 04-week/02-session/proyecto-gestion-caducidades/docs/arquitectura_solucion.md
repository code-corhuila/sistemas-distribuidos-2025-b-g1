# Documento de Arquitectura de Solución
## Sistema de Gestión de Inventario - Control de Caducidades

### Información del Documento
- **Versión:** 1.0
- **Fecha:** Agosto 2025
- **Autor:** Equipo Desarrollo CORHUILA
- **Estado:** Borrador para Revisión

---

## 1. Introducción

### 1.1 Propósito
Este documento describe la arquitectura técnica del Sistema de Gestión de Inventario enfocado en el control de productos próximos a vencer, desarrollado como proyecto académico para el curso de Sistemas Distribuidos.

### 1.2 Alcance
El documento cubre:
- Arquitectura de alto nivel del sistema
- Patrones arquitectónicos aplicados
- Decisiones de diseño y tecnologías
- Estrategias de despliegue y escalabilidad
- Consideraciones de seguridad y rendimiento

### 1.3 Audiencia
- Equipo de desarrollo
- Profesores y evaluadores
- Futuros mantenedores del sistema

## 2. Visión General del Sistema

### 2.1 Objetivos de Negocio
- **Primario:** Reducir pérdidas por productos vencidos ≥20%
- **Secundario:** Mejorar eficiencia operacional en gestión de inventario
- **Técnico:** Demostrar aplicación de principios de sistemas distribuidos

### 2.2 Características Clave
- Sistema web responsive (Angular + Spring Boot)
- Alertas automáticas por semáforo (rojo/ámbar/verde)
- Importación masiva de datos CSV
- Reportes PDF automatizados
- Rendimiento optimizado (p95 < 1s hasta 5,000 registros)

### 2.3 Restricciones y Limitaciones
- **Tecnológicas:** Java 17+, Angular 17+, PostgreSQL
- **Rendimiento:** p95 < 1s, exactitud ≥95%
- **Alcance:** MVP sin integración ERP/POS
- **Tiempo:** 6 semanas desarrollo

## 3. Arquitectura de Alto Nivel

### 3.1 Estilo Arquitectónico
**Arquitectura por Capas (Layered Architecture)** con elementos de **Arquitectura Hexagonal**:

```
┌─────────────────────────────────────────────────────────┐
│                 Presentation Layer                       │
│  ┌─────────────────┐    ┌─────────────────────────────┐  │
│  │   Angular SPA   │    │     REST API (Spring)      │  │
│  │   - Components  │◄──►│     - Controllers           │  │
│  │   - Services    │    │     - Security Filters     │  │
│  │   - Guards      │    │     - Validation           │  │
│  └─────────────────┘    └─────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
               │                           │
               ▼                           ▼
┌─────────────────────────────────────────────────────────┐
│                  Business Layer                         │
│  ┌─────────────────────────────────────────────────────┐ │
│  │                Services (Domain)                    │ │
│  │  - ProductService    - AlertService                 │ │
│  │  - BatchService      - ReportService                │ │
│  │  - ImportService     - AuditService                 │ │
│  └─────────────────────────────────────────────────────┘ │
│                           │                             │
│  ┌─────────────────────────────────────────────────────┐ │
│  │              Domain Models                          │ │
│  │  - Product, Batch, Supplier, User                  │ │
│  │  - Business Rules & Validations                    │ │
│  └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│                 Data Access Layer                       │
│  ┌─────────────────────────────────────────────────────┐ │
│  │            JPA Repositories                         │ │
│  │  - Spring Data JPA                                  │ │
│  │  - Custom Queries                                   │ │
│  │  - Transaction Management                           │ │
│  └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│                   Database Layer                        │
│  ┌─────────────────────────────────────────────────────┐ │
│  │              PostgreSQL 15                          │ │
│  │  - Tables, Views, Indexes                           │ │
│  │  - Functions, Triggers                              │ │
│  │  - Connection Pooling                               │ │
│  └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### 3.2 Patrones Arquitectónicos Aplicados

#### 3.2.1 Model-View-Controller (MVC)
- **Frontend:** Angular con arquitectura basada en componentes
- **Backend:** Spring MVC con separación clara de responsabilidades

#### 3.2.2 Repository Pattern
```java
@Repository
public interface BatchRepository extends JpaRepository<Batch, UUID> {
    
    @Query("""
        SELECT b FROM Batch b 
        JOIN FETCH b.product p 
        WHERE b.expirationDate <= :maxDate 
        AND b.status = :status 
        ORDER BY b.expirationDate ASC
        """)
    Page<Batch> findNearExpiryBatches(
        @Param("maxDate") LocalDate maxDate,
        @Param("status") BatchStatus status,
        Pageable pageable
    );
}
```

#### 3.2.3 Service Layer Pattern
```java
@Service
@Transactional
public class ExpiryAlertService {
    
    public List<ExpiryAlert> generateAlerts(int maxDays) {
        LocalDate cutoffDate = LocalDate.now().plusDays(maxDays);
        
        return batchRepository.findNearExpiryBatches(cutoffDate, ACTIVE, PageRequest.of(0, 1000))
            .stream()
            .map(this::mapToExpiryAlert)
            .sorted(this::compareByPriority)
            .collect(Collectors.toList());
    }
    
    private Priority calculatePriority(LocalDate expirationDate) {
        long daysToExpire = ChronoUnit.DAYS.between(LocalDate.now(), expirationDate);
        
        if (daysToExpire < 7) return Priority.RED;
        if (daysToExpire <= 30) return Priority.AMBER;
        return Priority.GREEN;
    }
}
```

#### 3.2.4 Command Query Responsibility Segregation (CQRS) - Simplificado
- **Commands:** Operaciones de escritura (crear, actualizar, eliminar)
- **Queries:** Operaciones de lectura optimizadas con vistas y proyecciones

## 4. Arquitectura de Componentes

### 4.1 Frontend (Angular)

#### 4.1.1 Estructura Modular
```
src/app/
├── core/                 # Servicios singleton y configuración global
│   ├── auth/            # Autenticación y autorización
│   ├── interceptors/    # HTTP interceptors
│   └── guards/          # Route guards
├── shared/              # Componentes, directivas y pipes reutilizables
│   ├── components/      # Componentes UI comunes
│   ├── models/          # Interfaces y tipos TypeScript
│   └── utils/           # Utilidades y helpers
├── features/            # Módulos de funcionalidad
│   ├── products/        # Gestión de productos
│   ├── batches/         # Gestión de lotes
│   ├── alerts/          # Sistema de alertas
│   ├── reports/         # Generación de reportes
│   └── import/          # Importación masiva
└── layout/              # Componentes de layout
    ├── header/
    ├── sidebar/
    └── footer/
```

#### 4.1.2 Patrón de Estado con Services
```typescript
@Injectable({
  providedIn: 'root'
})
export class AlertStateService {
  private readonly _alerts$ = new BehaviorSubject<ExpiryAlert[]>([]);
  private readonly _loading$ = new BehaviorSubject<boolean>(false);
  private readonly _filter$ = new BehaviorSubject<AlertFilter>({});
  
  public readonly alerts$ = this._alerts$.asObservable();
  public readonly loading$ = this._loading$.asObservable();
  public readonly filter$ = this._filter$.asObservable();
  
  public readonly criticalAlerts$ = this.alerts$.pipe(
    map(alerts => alerts.filter(alert => alert.priority === Priority.RED))
  );
  
  public loadAlerts(filter: AlertFilter): void {
    this._loading$.next(true);
    this._filter$.next(filter);
    
    this.alertService.getAlerts(filter).pipe(
      finalize(() => this._loading$.next(false))
    ).subscribe(alerts => this._alerts$.next(alerts));
  }
}
```

#### 4.1.3 Lazy Loading y Performance
```typescript
const routes: Routes = [
  {
    path: 'products',
    loadChildren: () => import('./features/products/products.module').then(m => m.ProductsModule),
    canLoad: [AuthGuard]
  },
  {
    path: 'alerts',
    loadChildren: () => import('./features/alerts/alerts.module').then(m => m.AlertsModule),
    canLoad: [AuthGuard]
  }
];
```

### 4.2 Backend (Spring Boot)

#### 4.2.1 Estructura de Paquetes
```
src/main/java/com/corhuila/gestion/caducidades/
├── config/              # Configuración de Spring
│   ├── DatabaseConfig.java
│   ├── SecurityConfig.java
│   └── SwaggerConfig.java
├── controller/          # Controladores REST
│   ├── ProductController.java
│   ├── BatchController.java
│   └── AlertController.java
├── service/             # Lógica de negocio
│   ├── ProductService.java
│   ├── ExpiryAlertService.java
│   └── ReportService.java
├── repository/          # Acceso a datos
│   ├── ProductRepository.java
│   └── BatchRepository.java
├── domain/              # Entidades y Value Objects
│   ├── entity/
│   │   ├── Product.java
│   │   └── Batch.java
│   └── dto/
│       ├── request/
│       └── response/
├── infrastructure/      # Integraciones externas
│   ├── pdf/
│   └── email/
└── Application.java     # Punto de entrada
```

#### 4.2.2 Configuración de Base de Datos
```java
@Configuration
@EnableJpaRepositories
@EnableTransactionManagement
public class DatabaseConfig {
    
    @Bean
    @Primary
    public DataSource primaryDataSource() {
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl("jdbc:postgresql://localhost:5432/gestion_caducidades");
        config.setUsername("admin_gestion");
        config.setPassword("${DB_PASSWORD}");
        config.setMaximumPoolSize(20);
        config.setMinimumIdle(5);
        config.setConnectionTimeout(30000);
        config.setIdleTimeout(600000);
        config.setMaxLifetime(1800000);
        return new HikariDataSource(config);
    }
    
    @Bean
    public PlatformTransactionManager transactionManager(EntityManagerFactory emf) {
        return new JpaTransactionManager(emf);
    }
}
```

#### 4.2.3 Optimizaciones de Rendimiento
```java
@Entity
@Table(name = "batch", indexes = {
    @Index(name = "idx_batch_exp_date", columnList = "expiration_date"),
    @Index(name = "idx_batch_prod_exp", columnList = "product_id, expiration_date"),
    @Index(name = "idx_batch_priority", columnList = "expiration_date, status, quantity")
})
@NamedQueries({
    @NamedQuery(
        name = "Batch.findNearExpiryWithProduct",
        query = """
            SELECT b FROM Batch b 
            JOIN FETCH b.product p 
            LEFT JOIN FETCH p.supplier s
            WHERE b.expirationDate BETWEEN :startDate AND :endDate 
            AND b.status = 'ACTIVE' 
            AND b.quantity > 0
            ORDER BY b.expirationDate ASC
            """
    )
})
public class Batch {
    // ... entidad
}
```

## 5. Estrategia de Datos

### 5.1 Modelo de Datos Optimizado

#### 5.1.1 Denormalización Controlada
```sql
-- Vista materializada para consultas frecuentes
CREATE MATERIALIZED VIEW mv_inventory_summary AS
SELECT 
    p.category,
    p.supplier_id,
    COUNT(b.id) as total_batches,
    SUM(b.quantity) as total_quantity,
    SUM(b.quantity * b.cost) as total_value,
    COUNT(CASE WHEN (b.expiration_date - CURRENT_DATE) < 7 THEN 1 END) as critical_batches,
    COUNT(CASE WHEN (b.expiration_date - CURRENT_DATE) BETWEEN 7 AND 30 THEN 1 END) as warning_batches
FROM product p
LEFT JOIN batch b ON p.id = b.product_id AND b.status = 'ACTIVE'
GROUP BY p.category, p.supplier_id;

-- Índice para refresh rápido
CREATE UNIQUE INDEX mv_inventory_summary_idx ON mv_inventory_summary(category, supplier_id);

-- Refresh automático cada hora
SELECT cron.schedule('refresh-inventory-summary', '0 * * * *', 'REFRESH MATERIALIZED VIEW CONCURRENTLY mv_inventory_summary;');
```

#### 5.1.2 Particionamiento por Fecha
```sql
-- Tabla particionada para movimientos de stock (futuro)
CREATE TABLE stock_movement_partitioned (
    LIKE stock_movement INCLUDING ALL
) PARTITION BY RANGE (created_at);

-- Particiones mensuales
CREATE TABLE stock_movement_2025_08 PARTITION OF stock_movement_partitioned
    FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');

CREATE TABLE stock_movement_2025_09 PARTITION OF stock_movement_partitioned
    FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');
```

### 5.2 Estrategias de Cache

#### 5.2.1 Cache de Aplicación
```java
@Configuration
@EnableCaching
public class CacheConfig {
    
    @Bean
    public CacheManager cacheManager() {
        CaffeineCacheManager cacheManager = new CaffeineCacheManager();
        cacheManager.setCaffeine(Caffeine.newBuilder()
            .maximumSize(1000)
            .expireAfterWrite(10, TimeUnit.MINUTES)
            .recordStats());
        return cacheManager;
    }
}

@Service
public class ProductService {
    
    @Cacheable(value = "products", key = "#root.methodName + '_' + #pageable.pageNumber + '_' + #pageable.pageSize")
    public Page<Product> findAll(Pageable pageable) {
        return productRepository.findAll(pageable);
    }
    
    @CacheEvict(value = "products", allEntries = true)
    public Product createProduct(CreateProductRequest request) {
        // ...
    }
}
```

#### 5.2.2 Cache de Base de Datos
```sql
-- Configuración PostgreSQL para cache
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET work_mem = '4MB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';
SELECT pg_reload_conf();
```

## 6. Seguridad

### 6.1 Autenticación y Autorización

#### 6.1.1 JWT Security Configuration
```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity(prePostEnabled = true)
public class SecurityConfig {
    
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        return http
            .csrf(csrf -> csrf.disable())
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/v1/auth/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/v1/products/**").hasAnyRole("VIEWER", "OPERATOR", "ADMIN")
                .requestMatchers(HttpMethod.POST, "/api/v1/products/**").hasAnyRole("OPERATOR", "ADMIN")
                .requestMatchers("/api/v1/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            )
            .oauth2ResourceServer(oauth2 -> oauth2.jwt(jwt -> jwt.jwtDecoder(jwtDecoder())))
            .build();
    }
}
```

#### 6.1.2 Auditoría de Seguridad
```java
@Entity
@EntityListeners(AuditingEntityListener.class)
public class AuditableEntity {
    
    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    @CreatedBy
    @Column(name = "created_by", updatable = false)
    private String createdBy;
    
    @LastModifiedBy
    @Column(name = "updated_by")
    private String updatedBy;
}

@Component
public class AuditorAwareImpl implements AuditorAware<String> {
    
    @Override
    public Optional<String> getCurrentAuditor() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        
        if (authentication == null || !authentication.isAuthenticated() ||
            "anonymousUser".equals(authentication.getPrincipal())) {
            return Optional.of("system");
        }
        
        return Optional.of(authentication.getName());
    }
}
```

### 6.2 Validación y Sanitización

#### 6.2.1 Validación de Entrada
```java
@RestController
@RequestMapping("/api/v1/products")
@Validated
public class ProductController {
    
    @PostMapping
    public ResponseEntity<ProductResponse> createProduct(
            @Valid @RequestBody CreateProductRequest request) {
        
        ProductResponse product = productService.createProduct(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(product);
    }
}

@Data
@Builder
public class CreateProductRequest {
    
    @NotBlank(message = "SKU es requerido")
    @Pattern(regexp = "^[A-Z0-9-]+$", message = "SKU debe contener solo letras mayúsculas, números y guiones")
    @Size(max = 50, message = "SKU no puede exceder 50 caracteres")
    private String sku;
    
    @NotBlank(message = "Nombre es requerido")
    @Size(min = 2, max = 255, message = "Nombre debe tener entre 2 y 255 caracteres")
    private String name;
    
    @NotNull(message = "Proveedor es requerido")
    private UUID supplierId;
    
    @DecimalMin(value = "0.0", inclusive = false, message = "Stock mínimo debe ser mayor a 0")
    private Integer minStock = 0;
}
```

## 7. Monitoring y Observabilidad

### 7.1 Logging Estructurado
```java
@RestController
@Slf4j
public class ProductController {
    
    @PostMapping
    public ResponseEntity<ProductResponse> createProduct(@Valid @RequestBody CreateProductRequest request) {
        String correlationId = UUID.randomUUID().toString();
        MDC.put("correlationId", correlationId);
        MDC.put("operation", "createProduct");
        MDC.put("sku", request.getSku());
        
        try {
            log.info("Creating product with SKU: {}", request.getSku());
            ProductResponse product = productService.createProduct(request);
            log.info("Product created successfully with ID: {}", product.getId());
            return ResponseEntity.status(HttpStatus.CREATED).body(product);
            
        } catch (Exception e) {
            log.error("Error creating product", e);
            throw e;
        } finally {
            MDC.clear();
        }
    }
}
```

### 7.2 Métricas de Aplicación
```java
@Component
public class BusinessMetrics {
    
    private final Counter productsCreated;
    private final Counter alertsGenerated;
    private final Timer alertCalculationTime;
    private final Gauge criticalAlertsCount;
    
    public BusinessMetrics(MeterRegistry meterRegistry) {
        this.productsCreated = Counter.builder("products.created")
            .description("Number of products created")
            .register(meterRegistry);
            
        this.alertsGenerated = Counter.builder("alerts.generated")
            .tag("priority", "all")
            .description("Number of alerts generated")
            .register(meterRegistry);
            
        this.alertCalculationTime = Timer.builder("alerts.calculation.time")
            .description("Time taken to calculate alerts")
            .register(meterRegistry);
            
        this.criticalAlertsCount = Gauge.builder("alerts.critical.count")
            .description("Current number of critical alerts")
            .register(meterRegistry, this, BusinessMetrics::getCriticalAlertsCount);
    }
    
    private double getCriticalAlertsCount() {
        // Implementación para obtener conteo actual
        return alertService.countCriticalAlerts();
    }
}
```

## 8. Despliegue y DevOps

### 8.1 Containerización

#### 8.1.1 Dockerfile Backend
```dockerfile
# Build stage
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline

COPY src ./src
RUN mvn clean package -DskipTests

# Runtime stage
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Crear usuario no-root
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Copiar artefactos
COPY --from=build /app/target/*.jar app.jar

# Configurar permisos
RUN chown -R appuser:appgroup /app
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

#### 8.1.2 Dockerfile Frontend
```dockerfile
# Build stage
FROM node:18-alpine AS build
WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build --prod

# Runtime stage
FROM nginx:alpine
COPY --from=build /app/dist/gestion-caducidades /usr/share/nginx/html

# Configuración Nginx
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### 8.2 Docker Compose para Producción
```yaml
version: '3.8'

services:
  app:
    build: ./backend
    restart: unless-stopped
    environment:
      SPRING_PROFILES_ACTIVE: production
      DB_HOST: db
      DB_PASSWORD: ${DB_PASSWORD}
      JWT_SECRET: ${JWT_SECRET}
    depends_on:
      db:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '0.5'
        reservations:
          memory: 512M
          cpus: '0.25'

  web:
    build: ./frontend
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./ssl:/etc/nginx/ssl:ro
    depends_on:
      - app

  db:
    image: postgres:15-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/init:/docker-entrypoint-initdb.d:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER} -d ${DB_NAME}"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
    driver: local
```

## 9. Escalabilidad y Rendimiento

### 9.1 Estrategias de Escalabilidad

#### 9.1.1 Escalamiento Horizontal
```yaml
# Kubernetes Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gestion-caducidades-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: gestion-caducidades-api
  template:
    metadata:
      labels:
        app: gestion-caducidades-api
    spec:
      containers:
      - name: api
        image: gestion-caducidades-api:latest
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
```

#### 9.1.2 Load Balancing
```nginx
upstream backend {
    least_conn;
    server app1:8080 max_fails=3 fail_timeout=30s;
    server app2:8080 max_fails=3 fail_timeout=30s;
    server app3:8080 max_fails=3 fail_timeout=30s;
}

server {
    listen 80;
    server_name gestion-caducidades.corhuila.edu.co;
    
    location /api/ {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Connection pooling
        proxy_http_version 1.1;
        proxy_set_header Connection "";
    }
    
    location / {
        root /usr/share/nginx/html;
        try_files $uri $uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
```

### 9.2 Optimizaciones de Base de Datos

#### 9.2.1 Read Replicas
```java
@Configuration
public class DatabaseRoutingConfig {
    
    @Bean
    @Primary
    public DataSource routingDataSource() {
        ReplicationRoutingDataSource routingDataSource = new ReplicationRoutingDataSource();
        
        Map<Object, Object> dataSources = new HashMap<>();
        dataSources.put("write", writeDataSource());
        dataSources.put("read", readDataSource());
        
        routingDataSource.setTargetDataSources(dataSources);
        routingDataSource.setDefaultTargetDataSource(writeDataSource());
        
        return routingDataSource;
    }
}

@Transactional(readOnly = true)
@ReadOnlyRoute
public class ProductQueryService {
    
    public Page<Product> findAll(Pageable pageable) {
        // Esta consulta irá al read replica
        return productRepository.findAll(pageable);
    }
}
```

#### 9.2.2 Connection Pooling Avanzado
```java
@Configuration
public class DatabaseConfig {
    
    @Bean
    public DataSource dataSource() {
        HikariConfig config = new HikariConfig();
        
        // Connection pool sizing
        config.setMaximumPoolSize(20);
        config.setMinimumIdle(5);
        config.setIdleTimeout(300000);
        config.setMaxLifetime(1200000);
        config.setConnectionTimeout(20000);
        config.setValidationTimeout(5000);
        
        // Performance tuning
        config.setLeakDetectionThreshold(60000);
        config.addDataSourceProperty("cachePrepStmts", "true");
        config.addDataSourceProperty("prepStmtCacheSize", "250");
        config.addDataSourceProperty("prepStmtCacheSqlLimit", "2048");
        config.addDataSourceProperty("useServerPrepStmts", "true");
        
        return new HikariDataSource(config);
    }
}
```

## 10. Consideraciones Futuras

### 10.1 Microservicios (Evolución Post-MVP)
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Product Service │    │  Inventory      │    │  Alert Service  │
│                 │◄──►│  Service        │◄──►│                 │
│  - CRUD         │    │                 │    │  - Calculations │
│  - Validation   │    │  - Batches      │    │  - Notifications│
└─────────────────┘    │  - Movements    │    └─────────────────┘
                       │  - Stock        │
                       └─────────────────┘
            │                   │                   │
            ▼                   ▼                   ▼
┌─────────────────────────────────────────────────────────┐
│               Event Bus (Apache Kafka)                   │
│  - ProductCreated    - StockUpdated    - AlertGenerated │
└─────────────────────────────────────────────────────────┘
```

### 10.2 Tecnologías Emergentes
- **Event Sourcing:** Para auditoría completa de cambios
- **CQRS:** Separación completa de comandos y consultas
- **GraphQL:** API más flexible para el frontend
- **WebSockets:** Notificaciones en tiempo real
- **Machine Learning:** Predicción de demanda y caducidad

### 10.3 Integración con Sistemas Externos
- **ERP Integration:** SAP, Oracle, Microsoft Dynamics
- **POS Systems:** Integración con puntos de venta
- **IoT Sensors:** Sensores de temperatura y humedad
- **Blockchain:** Trazabilidad de la cadena de suministro

## 11. Conclusiones

### 11.1 Beneficios de la Arquitectura Elegida
1. **Mantenibilidad:** Separación clara de responsabilidades
2. **Escalabilidad:** Preparada para crecimiento futuro
3. **Performance:** Optimizaciones específicas para los requisitos
4. **Seguridad:** Implementación robusta de controles de acceso
5. **Observabilidad:** Monitoring y logging adecuados

### 11.2 Trade-offs y Limitaciones
1. **Complejidad:** Mayor complejidad inicial vs. sistema monolítico simple
2. **Latencia:** Overhead de comunicación entre capas
3. **Recursos:** Requiere mayor conocimiento técnico del equipo

### 11.3 Métricas de Éxito Arquitectónico
- **Rendimiento:** p95 < 1s ✅
- **Disponibilidad:** > 99% uptime
- **Escalabilidad:** Soporta 10x carga actual
- **Mantenibilidad:** Tiempo de desarrollo de nuevas features < 2 semanas
- **Seguridad:** Zero vulnerabilidades críticas

---

**Documento aprobado por:** [Equipo de Arquitectura]  
**Próxima revisión:** [Fecha después de MVP]  
**Versión:** 1.0 - Agosto 2025
