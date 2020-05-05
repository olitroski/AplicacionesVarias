# ----------------------------------------------------------------------------------------- #
# ----- Script para abrir Stroop de reward - Carpeta: Stroop-Chile2015 - grupo CV 22y ----- #
# ----- 09.05.2018 - Oliver Rojas - Lab.Sueño - Inta - U.Chile ---------------------------- #
# ----- 02.05.2020 - Se actualiza con documentación y código menos spaguetti -------------- # 
# ----- 04.05.2020 - Versión cardio ------------------------------------------------------- # 
# ----------------------------------------------------------------------------------------- #
# Se hace en funcional porque de los R
# 1. Funcion para leer el archivo
# 2. Función para capturar raw data

# Previos
rm(list=ls())
# source("https://raw.githubusercontent.com/olitroski/sources/master/exploratory/sources.r")
library(stringr)
library(dplyr)
library(openxlsx)
options(warn=1)


# Test files
maindir <- "D:/OneDrive/INTA/AplicacionesVarias/Stroop/CV 22y/Stroop Tradicional CV 22y"
stroop.dir <- "C:/Users/olitr/Desktop/Stroop 20 años/Stroop CVH 22y Tradicional Sussanne"
# stroop.dir <- "D:/OneDrive/INTA/AplicacionesVarias/Stroop/CV 22y/Stroop Tradicional CV 22y/test_files"


# Listado de archivos
setwd(stroop.dir)
archivos <- dir()
archivos <- archivos[grep("Stroop_Chile2015", archivos)]
archivos <- archivos[grep(".txt", archivos)]

# stop()
	
# ---- 1. Leer el archivo ----------------------------------------------------------------- #
read.file <- function(file=NULL){
    # Lineas
	lineas <- readLines(file)
	
	# Checa file en blanco
	if (length(lineas)==0){
	    # Aviso de nara
	    head <- data.frame(status = "En blanco", stringsAsFactors = FALSE)
		lineas <- data.frame(file = file, error = "En blanco", stringsAsFactors = FALSE)
		
		# Resultado
		return(list(info = head, stroop = lineas))
	
	# Si pasa sigue
	} else {
    	# Crea un data.frame con la info de la cabecera
        head <- lineas[1:21]
        head <- c(lineas[grep("Experiment", head)],
                  lineas[grep("Subject", head)],
                  lineas[grep("SessionDate", head)],
                  lineas[grep("SessionTime", head)],
                  lineas[grep("Session:", head)],
                  paste("File:", file))
        
    	head <- str_split(head, ": ", simplify = TRUE)
    	head <- data.frame(t(head), stringsAsFactors = FALSE)
        names(head) <- head[1,]
    	head <- head[-1,]
    
    	# Usar las tabulaciones del archivo para filtrar lo que sirve
    	lineas <- lineas[grep("\t", lineas)]
    	lineas <- sub("\t", "", lineas)
	
    	# Resultado
	    return(list(info = head, stroop = lineas))
	}
}
# Test
# file <- archivos[1]
# lineData <- read.file(file)


# ---- 2. Leer la data --------------------------------------------------------------- #
## Funcion para crear el registro del sujeto
# file.list <- read.file(file)
read.data <- function(lineData = NULL){
	# Corrección por si viene en blanco desde la otra funcion
    if (lineData$info[1,1] == "En blanco"){
        return(lineData$stroop)
        
    # Si pasa
    } else {
    	# Captura la lista
    	info <- lineData[["info"]]
    	data <- lineData[["stroop"]]
    	
    	# Indice para capturar trials
    	index <- data.frame(ini=grep("* LogFrame Start *", data), fin=grep("* LogFrame End *", data))
    	index <- mutate(index, ini = ini + 1, fin = fin - 1)
    
    	# Nombre de las filas
    	trial.data <- data[c(index[1,1]:index[1,2])]
    	trial.data <- str_split(trial.data, ":", 2, simplify = TRUE)[, 1]
    	trial.data <- data.frame(variable = trial.data, stringsAsFactors=FALSE)
    	
    	for (i in 1:nrow(index)){
    		# Captura
    		trial <- data[c(index[i,1]:index[i,2])]
    		trial <- str_split_fixed(trial, ":", 2)
    		trial <- data.frame(trial, stringsAsFactors=FALSE)
    		trial <- select(trial, 2)
    		names(trial) <- paste("trial.", i, sep="")
    		# Pega la columna
    		trial.data <- cbind(trial.data, trial)
    	}
    
    	# Transpuesto
    	varnames <- trial.data[[1]]
    	trial.data <- select(trial.data, -variable)
    	trial.data <- data.frame(t(trial.data), stringsAsFactors=FALSE)
    	names(trial.data) <- varnames
    	row.names(trial.data) <- NULL
              
         # Agregar la data del sujeto
    	trial.data <- mutate(trial.data, 
    	                     sujeto = info[1, "Subject"], 
    	                     fecha = info[1, "SessionDate"],
    	                     hora = info[1, "SessionTime"],
    	                     exp = info[1, "Experiment"], 
    	                     session = info[1, "Session"],
    	                     file = info[1, "File"])
    
    	# Retorno
    	return(trial.data)
    }
}
# Test
# file <- archivos[1]
# lineData <- read.file(file)
# tidyData <- read.data(lineData)
# stop()


# ---- 3. Función de stats ----------------------------------------------------------- #
# Tiene un extra innecesario pero para no hacer más código la conservo, la 1° parte
stats.data <- function(tidyData){
    options(warn = 2)
    
    # Si viene en blanco desde arriba
    if (tidyData[1, 2] == "En blanco"){
        # file | error
        errores <- tidyData
        stats <- NULL
        
    # Si no tienen trials necesarios
    } else if (nrow(tidyData) != 72){
        # Error en numero de trials
        errores <- data.frame(file = tidyData[1, "file"], error = "Menos de 60 trials", stringsAsFactors = FALSE)
        stats <- NULL
            
    # Si pasa
    } else {
        # Seleccion de variables
        data <- select(tidyData, sujeto = sujeto, fecha = fecha, experiment = exp, 
                                 trial = RunExp, congruencia = Congruency, 
                                 respuesta = TextDisplay1.ACC, rtime = TextDisplay1.RT)
        
        # Aplicar tipos de variable correctos
        data <- mutate(data, 
                       congruencia = str_trim(congruencia), rtime = as.numeric(rtime),
                       respuesta = as.numeric(respuesta), sujeto = as.numeric(str_trim(sujeto)))
        
        # rtime 0 y error en trial
        data <- mutate(data, rtime = ifelse(rtime==0, NA, rtime))
        data <- slice(data, -(1:12))
        
        # ---- Adaptacion al cambio CCI (diferencia I-C) ----------------------------------------------------
        cci <- NULL
        data$acambio <- NA
        for (i in 1:58){
            # Busca la secuencia
            if (data$congruencia[i]   == "congruent"   & data$respuesta[i]   == 1 &
                data$congruencia[i+1] == "congruent"   & data$respuesta[i+1] == 1 &
                data$congruencia[i+2] == "incongruent" & data$respuesta[i+2] == 1){
                
                # Captura la diferencia
                rt <- data$rtime[i+2] - data$rtime[i+1]
                data$acambio[i+2] <- rt			
                cci <- c(cci, rt)
            }
        }
        
        # Si no hubieran CCI porque no hay correctas
        if (is.null(cci) == TRUE){
            cci <- data.frame(n.cci = NA, n.cci.ok = NA, mean.cci = NA)
        } else {
            cci <- data.frame(n.cci = length(cci), n.cci.ok = length(cci[cci>0]), mean.cci = mean(cci[cci>0]))
            cci <- mutate(cci, mean.cci = ifelse(is.na(mean.cci), NA, mean.cci))
        }
        cci
        
        
        # ---- Adaptacion al conflicto IIC (diferencia C-I) -------------------------------------------------
        iic <- NULL
        data$aconflict <- NA
        for (i in 1:58){
            if (data$congruencia[i]   == "incongruent" & data$respuesta[i]   == 1 &
                data$congruencia[i+1] == "incongruent" & data$respuesta[i+1] == 1 &
                data$congruencia[i+2] == "congruent"   & data$respuesta[i+2] == 1){
                rt <- data$rtime[i+2] - data$rtime[i+1]
                data$aconflict[i+2] <- rt			
                iic <- c(iic, rt)
            }
        }
        
        # Si no hay porque no hay correctas se corrige aca
        if (is.null(iic) == TRUE){
            iic <- data.frame(n.iic = NA, n.iic.ok = NA, mean.iic = NA)
        } else {
            iic <- data.frame(n.iic = length(iic), n.iic.ok = length(iic[iic>0]), mean.iic = mean(iic[iic>0]))
            iic <- mutate(iic, mean.iic = ifelse(is.na(mean.iic), NA, mean.iic))
        }
        iic
        
        
        # ---- Estadísticas tipicas --------------------------------------------------------------------------
        stats <- group_by(data, congruencia, respuesta)
        stats <- summarize(stats, rt = mean(rtime, na.rm=TRUE), n = n())
        stats <- as.data.frame(mutate(stats, id = paste(congruencia, respuesta)))
        stats <- select(stats, id, rt, n)
        stats <- mutate(stats, rt = round(ifelse(is.nan(rt), NA, rt), 1))
        
        # data.frame en el orden 
        restats <- data.frame(congruencia = c("congruent","congruent","incongruent","incongruent"),respuesta = c(0,1,0,1))
        restats <- mutate(restats, id = paste(congruencia, respuesta))
        # combinado
        stats <- merge(restats, stats, by="id", all.x=TRUE )
        stats <- select(stats, -id)
        rm(restats)
        stats
        
        # N y PCT
        n <- data.frame(t(stats$n))
        names(n) <- c("n.cong.0", "n.cong.1", "n.incon.0", "n.incon.1")
        n <- mutate(n, pct.cong.1 = round(n.cong.1/30, 2), 
                       pct.incon.1 = round(n.incon.1/30, 2))
        
        # RT
        rt <- data.frame(t(stats$rt))
        names(rt) <- c("rt.cong.0", "rt.cong.1", "rt.incon.0", "rt.incon.1")
        rt <- apply(rt, c(1, 2), function(x) ifelse(is.na(x), NA, x))
        rt <- data.frame(rt)
        
        # Combinar stats
        stats <- bind_cols(n, rt, cci, iic)
        stats <- mutate(stats, mean.cci = round(mean.cci, 1), mean.iic = round(mean.iic, 1))
        
        
        # ---- Juntar todo ------------------------------------------------------------
        # Agregar identificadores
        idData <- data.frame(id = tidyData[1, "sujeto"], 
                             hora = tidyData[1, "hora"], 
                             experimento = tidyData[1, "exp"], 
                             session = tidyData[1, "session"],
                             file = tidyData[1, "file"], stringsAsFactors = FALSE)
        
        stats <- bind_cols(select(idData, -file),
                           stats,
                           select(idData, file))
        
        errores <- NULL
    }

    # Retorno
    temp <- list(errores = errores, stats = stats)
    return(temp)
    options(warn=0)
}

# Test
# file <- archivos[1]
# lineData <- read.file(file)
# tidyData <- read.data(lineData)
# statData <- stats.data(tidyData)
# stop()



# ---- 4. Pasar todo a Excel -------------------------------------------------------
# Iniciar el Excel
excel <- createWorkbook()

# Iniciar data.frames en orden de aparición
# lineData$stroop no se archiva, es mucha info para un excel
dataInfo <- NULL
dataTidy <- NULL
dataStat <- NULL
dataError <- NULL

# Con contador
for (i in 1:length(archivos)){
    # Current Archivo 
    file <- archivos[i]
    print(paste0("pct: ", round(i/length(archivos)*100, 1), "% | Archivo: ", file))

    # Leer la data
    lineData <- read.file(file)
    if (lineData$info[1,1] != "En blanco"){
        dataInfo   <- bind_rows(dataInfo,   lineData$info)
    }

    # Hermosear data
    tidyData <- read.data(lineData)
    if (tidyData[1,2] != "En blanco"){
        dataTidy <- bind_rows(dataTidy, tidyData)
    }
    
    # Resultados
    statData <- stats.data(tidyData)
    dataStat <-  bind_rows(dataStat,  statData$stats)
    dataError <- bind_rows(dataError, statData$errores)
}

# Pasar los Excel
addWorksheet(excel, "dataStat")
writeData(excel, "dataStat", dataStat)

addWorksheet(excel, "dataTidy")
writeData(excel, "dataTidy", dataTidy)

addWorksheet(excel, "dataInfo")
writeData(excel, "dataInfo", dataInfo)

addWorksheet(excel, "dataError")
writeData(excel, "dataError", dataError)

# Y se guarda
setwd(maindir)
saveWorkbook(excel, "Stroop-Chile2015 CV 22y stats.xlsx", overwrite = TRUE)

