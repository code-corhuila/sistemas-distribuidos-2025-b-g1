-- =====================================================
-- DDL v0 - Sistema de Gestión de Inventario
-- Control de Productos Próximos a Vencer
-- =====================================================

-- Extensiones necesarias para UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- TABLA: supplier (Proveedores)
-- =====================================================
CREATE TABLE supplier (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    contact TEXT,
    email VARCHAR(255),
    phone VARCHAR(20),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    updated_by VARCHAR(100)
);

-- Índices para supplier
CREATE INDEX idx_supplier_name ON supplier(name);

-- =====================================================
-- TABLA: product (Productos)
-- =====================================================
CREATE TABLE product (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sku TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    category TEXT,
    unit TEXT NOT NULL DEFAULT 'UNIT', -- UNIT, KG, L, etc.
    min_stock INT DEFAULT 0,
    supplier_id UUID REFERENCES supplier(id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    updated_by VARCHAR(100)
);

-- Índices para product
CREATE INDEX idx_product_sku ON product(sku);
CREATE INDEX idx_product_name ON product(name);
CREATE INDEX idx_product_category ON product(category);
CREATE INDEX idx_product_supplier ON product(supplier_id);

-- =====================================================
-- TABLA: batch (Lotes)
-- =====================================================
CREATE TABLE batch (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES product(id),
    batch_code TEXT NOT NULL,
    expiration_date DATE NOT NULL,
    production_date DATE,
    quantity INT NOT NULL CHECK (quantity >= 0),
    cost NUMERIC(12,2) NOT NULL CHECK (cost >= 0),
    location TEXT,
    status VARCHAR(20) DEFAULT 'ACTIVE', -- ACTIVE, EXPIRED, SOLD_OUT
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    updated_by VARCHAR(100),
    
    -- Constraint: batch_code único por producto
    UNIQUE(product_id, batch_code)
);

-- Índices críticos para rendimiento
CREATE INDEX idx_batch_exp_date ON batch(expiration_date);
CREATE INDEX idx_batch_prod_exp ON batch(product_id, expiration_date);
CREATE INDEX idx_batch_code ON batch(batch_code);
CREATE INDEX idx_batch_status ON batch(status);
CREATE INDEX idx_batch_location ON batch(location);

-- =====================================================
-- TABLA: stock_movement (Movimientos de Stock)
-- =====================================================
CREATE TABLE stock_movement (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    batch_id UUID NOT NULL REFERENCES batch(id),
    movement_type VARCHAR(10) NOT NULL CHECK (movement_type IN ('IN', 'OUT', 'ADJ')),
    quantity INT NOT NULL,
    previous_quantity INT NOT NULL,
    new_quantity INT NOT NULL,
    reason TEXT,
    note TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL
);

-- Índices para stock_movement
CREATE INDEX idx_stock_movement_batch ON stock_movement(batch_id);
CREATE INDEX idx_stock_movement_type ON stock_movement(movement_type);
CREATE INDEX idx_stock_movement_date ON stock_movement(created_at);

-- =====================================================
-- TABLA: users (Usuarios del sistema)
-- =====================================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('ADMIN', 'OPERATOR', 'VIEWER')),
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para users
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- =====================================================
-- VISTA: near_expiry (Productos próximos a vencer)
-- =====================================================
CREATE OR REPLACE VIEW v_near_expiry AS
SELECT 
    b.id as batch_id,
    b.batch_code,
    b.expiration_date,
    b.quantity,
    b.cost,
    b.location,
    p.id as product_id,
    p.sku,
    p.name as product_name,
    p.category,
    p.unit,
    s.name as supplier_name,
    (b.expiration_date - CURRENT_DATE) as days_to_expire,
    CASE 
        WHEN (b.expiration_date - CURRENT_DATE) < 7 THEN 'RED'
        WHEN (b.expiration_date - CURRENT_DATE) BETWEEN 7 AND 30 THEN 'AMBER'
        ELSE 'GREEN'
    END as priority,
    b.created_at,
    b.updated_at
FROM batch b
INNER JOIN product p ON b.product_id = p.id
LEFT JOIN supplier s ON p.supplier_id = s.id
WHERE b.status = 'ACTIVE' 
  AND b.quantity > 0
  AND p.is_active = TRUE
ORDER BY b.expiration_date ASC;

-- =====================================================
-- FUNCIÓN: Calcular prioridad de vencimiento
-- =====================================================
CREATE OR REPLACE FUNCTION calculate_expiry_priority(expiration_date DATE)
RETURNS TEXT AS $$
BEGIN
    CASE 
        WHEN (expiration_date - CURRENT_DATE) < 7 THEN 
            RETURN 'RED';
        WHEN (expiration_date - CURRENT_DATE) BETWEEN 7 AND 30 THEN 
            RETURN 'AMBER';
        ELSE 
            RETURN 'GREEN';
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNCIÓN: Trigger para actualizar updated_at
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger a todas las tablas con updated_at
CREATE TRIGGER tr_supplier_updated_at 
    BEFORE UPDATE ON supplier 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_product_updated_at 
    BEFORE UPDATE ON product 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_batch_updated_at 
    BEFORE UPDATE ON batch 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- FUNCIÓN: Actualizar stock automáticamente
-- =====================================================
CREATE OR REPLACE FUNCTION update_batch_quantity()
RETURNS TRIGGER AS $$
BEGIN
    -- Actualizar la cantidad en el lote
    UPDATE batch 
    SET quantity = NEW.new_quantity,
        status = CASE 
            WHEN NEW.new_quantity = 0 THEN 'SOLD_OUT'
            WHEN expiration_date < CURRENT_DATE THEN 'EXPIRED'
            ELSE 'ACTIVE'
        END
    WHERE id = NEW.batch_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_update_batch_quantity
    AFTER INSERT ON stock_movement
    FOR EACH ROW EXECUTE FUNCTION update_batch_quantity();

-- =====================================================
-- ÍNDICES ADICIONALES PARA RENDIMIENTO
-- =====================================================

-- Índice compuesto para consultas de prioridad
CREATE INDEX idx_batch_priority_query ON batch(expiration_date, status, quantity) 
WHERE status = 'ACTIVE' AND quantity > 0;

-- Índice para auditoría
CREATE INDEX idx_stock_movement_audit ON stock_movement(created_by, created_at);

-- =====================================================
-- COMENTARIOS EN TABLAS
-- =====================================================
COMMENT ON TABLE supplier IS 'Proveedores de productos';
COMMENT ON TABLE product IS 'Catálogo de productos';
COMMENT ON TABLE batch IS 'Lotes de productos con fechas de vencimiento';
COMMENT ON TABLE stock_movement IS 'Movimientos de inventario (entradas, salidas, ajustes)';
COMMENT ON TABLE users IS 'Usuarios del sistema con roles';
COMMENT ON VIEW v_near_expiry IS 'Vista optimizada para consultar productos próximos a vencer';

-- =====================================================
-- FIN DEL SCRIPT DDL v0
-- =====================================================
