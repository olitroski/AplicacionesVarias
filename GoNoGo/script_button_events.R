## Script para crear base de datos con los trials (1-500) Go-no-Go a partir del CSV
## del <erp> file 
rm(list=ls()); library(openxlsx); library(dplyr)

## --- Set working directory ---------------------------------------------------- ##
# --- Choose folder with csv files --- #
# setwd("D:/OneDrive/INTA")
# # Seleccionar solo archivos que terminan en csv
# files <- dir()
# files <- files[grep("csv|CSV", files)]
# files
## Esto queda al final


## --- Cargar file -------------------------------------------------------------- ##
# Funcion para leer la seccion BUTTON EVENTS
read.csvfile <- function(erpcsv){
	# Capturar limites
	lineas <- readLines(erpcsv)
	ini <- grep("Button events", lineas) + 1
	fin <- grep("Correct presses", lineas) - 3
	
	# Leer archivos
	datos  <- read.table(erpcsv, header=TRUE, sep = ",", stringsAsFactors = FALSE,
			skip = ini, nrows = fin - ini)
			
	# Leer los meros trials
	ini2 <- grep("Trials", lineas)[1] 
	fin2 <- grep("Button events", lineas) - 3
	
	datos2  <- read.table(erpcsv, header=TRUE, sep = ",", stringsAsFactors = FALSE,
		skip = ini2, nrows = fin2 - ini2)

	return(list(datos = datos, trials = datos2))
}
# Test
# erpcsv <- files[1]
# datalist <- read.csvfile(erpcsv)
# View(datalist$datos)
# View(datalist$trials)


## ----- Funcion para arreglar los archivos importado --------------------------- ##
tidy.rawdata <- function(datalist){

	# Revisar si hay negativos, de haber corregir con NA
	datos <- datalist[[1]]
	malos <- filter(datos, Pressed < 0 | Released < 0 | ID == 3)
		
	# Corregir respuestas negativas por doble clic
	if (nrow(malos) > 0) {
		# Agregar variable a datos de los que están malso
		malos <- select(malos, Trial)
		malos <- as.numeric(malos$Trial)
		datos$malos <- ifelse(datos$Trial %in% malos, 1, NA)
		
		# Guarda datos ok
		datosOK <- filter(datos, is.na(malos))
		datosOK <- mutate(datosOK, status = "Ok")
	
		# --- Si (ID == 1) se borran y se rellena con NA y status "error"
		datosID1 <- filter(datos, malos == 1, ID == 1)
		datosID1 <- unique(datosID1$Trial)
		if (length(datosID1)>0){
			datosID1 <- data.frame(Trial = datosID1, ID = 1, Pressed = NA, Released = NA,
					Button = "Go", Response = "Incorrect", malos = 1, status = "Error")
		} else {datosID1 <- NULL}
		
		
		# --- Si (ID == 2) se borran y rellenan con NA y status "error"
		datosID2 <- filter(datos, malos == 1, ID == 2)
		datosID2 <- unique(datosID2$Trial)
		if (length(datosID2)>0){
			datosID2 <- data.frame(Trial = datosID2, ID = 2, Pressed = NA, Released = NA,
					Button = "Go", Response = "Incorrect", malos = 1, status = "Error")
		} else {datosID2 <- NULL}		
		
		
		# ---- Si (ID == 3) se borran y rellenan con NA y status "error"
		datosID3 <- filter(datos, malos == 1, ID == 3)
		datosID3 <- unique(datosID3$Trial)
		if (length(datosID3)>0){
			datosID3 <- data.frame(Trial = datosID3, ID = 3, Pressed = NA, Released = NA,
					Button = "NoGo", Response = "Incorrect", malos = 1, status = "Error")
		} else {datosID3 <- NULL}		
		
		
		# Combinar arreglos
		datos <- rbind(datosOK, datosID1, datosID2, datosID3)
		datos <- arrange(datos, Trial)
	
	# AÃ±adir variables neutras
	} else {
		datos <- mutate(datos, malos = NA, status = "Ok")
	}
	

	# Agregar los trials que faltan No-GO
	# quina <- c(1:500)    verion 21 años
	quina <- c(1:150)
	b3num  <- quina[!(quina %in% datos$Trial)]
	b3data <- data.frame(Trial = b3num, ID = 3, Pressed = NA, 
	          Released = NA, Button = NA, Response = NA, malos = NA, status = "Ok")
	datos <- rbind(datos, b3data)
	datos <- arrange(datos, Trial)
	
	
	# Del trial 1 a 50 es solo GO "ID = 1"
	datos$ID[1:40] <- 1
	
	# <<< tidy up del data.frame>>>
	# Cambiar ID a block
	datos <- rename(datos, trial=Trial, block=ID, pressed=Pressed, released=Released)
	
	# Calcular tiempo apretado
	datos <- mutate(datos, presstime = released - pressed)
	
	# Arreglar el Button
	datos <- mutate(datos, button = ifelse(block==1, "Test", ifelse(block==2, "Go", "NoGo")))
	
	# Borrar algunas cosas y ordenar
	datos <- select(datos, -Button, - malos, -Response)
	datos <- select(datos, trial, block, pressed, released, presstime, button, status)
	
	# Cambia a status si block = 1 y response = NA
	datos$status[datos$block==1 & is.na(datos$pressed)]  <- "Error"
	
	# Cambia status si block = 3 y response > 0
	datos$status[datos$block==3 & datos$pressed>0]  <- "Error"
	
	# Existe la posibilidad de que trials que no esten sean go == 2 y no como arriba, 
	# para corregir se carga la info de trial y se coteja con el invento.
	trials <- datalist[[2]]
	trials <- rename(trials, bloque = ID, tri = Trial)
	trials <- select(trials, bloque, tri)
	datos <- cbind(datos, trials)
	
		# Correccion
 		datos$status[datos$block==3 & datos$bloque==2] <- "Error"
 		datos$block[datos$block==3 & datos$bloque==2] <- 2
 		datos <- select(datos, -bloque, -tri)
	
	# Resultado
	return(datos)
}

# Test
# erpcsv <- files[1]
# datalist <- read.csvfile(erpcsv)
# tidydata <- tidy.rawdata(datalist)
# View(tidydata)


## ----- Funcion para crear estadisticas por bloque ---------------------------- ##
block.stats <- function(tidydata){
	
	# Recuentos
	freqdata <- mutate(tidydata, corr = ifelse(status=="Ok", 1, 0), 
						  inc = ifelse(status=="Error", 1, 0))
	freqdata <- group_by(freqdata, block)
	freqdata <- summarize(freqdata, cor=sum(corr), inc=sum(inc), 
		       pctcor=sum(corr)/n(), pctinc=sum(inc)/n())
	
	# Recuentos - to wide en data.frame
	freqdata <- as.data.frame(freqdata)
	freqdata <- mutate(freqdata, subject=1)
	freqdata <- reshape(freqdata, idvar="subject", timevar="block", 
			v.names=c("cor","inc","pctcor","pctinc"),direction = "wide")
	freqdata <- select(freqdata, -subject)

	
	# Estadsiticas (solo para status == "Ok")
	statdata <- filter(tidydata, status=="Ok")
	statdata <- group_by(statdata, block)
	statdata <- summarize(statdata, mpress = mean(pressed, na.rm=TRUE), sdpress=sd(pressed, na.rm=TRUE))
	
	# To wide
	statdata <- as.data.frame(statdata)
	statdata <- mutate(statdata, subject=1)
	statdata <- reshape(statdata, idvar="subject", timevar="block",
			v.names=c("mpress","sdpress"), direction = "wide")
	statdata <- select(statdata, -subject)
	
	# datos completos
	data <- cbind(freqdata, statdata)
	return(data)	
}

# Test
# erpcsv <- files[1]
# datalist <- read.csvfile(erpcsv)
# tidydata <- tidy.rawdata(datalist)
# stats <- block.stats(tidydata)
# View(stats)


## Funcion para captura la condicion de un trial ok o error
crossval <- function(tidydata){
	datos <- tidydata
	
	# Filtrados para guardar
	b1ok <- filter(datos, block==1, status=="Ok")
	b2ok <- filter(datos, block==2, status=="Ok")
	b3ok <- filter(datos, block==3, status=="Ok")
	b1error <- filter(datos, block==1, status=="Error")
	b2error <- filter(datos, block==2, status=="Error")
	b3error <- filter(datos, block==3, status=="Error")

	# Funcion para procesarlo
	filtrado <- function(filtered){
		data  <- filtered
	
		# Pos si no saca dato el filtrado
		if (dim(data)[1]==0){
			data <- "0"
		# Para los que sacan datos
		} else {
			data <- select(data, trial)
			data <- as.numeric(data$trial)
			data <- paste(data, collapse=", ")
		}
		
		# resultado
		return(data)
		
	}
	
	# Crear data frame para 
	crossdata <- data.frame(block = c(1, 2, 3),
			error = c(filtrado(b1error), filtrado(b2error), filtrado(b3error)),
			ok = c(filtrado(b1ok), filtrado(b2ok), filtrado(b3ok)), stringsAsFactors=FALSE)
	
	return(crossdata)
}

# Test
# erpcsv <- files[1]
# datalist <- read.csvfile(erpcsv)
# tidydata <- tidy.rawdata(datalist)
# evalcross <- crossval(tidydata)
# View(evalcross)



## Funcion para el idname
# a partir del filename
idname <- function(file){
	name <- file
	name <- unlist(strsplit(name, "\\."))
	name <- name[1]
	return(name)
}

# Test
# erpcsv <- files[1]
# idname(erpcsv)


## ---------------------------------------------------------------------------- ## 
## ----- Crear bases de datos para analisis ------------------------------------- ##
## ---------------------------------------------------------------------------- ##
# Cargar el directorio
procesarGNG <- function(){
    # Seleccionar el wd
    basfolder <- choose.dir(caption = "Selecciona carpeta donde estén los CSV")
    setwd(basfolder)

    # Cargar los archivos archivo <- files[1]
    files <- dir()
    files <- files[grep("csv|CSV", files)]

    # Procesar las stats primero
    statsfile <- NULL
    crossfile <- NULL
    tidyfile  <- NULL

    for (archivo in files){
        cat(archivo, "\n")

        # Lecturas y tidy y names
        nombre <- data.frame(id = idname(archivo), stringsAsFactors=FALSE)
        tidy <- archivo %>% read.csvfile() %>% tidy.rawdata()
        
        # Capturar estadisticas y corss
        stat <- cbind(nombre, block.stats(tidy))
        cross <- cbind(nombre, crossval(tidy))
        
        # Combinar
        tidyfile <- rbind(tidyfile, tidy)
        statsfile <- rbind(statsfile, stat)
        crossfile <- rbind(crossfile, cross)
    }

    # Guardar
    write.xlsx(statsfile, "statsfile.xlsx")
    write.xlsx(crossfile, "crossfile.xlsx")
    write.xlsx(tidyfile,  "tidyfile.xlsx")

    # Return
    resultado <- list(stat = statfile, cross = crossfile)
    return(resultado)
}
















