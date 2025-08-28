# Plan de Pruebas - Sistema de Gestión de Caducidades

## 1. Estrategia General de Pruebas

### Objetivos de Calidad
- **Cobertura de código:** ≥70% en servicios del backend
- **Rendimiento:** p95 < 1s para consultas de hasta 5,000 registros
- **Exactitud:** ≥95% en alertas de semáforo
- **Funcionalidad:** 100% de criterios de aceptación cumplidos

### Tipos de Pruebas por Épica

#### ÉPICA 1 - Fundaciones (Semana 1-2)
- **Pruebas de infraestructura:** Docker Compose, conectividad DB
- **Pruebas de esquema:** DDL, integridad referencial, índices
- **Pruebas de datos:** Seeds, constraints, triggers

#### ÉPICA 2-6 - Funcionalidades (Semana 2-6)
- **Pruebas unitarias:** Servicios, repositorios, reglas de negocio
- **Pruebas de integración:** API endpoints, transacciones
- **Pruebas end-to-end:** Flujos completos usuario-sistema
- **Pruebas de rendimiento:** Carga, stress, volumen

## 2. Casos de Prueba por Módulo

### 2.1. Gestión de Productos (UC01, UC02)

#### Pruebas Unitarias - ProductService
```java
@TestMethodOrder(OrderAnnotation.class)
class ProductServiceTest {
    
    @Test
    @Order(1)
    void givenValidProductData_whenCreateProduct_thenReturnsProduct() {
        // Arrange
        CreateProductRequest request = CreateProductRequest.builder()
            .sku("TEST-001")
            .name("Producto Test")
            .category("TEST")
            .unit("UNIT")
            .minStock(10)
            .supplierId(UUID.randomUUID())
            .build();
        
        // Act & Assert
        ProductResponse result = productService.createProduct(request);
        
        assertThat(result).isNotNull();
        assertThat(result.getSku()).isEqualTo("TEST-001");
        assertThat(result.getName()).isEqualTo("Producto Test");
    }
    
    @Test
    void givenDuplicateSku_whenCreateProduct_thenThrowsException() {
        // Test de SKU duplicado
    }
    
    @Test
    void givenInvalidSupplier_whenCreateProduct_thenThrowsException() {
        // Test de proveedor inexistente
    }
    
    @ParameterizedTest
    @ValueSource(strings = {"", "   ", "a", "very-long-sku-that-exceeds-limits"})
    void givenInvalidSku_whenCreateProduct_thenThrowsValidationException(String sku) {
        // Test de validaciones de SKU
    }
}
```

#### Pruebas de Integración - ProductController
```java
@SpringBootTest
@AutoConfigureTestDatabase
@Testcontainers
class ProductControllerIntegrationTest {
    
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15")
            .withDatabaseName("test_db")
            .withUsername("test")
            .withPassword("test");
    
    @Test
    void givenValidRequest_whenCreateProduct_thenReturns201() throws Exception {
        String requestBody = """
            {
                "sku": "INTEGRATION-001",
                "name": "Producto Integración",
                "category": "TEST",
                "unit": "UNIT",
                "minStock": 5,
                "supplierId": "%s"
            }
            """.formatted(existingSupplierId);
            
        mockMvc.perform(post("/api/v1/products")
                .contentType(MediaType.APPLICATION_JSON)
                .content(requestBody))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.sku").value("INTEGRATION-001"))
                .andExpect(jsonPath("$.name").value("Producto Integración"));
    }
    
    @Test
    void givenLargeDataset_whenGetProducts_thenReturnsWithinPerformanceThreshold() {
        // Test de rendimiento con 5000+ productos
        long startTime = System.currentTimeMillis();
        
        ResponseEntity<PagedProductResponse> response = restTemplate.getForEntity(
            "/api/v1/products?page=0&size=100", PagedProductResponse.class);
            
        long responseTime = System.currentTimeMillis() - startTime;
        
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(responseTime).isLessThan(1000); // < 1s
    }
}
```

### 2.2. Gestión de Lotes y Alertas (UC03, UC06, UC07)

#### Pruebas de Reglas de Negocio - ExpiryService
```java
class ExpiryServiceTest {
    
    @ParameterizedTest
    @CsvSource({
        "2025-08-29, RED",      // 2 días (< 7)
        "2025-09-03, RED",      // 7 días exactos
        "2025-09-10, AMBER",    // 14 días
        "2025-09-26, AMBER",    // 30 días exactos
        "2025-10-15, GREEN"     // > 30 días
    })
    void givenExpirationDate_whenCalculatePriority_thenReturnsCorrectPriority(
            String expirationDate, Priority expectedPriority) {
        
        LocalDate expiry = LocalDate.parse(expirationDate);
        Priority actual = expiryService.calculatePriority(expiry);
        
        assertThat(actual).isEqualTo(expectedPriority);
    }
    
    @Test
    void givenBatchesWithDifferentPriorities_whenGetNearExpiryAlerts_thenReturnsOrderedByPriority() {
        // Crear lotes con diferentes fechas
        List<Batch> testBatches = createTestBatches();
        
        List<ExpiryAlert> alerts = expiryService.getNearExpiryAlerts(30);
        
        // Verificar orden: RED -> AMBER -> GREEN
        assertThat(alerts).extracting(ExpiryAlert::getPriority)
                .containsSequence(Priority.RED, Priority.RED, Priority.AMBER, Priority.GREEN);
    }
    
    @Test
    void givenLargeVolumeOfBatches_whenCalculateAlerts_thenPerformanceIsAcceptable() {
        // Test con 5000 lotes
        List<Batch> largeBatchList = createLargeBatchDataset(5000);
        
        long startTime = System.nanoTime();
        List<ExpiryAlert> alerts = expiryService.calculateAlertsForBatches(largeBatchList);
        long duration = System.nanoTime() - startTime;
        
        assertThat(Duration.ofNanos(duration)).isLessThan(Duration.ofMillis(500));
        assertThat(alerts).hasSizeGreaterThan(0);
    }
}
```

#### Pruebas de Exactitud - AlertAccuracyTest
```java
@SpringBootTest
class AlertAccuracyTest {
    
    @Test
    void givenKnownTestDataset_whenGenerateAlerts_thenAccuracyIsGreaterThan95Percent() {
        // Dataset controlado con fechas conocidas
        TestDataset dataset = createControlledTestDataset();
        
        List<ExpiryAlert> generatedAlerts = alertService.generateAlerts();
        List<ExpiryAlert> expectedAlerts = dataset.getExpectedAlerts();
        
        double accuracy = calculateAccuracy(generatedAlerts, expectedAlerts);
        
        assertThat(accuracy).isGreaterThanOrEqualTo(0.95); // ≥95%
    }
    
    private double calculateAccuracy(List<ExpiryAlert> actual, List<ExpiryAlert> expected) {
        int correctPredictions = 0;
        int totalPredictions = actual.size();
        
        for (ExpiryAlert alert : actual) {
            boolean isCorrect = expected.stream()
                .anyMatch(exp -> exp.getBatchId().equals(alert.getBatchId()) 
                    && exp.getPriority().equals(alert.getPriority()));
            if (isCorrect) correctPredictions++;
        }
        
        return (double) correctPredictions / totalPredictions;
    }
}
```

### 2.3. Importación CSV (UC05)

#### Pruebas de Validación - ImportServiceTest
```java
class ImportServiceTest {
    
    @Test
    void givenValidCSVFile_whenValidateStructure_thenReturnsSuccess() {
        String csvContent = """
            sku,name,category,unit,supplier_name,batch_code,expiration_date,quantity,cost,location
            PROD-001,Producto 1,LACTEOS,UNIT,Proveedor A,LOTE-001,2025-12-31,100,2500.00,EST-A1
            PROD-002,Producto 2,CARNES,KG,Proveedor B,LOTE-002,2025-11-15,50,15000.00,NEVERA-B1
            """;
        
        MultipartFile file = createMockCSVFile(csvContent);
        
        ImportValidationResult result = importService.validateFile(file);
        
        assertThat(result.isValid()).isTrue();
        assertThat(result.getTotalRows()).isEqualTo(2);
        assertThat(result.getErrorRows()).isEqualTo(0);
    }
    
    @Test
    void givenCSVWithErrors_whenValidate_thenReturnsDetailedErrors() {
        String csvContent = """
            sku,name,category,unit,supplier_name,batch_code,expiration_date,quantity,cost,location
            ,Producto Sin SKU,LACTEOS,UNIT,Proveedor A,LOTE-001,2025-12-31,100,2500.00,EST-A1
            PROD-002,Producto 2,CARNES,KG,Proveedor Inexistente,LOTE-002,2025-11-15,50,15000.00,NEVERA-B1
            PROD-003,Producto 3,LACTEOS,UNIT,Proveedor A,LOTE-003,2025-13-32,-10,abc,EST-A1
            """;
        
        MultipartFile file = createMockCSVFile(csvContent);
        
        ImportValidationResult result = importService.validateFile(file);
        
        assertThat(result.isValid()).isFalse();
        assertThat(result.getErrorRows()).isEqualTo(3);
        assertThat(result.getErrors())
            .extracting(ImportError::getField)
            .contains("sku", "supplier_name", "expiration_date", "quantity", "cost");
    }
    
    @Test
    void givenLargeCSVFile_whenProcess_thenHandlesVolumeCorrectly() {
        // Test con 1000+ filas
        MultipartFile largeFile = createLargeCSVFile(1000);
        
        ImportJob job = importService.processImportAsync(largeFile, ImportOptions.builder()
            .batchSize(100)
            .skipDuplicates(true)
            .build());
        
        // Esperar completión (con timeout)
        awaitJobCompletion(job.getJobId(), Duration.ofMinutes(2));
        
        ImportJobStatus status = importService.getJobStatus(job.getJobId());
        
        assertThat(status.getStatus()).isEqualTo(JobStatus.COMPLETED);
        assertThat(status.getResult().getSuccessfulRows()).isGreaterThan(950); // >95% éxito
    }
}
```

### 2.4. Reportería (UC09)

#### Pruebas de Generación PDF - ReportServiceTest
```java
class ReportServiceTest {
    
    @Test
    void givenExpiryData_whenGenerateWeeklyReport_thenCreatesValidPDF() {
        // Preparar datos de prueba
        List<ExpiryAlert> alerts = createSampleExpiryAlerts(20);
        
        byte[] pdfBytes = reportService.generateWeeklyExpiryReport(alerts, 20, true);
        
        assertThat(pdfBytes).isNotEmpty();
        assertThat(isPdfValid(pdfBytes)).isTrue();
        assertThat(pdfBytes.length).isLessThan(5 * 1024 * 1024); // < 5MB
    }
    
    @Test
    void givenLargeDataset_whenGenerateReport_thenPerformanceIsAcceptable() {
        List<ExpiryAlert> largeDataset = createLargeExpiryDataset(1000);
        
        long startTime = System.currentTimeMillis();
        byte[] pdf = reportService.generateWeeklyExpiryReport(largeDataset, 100, true);
        long duration = System.currentTimeMillis() - startTime;
        
        assertThat(duration).isLessThan(5000); // < 5s para generar
        assertThat(pdf).isNotEmpty();
    }
    
    private boolean isPdfValid(byte[] pdfBytes) {
        try {
            PDDocument.load(pdfBytes).close();
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}
```

## 3. Pruebas End-to-End

### 3.1. Flujo Completo - Cypress Tests
```javascript
describe('Gestión de Caducidades - Flujo Completo', () => {
    
    beforeEach(() => {
        cy.login('operador1', 'password123');
        cy.visit('/dashboard');
    });
    
    it('debe permitir crear producto, lote y generar alertas', () => {
        // 1. Crear nuevo producto
        cy.get('[data-cy=nuevo-producto]').click();
        cy.get('[data-cy=sku-input]').type('E2E-TEST-001');
        cy.get('[data-cy=nombre-input]').type('Producto E2E Test');
        cy.get('[data-cy=categoria-select]').select('LACTEOS');
        cy.get('[data-cy=unidad-select]').select('UNIT');
        cy.get('[data-cy=proveedor-select]').select('Lácteos San Agustín');
        cy.get('[data-cy=guardar-producto]').click();
        
        cy.get('[data-cy=success-message]').should('contain', 'Producto creado exitosamente');
        
        // 2. Crear lote próximo a vencer
        cy.get('[data-cy=nuevo-lote]').click();
        cy.get('[data-cy=producto-select]').select('E2E-TEST-001');
        cy.get('[data-cy=codigo-lote-input]').type('LOTE-E2E-001');
        
        // Fecha que vence en 5 días (rojo)
        const futureDate = new Date();
        futureDate.setDate(futureDate.getDate() + 5);
        cy.get('[data-cy=fecha-vencimiento]').type(futureDate.toISOString().split('T')[0]);
        
        cy.get('[data-cy=cantidad-input]').type('100');
        cy.get('[data-cy=costo-input]').type('5000');
        cy.get('[data-cy=ubicacion-input]').type('EST-TEST-1');
        cy.get('[data-cy=guardar-lote]').click();
        
        cy.get('[data-cy=success-message]').should('contain', 'Lote creado exitosamente');
        
        // 3. Verificar alerta en dashboard
        cy.visit('/alertas');
        cy.get('[data-cy=filtro-prioridad]').select('RED');
        
        cy.get('[data-cy=alertas-table]')
            .should('contain', 'LOTE-E2E-001')
            .should('contain', 'Producto E2E Test');
            
        cy.get('[data-cy=prioridad-badge]')
            .should('have.class', 'badge-red')
            .should('contain', 'CRÍTICO');
    });
    
    it('debe generar reporte PDF correctamente', () => {
        cy.visit('/reportes');
        cy.get('[data-cy=reporte-semanal]').click();
        cy.get('[data-cy=top-productos]').clear().type('10');
        cy.get('[data-cy=incluir-graficos]').check();
        cy.get('[data-cy=generar-reporte]').click();
        
        // Verificar descarga
        cy.readFile('cypress/downloads/reporte-semanal.pdf').should('exist');
    });
    
    it('debe importar CSV exitosamente', () => {
        const csvFile = 'cypress/fixtures/productos-test.csv';
        
        cy.visit('/importar');
        cy.get('[data-cy=archivo-csv]').selectFile(csvFile);
        cy.get('[data-cy=validar-archivo]').click();
        
        // Verificar validación
        cy.get('[data-cy=validacion-resultado]')
            .should('contain', 'Archivo válido')
            .should('contain', 'Filas válidas: 10');
            
        cy.get('[data-cy=procesar-importacion]').click();
        
        // Esperar completación
        cy.get('[data-cy=progreso-importacion]', { timeout: 30000 })
            .should('contain', '100%');
            
        cy.get('[data-cy=resultado-importacion]')
            .should('contain', 'Importación completada exitosamente');
    });
    
    it('debe manejar errores de validación correctamente', () => {
        cy.visit('/productos/nuevo');
        
        // Intentar crear producto sin datos requeridos
        cy.get('[data-cy=guardar-producto]').click();
        
        cy.get('[data-cy=error-sku]').should('contain', 'SKU es requerido');
        cy.get('[data-cy=error-nombre]').should('contain', 'Nombre es requerido');
        cy.get('[data-cy=error-proveedor]').should('contain', 'Proveedor es requerido');
    });
});
```

## 4. Pruebas de Rendimiento

### 4.1. Tests con JMeter
```xml
<!-- plan-pruebas-rendimiento.jmx -->
<jmeterTestPlan version="1.2">
    <hashTree>
        <TestPlan testname="Gestión Caducidades - Performance Test">
            <elementProp name="TestPlan.arguments" elementType="Arguments" guiclass="ArgumentsPanel"/>
            <stringProp name="TestPlan.user_define_classpath"></stringProp>
            <boolProp name="TestPlan.functional_mode">false</boolProp>
        </TestPlan>
        
        <!-- Test: Consulta de alertas con 5000 registros -->
        <ThreadGroup testname="Alertas - Carga Normal">
            <stringProp name="ThreadGroup.on_sample_error">continue</stringProp>
            <elementProp name="ThreadGroup.main_controller" elementType="LoopController">
                <boolProp name="LoopController.continue_forever">false</boolProp>
                <stringProp name="LoopController.loops">100</stringProp>
            </elementProp>
            <stringProp name="ThreadGroup.num_threads">10</stringProp>
            <stringProp name="ThreadGroup.ramp_time">30</stringProp>
        </ThreadGroup>
        
        <!-- HTTP Request: GET /api/v1/alerts/near-expiry -->
        <HTTPSamplerProxy testname="GET Alertas Vencimiento">
            <elementProp name="HTTPsampler.Arguments" elementType="Arguments">
                <collectionProp name="Arguments.arguments">
                    <elementProp name="" elementType="HTTPArgument">
                        <boolProp name="HTTPArgument.always_encode">false</boolProp>
                        <stringProp name="Argument.value">maxDays=30&page=0&size=100</stringProp>
                        <stringProp name="Argument.metadata">=</stringProp>
                    </elementProp>
                </collectionProp>
            </elementProp>
            <stringProp name="HTTPSampler.domain">localhost</stringProp>
            <stringProp name="HTTPSampler.port">8080</stringProp>
            <stringProp name="HTTPSampler.path">/api/v1/alerts/near-expiry</stringProp>
            <stringProp name="HTTPSampler.method">GET</stringProp>
        </HTTPSamplerProxy>
        
        <!-- Assertion: Tiempo de respuesta < 1s -->
        <DurationAssertion testname="Response Time < 1s">
            <stringProp name="DurationAssertion.duration">1000</stringProp>
        </DurationAssertion>
        
        <!-- Assertion: Status 200 -->
        <ResponseAssertion testname="Status 200">
            <collectionProp name="Asserion.test_strings">
                <stringProp>200</stringProp>
            </collectionProp>
            <stringProp name="Assertion.test_field">Assertion.response_code</stringProp>
            <boolProp name="Assertion.assume_success">false</boolProp>
            <intProp name="Assertion.test_type">1</intProp>
        </ResponseAssertion>
    </hashTree>
</jmeterTestPlan>
```

### 4.2. Pruebas de Carga - Gatling
```scala
import io.gatling.core.Predef._
import io.gatling.http.Predef._

class GestionCaducidadesLoadTest extends Simulation {
    
    val httpProtocol = http
        .baseUrl("http://localhost:8080")
        .acceptHeader("application/json")
        .contentTypeHeader("application/json")
    
    val scn = scenario("Carga Normal de Usuarios")
        .exec(
            http("Login")
                .post("/api/v1/auth/login")
                .body(StringBody("""{"username":"operador1","password":"password123"}"""))
                .check(jsonPath("$.token").saveAs("authToken"))
        )
        .pause(1)
        .exec(
            http("Dashboard")
                .get("/api/v1/alerts/dashboard")
                .header("Authorization", "Bearer ${authToken}")
                .check(status.is(200))
                .check(responseTimeInMillis.lt(1000))
        )
        .pause(2)
        .exec(
            http("Alertas Críticas")
                .get("/api/v1/alerts/near-expiry?priority=RED&page=0&size=50")
                .header("Authorization", "Bearer ${authToken}")
                .check(status.is(200))
                .check(responseTimeInMillis.lt(1000))
                .check(jsonPath("$.content").exists)
        )
        .pause(3)
        .exec(
            http("Buscar Productos")
                .get("/api/v1/products?q=leche&page=0&size=20")
                .header("Authorization", "Bearer ${authToken}")
                .check(status.is(200))
                .check(responseTimeInMillis.lt(500))
        )
    
    setUp(
        scn.inject(
            rampUsers(50) during (30 seconds),
            constantUsers(50) during (2 minutes),
            rampUsers(100) during (30 seconds),
            constantUsers(100) during (1 minute)
        )
    ).protocols(httpProtocol)
    .assertions(
        global.responseTime.percentile3.lt(1000),
        global.responseTime.percentile4.lt(2000),
        global.successfulRequests.percent.gt(95)
    )
}
```

## 5. Configuración de CI/CD con Pruebas

### 5.1. GitHub Actions Workflow
```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test-backend:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_db
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up JDK 17
      uses: actions/setup-java@v3
      with:
        java-version: '17'
        distribution: 'temurin'
    
    - name: Cache Maven dependencies
      uses: actions/cache@v3
      with:
        path: ~/.m2
        key: ${{ runner.os }}-m2-${{ hashFiles('**/pom.xml') }}
    
    - name: Run unit tests
      run: |
        cd backend
        ./mvnw clean test -Dspring.profiles.active=test
    
    - name: Run integration tests
      run: |
        cd backend
        ./mvnw clean verify -Dspring.profiles.active=test
    
    - name: Generate test report
      uses: dorny/test-reporter@v1
      if: success() || failure()
      with:
        name: Backend Tests
        path: backend/target/surefire-reports/*.xml
        reporter: java-junit
    
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: backend/target/site/jacoco/jacoco.xml
        flags: backend
        name: backend-coverage
    
    - name: Quality Gate
      run: |
        cd backend
        ./mvnw sonar:sonar \
          -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml \
          -Dsonar.coverage.exclusions="**/dto/**,**/config/**"

  test-frontend:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
        cache-dependency-path: frontend/package-lock.json
    
    - name: Install dependencies
      run: |
        cd frontend
        npm ci
    
    - name: Run unit tests
      run: |
        cd frontend
        npm run test:ci
    
    - name: Run E2E tests
      run: |
        cd frontend
        npm run e2e:ci
    
    - name: Upload test results
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: cypress-results
        path: frontend/cypress/results

  performance-tests:
    runs-on: ubuntu-latest
    needs: [test-backend, test-frontend]
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Start application
      run: |
        docker-compose -f docker-compose.test.yml up -d
        sleep 30
    
    - name: Run performance tests
      run: |
        docker run --network host \
          -v $(pwd)/performance:/workspace \
          justb4/jmeter:latest \
          -n -t /workspace/plan-pruebas-rendimiento.jmx \
          -l /workspace/results.jtl \
          -e -o /workspace/report
    
    - name: Upload performance report
      uses: actions/upload-artifact@v3
      with:
        name: performance-report
        path: performance/report
```

## 6. Criterios de Aceptación por Épica

### ÉPICA 1 - Descubrimiento (Semana 1)
- ✅ Docker Compose levanta correctamente
- ✅ Base de datos se crea con schema_v0.sql
- ✅ Seeds cargan datos de prueba exitosamente
- ✅ Todos los índices están optimizados
- ✅ Swagger/OpenAPI está disponible

### ÉPICA 2 - Catálogos (Semana 2)
- ✅ CRUD productos: 100% tests unitarios
- ✅ CRUD proveedores: 100% tests unitarios
- ✅ Validaciones: Todos los casos edge cubiertos
- ✅ API endpoints: Tests de integración completos
- ✅ Cobertura: ≥70% en servicios

### ÉPICA 3 - Lotes y Alertas (Semana 3)
- ✅ Reglas de semáforo: Exactitud ≥95%
- ✅ Cálculo de prioridades: Tests parametrizados
- ✅ Consultas optimizadas: p95 < 1s con 5000 registros
- ✅ Dashboard: Métricas correctas en tiempo real

### ÉPICA 4 - Importación (Semana 4)
- ✅ Validación CSV: Detección 100% errores de formato
- ✅ Procesamiento: Maneja 1000+ filas sin errores
- ✅ Reportes: Errores detallados por fila
- ✅ Async processing: Jobs completados exitosamente

### ÉPICA 5 - Reportes (Semana 5)
- ✅ PDF generado: Formato correcto y completo
- ✅ Rendimiento: < 5s para reportes de 100+ items
- ✅ Datos exactos: Coherencia con alertas calculadas
- ✅ Filtros: Funcionales y performantes

### ÉPICA 6 - Calidad Final (Semana 6)
- ✅ Cobertura total: ≥70% backend, ≥60% frontend
- ✅ Tests E2E: Flujos críticos cubiertos
- ✅ Performance: Todos los criterios cumplidos
- ✅ Seguridad: Tests de autenticación/autorización
- ✅ Documentación: Manual de usuario y técnico

## 7. Herramientas y Configuración

### Dependencias de Testing (Backend)
```xml
<dependencies>
    <!-- JUnit 5 -->
    <dependency>
        <groupId>org.junit.jupiter</groupId>
        <artifactId>junit-jupiter</artifactId>
        <scope>test</scope>
    </dependency>
    
    <!-- Spring Boot Test -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
    </dependency>
    
    <!-- Testcontainers -->
    <dependency>
        <groupId>org.testcontainers</groupId>
        <artifactId>junit-jupiter</artifactId>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.testcontainers</groupId>
        <artifactId>postgresql</artifactId>
        <scope>test</scope>
    </dependency>
    
    <!-- AssertJ -->
    <dependency>
        <groupId>org.assertj</groupId>
        <artifactId>assertj-core</artifactId>
        <scope>test</scope>
    </dependency>
    
    <!-- WireMock -->
    <dependency>
        <groupId>com.github.tomakehurst</groupId>
        <artifactId>wiremock-jre8</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

### Configuración de Testing (Frontend)
```json
{
  "devDependencies": {
    "@angular/testing": "^17.0.0",
    "jasmine": "^4.5.0",
    "karma": "^6.4.0",
    "karma-chrome-headless": "^3.1.4",
    "karma-coverage": "^2.2.0",
    "cypress": "^13.0.0",
    "@cypress/code-coverage": "^3.10.0",
    "cypress-mochawesome-reporter": "^3.4.0"
  },
  "scripts": {
    "test": "ng test",
    "test:ci": "ng test --watch=false --code-coverage",
    "e2e": "cypress open",
    "e2e:ci": "cypress run --browser chrome --headless"
  }
}
```

Este plan de pruebas garantiza la calidad del sistema y el cumplimiento de todos los criterios de aceptación definidos en el proyecto.
