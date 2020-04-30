# Stroop Alimentos 2016 - NIH 21y

Vienen originalmente en formato ERP y son 8 archivos por persona, de `0` a `8`. Se deben exportar a texto antes de procesar.

> NOTA:
> La secuencia de revisar todos los archivos está en la **bitácora**

La secuencia de análisis es la siguiente

## 1. Leer el archivo

El archivo a analizar se limita a los datos entre la sección `"All presses"` y `"Correct presses"`

## 2. Etiquetar repetidos

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

## 3. Etiquetar el tipo de respuesta

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

### Repetidas tipo 1 y 2

Cuando el aprieta antes del estimulo. Tipo 1 es la primera y 2 la segunda repetición.

* Si es repetida `Tipo 1` (antes de...) y respuesta `Incorrecta`
  * Incorrecta
  * Latencia a `NA` (para los cálculos)
* Si repetida es `Tipo 2`  y respuesta `Correcta`
	* Incorrecta Correctiva
* Si repetida es `Tipo 2`  y respuesta `Incorrecta`
	* Se clasifica `777` como error, se equivocó antes y después del estímulo

### Repetidas Tipo 3 y 4

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

### El resto de respuestas

Estas respuestas ya no están repetidas y funcionan solas.

* Respuesta `Correcta`
	* Correcta
* Respuesta `Incorrecta`
	* Incorrecta
* Respuesta `Omitted` (estas se agregaron al principio)
	* Omitida

**Errores adicionales**  
En caso que no se cumpla ninguna de las condiciones ya descritas se etiqueta el Trial con un valor `999`.

## 4. Estadísticas

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



### <<<< FALTA >>>> 

Hermosear el código y agregar % de Omitidas, está escrito en imperativo y no funcional.



# Stroop Alimentos 2018 - NIH 21y

Este Stroop se hizo como versión nueva al de 2016, se estructura diferente pero lee el mismo tipo de datos, NIH 21y.

Lo primero es cargar librerías y leer el directorio



## read.file()

Es una función que lee un archivo de los determinados en el objeto `dir()`.

### Captura Press

Lee todo lo que esté entre `All presses` y `Correct presses` con la salvedad de asegurarse que existan datos porque en los archivos de preuba a veces no aprietan nada y no hay nada que importar y eso arroja un error. Luce así.

```
$press
   Trial ID Pressed Released   Button  Response
1      1  1     560      740    verde   Correct
2      2  2     640      788     rojo   Correct
3      3  2     766      926    verde   Correct
4      4  1     742      903     azul   Correct
5      5  1     721      841     rojo   Correct
6      6  2     745      913    verde Incorrect
7      7  2     738      882    verde   Correct
8      8  1     777      930     rojo   Correct
9      9  1     895       NA     azul   Correct
10    10  2     685      873     rojo   Correct
11    11  1     752      870     azul Incorrect
12    12  1     787      963 amarillo   Correct
13    13  2     728      916    verde   Correct
14    15  2     636      780     azul Incorrect
15    16  1     837       NA     azul   Correct
16    17  2     687      830     rojo   Correct
17    19  1     759      913 amarillo Incorrect
18    20  2     773      910 amarillo   Correct
```



### Capturar segmento Trials

El segmento que existe entre `Trials` y `Button events` contiene información de los Trials para corregir los omitidos que no aparecen en **press**.

Esto si debiera estar por lo cual se agrega un marcador de error que detiene el programa si es que no hay datos en press y la variable ID de esta sección  es diferente que 3.

Luce así:

```
$trials
   Trial ID Pre.Set. Pre.Act. Trial.Set. Trial.Act. Post.Set. Post.Act.
1      1  1      100      100       1002       1002       200       200
2      2  2      100      100       1002       1002       200       200
3      3  2      100      100       1002       1002       200       200
4      4  1      100      100       1002       1002       200       200
5      5  1      100      100       1002       1002       200       200
6      6  2      100      100       1002       1002       200       200
7      7  2      100      100       1002       1002       200       200
8      8  1      100      100       1002       1002       200       200
9      9  1      100      100       1002       1002       200       200
10    10  2      100      100       1002       1002       200       200
11    11  1      100      100       1002       1002       200       200
12    12  1      100      100       1002       1002       200       200
13    13  2      100      100       1002       1002       200       200
14    14  1      100      100       1002       1002       200       200
15    15  2      100      100       1002       1002       200       200
16    16  1      100      100       1002       1002       200       200
17    17  2      100      100       1002       1002       200       200
18    18  2      100      100       1002       1002       200       200
19    19  1      100      100       1002       1002       200       200
20    20  2      100      100       1002       1002       200       200
```



### Captura el nombre del archivo

Guarda nombre de archivo y id.block para luego incorporar a la base de datos resultando. Por ejemplo:

```
$name
           file  id.block
1 236_3cv a.CSV 236_3cv a
```

### Resultado

Una lista con estos 3 elementos con nombres.

* press
* trials
* name

## tidy.data()

Lo siguiente es dejar los datos analizables, corrigiendo algunas cosas. Esta función toma como argumento el resultado de la función anterior.

Si no hay datos retorna un valor **NULL**

### Identificar repetidos

SI no hay suficientes trials se agrega un **break** para que detenga el loop sobre los trials. Pero si es un archivo normal agrega una variables **repeated** marcando 1 para la primera repetición y 2 para la segunda.

### Borrar repetidos

Siempre se **borra el primer repetido** y se **conserva el segundo**, además se le asigna el valor **Incorrect** en la variable repeated.

### Omitidos

Con el segmento **Trials** se agregan los omitidos, pasando el Trial y su variable ID.

Adicionalmente se nominan los trials que fueron omitidos en la variable **Response**. Luce así.

```
   Trial ID.x ID.y Pressed Released   Button  Response repeated
1      1    1    1     560      740    verde   Correct        0
2      2    2    2     640      788     rojo   Correct        0
3      3    2    2     766      926    verde   Correct        0
4      4    1    1     742      903     azul   Correct        0
5      5    1    1     721      841     rojo   Correct        0
```

### Correcciones finales

Se capturan solo las variables trial, estimulo, latencia y respuesta. Se le pega el Id y demás datos. 

Finalmente se corrige si la latencia es negativa y la respuesta es incorrecta con un valor **NA**.

Luce así:

```
    id.block trial estimulo latency  response          file
1  236_3cv a     1        1     560   Correct 236_3cv a.CSV
2  236_3cv a     2        2     640   Correct 236_3cv a.CSV
3  236_3cv a     3        2     766   Correct 236_3cv a.CSV
4  236_3cv a     4        1     742   Correct 236_3cv a.CSV
```



## stats()

Función para calcular la estadísticas, se nutre de los datos que arroja la función anterior.

### Chequeos

Si la data viene en blanco retorna un NULL, aunque debió detenerse antes.

El **bloque cero** tiene `estimulo = 3` si se procesa con esta función retorna un NULL (no hace nada)

### Estadísticas - Conteos

Lo primero es que hace una tabal entre response y estimulo y desde ahi saca algunas estadísticas. Por ejemplo:

```
> table
            1 2
  Correct   7 7
  Incorrect 2 2
  Omitted   1 1
```

Termina así

```
> table[, 1:8]
  n.corr1 n.inco1 n.omit1 n.etotal1 n.corr2 n.inco2 n.omit2 n.etotal2
        7       2       1         3       7       2       1         3
> table[, 9:16]
  p.corr1 p.inco1 p.omit1 p.etotal1 p.corr2 p.inco2 p.omit2 p.etotal2
       70      20      10        30      70      20      10        30
```



### Estadísticas - Descriptivas

Estas se hacen con un `group_by` de `dplyr` y se sacan las medias y desviaciones estándar. Queda todo así.

```
> stats
   m.corr1 m.inco1  m.corr2 m.inco2  s.corr1  s.inco1  s.corr2 s.inco2
  750.6667     816 674.4286      NA 129.8432 60.81118 53.70244      NA
```

Junta todo y listo

## Proceso final

Para terminar y procesar todo se procesa cada archivo y se guarda en un Excel todo el proceso, desde los originales a las estadísticas.

Nombre del Excel será: `stats_stroop.alimento_NIH21y.xlsx`

Hay unos colados de `gonogo` que se archivan con una excepción en el código

Listo todo.







