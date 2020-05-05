# Stroop Reward NIH 21y

## Versión Resonancia

Esta es para la versión en carpeta **StroopChile_Resonancia**, el procedimiento es básicamente el mismo usado en la otra versión, la consideración es que el archivo de datos de entrada tiene otra disposición, es un archivo de texto separado por tabulaciones con una primera línea que no se usa.

Los archivos tienen este patrón de nominación: `"2153_1.txt"` 

Se pueden consultar ejemplos en el folder de **test_files**, también hay un archivo de Excel en donde se hace notar la diferencia de variables y qué nombres tienen para poder hacer la adaptación del Script.

## Lectura archivos: read.file()

Función para leer los archivos. Las diferencias para adaptar el script de 2013 es la siguiente.

| StroopChile_Resonancia  NIH 21y | Stroop-Chile2013  NIH 21y  | Observacion |
| ------------------------------- | -------------------------- | ----------- |
| ExperimentName                  | RunExp                     | Trial       |
| Subject                         | Duration                   |             |
| Session                         | Type                       | Estimulo    |
| Display.RefreshRate             | Procedure                  |             |
| Group                           | ColoredWords               |             |
| RandomSeed                      | Word                       |             |
| SessionDate                     | InkColor                   |             |
| SessionTime                     | CorrectAns                 |             |
| Block                           | RunExp.Cycle               |             |
| ColoredWords                    | RunExp.Sample              |             |
| Congruency                      | Running                    |             |
| CorrectAns                      | Congruency                 | Congruencia |
| Duration                        | TextDisplay1.OnsetDelay    |             |
| InkColor                        | TextDisplay1.OnsetTime     |             |
| Procedure                       | TextDisplay1.DurationError |             |
| RunExp                          | TextDisplay1.RTTime        |             |
| RunExp.Cycle                    | TextDisplay1.ACC           | Respuesta   |
| RunExp.Sample                   | TextDisplay1.RT            | RT          |
| Running                         | TextDisplay1.RESP          |             |
| TextDisplay1.ACC                | TextDisplay1.CRESP         |             |
| TextDisplay1.CRESP              | sujeto                     | Header      |
| TextDisplay1.DurationError      | fecha                      | Header      |
| TextDisplay1.OnsetDelay         | hora                       | Header      |
| TextDisplay1.OnsetTime          | exp                        | Header      |
| TextDisplay1.RESP               | session                    | Header      |
| TextDisplay1.RT                 | file                       | Archivo     |
| TextDisplay1.RTTime             |                            |             |
| Type                            |                            |             |
| Word                            |                            |             |

Hay que adaptar la adquisición de datos a esta nueva forma, de momento también son 60 trials.

Hubo un archivo que no tenia la primera línea como el resto, la solución fue agregar una excepción que si el archivo de origen tiene 61 líneas no se salte la primera. Por defecto es `skip = 1` en el `read.table()`



## Procesar líneas: read.data()

En este paso se adapta la el data frame que ya está en formato planilla al script en donde se leen las líneas del archivo de texto.

Se deja lo más parecido para que capture las mismas excepciones y tenga los mismos nombres que el proceso chile2013.



## Calcular estadísticas: stats.data()

En esta función toma el resultado anterior y calcula las stats en varias etapas. Este proceso se repite así que lo dejo tal cual.

### Preparar los datos

Lo primero será tomar la data anterior y dejar solo las variables que sirven según los siguientes nombres.

```
sujeto = sujeto, fecha = fecha, experiment = exp, 
trial = RunExp, estimulo = Type, congruencia = Congruency, 
respuesta = TextDisplay1.ACC, rtime = TextDisplay1.RT)
```

- Si tiene tiempo de respuesta igual a 0 dejar como NA
- Si tiene menos de 60 trials, lo anota y pasa del archivo

### Calcular estadísticas

Las estadísticas se calculan en base a combinaciones de estimulo, congruencia y respuesta, por esto debieran existir 12 combinaciones. 

> Se calcula el RT promedio en esas combinaciones

Se crea una data frame con todas las combinaciones y se lleva al data frame de medias, debiera lucir de esta forma.

```
   estimulo congruencia respuesta    rt  n
1   neutral   congruent         0    NA  3
2   neutral   congruent         1 753.0  2
3   neutral incongruent         0 656.5  5
4   neutral incongruent         1 728.6 10
5    punish   congruent         0    NA NA
6    punish   congruent         1 577.5  8
7    punish incongruent         0 675.0  3
8    punish incongruent         1 595.7  9
9    reward   congruent         0    NA  1
10   reward   congruent         1 491.2  6
11   reward incongruent         0 736.5  2
12   reward incongruent         1 661.8 11
```

Por ejemplo en este, en la fila 5 hay un `punish - congruent - incorrect` que no estaba originalmente porque el sujeto no se equivocó, ahora está y se contabiliza.

Si contabilizamos el N vemos que está correcto.

```R
> sum(stats$n, na.rm = TRUE)
[1] 60
```

> Los `NA` en `n` se pasan a cero.

#### Cálculos con conteos

Lo primero es usar los conteos para calcular porcentajes. Las variables de conteo se dejan con nombres compuestos por:

```
tipo estadistica + congruencia + punich + respuesta
```

 Por ejemplo variable de conteos, congruentes, neutrales, incorrectos tendrá el nombre: `nCongN.0` el listado sería por lo tanto:

```
	names(count) <- c("nCongN.0", "nCongN.1", "nInconN.0", "nInconN.1",
	                  "nCongP.0", "nCongP.1", "nInconP.0", "nInconP.1",
	                  "nCongR.0", "nCongR.1", "nInconR.0", "nInconR.1")
```

A partir de esto se calculan los porcentajes de correctas para cada tipo, por ejemplo para congruentes neutras:

```
pCongN.1 = nCongN.1/(nCongN.1 + nCongN.0)
```

Luego el Porcentaje de correctas congruentes

```
pCong.1  = ( nCongN.1+ nCongP.1+ nCongR.1)/
           (nCongN.1+ nCongP.1+ nCongR.1+ nCongN.0+ nCongP.0+ nCongR.0)
           
pIncon.1 = (nInconN.1+nInconP.1+nInconR.1)/
           (nInconN.1+nInconP.1+nInconR.1+nInconN.0+nInconP.0+nInconR.0)
```

Luego porcentaje correctas por estimulo

```
pN.1 = (nCongN.1 + nInconN.1)/20
pP.1 = (nCongP.1 + nInconP.1)/20
pR.1 = (nCongR.1 + nInconR.1)/20
```

#### Cálculos con RT

En este caso se calculan las medias de RT para todas las combinaciones además de las siguientes.

* Estimulo `(neutral, punish, reward)` y Respuesta `(0, 1)`
* Congruencia `(congruent, incongruent)` y Respuesta `(0, 1)`

#### Finalizar

Luego se junta todo y listo, resultando en 6 grupos de variables

0. Se le agregan los identificadores de archivo

1. Conteos todas las combinaciones
2. Porcentaje correctas
3. Porcentaje de correctas por estimulo y congruencia
4. Medias RT todas las combinaciones
5. Medias RT congruencia respuesta
6. Medias RT estimulo respuesta

### Excel

Se junta todo en un Excel con casi lujo de detalle, solo se excluyen las líneas de texto del Stroop en bruto porque es mucha info para un Excel, siempre se puede consultar cada archivo por separado.

## Archivos

Los archivos son 225, 3 por sujeto y el resultado final recibe el mismo tratamiento que chile2013, un Excel queda guardado con `password` en el repositorio.





---

**Oliver Rojas, 2020** 
Lab. Sueño, INTA, U. Chile






















