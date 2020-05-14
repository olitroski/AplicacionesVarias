# Stroop Tradicional CV 22y

Esta es para la versión en carpeta **Stroop-Tradicional**, el intento anterior si bien funciona combina cosas en Stata y varios script, acá se deja todo en uno.

Los archivos tienen este patrón de nominación: `"Stroop_Chile2015-1777-1.txt"` 

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

Luego de la cabecera los datos están indentados por una tabulación, se usa esa característica para capturar la data. Se diferencia del stroop de NIH 21y en varias lineas, la primera es la versión NIH

#### Versión NIH 21y

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

#### Versión CV 22y
```
	*** LogFrame Start ***
	RunExp: 1
	Duration: 800
	Procedure: NeutralProc
	ColoredWords: 1
	Word: amarillo
	InkColor: blue
	CorrectAns: b
	RunExp.Cycle: 1
	RunExp.Sample: 1
	Running: RunExp
	Congruency: incongruent
	TextDisplay1.OnsetDelay: 13
	TextDisplay1.OnsetTime: 62075
	TextDisplay1.DurationError: 0
	TextDisplay1.RTTime: 0
	TextDisplay1.ACC: 0
	TextDisplay1.RT: 0
	TextDisplay1.RESP: 
	TextDisplay1.CRESP: b
	*** LogFrame End ***
```

Cada trial luce de esta forma, se usa el `Start` y el `End` para capturar.

## Procesar líneas: read.data()

Capturada las líneas de datos ahora se deben transformar en un data frame. Se corrige para que el N de Trials sea calculado por el file, por si es diferente no se cuele uno de CV. Se deja de momento en formato `wide` para mostrar y luego se pasa a formato `long`.

```
> trial.data[,c(1, 2, 17, 23)]
                     variable      trial.1     trial.16     trial.22
1                      RunExp            1           16           22
2                    Duration          800          800          800
3                   Procedure  NeutralProc  NeutralProc  NeutralProc
4                ColoredWords            1           16           22
5                        Word     amarillo         azul         azul
6                    InkColor         blue         blue       yellow
7                  CorrectAns            b            b            v
8                RunExp.Cycle            1            1            1
9               RunExp.Sample            1           16           22
10                    Running       RunExp       RunExp       RunExp
11                 Congruency  incongruent    congruent  incongruent
12    TextDisplay1.OnsetDelay           10           18           19
13     TextDisplay1.OnsetTime        16395        43111        53948
14 TextDisplay1.DurationError            0      -999999      -999999
15        TextDisplay1.RTTime            0        43820        54715
16           TextDisplay1.ACC            0            1            0
17            TextDisplay1.RT            0          709          767
18          TextDisplay1.RESP                         b            b
19         TextDisplay1.CRESP            b            b            v
```

Se le agregan antecedentes como el filename, id, etc. Tiene 19 líneas porque no tiene  la tercera línea de NIH `type` que es el **estimulo**.



## Calcular estadísticas: stats.data()

### Trials

A diferencia de NIH que tiene 60 trials útiles, esta prueba (Chile2015) tiene **72 Trials** donde las primeras **12** son de prueba. Y por lo tanto se excluyen del análisis.

#### Adaptación al cambio

Es la combinación siguiente. **Cuando la respuesta es correcta** en los 3 Trials

```
Congruente(1) > Congruente(2) > Incongruente
```

Detectada esta secuencia se captura el RT diferencia.

```
Incongruente - Congruente(2)
```

O sea

1. Se buscan en todos los trials la secuencia CCI y se anotan cuantos hay eso es `n.cci`
2. Se esos CCI encontrados se van a usar los que tengan esos 3 trials **correctos** en la respuesta, `cci.ok`
3. en esos OK se va a calcular el promedio RT

Pudiera ser que no existan `n.cci.ok` porque no cumplen con que sean correctos los 3 trials. En ese caso se dejará en la base de datos final con un `NA` al igual que el `mean.cci`.

Entonces se hace una mini data frame

```
  n.cci n.cci.ok mean.cci
      6        2     77.5
```

#### Adaptación al conflicto

Es lo mismo pero con la combinación

```
Incongruente(1) > Incongruente(2) > Congruente
```

Que sean correctas y que **para el promedio los RT sean positivos**  

```
  n.iic n.iic.ok mean.iic
      6        4   104.25
```

Como en este caso que no hay.

### Resto de estadísticas

Se calculan igual que para el NIH, con las combinaciones de congruencia. También se corrige si falta alguna combinación por falta de respuesta en RT

```
  congruencia respuesta    rt  n
    congruent         0 489.4  5
    congruent         1 481.6 25
  incongruent         0 679.0  1
  incongruent         1 446.5 29
```

Los porcentajes también se calculan para las correctas

### Excel

Se junta todo en un Excel con casi lujo de detalle, solo se excluyen las líneas de texto del Stroop en bruto porque es mucha info para un Excel, siempre se puede consultar cada archivo por separado.

```
"Stroop-Chile2015 CV 22y stats.xlsx"
```

## Test archivos

A simple vista son los mismos, no se comprueban porque ya se hizo en todos. Mismo tratamiento, el Excel queda guardado con `password`

Solo se guarda el Excel en el repositorio.

Se borra el archivo 

```
prueba_98.txt		No es de la prueba
```

Al ojo hay algunos archivos que no son de este experimento, están al inicio del Excel.



---

**Oliver Rojas, 2020** 
Lab. Sueño, INTA, U. Chile






















