-- CASO 1: 

SELECT
    t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno AS "Nombre Completo Trabajador",
    TO_CHAR(t.numrut, '999G999G999') || '-' || t.dvrut AS "Rut Trabajador",
    ttra.desc_categoria AS "Tipo Trabajador",
    UPPER(cc.nombre_ciudad) AS "Ciudad Trabajador",
    TO_CHAR(t.sueldo_base, '$999G999G999')AS "Sueldo Base"
FROM trabajador t
INNER JOIN tipo_trabajador ttra ON t.id_categoria_t = ttra.id_categoria
INNER JOIN comuna_ciudad cc ON t.id_ciudad = cc.id_ciudad
WHERE t.sueldo_base BETWEEN 650000 AND 3000000
ORDER BY cc.nombre_ciudad DESC, t.sueldo_base;


--CASO 2:

SELECT
    TO_CHAR(t.numrut, '999G999G999') || '-' || t.dvrut AS "Rut Trabajador",
    INITCAP(t.nombre) || ' ' || UPPER(t.appaterno) AS "Nombre Trabajador",
    COUNT(tc.nro_ticket) AS "Total Tickets",
    TO_CHAR(SUM(tc.monto_ticket), '$999G999G999') AS "Total Vendido",
    TO_CHAR(SUM(ct.valor_comision), '$999G999G999') AS "Comisiòn Total",
    tt.desc_categoria AS "Tipo Trabajador",
    INITCAP(cc.nombre_ciudad) AS "Ciudad Trabajador"
FROM trabajador t
INNER JOIN tickets_concierto tc ON t.numrut = tc.numrut_t
INNER JOIN comisiones_ticket ct ON tc.nro_ticket = ct.nro_ticket
INNER JOIN tipo_trabajador tt ON t.id_categoria_t = tt.id_categoria
INNER JOIN comuna_ciudad cc ON t.id_ciudad = cc.id_ciudad
GROUP BY t.numrut, t.dvrut, t.nombre, t.appaterno, tt.desc_categoria, cc.nombre_ciudad
HAVING SUM(tc.monto_ticket) > 50000
ORDER BY SUM(tc.monto_ticket) DESC; 

--CASO 3:

SELECT
    TO_CHAR(t.numrut, '999G999G999') || '-' || t.dvrut AS "RUT Trabajador",
    INITCAP(t.nombre) || ' ' || INITCAP(t.appaterno) AS "Trabajador Nombre",
    EXTRACT(YEAR FROM t.fecing) AS "Año Ingreso",
    EXTRACT(YEAR FROM sysdate) - EXTRACT(YEAR FROM t.fecing) AS "Años Antiguedad",
    COUNT(af.numrut_carga) AS "Num. Cargas Familiares",
    i.nombre_isapre AS "Nombre Isapre",
    TO_CHAR(t.sueldo_base, '$999G999G999') AS "Sueldo Base",
    CASE
        WHEN i.nombre_isapre = 'FONASA' THEN TO_CHAR(ROUND(t.sueldo_base * 0.01 ,0), '$999G999G999')
    ELSE TO_CHAR(0, '999G999G999')    
    END AS "Bono Fonasa",
    CASE
        WHEN EXTRACT(YEAR FROM sysdate) - EXTRACT(YEAR FROM t.fecing) <= 10 THEN TO_CHAR(ROUND(t.sueldo_base * 0.1,0), '$999G999G999')
        WHEN EXTRACT(YEAR FROM sysdate) - EXTRACT(YEAR FROM t.fecing) > 10 THEN TO_CHAR(ROUND(t.sueldo_base * 0.15,0), '$999G999G999')
    END AS "Bono Antiguedad",
    INITCAP(a.nombre_afp) AS "Nombre AFP",
    ec.desc_estcivil AS "Estado Civil"
FROM trabajador t
LEFT JOIN asignacion_familiar af ON t.numrut = af.numrut_t
INNER JOIN isapre i ON t.cod_isapre = i.cod_isapre
INNER JOIN afp a ON t.cod_afp = a.cod_afp
INNER JOIN est_civil e ON t.numrut = e.numrut_t
INNER JOIN estado_civil ec ON e.id_estcivil_est = ec.id_estcivil
GROUP BY t.numrut, t.dvrut, t.nombre, t.appaterno, t.fecing, t.sueldo_base, i.nombre_isapre, a.nombre_afp, ec.desc_estcivil, e.fecter_estcivil 
HAVING e.fecter_estcivil IS NULL
ORDER BY TO_CHAR(t.numrut, '999G999G999') || '-' || t.dvrut;
 




