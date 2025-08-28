# Diagramas de Arquitectura - Sistema de Gestión de Caducidades

## 1. Diagrama de Clases de Dominio

```plantuml
@startuml Diagrama_Clases_Dominio
!theme plain
skinparam classAttributeIconSize 0
skinparam classFontSize 10

' =====================================================
' ENTIDADES PRINCIPALES
' =====================================================

class Product {
    +id: UUID
    +sku: String
    +name: String
    +description: String
    +category: String
    +unit: String
    +minStock: Integer
    +supplierId: UUID
    +isActive: Boolean
    +createdAt: DateTime
    +updatedAt: DateTime
    --
    +calculateTotalStock(): Integer
    +getActiveBatches(): List<Batch>
    +isLowStock(): Boolean
}

class Batch {
    +id: UUID
    +productId: UUID
    +batchCode: String
    +expirationDate: Date
    +productionDate: Date
    +quantity: Integer
    +cost: BigDecimal
    +location: String
    +status: BatchStatus
    +createdAt: DateTime
    +updatedAt: DateTime
    --
    +calculateDaysToExpire(): Integer
    +getPriority(): Priority
    +isExpired(): Boolean
    +getTotalValue(): BigDecimal
    +canSell(quantity: Integer): Boolean
}

class StockMovement {
    +id: UUID
    +batchId: UUID
    +movementType: MovementType
    +quantity: Integer
    +previousQuantity: Integer
    +newQuantity: Integer
    +reason: String
    +note: String
    +createdAt: DateTime
    +createdBy: String
    --
    +validate(): Boolean
    +apply(): void
}

class Supplier {
    +id: UUID
    +name: String
    +contact: String
    +email: String
    +phone: String
    +address: String
    +createdAt: DateTime
    +updatedAt: DateTime
    --
    +getProducts(): List<Product>
    +isActive(): Boolean
}

class User {
    +id: UUID
    +username: String
    +email: String
    +passwordHash: String
    +fullName: String
    +role: UserRole
    +isActive: Boolean
    +lastLogin: DateTime
    +createdAt: DateTime
    --
    +hasPermission(action: String): Boolean
    +canModify(entity: Object): Boolean
}

' =====================================================
' ENUMERACIONES
' =====================================================

enum MovementType {
    IN
    OUT
    ADJ
}

enum BatchStatus {
    ACTIVE
    EXPIRED
    SOLD_OUT
}

enum Priority {
    RED
    AMBER
    GREEN
}

enum UserRole {
    ADMIN
    OPERATOR
    VIEWER
}

' =====================================================
' VALUE OBJECTS
' =====================================================

class ExpiryAlert {
    +batchId: UUID
    +productName: String
    +daysToExpire: Integer
    +priority: Priority
    +quantity: Integer
    +totalValue: BigDecimal
    +location: String
    --
    +isCritical(): Boolean
    +getFormattedMessage(): String
}

class InventoryReport {
    +reportDate: Date
    +totalProducts: Integer
    +totalBatches: Integer
    +criticalItems: List<ExpiryAlert>
    +totalValue: BigDecimal
    --
    +generatePDF(): byte[]
    +sendEmail(): void
}

' =====================================================
' RELACIONES
' =====================================================

Supplier ||--o{ Product : "supplies"
Product ||--o{ Batch : "has"
Batch ||--o{ StockMovement : "movements"
User ||--o{ StockMovement : "creates"

Product --> Priority : "calculates"
Batch --> BatchStatus : "has"
Batch --> Priority : "calculates"
StockMovement --> MovementType : "has"
User --> UserRole : "has"

Batch ..> ExpiryAlert : "generates"
ExpiryAlert ..> InventoryReport : "includes"

' =====================================================
' NOTAS
' =====================================================

note top of Product : "Catálogo de productos\ncon información básica"

note right of Batch : "Lotes con fechas de vencimiento\ny cantidades específicas"

note bottom of StockMovement : "Registro de todos los\nmovimientos de inventario"

note left of ExpiryAlert : "Alertas generadas\npor reglas de negocio"

@enduml
```

## 2. Diagrama de Casos de Uso

```plantuml
@startuml Casos_Uso_MVP
!theme plain

' =====================================================
' ACTORES
' =====================================================

actor "Operador" as OP
actor "Visor" as VI
actor "Administrador" as AD

' =====================================================
' SISTEMA
' =====================================================

rectangle "Sistema Gestión Caducidades" {
    
    ' Gestión de Catálogos
    package "Gestión de Catálogos" {
        usecase "UC01\nGestionar Productos" as UC01
        usecase "UC02\nGestionar Proveedores" as UC02
    }
    
    ' Gestión de Inventario
    package "Gestión de Inventario" {
        usecase "UC03\nRegistrar Lotes" as UC03
        usecase "UC04\nActualizar Stock" as UC04
        usecase "UC05\nImportar CSV" as UC05
    }
    
    ' Monitoreo y Alertas
    package "Monitoreo y Alertas" {
        usecase "UC06\nConsultar Próximos\na Vencer" as UC06
        usecase "UC07\nGenerar Alertas\nSemáforo" as UC07
        usecase "UC08\nFiltrar por\nPrioridad" as UC08
    }
    
    ' Reportería
    package "Reportería" {
        usecase "UC09\nGenerar Reporte\nPDF Semanal" as UC09
        usecase "UC10\nExportar Datos" as UC10
    }
    
    ' Administración
    package "Administración" {
        usecase "UC11\nGestionar Usuarios" as UC11
        usecase "UC12\nAuditar Cambios" as UC12
        usecase "UC13\nConfigurar Sistema" as UC13
    }
}

' =====================================================
' RELACIONES PRINCIPALES
' =====================================================

' Operador - Gestión completa
OP --> UC01
OP --> UC02
OP --> UC03
OP --> UC04
OP --> UC05
OP --> UC06
OP --> UC07
OP --> UC08
OP --> UC09
OP --> UC10

' Visor - Solo consulta
VI --> UC06
VI --> UC07
VI --> UC08
VI --> UC09

' Administrador - Acceso total
AD --> UC01
AD --> UC02
AD --> UC03
AD --> UC04
AD --> UC05
AD --> UC06
AD --> UC07
AD --> UC08
AD --> UC09
AD --> UC10
AD --> UC11
AD --> UC12
AD --> UC13

' =====================================================
' RELACIONES ENTRE CASOS DE USO
' =====================================================

UC03 .> UC04 : <<include>>
UC05 .> UC01 : <<include>>
UC05 .> UC03 : <<include>>
UC07 .> UC06 : <<include>>
UC09 .> UC06 : <<include>>
UC12 .> UC04 : <<include>>

' =====================================================
' NOTAS ACLARATORIAS
' =====================================================

note right of UC05 : "Validación de plantilla CSV\ny reporte de errores"

note top of UC07 : "Reglas: Rojo <7 días\nÁmbar 7-30 días\nVerde >30 días"

note bottom of UC09 : "Top 20 productos\npróximos a vencer"

note left of UC12 : "Registro de quién\ny cuándo modificó"

@enduml
```

## 3. Diagrama de Arquitectura del Sistema

```plantuml
@startuml Arquitectura_Sistema
!theme plain

' =====================================================
' CAPAS DE LA APLICACIÓN
' =====================================================

package "Frontend Layer" {
    component [Angular App] as WEB
    component [Angular Material] as UI
    component [RxJS] as RX
    component [Lazy Modules] as LAZY
    
    WEB --> UI
    WEB --> RX
    WEB --> LAZY
}

package "API Gateway Layer" {
    component [Spring Boot API] as API
    component [REST Controllers] as REST
    component [OpenAPI/Swagger] as SWAGGER
    component [Security Filter] as SEC
    
    API --> REST
    API --> SWAGGER
    API --> SEC
}

package "Business Layer" {
    component [Product Service] as PROD_SVC
    component [Batch Service] as BATCH_SVC
    component [Alert Service] as ALERT_SVC
    component [Report Service] as REPORT_SVC
    component [Import Service] as IMPORT_SVC
    
    PROD_SVC --> BATCH_SVC
    ALERT_SVC --> BATCH_SVC
    REPORT_SVC --> BATCH_SVC
    IMPORT_SVC --> PROD_SVC
    IMPORT_SVC --> BATCH_SVC
}

package "Data Layer" {
    component [JPA Repositories] as REPO
    component [Entity Models] as ENTITY
    component [Database Views] as VIEWS
    
    REPO --> ENTITY
    REPO --> VIEWS
}

package "Database Layer" {
    database "PostgreSQL" as DB {
        component [Tables] as TABLES
        component [Indexes] as IDX
        component [Functions] as FUNCS
        component [Triggers] as TRIG
    }
    
    TABLES --> IDX
    TABLES --> FUNCS
    TABLES --> TRIG
}

' =====================================================
' INTEGRACIONES EXTERNAS
' =====================================================

package "External Services" {
    component [PDF Generator] as PDF
    component [Email Service] as EMAIL
    component [File Storage] as FILES
}

package "Monitoring & Logging" {
    component [Application Logs] as LOGS
    component [Performance Metrics] as METRICS
    component [Health Checks] as HEALTH
}

' =====================================================
' FLUJO DE DATOS
' =====================================================

WEB --> API : "HTTP/REST"
API --> REST
REST --> PROD_SVC
REST --> BATCH_SVC
REST --> ALERT_SVC
REST --> REPORT_SVC
REST --> IMPORT_SVC

PROD_SVC --> REPO
BATCH_SVC --> REPO
ALERT_SVC --> REPO
REPORT_SVC --> REPO
IMPORT_SVC --> REPO

REPO --> DB

REPORT_SVC --> PDF
ALERT_SVC --> EMAIL
IMPORT_SVC --> FILES

API --> LOGS
API --> METRICS
API --> HEALTH

' =====================================================
' NOTAS TÉCNICAS
' =====================================================

note top of WEB : "SPA con lazy loading\ny responsive design"

note right of API : "RESTful API con\nvalidaciones y CORS"

note bottom of DB : "Índices optimizados\npara consultas de fecha"

note left of PDF : "Reportes con\ncharts y tablas"

@enduml
```

## 4. Diagrama Entidad-Relación (DER)

```plantuml
@startuml Diagrama_ER
!theme plain

' =====================================================
' ENTIDADES
' =====================================================

entity "supplier" {
    * id : UUID <<PK>>
    --
    * name : TEXT
    contact : TEXT
    email : VARCHAR(255)
    phone : VARCHAR(20)
    address : TEXT
    created_at : TIMESTAMP
    updated_at : TIMESTAMP
    created_by : VARCHAR(100)
    updated_by : VARCHAR(100)
}

entity "product" {
    * id : UUID <<PK>>
    --
    * sku : TEXT <<UK>>
    * name : TEXT
    description : TEXT
    category : TEXT
    * unit : TEXT
    min_stock : INT
    supplier_id : UUID <<FK>>
    is_active : BOOLEAN
    created_at : TIMESTAMP
    updated_at : TIMESTAMP
    created_by : VARCHAR(100)
    updated_by : VARCHAR(100)
}

entity "batch" {
    * id : UUID <<PK>>
    --
    * product_id : UUID <<FK>>
    * batch_code : TEXT
    * expiration_date : DATE
    production_date : DATE
    * quantity : INT
    * cost : NUMERIC(12,2)
    location : TEXT
    status : VARCHAR(20)
    created_at : TIMESTAMP
    updated_at : TIMESTAMP
    created_by : VARCHAR(100)
    updated_by : VARCHAR(100)
}

entity "stock_movement" {
    * id : UUID <<PK>>
    --
    * batch_id : UUID <<FK>>
    * movement_type : VARCHAR(10)
    * quantity : INT
    * previous_quantity : INT
    * new_quantity : INT
    reason : TEXT
    note : TEXT
    * created_at : TIMESTAMP
    * created_by : VARCHAR(100)
}

entity "users" {
    * id : UUID <<PK>>
    --
    * username : VARCHAR(50) <<UK>>
    * email : VARCHAR(255) <<UK>>
    * password_hash : TEXT
    * full_name : VARCHAR(255)
    * role : VARCHAR(20)
    is_active : BOOLEAN
    last_login : TIMESTAMP
    created_at : TIMESTAMP
    updated_at : TIMESTAMP
}

' =====================================================
' VISTA MATERIALIZADA
' =====================================================

entity "v_near_expiry" {
    batch_id : UUID
    batch_code : TEXT
    expiration_date : DATE
    quantity : INT
    cost : NUMERIC(12,2)
    location : TEXT
    product_id : UUID
    sku : TEXT
    product_name : TEXT
    category : TEXT
    unit : TEXT
    supplier_name : TEXT
    days_to_expire : INT
    priority : TEXT
    created_at : TIMESTAMP
    updated_at : TIMESTAMP
}

' =====================================================
' RELACIONES
' =====================================================

supplier ||--o{ product : "supplies"
product ||--o{ batch : "contains"
batch ||--o{ stock_movement : "has movements"
users ||--o{ stock_movement : "creates"

' Relaciones para la vista
batch ||--|| v_near_expiry : "materializes"
product ||--|| v_near_expiry : "includes"
supplier ||--|| v_near_expiry : "references"

' =====================================================
' ÍNDICES CRÍTICOS
' =====================================================

note top of batch : "Índices:\n- expiration_date\n- product_id + expiration_date\n- batch_code\n- status + quantity"

note right of product : "Índices:\n- sku (único)\n- name\n- category\n- supplier_id"

note bottom of stock_movement : "Índices:\n- batch_id\n- movement_type\n- created_at\n- created_by"

note left of v_near_expiry : "Vista optimizada para\nconsultas de vencimiento\ny tablero de control"

@enduml
```

## 5. Diagrama de Secuencia - Importación CSV

```plantuml
@startuml Secuencia_Importacion_CSV
!theme plain

actor "Operador" as OP
participant "Frontend" as FE
participant "ImportController" as CTRL
participant "ImportService" as SVC
participant "ValidationService" as VAL
participant "ProductService" as PROD
participant "BatchService" as BATCH
database "PostgreSQL" as DB

== Inicio de Importación ==

OP -> FE : Selecciona archivo CSV
FE -> FE : Valida formato y tamaño
FE -> CTRL : POST /api/import/validate

CTRL -> SVC : validateFile(file)
SVC -> VAL : validateCSVStructure(file)
VAL -> SVC : ValidationResult
SVC -> CTRL : ValidationResponse
CTRL -> FE : Response con errores/éxitos

alt Validación exitosa
    FE -> OP : Muestra preview de datos
    OP -> FE : Confirma importación
    
    == Procesamiento por Lotes ==
    
    FE -> CTRL : POST /api/import/process
    CTRL -> SVC : processImport(file, options)
    
    loop Por cada fila del CSV
        SVC -> VAL : validateRow(row)
        
        alt Fila válida
            SVC -> PROD : findOrCreateProduct(productData)
            PROD -> DB : SELECT/INSERT product
            DB -> PROD : Product entity
            PROD -> SVC : Product result
            
            SVC -> BATCH : createBatch(batchData)
            BATCH -> DB : INSERT batch
            DB -> BATCH : Batch entity
            BATCH -> SVC : Batch result
            
            SVC -> SVC : addToSuccessLog(row)
        else Fila inválida
            SVC -> SVC : addToErrorLog(row, errors)
        end
    end
    
    SVC -> SVC : generateImportReport()
    SVC -> CTRL : ImportResult
    CTRL -> FE : Response con estadísticas
    
    FE -> OP : Muestra resumen de importación
    
else Validación fallida
    FE -> OP : Muestra errores de validación
end

@enduml
```

## Uso de los Diagramas

Estos diagramas están en formato PlantUML y pueden ser utilizados de las siguientes maneras:

1. **Copiar en herramientas online:**
   - [PlantUML Online](http://www.plantuml.com/plantuml/uml/)
   - [PlantText](https://www.planttext.com/)

2. **Integrar en documentación:**
   - GitLab/GitHub con soporte PlantUML
   - Confluence con plugin PlantUML
   - VS Code con extensión PlantUML

3. **Generar imágenes:**
   - Exportar como PNG/SVG para documentos
   - Incluir en presentaciones del proyecto

## Próximos Pasos

1. Revisar y ajustar los diagramas según feedback del equipo
2. Implementar las entidades del modelo de dominio
3. Crear la especificación OpenAPI detallada
4. Configurar el entorno de desarrollo con Docker
