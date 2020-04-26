# Script Stroop

Situación de script de R para procesar estudios de Stroop. De momento se separan por carpetas aun cuando sean los mismos, se dejan algunos ejemplos en cada uno.

## CVH 22 años

### Alimentos

Vienen originalmente en formato ERP y son 8 archivos por persona, de `0` a `8`. Se deben exportar a texto antes de procesar.

La secuencia de análisis es la siguiente

#### 1. Leer el archivo

El archivo a analizar se limita a los datos entre la sección `"All presses"` y `"Correct presses"`

#### 2. Etiquetar repetidos

Dentro de los registros existen Trial repetidos producidos por las veces y el momento en que se aprieta el botón, se puede apretar antes del estimulo lo cual se traduce en una latencia negativa (variable pressed) y luego aparece el estimulo y vuelve a apretar.

Son hartas combinaciones, pero lo primero será determinar los 2 tipos

```
# Cuando aprietan antes
Si Pressed es < 0
	Se asigna valor 1
	Y al siguiente valor 2
	
# Cuando repite pero aprieta después
Si Pressed es > 0
	Se asigna valor 3
	Y al siguiente valor 4
```

Ya con estas etiquetas se puede etiquetar todos los Trial de manera correcta, porque puede se repetida pero correcta e incorrecta, o correcta con latencia muy baja, etc.

De nuevo:.

> 1 y 2 repetido donde apretó antes del estímulo
>
> 3 y 4 repetido donde apretó después del estimulo

Se hace en 2 pasos, primero etiquetar repetidos y luego etiquetar respuesta porque si se hace en una sola sentencia queda muy difícil de explicar y leer el código.

#### 3. Etiquetar el tipo de respuesta

Las etiquetas son las siguientes, esto se hace línea a línea

```
0 = Correcta
1 = Omitidas
2 = Incorrecta 
3 = Incorrecta Correctiva
```

La secuencia de condiciones es la siguiente.

**Omitidas**  
Las omitidas no aparecen, entonces como son 20 trials hay que buscar lo que falta y agregar con valores `NA`.

**Repetidas tipo 1 y 2**  
Cuando el aprieta antes del estimulo. Tipo 1 es la primera y 2 la segunda repetición.

* Si es repetida `Tipo 1` (antes de...) y respuesta `Incorrecta`
  * Incorrecta
  * Latencia a `NA` (para los cálculos)
* Si repetida es `Tipo 2`  y respuesta `Correcta`
	* Incorrecta Correctiva
* Si repetida es `Tipo 2`  y respuesta `Incorrecta`
	* Se clasifica `777` como error, se equivocó antes y después del estímulo

**Repetidas Tipo 3 y 4**  
Cuando aprieta después del estímulo. Tipo 3 es la primera y 4 la segunda repetición.

* Repetida `Tipo 3` y respuesta `Correcta` y latencia `> 100`
	* Correcta
	* La siguiente se asigna `666` y se salta (ya no es útil)
* Repetida `Tipo 3` y respuesta `Incorrecta`
	* Incorrecta
* Repetida `Tipo 4` y respuesta `Correcta`
	* Incorrecta correctiva
* Repetida `Tipo 4` y respuesta `Incorrecta`
	* Se clasifica `888` como error porque ya se equivocó en 3 y no sirve

**El resto de respuestas**  
Estas respuestas ya no están repetidas y funcionan solas.

* Respuesta `Correcta`
	* Correcta
* Respuesta `Incorrecta`
	* Incorrecta
* Respuesta `Omitted` (estas se agregaron al principio)
	* Omitida

**Errores adicionales**  
En caso que no se cumpla ninguna de las condiciones ya descritas se etiqueta el Trial con un valor `999`.

#### 4. Estadísticas

Lo siguiente es calcular la estadísticas, por supuesto se descartan los tipos de respuesta que sean de error. De todas formas se guardan estas clasificaciones y los datos originales para revisión e inspección.

Esto ya es sencillo, para cada tipo de respuesta:

```
0 = Correcta
1 = Omitidas
2 = Incorrecta 
3 = Incorrecta Correctiva
```

Se le calcula 

* Media
* Conteo
* Desviación estándar poblacional 

La desviación poblacional porque al contemplar dividir por `N` en lugar de por `N-1` permite hacer el cálculo cuando hay pocos datos. Al fin y al cabo es una medida de variabilidad solamente.

Con los conteos se calculan los porcentajes

* % Correctas
* % Incorrectas 
* % Incorrectas correctivas
* % Omitidas



# <<<< FALTA >>>> Hermosear el código y agregar % de Omitidas, está escrito en imperativo y no funcional.




## NIH 21 Años



