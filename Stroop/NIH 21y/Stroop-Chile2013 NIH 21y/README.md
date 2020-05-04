# Stroop Reward NIH 21y

Esta es para la versión en carpeta **Stroop-Chile2013**, el intento anterior si bien funciona combina cosas en Stata y varios script, acá se deja todo en uno.

Los archivos tienen este patrón de nominación: `"RewardsStroop_1_041708_Chile2013-6295-1.txt"` 

## Lectura archivos: read.file()

Función para leer los archivos. Algo a notar es que pueden venir en blanco, así que se agrega un excepción para esto.

### Encabezado

Cada archivo tiene un encabezado con esta forma. Entre la línea 1 y la 20

```
1	*** Header Start ***
2	VersionPersist: 1
3	LevelName: Session
4	LevelName: Block
5	LevelName: Trial
6	LevelName: SubTrial
7	LevelName: LogLevel5
8	LevelName: LogLevel6
9	LevelName: LogLevel7
10	LevelName: LogLevel8
11	LevelName: LogLevel9
12	LevelName: LogLevel10
13	Experiment: RewardsStroop_1_041708_Chile2013
14	SessionDate: 04-17-2014
15	SessionTime: 12:20:27
16	Subject: 6298
17	Session: 1
18	RandomSeed: -45388445
19	Group: 1
20	Display.RefreshRate: 59.888
21	*** Header End ***
```

Se toman las líneas 16, 14 y 13. Como información para identificar el archivo.

```
16	Subject: 6298
14	SessionDate: 04-17-2014
13	Experiment: RewardsStroop_1_041708_Chile2013
```

### Data Trials

Luego de la cabecera los datos están indentados por una tabulación, se usa esa característica para capturar la data.

```
	*** LogFrame Start ***
	RunExp: 1
	Duration: 500
	Type: neutral
	Procedure: NeutralProc
	ColoredWords: 8
	Word: azul
	InkColor: yellow
	CorrectAns: v
	RunExp.Cycle: 1
	RunExp.Sample: 1
	Running: RunExp
	Congruency: incongruent
	TextDisplay1.OnsetDelay: 5
	TextDisplay1.OnsetTime: 56247
	TextDisplay1.DurationError: 0
	TextDisplay1.RTTime: 0
	TextDisplay1.ACC: 0
	TextDisplay1.RT: 0
	TextDisplay1.RESP: 
	TextDisplay1.CRESP: v
	*** LogFrame End ***
```

Cada trial luce de esta forma, se usa el `Start` y el `End` para capturar, en este caso son 60.

## Procesar líneas: read.data()

Capturada las líneas de datos ahora se deben transformar en un data frame. Se corrige para que el N de Trials sea dado por el mismo file, por si es diferente no se cuele uno de CV. Se deja de momento en formato `wide` para mostrar y luego se pasa a formato `long`.

```
> trial.data[,c(1, 2, 17, 23)]
                     variable      trial.1     trial.16     trial.22
1                      RunExp            1           16           22
2                    Duration          500          500          500
3                        Type      neutral      neutral       reward
4                   Procedure  NeutralProc  NeutralProc   RewardProc
5                ColoredWords            2            4            2
6                        Word         rojo     amarillo         rojo
7                    InkColor       yellow          red       yellow
8                  CorrectAns            v            c            v
9                RunExp.Cycle            1            1            1
10              RunExp.Sample            1           16           22
11                    Running       RunExp       RunExp       RunExp
12                 Congruency  incongruent  incongruent  incongruent
13    TextDisplay1.OnsetDelay            0            5            5
14     TextDisplay1.OnsetTime        85121       154083       181100
15 TextDisplay1.DurationError            0      -999999      -999999
16        TextDisplay1.RTTime            0       154665       181725
17           TextDisplay1.ACC            0            1            1
18            TextDisplay1.RT            0          582          625
19          TextDisplay1.RESP                         c            v
20         TextDisplay1.CRESP            v            c            v
```

Se le agregan antecedentes como el filename, id, etc.



## Calcular estadísticas: stats.data()

En esta función toma el resultado anterior y calcula las stats en varias etapas.

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

Se junta todo en un Excel con casi lujo de detalle, solo se excluyen las lineas de texto del Stroop en bruto porque es mucha info para un Excel, siempre se puede consultar cada archivo por separado.

## Test archivos

Se revisó que los archivos del PC del laboratorio fueran los mismos que los compartidos por Dropbox.

```
--- Reporte variables del merge ---
Master 2:2 - Inicio: file_su 
              Final: file_su 

Using 3:3 - Inicio: file_oli 
              Final: file_oli 

          StatusMerge Count
        Only in using     0
       Only in master     0
     -No data, check-     0
 Matched observations  1026
        --- Total ---  1026
```

De estos 1026 la mitad de ellos son analizables cada sujeto o prueba tiene dos archivos.

```
RewardsStroop_1_041708_Chile2013-10000-1.edat
RewardsStroop_1_041708_Chile2013-10000-1.txt
```

El valor intermedio indica la el valor de sesión que queda registrado en el Excel.

Mismo tratamiento, el Excel queda guardado con `password`





---

**Oliver Rojas, 2020** 
Lab. Sueño, INTA, U. Chile






















