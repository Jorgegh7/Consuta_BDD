-- CASO 1: 

SELECT TO_CHAR(numrut_cli, '999G999G999') || '-' || dvrut_cli  AS "RUT Cliente",
nombre_cli || ' ' || appaterno_cli || ' ' || apmaterno_cli AS "Nombre Completo Cliente",
direccion_cli AS "Dirección Cliente",
TO_CHAR(renta_cli, '$999G999G999') AS "Renta Cliente",
LPAD(
    (SUBSTR(celular_cli,1, 1) || '-' || 
     SUBSTR(celular_cli,2, 3) || '-' || 
     SUBSTR(celular_cli,4,4)), 11, '0') AS "Celular Cliente",
CASE
    WHEN renta_cli > 500000 THEN 'TRAMO 1'
    WHEN renta_cli BETWEEN 400000 AND 500000 THEN 'TRAMO 2'
    WHEN renta_cli BETWEEN 200000 AND 399999 THEN 'TRAMO 3'
    WHEN renta_cli < 200000 THEN 'TRAMO 4'
END AS "Tramo Renta Cliente"    
FROM cliente
WHERE celular_cli IS NOT NULL
AND renta_cli BETWEEN &renta_minima AND &renta_maxima
ORDER BY "Nombre Completo Cliente";


-- CASO 2: 

SELECT id_categoria_emp AS "CODIGO_CATEGORIA",
CASE 
    WHEN id_categoria_emp = 1 THEN 'Gerente'
    WHEN id_categoria_emp = 2 THEN 'Supervisor'
    WHEN id_categoria_emp = 3 THEN 'Ejecutivo de Arriendo'
    WHEN id_categoria_emp = 4 THEN 'Auxiliar'
    ELSE 'No identificado'
END AS "DESCRIPCION_CATEGORIA",
COUNT(id_sucursal) AS "CANTIDAD_EMPLEADOS",
CASE
    WHEN id_sucursal = 10 THEN 'Sucursal Las Condes'
    WHEN id_sucursal = 20 THEN 'Sucursal Santiago Centro'
    WHEN id_sucursal = 30 THEN 'Sucursal Providencia'
    WHEN id_sucursal = 40 THEN 'Sucursal Vitacura'
END AS "SUCURSAL",
TO_CHAR(ROUND(AVG(sueldo_emp)), '$999G999G999') AS "SUELDO_PROMEDIO"
FROM empleado
GROUP BY id_categoria_emp, id_sucursal
HAVING AVG(sueldo_emp) >= &SUELDO_PROMEDIO_MINIMO
ORDER BY "SUELDO_PROMEDIO" DESC; 

-- CASO 3: 

SELECT id_tipo_propiedad AS "CODIGO_TIPO",
CASE
    WHEN id_tipo_propiedad = 'A' THEN 'CASA'
    WHEN id_tipo_propiedad = 'B' THEN 'DEPARTAMENTO'
    WHEN id_tipo_propiedad = 'C' THEN 'LOCAL'
    WHEN id_tipo_propiedad = 'D' THEN 'PARCELA SIN CASA'
    WHEN id_tipo_propiedad = 'E' THEN 'PARCELA CON CASA'
END AS "DESCRIPCION_TIPO",
COUNT (id_tipo_propiedad) AS "TOTAL_PROPIEDADES",
TO_CHAR(ROUND(AVG(valor_arriendo)), '$999G999G999') AS "PROMEDIO_ARRIENDO",
TO_CHAR(ROUND(AVG(superficie), 2), '999G999D00') AS "PROMEDIO_SUPERFICIE",
TO_CHAR(ROUND((SUM(valor_arriendo) /(SUM(superficie)))), '$999G999') AS "VALOR_ARRIENDO_M2",
CASE
    WHEN (ROUND((SUM(valor_arriendo) / SUM(superficie)))) < 5000 THEN 'Economico'
    WHEN (ROUND((SUM(valor_arriendo) / SUM(superficie)))) BETWEEN 5000 AND 10000 THEN 'Medio'
    WHEN (ROUND((SUM(valor_arriendo) / SUM(superficie)))) > 10000 THEN 'Alto'
END AS "Clasificación"
FROM propiedad
GROUP BY id_tipo_propiedad
HAVING (ROUND((SUM(valor_arriendo) / SUM(superficie)))) > 1000
ORDER BY "VALOR_ARRIENDO_M2" DESC; 










