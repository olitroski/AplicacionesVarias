# Script para hacer cosas aleatorias
# Ojo que es lento porque uso data.frames si se vectoriza sería mil más de rápido.
# Es copiar y pegar en el RStudio o el que guste
# O.Rojas - Lab.Sueño - U.Chile - 01.2020
library(dplyr)

# Funcion para encontrar secuencias....
find.segment <- function(df = NULL, var = NULL, filtro = NULL){
    library(dplyr)
    tempvar <- df[[substitute(var)]]  
    segm <- which(tempvar == filtro)

    indx1 <- segm - c(-10, segm[-length(segm)])
    indx1 <- segm[which(indx1 > 1)]    
    
    indx2 <- segm - c(segm[-1], 10000000)
    indx2 <- segm[which(indx2 < -1)]
    
    segmdf <- data.frame(ini = indx1, fin = indx2)
    return(segmdf)
}

# Crear un data.frame con los valores que se van a aleatorizar
sonido <- c(rep("Guibu", 50), rep("Bidu", 50))

combina <- c(rep("Guibu 2800", 25), rep("Guibu 1800", 25),
             rep("Bidu  2800", 25), rep("Bidu  1800", 25))

aleatorio <- data.frame(sonido = sonido, 
                        trial = combina, 
                        stringsAsFactors = FALSE)


# Valores iniciales para el bucle
N <- 1
ok.bidu <- FALSE
ok.guibu <- FALSE
OK = FALSE


# Prueba diferentes ordenamientos mientras el objeto "OK" no 
# tenga valor "TRUE"
while (OK != TRUE){
    # Imprime el numero de repeticion y al tiro le suma un 
    # valor para la prox repeticion
    print(N)
    N <- N + 1
    
    # Crea una variable de numeros aleatorios (dist Uniforme) y ordena
    # el data.frame por esa variable (arrange), asi queda todo desordenado
    aleatorio$random <- runif(100)
    aleatorio <- arrange(aleatorio, random)
    
    # Usando la funcion "find.segment" se buscan las veces que sale repetido
    # el "Bidu" y evalua si el maximo es "<= 3" de ser asi cambia el valor
    # a "TRUE" (al inicio era FALSE)
    seq.bidu <- find.segment(df = aleatorio, var = sonido, filtro = "Bidu")
    seq.bidu <- mutate(seq.bidu, delta = fin - ini + 1)
    if (max(seq.bidu$delta) <= 3){ok.bidu <- TRUE}
    
    # Para "Guibu"... por cierto la variable "delta" cuenta la cantidad de repetidos
    seq.guibu <- find.segment(df = aleatorio, var = sonido, filtro = "Guibu")
    seq.guibu <- mutate(seq.guibu, delta = fin - ini + 1)
    if (max(seq.guibu$delta) <= 3){ok.guibu <- TRUE}
    
    # Y decide, si encontro que ambas condiciones se cumplen cambia el valor de
    # "OK" a TRUE y el bucle se detiene. De lo contrario le vuelve a dejar 
    # a ok.guibu y ok.bidu los valores iniciales de FALSE, en caso de que se cambie
    # Solo uno.
    if (ok.guibu == TRUE & ok.bidu == TRUE){
        OK <- TRUE
    } else {
        ok.bidu <- FALSE
        ok.guibu <- FALSE
    }
    
}
# Y muestra el resultado.
cat(paste("Se encontró un resultado a la iteración: ", N))
View(aleatorio)
