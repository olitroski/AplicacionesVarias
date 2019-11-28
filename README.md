# AplicacionesVarias
Script variados para muchas cosas. Algunas del Lab. otras mias. 

## B-Spline Trajectories
Es un manual que hice para calcular trayectorias usando splines y el TRAJ en Stata. Está a nivel usuario, lo más sencillo posible se requieren algunos conocimientos básicos de R y Stata.

La idea es:
1. Tomar un archivo Excel con los datos en formato wide
2. Pasarlo al Stata dejarlo en formato long
3. Abrirlo en R y calcular un spline basis del tiempo
4. Cargar los datos + spline basis en Stata
5. Pasarlo a formato wide
6. Usar TRAJ para calcular trayectorias.



## Go no GO

Este Script procesa la prueba go-no-go con el paradigma del laboratorio. De momento procesa el de 15 años con 40 trials de prueba, pero cambiarlo se puede adaptar cualquiera. El de 21 años tenía 50 y 500 trials.

En la carpeta están los detalles

