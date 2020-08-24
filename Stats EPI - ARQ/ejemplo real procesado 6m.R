# ------------------------------------------------------------------------------------- #
# ---- Script para procesar EPI y ARQ para actigafía niños de Kathy. Se reusa el ------ #
# ---- método anterior ya desarrollado para el dr, se copia todo y se adapta porque --- #
# ---- la cata dejó listo el ID de los sujetos ---------------------------------------- #
# ------------------------------------------------------------------------------------- #
# Cargar todo
rm(list=ls())
library(openxlsx)
library(stringr)
library(lubridate)
library(dplyr)
library(olibrary)
mainfolder <- "D:/OneDrive/INTA/Cata/2020.06 sincro EPI"
setwd(mainfolder)

# Cargar los script
setwd("D:/OneDrive/INTA/AplicacionesVarias/Stats EPI - ARQ")
script <- dir()
script <- script[grep("_function", script)]
# sapply(script, source)
for (s in script){
    source(s)
}
rm(script, s)
# stop()

# ---- Procesar un epi ---------------------------------------------------------------- #
# Los archivos
setwd(file.path(mainfolder, "6 meses"))
dir()[grep(".csv", dir())]
epi <- function_read.epi("EPI_6m.csv")
arq <- function_read.arq("ARQ 6m L-D.csv")

# Validar lo que cruce
epi <- omerge(epi, arq, byvar = "key", keep = TRUE)

stop()


epi <- epi$match

# Depurar 
rm(arq)
epi <- select(epi, -jornada, -merge)
epi <- arrange(epi, id, periodo, hora)
epi <- mutate(epi, edited = hora < hora.arq)

# Guardar episodios no incluidos y sacarlos del epi
excluded <- filter(epi, edited == TRUE)
epi <- filter(epi, edited == FALSE)

# Terminar
epi <- select(epi, -key, -hora.arq, -edited)


# ---- Pasar la funcion de eventos válidos -------------------------------------------- #
# Pro procesar
epi <- function_ValidEvents(epi)
drop <- epi$drop
epi <- epi$datos

# Validar que se puede analizar
epi <- select(epi, -actividad)
check.epidata(epi)


# ---- Ahora si pasar el resto -------------------------------------------------------- #
horaini <- function_hi(epi)
conteo <- function_conteo(epi)
duracion <- function_duration(epi)
maximos <- function_duracionMax(epi)
latencia <- function_latencia(epi)
par24horas <- function_24h(epi) 
CausaEfecto <- function_combi24h(epi)

# Combinar los dropeos y conservar 24horas
drop <- bind_rows(drop, par24horas$sinpar)
par24horas <- par24horas$conpar


# ----- Juntar todo en un Excel ------------------------------------------------------- #
excel <- createWorkbook()
dfs <- Filter(function(x) inherits(get(x), "data.frame"), ls())

for (xls in dfs){
    addWorksheet(excel, xls)
    eval(parse(text = paste0("writeData(excel, '", xls, "', ", xls, ")")))
    eval(parse(text = paste0("freezePane(excel, '", xls, "', firstRow = TRUE)")))
    eval(parse(text = paste0("c <- ncol(", xls, ")")))
    eval(parse(text = paste0("setColWidths(excel, '", xls, "', cols = 1:", c, ", widths = 'auto')")))
}

saveWorkbook(excel, "epi.stats_babe6m.xlsx", overwrite=TRUE)


