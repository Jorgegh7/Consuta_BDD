-- ================================================
         -- CASO 1:
-- ================================================

---------------------------------------------------
-- Creacion de Roles desde Usuario SYS
---------------------------------------------------

--Creacion ROL PRY2205_ROL_D
CREATE ROLE PRY2205_ROL_D; 

--Privilegios de sistema
GRANT CREATE TABLE,
      CREATE VIEW, 
      CREATE SYNONYM,
      CREATE PUBLIC SYNONYM, 
      CREATE SEQUENCE 
TO PRY2205_ROL_D;  

--Creacion ROL PRY2205_ROL_P
CREATE ROLE PRY2205_ROL_P; 

--Privilegios de sistema
GRANT CREATE SEQUENCE,
      CREATE TRIGGER,
      CREATE TABLE     
TO PRY2205_ROL_P; 

---------------------------------------------------
    -- Creacion de Usuarios desde Usuario SYS
---------------------------------------------------

-- Creacion de Usuario PRY2205_USER1

ALTER SESSION SET "_Oracle_Script"=TRUE;

CREATE USER PRY2205_USER1 
IDENTIFIED BY "PRY2205.USER1" 
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON USERS;

-- Otorgar permiso para crear sesión 
GRANT CREATE SESSION TO PRY2205_USER1;

-- Entrega Rol a usuario PRY2205_USER1
GRANT PRY2205_ROL_D TO PRY2205_USER1;

-- Creacion de Usuario PRY2205_USER2

CREATE USER PRY2205_USER2 
IDENTIFIED BY "PRY2205.USER2" 
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON USERS;

-- Otorgar permiso para crear sesión
GRANT CREATE SESSION TO PRY2205_USER2;

-- Entrega Rol a usuario PRY2205_USER2
GRANT PRY2205_ROL_P TO PRY2205_USER2;

-- A PESAR DE CREAR EL ROL Y ENREGARSELO AL USUARIO1 
-- TUVE QUE DARLE EL PERMISO PARA CREAR VIEW DE FORMA MANUAL DESDE SYS
-- GRANT CREATE VIEW TO PRY2205_USER1;

---------------------------------------------------
    -- Creación de Sinónimos desde PRY2205_USER1
---------------------------------------------------

-- Sinónimos Publicos (con acceso PRY2205_USER2 Caso 2)
CREATE PUBLIC SYNONYM libro FOR PRY2205_USER1.libro;
CREATE PUBLIC SYNONYM ejemplar FOR PRY2205_USER1.ejemplar;
CREATE PUBLIC SYNONYM prestamo FOR PRY2205_USER1.prestamo;
CREATE PUBLIC SYNONYM empleado FOR PRY2205_USER1.empleado;

-- Sinónimos Privados (Acceso Caso 3)
CREATE SYNONYM prest FOR prestamo;
CREATE SYNONYM alu FOR alumno;
CREATE SYNONYM car FOR carrera;
CREATE SYNONYM lib FOR libro;
CREATE SYNONYM reb FOR rebaja_multa;

---------------------------------------------------
    -- Otorgar acceso SELECT a PRY2205_USER2 sobre las tablas para el caso 2  
---------------------------------------------------
GRANT SELECT ON libro TO PRY2205_USER2;
GRANT SELECT ON ejemplar TO PRY2205_USER2;
GRANT SELECT ON prestamo TO PRY2205_USER2;
GRANT SELECT ON empleado TO PRY2205_USER2;

-- ================================================
-- CASO 2 Creación de Informe desde PRY2205_USER2  
-- ================================================

---------------------------------------------------
    -- Creación de secuencia desde PRY2205_USER2  
---------------------------------------------------

CREATE SEQUENCE SEQ_CONTROL_STOCK
START WITH 1
INCREMENT BY 1
NOCACHE; 

---------------------------------------------------
-- Creación de tabla por medio de Select desde PRY2205_USER2    
---------------------------------------------------

--No se puede introducir directamente una SEQUENCE cuando hay ORDER BY 
--Hay que crear la tabla con ID_CONTROL DE FORMA inicial de lo contrario la columna quedaria al final
--La sentencia CREATE TABLE NO ACEPTA VALORES NULOS INDEFINIDOS 

CREATE TABLE CONTROL_STOCK_LIBROS
AS
SELECT 
    CAST(NULL AS NUMBER) AS "ID_CONTROL", 
    l.libroid AS "LIBRO_ID",
    l.nombre_libro,
    COUNT(DISTINCT e.ejemplarid)AS "TOTAL_EJEMPLARES",
    COUNT(DISTINCT p.ejemplarid) AS "EN_PRESTAMO",
    COUNT(DISTINCT e.ejemplarid) - COUNT(DISTINCT p.ejemplarid) AS "DISPONIBLES",
    ROUND((COUNT(DISTINCT p.ejemplarid) * 100) / COUNT(DISTINCT e.ejemplarid),2) AS "PORCENTAJE_PRESTAMO",
    CASE 
        WHEN (COUNT(DISTINCT e.ejemplarid) - 
              (SELECT COUNT(DISTINCT pres.ejemplarid)
               FROM prestamo pres
               WHERE pres.libroid = l.libroid
                 AND pres.fecha_inicio >= ADD_MONTHS(SYSDATE, -24))) > 2 THEN 'S'   -- > a 2 EJEMPLARES 
        ELSE 'N'
    END AS "STOCK_CRITICO"
FROM libro l
INNER JOIN ejemplar e ON e.libroid = l.libroid
INNER JOIN prestamo p ON p.libroid = l.libroid
INNER JOIN empleado emp ON emp.empleadoid = p.empleadoid
WHERE emp.empleadoid IN (150,180,190)
    AND MONTHS_BETWEEN(p.fecha_inicio, SYSDATE) <=24   --CONSIDERA LOS PRESTAMOS REALIZADOS 2 AÑOS ANTES DEL AÑO ACTUAL DE EJECUCIÓN
GROUP BY l.libroid, l.nombre_libro
ORDER BY l.libroid; 

-- En la pauta Informe Control Stock Bibliográfico hay un error al considerar valores N o S
-- Se consideran S teniendo valores < a 2 en DISPONIBLE 
-- EL enunciado dice: Si existen MAS de 2 ejemplares  DISPONIBLES, se asigna el valor 'S' (suficiente stock) 

---------------------------------------------------
-- OTORGARLE A ID_CONTROL EL VALOR DE LA SEQUENCE desde PRY2205_USER2  
---------------------------------------------------

UPDATE CONTROL_STOCK_LIBROS 
SET ID_CONTROL = SEQ_CONTROL_STOCK.NEXTVAL;

--
SELECT * FROM control_stock_libros; 
--

-- ================================================
-- CASO 3: Optimización de sentencias SQL Desde PRY2205_USER1
-- ================================================

---------------------------------------------------
-- 3.1 CREACIÓN DE VISTA desde PRY2205_USER1  
---------------------------------------------------

CREATE VIEW VW_DETALLE_MULTAS AS
SELECT
    p.prestamoid AS "ID_PRESTAMO",
    INITCAP(a.nombre || ' ' || a.apaterno) AS "NOMBRE_ALUMNO",
    c.descripcion AS "NOMBRE_CARRERA",
    p.libroid AS "ID_LIBRO", 
    TO_CHAR(l.precio, '$999G999G999')AS "VALOR_LIBRO",
    TO_CHAR(p.fecha_termino,'DD/MM/YYYY') AS "FECHA_TERMINO",
    TO_CHAR(p.fecha_entrega, 'DD/MM/YYYY') AS "FECHA_ENTREGA",
    p.fecha_entrega - p.fecha_termino AS "DIAS_ATRASO",
    TO_CHAR(ROUND(l.precio * 0.03 * (p.fecha_entrega - p.fecha_termino)), '$999G999G999') AS "VALOR_MULTA",
    NVL(r.porc_rebaja_multa/100,0)AS "PORCENTAJE_REBAJA_MULTA",
    CASE
        WHEN NVL(r.porc_rebaja_multa/100,0) >0 
            THEN TO_CHAR(ROUND(l.precio * 0.03 * (p.fecha_entrega - p.fecha_termino)) - (NVL(r.porc_rebaja_multa/100,0) * ROUND(l.precio * 0.03 * (p.fecha_entrega - p.fecha_termino))),'$999G999G999') 
        ELSE TO_CHAR(ROUND(l.precio * 0.03 * (p.fecha_entrega - p.fecha_termino)), '$999G999G999')    
    END AS "VALOR_REBAJADO"    
FROM prest p
INNER JOIN alu a ON a.alumnoid = p.alumnoid
INNER JOIN car c ON c.carreraid = a.carreraid
INNER JOIN lib l ON l.libroid = p.libroid
LEFT JOIN reb r ON r.carreraid = c.carreraid
WHERE p.fecha_entrega - p.fecha_termino > 0
    AND EXTRACT(YEAR FROM p.fecha_termino) = EXTRACT(YEAR FROM SYSDATE) -2
ORDER BY p.fecha_entrega DESC; 

SELECT * FROM VW_DETALLE_MULTAS; 

---------------------------------------------------
-- 3.2 CREACIÓN DE ÍNDICES desde PRY2205_USER1  
---------------------------------------------------

CREATE INDEX idx_prestamo_atraso ON prest((fecha_entrega - fecha_termino));

CREATE INDEX idx_car_desc ON car(descripcion);  

CREATE INDEX idx_prest_fecha_termino_annio ON prest(EXTRACT(YEAR FROM fecha_termino)); 

CREATE INDEX idx_lib_precio ON lib(precio);

CREATE INDEX idx_alumno_nombre_apellido ON alu(INITCAP(nombre || ' ' || apaterno));

CREATE INDEX idx_reb_porcentaje ON reb((porc_rebaja_multa/100)); 

