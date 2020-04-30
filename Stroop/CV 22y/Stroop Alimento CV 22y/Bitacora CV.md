# Bitácora CV

Esta es la secuencia de análisis del Stroop de Alimento CV 22 años con toda la vuelta. Es igual que la versión de NIH que fue documentada primero, por lo cual se replica el modelo

## Archivos

Tengo 3 grupos de archivos y lo primero será comprobar que son lo mismo.

### Stroop CV Archivos Dropbox Sussanne

Son los que me compartió Jeanette y Sussanne, corresponde sólo a archivos ERP

### Stroop CV Archivos Inta Oliver ERP

Son los que tenía yo en el INTA de un trabajo previo, también son archivos ERP

### Stroop CV Archivos Inta Oliver CSV

Supongo son los mismos que su versión ERP pero pasada a CSV en esa ocasión en la cual pasé archivos ERP a CSV mediante un Script de manejo de acciones de Windows.

Se hizo de esta forma

1. Se crea un script genérico de **Pulover's Macro Creator**  (**PMC**) que hace toda la operatoria en Windows como si fuera un humano. [www.macrocreator.com](https://www.macrocreator.com/download/)
2. En este script se dejan algunas líneas en donde introducir los datos propios de cada archivo

3. Con un Script de R se fabrican tantos Script de PMC como archivos de ERP se tengan, 
4. Se pegan unos bajo el otro (los script de PMC)
5. Luego en PMC se ejecuta esta lista enorme de instrucciones, el resultado será un CSV de cada ERP.

## Sha

El hash o función hash es una función criptográfica que calcula un valor único para un archivo, existen muchos algoritmos, en este caso estamos usando el **Sha1** que es bastante potente, lo que quiere decir que si dos archivos tienen el mismo Sha1, tienen el mismo contenido, *aun cuando tengan diferentes nombres*.

Como dice Wikipedia



## Comprobar archivos ERP

En esta parte voy a probar que las 3 carpetas tengan básicamente lo mismo, entiendo que en las mías borré algunos porque estaban malos o con nombre diferente. Para el caso de CV los archivos están en 2 carpetas, así que se debe hacer por carpeta.

Voy a hacer script de R individuales para cada tarea para tener todo más parcelado. Los archivos no quedarán en GitHub porque no tengo suficiente espacio para guardar tanta cosa. La muestra de como lucen los hash solo está en la carpeta NIH stroop alimento por si se quiere ver.

### Carpeta 1 - Sussanne ERP vs Oliver ERP

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
 Matched observations  2101
        --- Total ---  2101
```

Cruzaron todos. Son 2101 archivos de ERP

### Carpeta 1 - Oliver ERP vs Oliver CSV

```
--- Reporte variables del merge ---
Master 2:2 - Inicio: sha 
              Final: sha 

Using 3:3 - Inicio: shaCSV 
              Final: shaCSV 

          StatusMerge Count
        Only in using     3
       Only in master     0
     -No data, check-     0
 Matched observations  2101
        --- Total ---  2104
```

Cruzan 2101, hay 3 que no

```R
> combiOlito$using
            file  sha                                   shaCSV         merge
1  data.raw.xlsx <NA> 8aecf0bfcb1878dc3685b62ed75d763d7916ba48 Only in using
2 data.stat.xlsx <NA> bac32f6f736af340f0c017059ffa7b747523c664 Only in using
3 data.tidy.xlsx <NA> cb302c0f695bdd65f2dc0282865b97a6bbf403ef Only in using
```

Son archivos de resultados así que da igual.

> Carpeta 1 cruza todo y son los mismos archivos.

### Carpeta 2 - Sussanne ERP vs Oliver ERP

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
 Matched observations  2089
        --- Total ---  2089
```

Cruzan perfecto 2089 archivos

### Carpeta 2 - Oliver ERP vs Oliver CSV

```R
--- Reporte variables del merge ---
Master 2:2 - Inicio: sha 
              Final: sha 

Using 3:3 - Inicio: shaCSV 
              Final: shaCSV 

          StatusMerge Count
        Only in using     3
       Only in master     0
     -No data, check-     0
 Matched observations  2089
        --- Total ---  2092
```

Cruzan perfecto 2089 archivos, los otros 3 debieran ser de resultado también.

```
> combiOlito$using
            file  sha                                   shaCSV         merge
1  data.raw.xlsx <NA> 8aecf0bfcb1878dc3685b62ed75d763d7916ba48 Only in using
2 data.stat.xlsx <NA> bac32f6f736af340f0c017059ffa7b747523c664 Only in using
3 data.tidy.xlsx <NA> cb302c0f695bdd65f2dc0282865b97a6bbf403ef Only in using
```

Exacto

### RAR y Script R

Dejo CSV en un Comprimido todo en una sola carpeta, para poder tirar el script de una sola vez.

Los detalles del Script quedan en el readme de la carpeta del repo.



























