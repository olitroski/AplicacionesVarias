# Scrip para compilar los errores de canales
# setwd("D:/OneDrive/INTA") <----- Pegar aquí el working directory
setwd("D:/OneDrive/INTA")
rm(list=ls())
library(dplyr)
stop()
{


# Capturar el archivo
# file <- "prueba.CSV"  # Este es el antiguo el de 500 trials de 21 años ahora etoy probando el de 15y
files <- dir()
files <- files[grep("csv|CSV", files)]
file <- files[1]

# Captura el trozo de los bad channels
lineas <- readLines(file)
ini <- grep("Bad Channels", lineas) 
fin <- grep("Custom Trials", lineas) - 3
datos <- read.table(file, header = TRUE, sep = ",", stringsAsFactors = FALSE, 
                    skip = ini, nrows = fin - ini)

# Recortar las columnas, en el importe quedaron como logical los full NA
varname <- names(datos)
for (j in varname){
     tipo <- class(datos[[j]])
     if (tipo == "logical"){
          datos[[j]] <- NULL
     }
}

# Recortar las filas, mediante variable accesoria y transpose
datos[datos == "X"]  <- "1"
for (j in 2:dim(datos)[[2]]) {datos[j] <- as.numeric(datos[[j]])}
datos[is.na(datos)] <- 0
datos$suma <- rowSums(datos[2:dim(datos)[2]])
datos <- filter(datos, suma != 0)
datos$suma <- NULL
datos <- t(datos)


# Cambiar el punto por el trial, reemplaza el evento por el trial
fila <- dim(datos)[1]
col <- dim(datos)[2]
for (j in 1:col){
     for (i in 2:fila){
          if (datos[i,j]==1){
               datos[i,j] <- datos[1,j]
          } else {
               datos[i,j] <- NA
          }
     }
}
datos <- datos[-1,]
datos <- as.data.frame(datos)


# Compilar el resutlado, pasando linea a string y concatenando
for (i in 1:dim(datos)[1]){
     trial <- row.names(datos[i,])
     linea <- as.character(datos[i,])
     linea <- linea[!(grepl("NA", linea))]
     linea <- paste(linea, collapse=", ")
     cat("(", trial, " = ", linea, ") ", sep="")
}

}
View(datos)
