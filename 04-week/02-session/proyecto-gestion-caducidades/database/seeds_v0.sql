-- =====================================================
-- SEEDS v0 - Datos de prueba
-- Sistema de Gestión de Inventario
-- =====================================================

-- Limpiar datos existentes (para desarrollo)
TRUNCATE TABLE stock_movement CASCADE;
TRUNCATE TABLE batch CASCADE;
TRUNCATE TABLE product CASCADE;
TRUNCATE TABLE supplier CASCADE;
TRUNCATE TABLE users CASCADE;

-- =====================================================
-- USUARIOS DEL SISTEMA
-- =====================================================
INSERT INTO users (id, username, email, password_hash, full_name, role) VALUES
    (uuid_generate_v4(), 'admin', 'admin@corhuila.edu.co', '$2a$10$example_hash_admin', 'Administrador Sistema', 'ADMIN'),
    (uuid_generate_v4(), 'operador1', 'operador1@corhuila.edu.co', '$2a$10$example_hash_op1', 'Juan Pérez', 'OPERATOR'),
    (uuid_generate_v4(), 'operador2', 'operador2@corhuila.edu.co', '$2a$10$example_hash_op2', 'María García', 'OPERATOR'),
    (uuid_generate_v4(), 'visor1', 'visor1@corhuila.edu.co', '$2a$10$example_hash_viewer', 'Carlos López', 'VIEWER');

-- =====================================================
-- PROVEEDORES
-- =====================================================
INSERT INTO supplier (id, name, contact, email, phone, address, created_by) VALUES
    (uuid_generate_v4(), 'Distribuidora La Cosecha', 'Ana Rodríguez', 'ventas@lacosecha.com.co', '+57 318 456 7890', 'Calle 15 #23-45, Neiva', 'admin'),
    (uuid_generate_v4(), 'Frigoríficos del Huila', 'Pedro Martínez', 'comercial@frigohuila.com.co', '+57 320 123 4567', 'Zona Industrial, Neiva', 'admin'),
    (uuid_generate_v4(), 'Lácteos San Agustín', 'Laura Sánchez', 'info@lacteossanagustin.com', '+57 315 987 6543', 'Vía San Agustín Km 12, Huila', 'admin'),
    (uuid_generate_v4(), 'Panadería Central', 'Roberto Jiménez', 'pedidos@panaderiacentral.com', '+57 311 555 0123', 'Centro, Neiva', 'admin'),
    (uuid_generate_v4(), 'Medicamentos Farma Plus', 'Dra. Elena Vargas', 'gerencia@farmaplus.com.co', '+57 317 888 9999', 'Av. Circunvalar #45-67, Neiva', 'admin');

-- Variables para almacenar IDs (simulando, ya que PostgreSQL no tiene variables como MySQL)
-- Usaremos CTEs en las siguientes inserciones

-- =====================================================
-- PRODUCTOS
-- =====================================================
WITH supplier_ids AS (
    SELECT id, name FROM supplier
),
product_data AS (
    SELECT 
        uuid_generate_v4() as id,
        sku,
        name,
        description,
        category,
        unit,
        min_stock,
        supplier_name,
        'admin' as created_by
    FROM (VALUES
        ('PROD-001', 'Leche Entera 1L', 'Leche pasteurizada entera en bolsa', 'LACTEOS', 'L', 50, 'Lácteos San Agustín'),
        ('PROD-002', 'Yogurt Natural 200g', 'Yogurt natural sin azúcar', 'LACTEOS', 'UNIT', 30, 'Lácteos San Agustín'),
        ('PROD-003', 'Queso Campesino 500g', 'Queso fresco tipo campesino', 'LACTEOS', 'UNIT', 20, 'Lácteos San Agustín'),
        ('PROD-004', 'Pan Integral 750g', 'Pan integral con semillas', 'PANADERIA', 'UNIT', 40, 'Panadería Central'),
        ('PROD-005', 'Croissant x6', 'Croissants frescos pack de 6', 'PANADERIA', 'PACK', 25, 'Panadería Central'),
        ('PROD-006', 'Pollo Entero', 'Pollo entero fresco', 'CARNES', 'KG', 15, 'Frigoríficos del Huila'),
        ('PROD-007', 'Carne Molida 500g', 'Carne molida de res', 'CARNES', 'UNIT', 25, 'Frigoríficos del Huila'),
        ('PROD-008', 'Manzanas Rojas', 'Manzanas rojas importadas', 'FRUTAS', 'KG', 30, 'Distribuidora La Cosecha'),
        ('PROD-009', 'Bananos', 'Bananos frescos nacionales', 'FRUTAS', 'KG', 40, 'Distribuidora La Cosecha'),
        ('PROD-010', 'Tomates', 'Tomates frescos locales', 'VERDURAS', 'KG', 35, 'Distribuidora La Cosecha'),
        ('PROD-011', 'Lechuga', 'Lechuga crespa fresca', 'VERDURAS', 'UNIT', 20, 'Distribuidora La Cosecha'),
        ('PROD-012', 'Paracetamol 500mg', 'Analgésico antipirético', 'MEDICAMENTOS', 'UNIT', 100, 'Medicamentos Farma Plus'),
        ('PROD-013', 'Ibuprofeno 400mg', 'Antiinflamatorio no esteroideo', 'MEDICAMENTOS', 'UNIT', 80, 'Medicamentos Farma Plus'),
        ('PROD-014', 'Vitamina C 1g', 'Suplemento vitamínico', 'MEDICAMENTOS', 'UNIT', 60, 'Medicamentos Farma Plus'),
        ('PROD-015', 'Alcohol Antiséptico 70%', 'Alcohol para desinfección', 'MEDICAMENTOS', 'ML', 200, 'Medicamentos Farma Plus')
    ) AS v(sku, name, description, category, unit, min_stock, supplier_name)
)
INSERT INTO product (id, sku, name, description, category, unit, min_stock, supplier_id, created_by)
SELECT 
    pd.id,
    pd.sku,
    pd.name,
    pd.description,
    pd.category,
    pd.unit,
    pd.min_stock,
    s.id,
    pd.created_by
FROM product_data pd
JOIN supplier_ids s ON s.name = pd.supplier_name;

-- =====================================================
-- LOTES CON DIFERENTES ESTADOS DE VENCIMIENTO
-- =====================================================
WITH product_ids AS (
    SELECT id, sku FROM product
),
batch_data AS (
    SELECT 
        uuid_generate_v4() as id,
        product_sku,
        batch_code,
        expiration_date,
        production_date,
        quantity,
        cost,
        location,
        'admin' as created_by
    FROM (VALUES
        -- ROJOS (< 7 días) - CRÍTICOS
        ('PROD-001', 'LOTE-2025-001', CURRENT_DATE + INTERVAL '3 days', CURRENT_DATE - INTERVAL '15 days', 25, 2500.00, 'ESTANTE-A1'),
        ('PROD-002', 'LOTE-2025-002', CURRENT_DATE + INTERVAL '5 days', CURRENT_DATE - INTERVAL '10 days', 18, 1800.00, 'NEVERA-B2'),
        ('PROD-012', 'LOTE-2025-003', CURRENT_DATE + INTERVAL '6 days', CURRENT_DATE - INTERVAL '90 days', 50, 25000.00, 'FARMACIA-C1'),
        ('PROD-004', 'LOTE-2025-004', CURRENT_DATE + INTERVAL '2 days', CURRENT_DATE - INTERVAL '3 days', 12, 3600.00, 'PANADERIA-D1'),
        ('PROD-006', 'LOTE-2025-005', CURRENT_DATE + INTERVAL '4 days', CURRENT_DATE - INTERVAL '5 days', 8, 16000.00, 'FRIGORIFICO-E1'),
        
        -- ÁMBAR (7-30 días) - PRECAUCIÓN
        ('PROD-003', 'LOTE-2025-006', CURRENT_DATE + INTERVAL '15 days', CURRENT_DATE - INTERVAL '20 days', 30, 15000.00, 'NEVERA-B1'),
        ('PROD-005', 'LOTE-2025-007', CURRENT_DATE + INTERVAL '10 days', CURRENT_DATE - INTERVAL '2 days', 22, 6600.00, 'PANADERIA-D2'),
        ('PROD-007', 'LOTE-2025-008', CURRENT_DATE + INTERVAL '12 days', CURRENT_DATE - INTERVAL '3 days', 15, 22500.00, 'FRIGORIFICO-E2'),
        ('PROD-013', 'LOTE-2025-009', CURRENT_DATE + INTERVAL '25 days', CURRENT_DATE - INTERVAL '60 days', 75, 37500.00, 'FARMACIA-C2'),
        ('PROD-014', 'LOTE-2025-010', CURRENT_DATE + INTERVAL '20 days', CURRENT_DATE - INTERVAL '30 days', 45, 13500.00, 'FARMACIA-C3'),
        
        -- VERDES (> 30 días) - SEGUROS
        ('PROD-001', 'LOTE-2025-011', CURRENT_DATE + INTERVAL '45 days', CURRENT_DATE - INTERVAL '5 days', 100, 10000.00, 'ESTANTE-A2'),
        ('PROD-008', 'LOTE-2025-012', CURRENT_DATE + INTERVAL '60 days', CURRENT_DATE - INTERVAL '2 days', 50, 7500.00, 'FRUTAS-F1'),
        ('PROD-009', 'LOTE-2025-013', CURRENT_DATE + INTERVAL '35 days', CURRENT_DATE - INTERVAL '1 days', 80, 4000.00, 'FRUTAS-F2'),
        ('PROD-010', 'LOTE-2025-014', CURRENT_DATE + INTERVAL '40 days', CURRENT_DATE - INTERVAL '1 days', 60, 3600.00, 'VERDURAS-G1'),
        ('PROD-011', 'LOTE-2025-015', CURRENT_DATE + INTERVAL '32 days', CURRENT_DATE - INTERVAL '1 days', 35, 1750.00, 'VERDURAS-G2'),
        ('PROD-015', 'LOTE-2025-016', CURRENT_DATE + INTERVAL '180 days', CURRENT_DATE - INTERVAL '10 days', 150, 15000.00, 'FARMACIA-C4'),
        
        -- Lotes adicionales para testing de volumen
        ('PROD-002', 'LOTE-2025-017', CURRENT_DATE + INTERVAL '8 days', CURRENT_DATE - INTERVAL '8 days', 40, 4000.00, 'NEVERA-B3'),
        ('PROD-004', 'LOTE-2025-018', CURRENT_DATE + INTERVAL '50 days', CURRENT_DATE - INTERVAL '1 days', 60, 18000.00, 'PANADERIA-D3'),
        ('PROD-006', 'LOTE-2025-019', CURRENT_DATE + INTERVAL '7 days', CURRENT_DATE - INTERVAL '4 days', 20, 40000.00, 'FRIGORIFICO-E3'),
        ('PROD-012', 'LOTE-2025-020', CURRENT_DATE + INTERVAL '90 days', CURRENT_DATE - INTERVAL '30 days', 200, 100000.00, 'FARMACIA-C5')
    ) AS v(product_sku, batch_code, expiration_date, production_date, quantity, cost, location)
)
INSERT INTO batch (id, product_id, batch_code, expiration_date, production_date, quantity, cost, location, created_by)
SELECT 
    bd.id,
    p.id,
    bd.batch_code,
    bd.expiration_date,
    bd.production_date,
    bd.quantity,
    bd.cost,
    bd.location,
    bd.created_by
FROM batch_data bd
JOIN product_ids p ON p.sku = bd.product_sku;

-- =====================================================
-- MOVIMIENTOS DE STOCK INICIALES
-- =====================================================
WITH batch_ids AS (
    SELECT id, batch_code, quantity FROM batch
)
INSERT INTO stock_movement (id, batch_id, movement_type, quantity, previous_quantity, new_quantity, reason, note, created_by)
SELECT 
    uuid_generate_v4(),
    b.id,
    'IN',
    b.quantity,
    0,
    b.quantity,
    'INGRESO_INICIAL',
    'Ingreso inicial de lote - carga de datos semilla',
    'admin'
FROM batch_ids b;

-- =====================================================
-- ALGUNOS MOVIMIENTOS DE SALIDA PARA SIMULAR ACTIVIDAD
-- =====================================================
WITH recent_batches AS (
    SELECT id, quantity FROM batch WHERE batch_code IN ('LOTE-2025-001', 'LOTE-2025-006', 'LOTE-2025-011')
)
INSERT INTO stock_movement (id, batch_id, movement_type, quantity, previous_quantity, new_quantity, reason, note, created_by)
SELECT 
    uuid_generate_v4(),
    rb.id,
    'OUT',
    5,
    rb.quantity,
    rb.quantity - 5,
    'VENTA',
    'Salida por venta - movimiento de prueba',
    'operador1'
FROM recent_batches rb;

-- Actualizar las cantidades en los lotes después de las salidas
UPDATE batch SET quantity = quantity - 5 
WHERE batch_code IN ('LOTE-2025-001', 'LOTE-2025-006', 'LOTE-2025-011');

-- =====================================================
-- ESTADÍSTICAS GENERADAS
-- =====================================================

-- Mostrar resumen de datos cargados
SELECT 'Proveedores' as tabla, COUNT(*) as registros FROM supplier
UNION ALL
SELECT 'Productos' as tabla, COUNT(*) as registros FROM product
UNION ALL
SELECT 'Lotes' as tabla, COUNT(*) as registros FROM batch
UNION ALL
SELECT 'Movimientos' as tabla, COUNT(*) as registros FROM stock_movement
UNION ALL
SELECT 'Usuarios' as tabla, COUNT(*) as registros FROM users;

-- Mostrar distribución por prioridad
SELECT 
    CASE 
        WHEN (expiration_date - CURRENT_DATE) < 7 THEN 'ROJO (< 7 días)'
        WHEN (expiration_date - CURRENT_DATE) BETWEEN 7 AND 30 THEN 'ÁMBAR (7-30 días)'
        ELSE 'VERDE (> 30 días)'
    END as prioridad,
    COUNT(*) as cantidad_lotes,
    SUM(quantity) as total_unidades,
    ROUND(SUM(cost * quantity), 2) as valor_total
FROM batch 
WHERE status = 'ACTIVE'
GROUP BY 
    CASE 
        WHEN (expiration_date - CURRENT_DATE) < 7 THEN 'ROJO (< 7 días)'
        WHEN (expiration_date - CURRENT_DATE) BETWEEN 7 AND 30 THEN 'ÁMBAR (7-30 días)'
        ELSE 'VERDE (> 30 días)'
    END
ORDER BY 
    CASE 
        WHEN prioridad = 'ROJO (< 7 días)' THEN 1
        WHEN prioridad = 'ÁMBAR (7-30 días)' THEN 2
        ELSE 3
    END;

-- =====================================================
-- FIN SCRIPT DE SEEDS v0
-- =====================================================

-- Comentario final
SELECT 'Seeds v0 cargados exitosamente' as status, 
       'Base de datos lista para desarrollo y testing' as mensaje;
