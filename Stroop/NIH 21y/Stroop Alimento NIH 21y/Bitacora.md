# Bitacora

Esta es la secuencia de análisis del Stroop de Alimento NIH 21 años con toda la vuelta.

## Archivos

Tengo 3 grupos de archivos y lo primero será comprobar que son lo mismo, al menos en sus nombres.

### Stroop NIH Archivos Dropbox Sussanne

Son los que me compartió Jeanette y Sussanne, corresponde sólo a archivos ERP

### Stroop NIH Archivos Inta Oliver ERP

Son los que tenía yo en el INTA de un trabajo previo, también son archivos ERP

### Stroop NIH Archivos Inta Oliver CSV

Supongo son los mismos que su versión ERP pero pasada a CSV en esa ocasión en la cual pasé archiovs ERP a CSV mediante un Script de manejo de acciones de Windows.

Se hizo de esta forma

1. Se crea un script genérico de **Pulover's Macro Creator**  (**PMC**) que hace toda la operatoria en Windows como si fuera un humano.
2. En este script se dejan algunas líneas en donde introducir los datos propios de cada archivo

3. Con un Script de R se fabrican tantos Script de PMC como archivos de ERP se tengan, 
4. Se pegan unos bajo el otro (los script de PMC)
5. Luego en PMC se ejecuta esta lista enorme de instrucciones, el resultado será un CSV de cada ERP.

## Sha

El hash o función hash es una función criptográfica que calcula un valor único para un archivo, existen muchos algoritmos, en este caso estamos usando el **Sha1** que es bastante potente, lo que quiere decir que si dos archivos tienen el mismo Sha1, tienen el mismo contenido, *aun cuando tengan diferentes nombres*.

Como dice Wikipedia



## Comprobar archivos ERP

En esta parte voy a probar que las 3 carpetas tengan básicamente lo mismo, entiendo que en las mías borré algunos porque estaban malos o con nombre diferente.

Voy a hacer script de R individuales para cada tarea para tener todo más parcelado. Los archivos no quedarán en GitHub porque no tengo suficiente espacio para guardar tanta cosa.

Alegría, alegría... son lo mismo

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
 Matched observations  1259
        --- Total ---  1259
```

Cruzaron todos. Son 1259 archivos de ERP de 

Los hash se ven así, en los archivos de Sussanne

```R
> head(sussanne)
      file_su                                      sha
1 10000_0.ERP 1e8f1673dc97634c68b90116f2352d1d00e7a23e
2 10000_1.ERP 3d345b1f89f0255129ba541b587665dadb99115d
3 10000_2.ERP 2ecc6459d2eed891b4d7fc27683cd9984b6a5caf
4 10000_3.ERP d7d48302f184631a3409f851cae011b86ea83bf3
5 10000_4.ERP d09724e90a80d32a78f344598270ad0b32f309e9
6 10000_5.ERP bd125f09b150c62cead2a3975b53255846de9ddf
```

En los de Oliver

```R
> head(olito)
     file_oli                                      sha
1 10000_0.ERP 1e8f1673dc97634c68b90116f2352d1d00e7a23e
2 10000_1.ERP 3d345b1f89f0255129ba541b587665dadb99115d
3 10000_2.ERP 2ecc6459d2eed891b4d7fc27683cd9984b6a5caf
4 10000_3.ERP d7d48302f184631a3409f851cae011b86ea83bf3
5 10000_4.ERP d09724e90a80d32a78f344598270ad0b32f309e9
6 10000_5.ERP bd125f09b150c62cead2a3975b53255846de9ddf
```

## Archivos CSV

Como se comprobó que son lo mismo, los CSV que hice yo son los mismos. El resultado de revisar los archivos es 

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
 Matched observations  1259
        --- Total ---  1262
```

Hay 3 que no cruzan, pero por el N debiera ser de otra cosa

```
> combiOlito$using
            file  sha                                   shaCSV         merge
1  data.raw.xlsx <NA> 8aecf0bfcb1878dc3685b62ed75d763d7916ba48 Only in using
2 data.stat.xlsx <NA> bac32f6f736af340f0c017059ffa7b747523c664 Only in using
3 data.tidy.xlsx <NA> cb302c0f695bdd65f2dc0282865b97a6bbf403ef Only in using
```

Sep son los resultados del script de procesado.

Listo entonces para probar el Script. Voy a ver si puedo dejar en Github un comprimido de los CSV. 

### RAR5

Quedaron en 3.3MB los files CSV, como es poco los subo a GitHub.

## Script

Los detalles del Script quedan en el readme de la carpeta del repo.



























