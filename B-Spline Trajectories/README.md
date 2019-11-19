# Notas en Modelamiento de trayectorias

La idea de este procedimiento es la estimación de trayectorias para una variable longitudinal aproximadamente normal usando **R** y **Stata**. Está formulado en versión usuario, es decir, no se discuten aspectos matemáticos, estadísticos o de programación. Se prefirió este enfoque para que la alumna pueda implementar de manera sencilla en su Tesis y no a la medida del analista.

## Desarrollo de la idea

La idea fue presentada como una forma de estimar trayectorias para un grupo de personas con valores de BMI (Bodd Mass Index) en varias edades, para ello se eligió el procedimiento descrito por Jones (2001) el cual desarrolló un método basado en un ajuste de polinomios para modelar trayectorias.

Una trayectoria puede ser lineal o una curva en una forma exponencial o combinaciones mediante polinomios, la complejidad de la curva la da el usuario y ese es precisamente uno de los problemas de este método, ya que un polinomio de grado 3 o superior puede ajustar cualquier cosa y las trayectorias pueden no reflejar la realidad.

![](C:\Users\Oliver\Desktop\B-Spline Trajectories\img\01.traj.ie.png)

Entonces la idea es pedirle al sistema:

- Un N de trayectorias (desde 2)
- Un grado de complejidad (lineal, exponencial, cúbico, etc.)

El programa, a partir de las las trayectorias estimadas le asignará a cada sujeto una probabilidad de pertenecer. Francis (2016) indica usar un 70%, si tiene menos probabilidad se descarta la observación. Además se obtiene como output la representación gráfica de las trayectorias estimadas.

Este sistema se denomina TRAJ por el nombre que el autor le dio en SAS, también desarrolló una versión para Stata que facilita mucho el modelamiento

En la página del autor se encuentran ejemplos y los script para SAS y Stata [http://www.andrew.cmu.edu/user/bjones/](http://www.andrew.cmu.edu/user/bjones/)

```
// To install the Stata version:
net from http://www.andrew.cmu.edu/user/bjones/traj
net install traj, force
help traj
```

## B-Splines

Sugerido el método se recibió la recomendación de considerar el uso de "splines cúbicos", en Paraskevi 2018 se muestra que el ajuste usando esta metodología se acerca más a la realidad, en su exposición usa datos con trayectorias conocidas y pone a prueba algunas metodologías.

> *A muy, pero muy grandes rasgos* los splines funcionan como las series de Fourier, estas indican que cualquier onda está compuesta por la suma de ondas de menor grado. O sea, el sistema se puede entender como la suma de subsistemas. En los splines se aplica la misma idea, mientras más nivel le doy al spline estoy diciendo que la trayectoria final está compuesta por la suma de más partes.
>
> En Wikipedia uno se puede hacer una idea de esto. [https://es.wikipedia.org/wiki/Spline](https://es.wikipedia.org/wiki/Spline)

Entonces se sugiere usar el paquete **splines** de **R** para estimar los splines basales y con estos resultados alimentar el programa TRAJ en Stata indicando que el grado del polinomio sea cero.

## Desarrollo de un ejemplo

Vamos a tomar el primer ejemplo de la página del autor, pero en lugar de hacer todo en TRAJ haremos la implementación de B-Splines.

Este ejemplo usa los datos de **opposition** de 138 sujetos del *Montreal Longitudinal  Study*, en el cual profesores evaluaron estudiantes anualmente a las edades de 6 y 10 - 15 en la escala de *opposition* que tiene un rango de 0 a 10. 

Vamos a ajustar 2 trayectorias cúbicas a estos datos.

### 1. Los datos

Los datos deben estar en un formato a lo ancho para Stata y longitudinal para R, como en Stata es más simple minimizaremos el tratamiento de datos en R. Los datos del archivo `OPPOSITN.xlsx` lucen de la siguiente forma.

![](C:\Users\Oliver\Desktop\B-Spline Trajectories\img\02.opo.png)

El tiempo es **T** y la variable de oposición es **V**. 

> **Importante**: el tiempo se puede expresar como cualquier variable numérica, aquí se dejo como el autor desarrolla el ejemplo. La alumna utilizó meses y funcionó sin problemas.

Si nos fijamos el sujeto `id = 1004` tiene datos faltantes, ocurre que como este sistema usa de fondo un modelo mixto no es estrictamente necesario que todos los sujetos tengan todos los datos, como es lógico se debe evitar esta situación, pero de ser, procurar excluir sujetos con muchos valores faltantes (máximo 2 por ejemplo).

### 2. Reshape en Stata

Lo siguiente  será importar estos datos en Stata y cambiar su estructura. Lo primero es setear la carpeta de trabajo con el **comando cd**.

Por ejemplo una carpeta en el escritorio de Windows

```
C:\Users\Oliver\Desktop\B-Spline Trajectories
```

El Archivo de Excel deberá estar en una carpeta que contendrá todos los archivos y resultados. Los comando de Stata para importar el **Excel**, hacer el **reshape** y guardar el archivo para luego abrir en R son los siguiente. Por simplicidad es preferible que la base de datos solo tenga id, la medición y el tiempo, nada más.

```
* Cargar el espacio de trabajo
cd "D:\.....\TRAJ\Ejemplo Splines"

* Importar el Excel
import excel using "OPPOSITN.xlsx", clear first sheet("OPPOSITN")

* Guardar los datos en formato Stata 12 para tener los datos en versión WIDE
saveold "OPPOSITN_wide.dta", replace

* Reshape de wide a long
reshape long V0 T0, i(id) j(epoch)

* El tiempo quedó en T0 y la medición en V0. Cambiar nombres
rename (V0 T0) (data time)

* Guardar formato long para pasar al R
save "OPPOSITN_long.dta", replace
```

Los datos lucen así recién importados

![](C:\Users\Oliver\Desktop\B-Spline Trajectories\img\03.statawide.png)

Con el reshape

![](C:\Users\Oliver\Desktop\B-Spline Trajectories\img\04.statalong.png)

Se guarda todo en el archivo **"OPPOSITN_long.dta"**

### 3. Spline bases en R

Ahora toca llevar estos datos a R para calcular el spline basis. Vamos a usar un DF (grados de libertad) igual a 4, lo cual equivale a un spline de tercer nivel (cúbico). Siempre tiene un valor +1 y por eso se escribe `DF = 4`. En la explicación de Wikipedia se entiende bien la razón de esto.

Hay que instalar la librería **haven** con `install.packages("haven")` para leer el archivo de Stata (.DTA), la librería **splines** viene de base con el R. La librería `foreign` solo lee archivos **dta** hasta versión 12, por eso usamos `haven`.

Como siempre lo primero será setear el directorio de trabajo. En la parte de Stata teníamos `"D:\.....\TRAJ\Ejemplo Splines"` como ejemplo. Esto es en Windows, notar que las carpetas se separan con la barra inclinada a la izquierda, en **R** es a la derecha y se usa el comando `setwd()` para configurar la carpeta de trabajo.

```R
# Setear directorio de trabajo donde estan los archivos
setwd("D:/...../TRAJ/Ejemplo Splines")
 
# Cargar los datos con el paquete haven
library(haven)
datos <- read_dta("OPPOSITN_long.dta")
 
# Mirar los datos
 head(datos, 7)
# A tibble: 7 x 4
     id epoch  data  time
  <dbl> <dbl> <dbl> <dbl>
1  1000     1     2  -0.6
2  1000     2     0  -0.2
3  1000     3     1  -0.1
4  1000     4     0   0  
5  1000     5     0   0.1
6  1000     6     0   0.2
7  1000     7     0   0.3
```

Vemos que los datos están en el objeto "datos" y son los mismos del Stata.

```R
# Calculamos un spline basis cúbico 
library(splines)
spline <- bs(datos$time, df=4)
 
# El resultado es una matriz, lo transformamos en data frame
# y ponemos nombres a las variables
spline <- data.frame(spline)
names(spline) <- c("sp_uno", "sp_dos", "sp_tre", "sp_cua")
head(spline, 7)

       sp_uno     sp_dos    sp_tre     sp_cua
1 0.000000000 0.00000000 0.0000000 0.00000000
2 0.403292181 0.42798354 0.1316872 0.00000000
3 0.249485597 0.48868313 0.2572016 0.00000000
4 0.111111111 0.44444444 0.4444444 0.00000000
5 0.032921811 0.27983539 0.6502058 0.03703704
6 0.004115226 0.09053498 0.6090535 0.29629630
7 0.000000000 0.00000000 0.0000000 1.00000000
```

El spline basis es una matriz y en R las planillas son un objeto **data.frame** entonces pasamos el spline basis a data frame y asignamos los nombres a las variables. **Es importante que no tengan números para el reshape posterior.**

En este ejemplo las 7 lineas son los 7 tiempos del primer sujeto su spline del tiempo está compuesto por la suma de estos 3 + 1 splines. Ahora pegamos esto a los datos y exportamos a un archivo de Stata.

```R
# Juntamos los datos y los splines
datos_spline <- cbind(datos, spline)
head(datos_spline, 7)
    id epoch data time      sp_uno     sp_dos    sp_tre     sp_cua
1 1000     1    2 -0.6 0.000000000 0.00000000 0.0000000 0.00000000
2 1000     2    0 -0.2 0.403292181 0.42798354 0.1316872 0.00000000
3 1000     3    1 -0.1 0.249485597 0.48868313 0.2572016 0.00000000
4 1000     4    0  0.0 0.111111111 0.44444444 0.4444444 0.00000000
5 1000     5    0  0.1 0.032921811 0.27983539 0.6502058 0.03703704
6 1000     6    0  0.2 0.004115226 0.09053498 0.6090535 0.29629630
7 1000     7    0  0.3 0.000000000 0.00000000 0.0000000 1.00000000
 
# Listo, ahora exporetamos a stata
write_dta(datos_spline, "OPPOSITN_longSpline.dta")
```

Y listo, ya podemos irnos a Stata. 

### 4. Estimación de las trayectorias en Stata

Lo primero será instalar el paquete TRAJ en el Stata si es que ya no está instalado, escribiendo los siguientes comandos en un do-file o en la consola.

```
// To install the Stata version:
net from http://www.andrew.cmu.edu/user/bjones/traj
net install traj, force
help traj
```

Luego cargamos los datos, no olvidar que seguimos en el mismo directorio de trabajo si es que no cerramos el Stata, si lo cerramos habría que usar nuevamente el comando **cd** como ya se explicó.

```
* Cargar el archivo que hicimos en R
use "OPPOSITN_longSpline.dta", clear

* Reshape para dejar en wide
reshape wide data time sp_uno sp_dos sp_tre sp_cua, i(id) j(epoch)
```

El resumen del reshape es:

![](C:\Users\Oliver\Desktop\B-Spline Trajectories\img\05_reshape.png)

Como vemos pasamos de 8 variables a 43, son muchas variables... 7 de data, 7 de time y 7x4 del spline basis. Ahora vamos a calcular trayectorias, como vamos a necesitar los spline basis del tiempo usaremos  el comodin ***** en lugar de escribir todas las variables.

#### Explicación del comando

El comando es el siguiente y vamos a explicar paso a paso qué significa.

```
traj, var(data*) indep(time*) model(cnorm) min(0) max(10) order(0 0) tcov(sp_uno* sp_dos* sp_tre* sp_cua*)
```

* `traj`: Es el comando principal
* `var(data*)`: todas las variables de medición, el asterisco significa data1, data2, etc.
* `indep(time*)`: Las variables de tiempo.
* `model(cnorm)`: La variable de medición es aproximadamente normal, hay otras opciones que se pueden consultar en la ayuda del paquete TRAJ.
* `min (0) max (10)`: Son los límites de la variable de medición.
* `order(0 0)`:  Es la cantidad de trayectorias que deseamos calcular, si quisiéramos 3 habría que escribir `(0 0 0)`, como en este caso estamos usando splines basis como covariable del tiempo y no TRAJ de polinomio tendrán valor cero. Si estuviéramos usando TRAJ (y no splines) habría que indicar el nivel de cada trayectoria, por ejemplo si queremos calcular tres trayectorias la primera cuadrática y tres cúbicas se escribiría `(2 3 3)` y sin las covariables de tiempo.

* `tcov(sp_uno* sp_dos* sp_tre* sp_cua*)`: Usamos el spline basis como covariables de tiempo. 

Y así de esta forma usamos el paquete TRAJ de Stata para calcular trayectorias con splines.

#### Explicación del resultado

```
==== traj stata plugin ====  Jones BL  Nagin DS,  build: Apr  8 2019
 
138 observations read.
138 observations used in the trajectory model.
 
WARNING: False convergence
                        Maximum Likelihood Estimates
                        Model: Censored Normal (cnorm)

                                       Standard       T for H0:
 Group   Parameter        Estimate        Error     Parameter=0   Prob > |T|
 
 1       Intercept         0.82586      0.33139           2.492       0.0129
         sp_uno1          -0.23329      1.89150          -0.123       0.9019
         sp_dos1           0.04742      1.53175           0.031       0.9753
         sp_tre1          -2.52340      0.76126          -3.315       0.0010
         sp_cua1          -1.88785      0.51772          -3.646       0.0003
 
 2       Intercept         3.24895      0.49999           6.498       0.0000
         sp_uno1          -1.02550      2.63711          -0.389       0.6975
         sp_dos1           4.43774      2.00781           2.210       0.0273
         sp_tre1          -2.85030      1.02318          -2.786       0.0055
         sp_cua1           0.13589      0.71333           0.191       0.8490
 
         Sigma             2.76498      0.09521          29.042       0.0000
 
  Group membership
 1       (%)              68.09676      5.31008          12.824       0.0000
 2       (%)              31.90324      5.31008           6.008       0.0000
 
 BIC= -1647.67 (N=901)  BIC= -1636.41 (N=138)  AIC= -1618.85  ll=  -1606.85
```

Para buscar el mejor modelo de trayectorias que explique los datos usaremos los valores **BIC** o Criterio de información bayesiano, mientras más bajo mejor, de la misma forma que el **AIC** o Criterio de Información de Akaike.

El resto son la ecuación de cada trayectoria y los porcentajes de asignación de sujetos. Se puede graficar usando esa ecuación con el comando `trajplot`

```
* Hacer el gráfico de las trayectorias
trajplot
```

![](C:\Users\Oliver\Desktop\B-Spline Trajectories\img\06_traj2.png)

Y además en los datos se agregan tres variables, una por cada trayectoria indicando la probabilidad de pertenencia de cada sujeto.

![](C:\Users\Oliver\Desktop\B-Spline Trajectories\img\07_trajp.png)

El sistema por defecto asigna a cada sujeto según la mayor probabilidad. Pero si seguimos el ejemplo de Francis (2007) podemos determinar que el mínimo para formar parte de un grupo sea 70%.

## Iteración del modelo

Ya sabemos hacer un modelo de trayectorias con splines y traj, ahora hay que hacerlo en serio y para ello se deben calcular muchos modelos para elegir el que mejor describe la muestra, para ello tendremos que calcular varios splines y varias trayectorias. Por ejemplo de 1 a 3 splines y 2 a 6 trayectorias. La secuencia sería:

1. Calcular un spline basis en R con `df = 2`
   A) Calcular en Stata 2 trayectorias
   B) Calcular en Stata 3 trayectorias
   C) Calcular en Stata 4 trayectorias
   D) Calcular en Stata 5 trayectorias
   E) Calcular en Stata 6 trayectorias
   
2. Calcular un spline basis en R con `df = 3`
   A) Calcular en Stata 2 trayectorias
   B) Calcular en Stata 3 trayectorias
   C) Calcular en Stata 4 trayectorias
   D) Calcular en Stata 5 trayectorias
   E) Calcular en Stata 6 trayectorias
   
3. Calcular un spline basis en R con `df = 4`
   A) Calcular en Stata 2 trayectorias
   B) Calcular en Stata 3 trayectorias
   C) Calcular en Stata 4 trayectorias
   D) Calcular en Stata 5 trayectorias
   E) Calcular en Stata 6 trayectorias

Son 15 modelos y elegiremos el que tenga valores de **BIC** más bajos y sea lo más coherente con lo que conocemos de los datos. No porque un modelo tenga el valor mejor de BIC o AIC quiere decir que sea el modelo que mejor explica, se deben considerar ambas cosas.

## Notas finales

También se puede modela usando covariables que pudieran afectar el desarrollo de las trayectorias, se pueden usar modelos binarios y varias cosas más que se pueden consultar en la ayuda del TRAJ con `help traj`.

Si bien las trayectorias con splines ajustan muy bien, no son tan diferentes de las modeladas con polinomios, sin embargo, con splines son más suaves y coherentes.

Efectivamente se podría hacer todo en R replicando el programa de SAS, no debiera ser muy complicado, además existen librerías de R para ajustar regresiones con splines. Pero este es un trabajo para alguien ajeno al data science, por eso se hizo de esta manera.

### Bibliografia

* En los papers de Jones está el desarrollo del modelo TRAJ
* En Francis está un excelente ejemplo desde el cual se infirió este manual
* Nagin es para más antecedentes

### El código

Hay dos script en la carpeta el de Stata **splinesStata.do** y el de R **splinesR**. Los datos están en **OPPOSITN.xlsx** y el resto de archivos son biblio y archivos creados en el proceso.



​																												Prof. Oliver Rojas Bustamante, Marzo 2019







