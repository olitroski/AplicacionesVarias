# Como usar el super script para go no go

Ya escribiré que hace que... de momento cómo usarlo.

## Librerías

Se necesitan las siguientes librerías

```
install.packages("dplyr")
install.packages("openxlsx")
install.packages("devtools")
```



## Source script

Si no están instalados los paquetes va a salir error, así que mejor asegurarse con:

```
library(dplyr)
library(openxlsx)
library(devtools)
```

Luego copiar esta dirección en la consola o un script nuevo. Ojo que se va a borrar el environment así que si hay trabajo no guardado en R hay que hacerlo ahora.

## Cargar el Script

Lo primero será cargar el script desde internet. Copiar y pegar este código en la consola de R.

```
library(devtools)
source("https://raw.githubusercontent.com/olitroski/AplicacionesVarias/master/GoNoGo/script_button_events.R")
```

Luego ejecutar el script con la función **procesarGNG** 

```
procesarGNG()
```

Esto va a abrir una ventana para elegir la carpeta donde están los archivos CSV que arroja el ERP. OJo que el  script no discrimina de otros CSV.

> Un folder solo con archivos CSV de Go-No-GO

Se van a crear 3 archivos de Excel en la carpeta. 

1. Las stats para todos los archivos
2. Los trials de error por archivo
3. La base de datos desde la que salen las stats, sirve para comprobar que todo esté correcto.



