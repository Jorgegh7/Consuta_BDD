-- SEMANA 7

-- CASO 1:
--Simular las mejoras en la remuneración

--Bonificación por ticket:
--No hay ticket --> "No hay info"
--Ticket <= $50.000 --> 0
--Ticket Between 50.000 AND 100.000 --> 5% de bonificacion
--Ticket > 100.000 --> 7% de bonificacion
--La simulación ticket se obtiene sumando el sueldo base más la bonificación por ticket.

--Simulacion de mejoras en la remuneracion opr Ticket 

SELECT
    (t.numrut || '-' || t.dvrut)AS "RUT",
    INITCAP(t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno) AS "NOMBRE_TRABAJADOR", 
    NVL(TO_CHAR(SUM(CASE
                        WHEN tc.monto_ticket <= 50000 THEN 0
                        WHEN tc.monto_ticket BETWEEN 50000 AND 100000 THEN tc.monto_ticket * 0.05
                        WHEN tc.monto_ticket > 100000 THEN tc.monto_ticket * 0.07
                    END), '999G999G999'), 'No hay info') AS "Bonificación Por Ticket",
    t.sueldo_base AS "Sueldo Base",         
    t.sueldo_base + ROUND(SUM(CASE
                            WHEN tc.monto_ticket IS NULL THEN 0
                            WHEN tc.monto_ticket <= 50000 THEN 0
                            WHEN tc.monto_ticket BETWEEN 50000 AND 100000 THEN tc.monto_ticket * 0.05
                            WHEN tc.monto_ticket > 100000 THEN tc.monto_ticket * 0.07
                        END))  AS "Simulación Ticket"
FROM trabajador t
FULL JOIN tickets_concierto tc ON tc.numrut_t = t.numrut
GROUP BY t.numrut, t.dvrut, t.nombre, t.appaterno, t.apmaterno, t.sueldo_base;  

-- Simulacion de mejoras por antigüedad

SELECT
    (t.numrut || '-' || t.dvrut)AS "RUT",
    TRUNC(MONTHS_BETWEEN(SYSDATE, t.fecing)/12) AS "Años de Antigüedad",
    TO_CHAR(t.sueldo_base, '999G999G999') AS "Sueldo Base",
    NVL(ba.porcentaje,0) AS "Porcentaje",
    TO_CHAR(NVL(t.sueldo_base * ba.porcentaje, 0), '999G999G999') AS "Bono",
    TO_CHAR(ROUND(t.sueldo_base * (1 + NVL(ba.porcentaje,0) )), '999G999G999')AS "Bonificación por Antigüedad"   
FROM trabajador t
FULL JOIN bono_antiguedad ba 
    ON TRUNC(MONTHS_BETWEEN(SYSDATE, t.fecing)/12) BETWEEN ba.limite_inferior AND ba.limite_superior; 


-- CREACION SECUENCIA

CREATE SEQUENCE seq_bonificacion_trabajador_id
START WITH 100
INCREMENT BY 10
NOCACHE; 

-- CREACION DE SINONIMOS

CREATE OR REPLACE SYNONYM trab
FOR TRABAJADOR;

CREATE OR REPLACE SYNONYM bant
FOR BONO_ANTIGUEDAD; 
    
CREATE OR REPLACE SYNONYM tcon
FOR TICKETS_CONCIERTO; 


-- INFORME FINAL SELECT
SELECT
    (t.numrut || '-' || t.dvrut)AS "RUT",
    INITCAP(t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno)AS "NOMBRE_TRABAJADOR",
    TO_CHAR(t.sueldo_base, '$999G999G999') AS "SUELDO_BASE",
    NVL(TO_CHAR(tc.nro_ticket), 'No hay info') AS "NUM_TICKET",
    INITCAP(t.direccion) AS "DIRECCION",
    i.nombre_isapre AS "SISTEMA_SALUD",
    TO_CHAR(NVL(tc.monto_ticket, 0), '$999G999G999') AS "MONTO",
    TO_CHAR(ROUND(CASE
    WHEN tc.monto_ticket IS NULL THEN 0
        WHEN tc.monto_ticket <= 50000 THEN 0
        WHEN tc.monto_ticket BETWEEN 50000 AND 100000 THEN tc.monto_ticket * 0.05
        WHEN tc.monto_ticket > 100000 THEN tc.monto_ticket * 0.07
    END), '$999G999G999') AS "BONIF_X_TICKET",
    TO_CHAR(ROUND(t.sueldo_base + (CASE
                        WHEN tc.monto_ticket IS NULL THEN 0
                        WHEN tc.monto_ticket <= 50000 THEN 0
                        WHEN tc.monto_ticket BETWEEN 50000 AND 100000 THEN tc.monto_ticket * 0.05
                        WHEN tc.monto_ticket > 100000 THEN tc.monto_ticket * 0.07
                    END)), '$999G999G999') AS "SIMULACION_X_TICKET",
    TO_CHAR(ROUND(t.sueldo_base * (1 + NVL(ba.porcentaje,0) )), '999G999G999') AS "SIMULACION_ANTIGUEDAD"                    
FROM trab t
LEFT JOIN tcon tc ON tc.numrut_t = t.numrut
INNER JOIN isapre i ON i.cod_isapre = t.cod_isapre
LEFT JOIN bant ba 
    ON TRUNC(MONTHS_BETWEEN(SYSDATE, t.fecing)/12) BETWEEN ba.limite_inferior AND ba.limite_superior
WHERE TRUNC(MONTHS_BETWEEN(SYSDATE, t.fecnac)/12) >= 50
    AND i.porc_descto_isapre >4;     



-- INFORME FINAL INSERT

INSERT INTO DETALLE_BONIFICACIONES_TRABAJADOR (
    num, 
    rut, 
    nombre_trabajador, 
    sueldo_base, 
    num_ticket, direccion, 
    sistema_salud, monto, 
    bonif_x_ticket, 
    simulacion_x_ticket,
    simulacion_antiguedad)
SELECT
    seq_bonificacion_trabajador_id.NEXTVAL,
    (t.numrut || '-' || t.dvrut)AS "RUT",
    INITCAP(t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno)AS "NOMBRE_TRABAJADOR",
    TO_CHAR(t.sueldo_base, '$999G999G999') AS "SUELDO_BASE",
    NVL(TO_CHAR(tc.nro_ticket), 'No hay info') AS "NUM_TICKET",
    INITCAP(t.direccion) AS "DIRECCION",
    i.nombre_isapre AS "SISTEMA_SALUD",
    TO_CHAR(NVL(tc.monto_ticket, 0), '$999G999G999') AS "MONTO",
    TO_CHAR(ROUND(CASE
    WHEN tc.monto_ticket IS NULL THEN 0
        WHEN tc.monto_ticket <= 50000 THEN 0
        WHEN tc.monto_ticket BETWEEN 50000 AND 100000 THEN tc.monto_ticket * 0.05
        WHEN tc.monto_ticket > 100000 THEN tc.monto_ticket * 0.07
    END), '$999G999G999') AS "BONIF_X_TICKET",
    TO_CHAR(ROUND(t.sueldo_base + (CASE
                        WHEN tc.monto_ticket IS NULL THEN 0
                        WHEN tc.monto_ticket <= 50000 THEN 0
                        WHEN tc.monto_ticket BETWEEN 50000 AND 100000 THEN tc.monto_ticket * 0.05
                        WHEN tc.monto_ticket > 100000 THEN tc.monto_ticket * 0.07
                    END)), '$999G999G999') AS "SIMULACION_X_TICKET",
    TO_CHAR(ROUND(t.sueldo_base * (1 + NVL(ba.porcentaje,0) )), '999G999G999') AS "SIMULACION_ANTIGUEDAD"                    
FROM trab t
LEFT JOIN tcon tc ON tc.numrut_t = t.numrut
INNER JOIN isapre i ON i.cod_isapre = t.cod_isapre
LEFT JOIN bant ba 
    ON TRUNC(MONTHS_BETWEEN(SYSDATE, t.fecing)/12) BETWEEN ba.limite_inferior AND ba.limite_superior
WHERE TRUNC(MONTHS_BETWEEN(SYSDATE, t.fecnac)/12) >= 50
    AND i.porc_descto_isapre >4;    



SELECT * FROM detalle_bonificaciones_trabajador
ORDER BY monto DESC, nombre_trabajador;




-- CASO 2:

-- P.1
--CREACION OBJETO VISTA V_AUMENTOS_ESTUDIOS
-- RUT, nombre y apellidos, nivel de educación, porcentaje de bono asociado a los estudios, 
--sueldo actual, aumento calculado según el nivel de estudios y la simulación del sueldo con el aumento incorporado


-- CREACION OBJETO VISTA

CREATE OR REPLACE VIEW V_AUMENTOS_ESTUDIOS
AS
SELECT
    TO_CHAR(t.numrut, '99G999G999') AS "RUT_TRABAJADOR",
    INITCAP(t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno) AS "TRABAJADOR",
    be.descrip AS "NIVEL_EDUCACION",
    TO_CHAR(be.porc_bono, 'FM0000000') AS "PCT_ESTUDIOS",
    t.sueldo_base AS "SUELDO_ACTUAL",
    ROUND((t.sueldo_base * be.porc_bono)/100) AS "AUMENTO",
    LPAD(TO_CHAR(t.sueldo_base + ROUND((t.sueldo_base * be.porc_bono)/100), 'FM$999G999G999'),18 , ' ') AS "SUELDO_AUMENTADO "
FROM trabajador t
INNER JOIN bono_escolar be ON be.id_escolar = t.id_escolaridad_t
ORDER BY be.porc_bono, (t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno)
; 


-- P.2
-- OPTIMIZAR CON 2 INDICES 

-- CONSULTA A MEJORAR POR MEDIO DE INDICES 

SELECT
    numrut, fecnac, t.nombre, appaterno, t.apmaterno
FROM trabajador t
JOIN isapre i ON i.cod_isapre = t.cod_isapre
WHERE UPPER(t.apmaterno) = 'CASTILLO'
ORDER BY 3; 
  
-- CREACION DE INDICES 

CREATE INDEX idx_trabajador_apm ON trabajador(apmaterno);
CREATE INDEX idx_trabajador_apm_2 ON trabajador(UPPER(apmaterno));
CREATE INDEX idx_trabajador_nombre ON trabajador (nombre); 
     
    
    
    
    
    
    
    
    




    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
