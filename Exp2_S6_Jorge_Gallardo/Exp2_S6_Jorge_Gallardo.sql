-- Actividad Sumativa Nº2

-- Caso 1: 
--  Identificar consultores que han trabajado en Banca (sector 3) y 
--  Retail (sector 4).
--  Mostrar:
--  ID y nombre completo.
--  Número de asesorías y honorarios por sector.
--  Totales generales.
--  Usar: Operadores SET, subconsultas, funciones, joins, agrupaciones.

SELECT
    p.id_profesional AS "ID",
    INITCAP(p.appaterno || ' '|| p.apmaterno || ' ' || p.nombre) AS "PROFESIONAL",
    
    (SELECT 
           COUNT(a2.honorario)
    FROM asesoria a2
    WHERE a2.id_profesional = p.id_profesional 
        AND a2.cod_empresa = 3) AS "NRO ASESORIA BANCA",
        
    (SELECT 
           TO_CHAR(SUM(a2.honorario), '$999G999G999')
    FROM asesoria a2
    WHERE a2.id_profesional = p.id_profesional 
        AND a2.cod_empresa = 3) AS "MONTO_TOTAL_BANCA",
        
     (SELECT 
            COUNT(a2.honorario)
    FROM asesoria a2
    WHERE a2.id_profesional = p.id_profesional 
        AND a2.cod_empresa = 4) AS "NRO ASESORIA RETAIL", 
        
    (SELECT 
           TO_CHAR(SUM(a2.honorario), '$999G999G999')
    FROM asesoria a2
    WHERE a2.id_profesional = p.id_profesional 
        AND a2.cod_empresa = 4) AS "MONTO_TOTAL_RETAIL",
        
    (SELECT 
           COUNT(a2.honorario)
     FROM asesoria a2
     WHERE a2.id_profesional = p.id_profesional 
     AND a2.cod_empresa IN(3,4)) AS "TOTAL ASESORIAS", 
     
     (SELECT 
           TO_CHAR(SUM(a2.honorario), '$999G999G999')
     FROM asesoria a2
     WHERE a2.id_profesional = p.id_profesional 
     AND a2.cod_empresa IN(3,4)) AS "TOTAL HONORARIOS"
     
FROM profesional p
INNER JOIN asesoria a 
    ON a.id_profesional = p.id_profesional
INNER JOIN empresa e 
    ON e.cod_empresa = a.cod_empresa
WHERE a.cod_empresa IN (3,4)
GROUP BY 
    p.id_profesional, 
    p.appaterno, 
    p.apmaterno, 
    p.nombre
HAVING COUNT(DISTINCT a.cod_empresa) = 2
ORDER BY p.id_profesional;




-- Caso 2: Resumen de Honorarios
--  Generar un reporte mensual de asesorías finalizadas en abril del año 
--  pasado.
--  Guardar los resultados en una tabla llamada REPORTE_MES.
--  Incluir:
--  ID, nombre, profesión, comuna.
--  Número de asesorías, total, promedio, mínimo y máximo de honorarios.
--  Usar: DDL, funciones, joins, agrupaciones.

CREATE TABLE REPORTE_MES
AS 
SELECT
    p.id_profesional AS "ID_PROF",
    INITCAP(p.appaterno || ' '|| p.apmaterno || ' ' || p.nombre) AS "NOMBRE_COMPLETO",
    INITCAP(prof.nombre_profesion) AS "NOMBRE_PROFESION",
    INITCAP(c.nom_comuna) AS "NOM_COMUNA",
    COUNT(a.inicio_asesoria) AS "NRO_ASESORIAS",
    SUM(a.honorario) AS "MONTO_TOTAL_HONORARIOS",
    ROUND(AVG(a.honorario)) AS "PROMEDIO_HONORARIO",
    MIN(a.honorario) AS "HONORARIO_MINIMO",
    MAX(a.honorario) AS "HONORARIO_MAXIMO"
FROM profesional p    
INNER JOIN profesion prof 
    ON p.cod_profesion = prof.cod_profesion
INNER JOIN comuna c 
    ON  p.cod_comuna =  c.cod_comuna
INNER JOIN asesoria a 
    ON p.id_profesional = a.id_profesional
WHERE EXTRACT(YEAR FROM a.inicio_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1
    AND EXTRACT(MONTH FROM a.inicio_asesoria) = 4
GROUP BY 
    p.id_profesional, 
    p.appaterno, 
    p.apmaterno, 
    p.nombre, 
    prof.nombre_profesion, 
    c.nom_comuna
ORDER BY p.id_profesional; 
    
SELECT * FROM REPORTE_MES;    

-- Caso 3: Modificación de Honorarios
--  Actualizar el sueldo de los profesionales según su desempeño en marzo del año pasado:
--  Si honorarios < $1.000.000 → aumento del 10%.
--  Si honorarios ≥ $1.000.000 → aumento del 15%.
--  Generar reportes antes y después de la actualización.
--  Usar: DML, funciones, joins, agrupaciones.


-- TABLA SIN AJUSTE

CREATE TABLE CALCULO_HONORARIOS_SIN_AJUSTE
AS
SELECT
    SUM(a.honorario) AS "HONORARIO",
    p.id_profesional AS "ID_PROFESIONAL",
    p.numrun_prof AS "NUM_RUN_PROF",
    p.sueldo AS "SUELDO"
FROM asesoria a
INNER JOIN profesional p 
    ON a.id_profesional = p.id_profesional
WHERE EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) -1
    AND EXTRACT(MONTH FROM a.fin_asesoria) = 3
GROUP BY 
    p.id_profesional, 
    p.numrun_prof, 
    p.sueldo;  

SELECT * FROM CALCULO_HONORARIOS_SIN_AJUSTE
ORDER BY id_profesional; 

-- TABLA CON AJUSTE DESDE SELECT

CREATE TABLE CALCULO_HONORARIOS_CON_AJUSTE
AS
SELECT
    SUM(a.honorario) AS "HONORARIO",
    p.id_profesional AS "ID_PROFESIONAL",
    p.numrun_prof AS "NUM_RUN_PROF",
    p.sueldo AS "SUELDO"
FROM asesoria a
INNER JOIN profesional p 
    ON a.id_profesional = p.id_profesional
WHERE EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) -1
    AND EXTRACT(MONTH FROM a.fin_asesoria) = 3
GROUP BY 
    p.id_profesional, 
    p.numrun_prof, 
    p.sueldo  
ORDER BY id_profesional;

SELECT * FROM CALCULO_HONORARIOS_CON_AJUSTE
ORDER BY id_profesional; 

-- SAVEPOINT para volver en caso de error
SAVEPOINT a; 

UPDATE profesional p 
SET p.sueldo = (SELECT 
                CASE
                    WHEN SUM(a.honorario) < 1000000
                    THEN ROUND(p.sueldo * 1.10)
                    WHEN SUM(a.honorario) >= 1000000
                    THEN ROUND(p.sueldo * 1.15)
                    ELSE p.sueldo
                END
                FROM asesoria a
                WHERE a.id_profesional = p.id_profesional
                    AND EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) -1
                    AND EXTRACT(MONTH FROM a.fin_asesoria) = 3    
                GROUP BY a.id_profesional)
                
WHERE p.id_profesional IN (
    SELECT a.id_profesional
    FROM asesoria a
    WHERE EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1
      AND EXTRACT(MONTH FROM a.fin_asesoria) = 3
)
    



