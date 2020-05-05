# ----------------------------------------------------------------------------------------- #
# ----- Script para abrir Stroop de reward - StroopChile_Resonancia - grupo NIH 21y ------- #
# ----- 09.05.2018 - Oliver Rojas - Lab.Sueño - Inta - U.Chile ---------------------------- #
# ----- 02.05.2020 - Se actualiza con documentación y código menos spaguetti -------------- # 
# ----- 05.05.2020 - Se adapta del otro porque es una variación. -------------------------- # 
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
maindir <- "D:/OneDrive/INTA/AplicacionesVarias/Stroop/NIH 21y/StroopChile_Resonancia NIH 21y"
# stroop.dir <- "D:/OneDrive/INTA/AplicacionesVarias/Stroop/NIH 21y/StroopChile_Resonancia NIH 21y/test_files"
stroop.dir <- "C:/Users/olitr/Desktop/Stroop 20 años/StroopChile_Resonancia NIH 21y"


# Listado de archivos
setwd(stroop.dir)
archivos <- dir()
archivos <- archivos[grep(".txt", archivos)]

# file <- archivos[5]
# stop()
	
# ---- 1. Leer el archivo ----------------------------------------------------------------- #
read.file <- function(file=NULL){
    # Puede haber problemas con el encabezado, arreglo para que acepte de 61 y 60 lineas
    if (length(readLines(file)) == 62){
        # Capturar como tabla
        lineas <- read.table(file, header = TRUE, sep = "\t", skip = 1, stringsAsFactors = FALSE)
    } else {
        lineas <- read.table(file, header = TRUE, sep = "\t", skip = 0, stringsAsFactors = FALSE)
    }
    
    
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
	    head <- c(paste("Experiment:",  lineas[1, "ExperimentName"]),
	              paste("Subject:",     lineas[1, "Subject"]),
	              paste("SessionDate:", lineas[1, "SessionDate"]),
	              paste("SessionTime:", lineas[1, "SessionTime"]),
	              paste("Session:",      lineas[1, "Session"]),
	              paste("file:",        file))

    	head <- str_split(head, ": ", simplify = TRUE)
    	head <- data.frame(t(head), stringsAsFactors = FALSE)
        names(head) <- head[1,]
    	head <- head[-1,]
    
    	# Resultado
	    return(list(info = head, stroop = lineas))
	}
}
# Test
# file <- archivos[5]
# lineData <- read.file(file)
# stop()




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
    	
        # Combinar 
    	info <- rename(info, 
    	               exp = "Experiment", sujeto = "Subject", fecha = "SessionDate",
    	               hora = "SessionTime", exp = "Experiment", session = "Session")
        info <- info[rep(seq_len(nrow(info)), 60), ]
    	trial.data <- bind_cols(info, data)
    
    	# Retorno
    	return(trial.data)
    }
}
# Test
# file <- archivos[5]
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
    } else if (nrow(tidyData) != 60){
        # Error en numero de trials
            errores <- data.frame(file = tidyData[1, "file"], error = "Menos de 60 trials", stringsAsFactors = FALSE)
            stats <- NULL
            
    # Si pasa
    } else {
        # Seleccion de variables
        errores <- NULL
        data <- select(tidyData, sujeto = sujeto, fecha = fecha, experiment = exp, 
                                 trial = RunExp, estimulo = Type, congruencia = Congruency, 
                                 respuesta = TextDisplay1.ACC, rtime = TextDisplay1.RT)
        
        # Aplicar tipos de variable correctos
        data <- mutate(data, 
                       congruencia = str_trim(congruencia), rtime = as.numeric(rtime),
                       respuesta = as.numeric(respuesta), sujeto = as.numeric(str_trim(sujeto)), 
                       estimulo = str_trim(estimulo))
        
        # rtime 0 y error en trial
        data <- mutate(data, rtime = ifelse(rtime==0, NA, rtime))
        
        # Basicas
        stats <- group_by(data, congruencia, respuesta, estimulo)
        stats <- summarize(stats, rt = mean(rtime, na.rm=TRUE), n = n())
        stats <- as.data.frame(mutate(stats, id = paste(congruencia, respuesta, estimulo)))
        stats <- select(stats, id, rt, n)
        stats <- mutate(stats, rt = round(ifelse(is.nan(rt), NA, rt), 1))
        
        # Temporal con todas las combinaciones
        temp <- data.frame(
            congruencia = c(rep("congruent",6), rep("incongruent", 6)),
            respuesta = rep(c(0,0,0,1,1,1), 2), 
            estimulo = rep(c("neutral", "punish", "reward"), 4), stringsAsFactors = FALSE)
        temp <- mutate(temp, id = paste(congruencia, respuesta, estimulo))
        
        # Combinar por si falta algo --- hay exceso acá por una reedición ---
        stats <- merge(temp, stats, by="id", all.x=TRUE )
        stats <- select(stats, estimulo, congruencia, respuesta, rt, n) 
        stats <- arrange(stats, estimulo, congruencia, respuesta)
        stats <- mutate(stats, n = ifelse(is.na(n), 0, n))
        rm(temp)
        
        # --- Conteos Todos las celdas ---------------------------------------------------------
        count <- data.frame(t(stats$n))
        names(count) <- c("nCongN.0", "nCongN.1", "nInconN.0", "nInconN.1",
                          "nCongP.0", "nCongP.1", "nInconP.0", "nInconP.1",
                          "nCongR.0", "nCongR.1", "nInconR.0", "nInconR.1")
        
        
        ## Porcentajes Correctas: Estimulo > Congruencia
        pct.celdas <- mutate(count, 
                             pCongN.1 = nCongN.1/(nCongN.1 + nCongN.0), pInconN.1 = nInconN.1/(nInconN.1 + nInconN.0), 
                             pCongP.1 = nCongP.1/(nCongP.1 + nCongP.0), pInconP.1 = nInconP.1/(nInconP.1 + nInconP.0), 
                             pCongR.1 = nCongR.1/(nCongR.1 + nCongR.0), pInconR.1 = nInconR.1/(nInconR.1 + nInconR.0))
        pct.celdas <- select(pct.celdas, pCongN.1, pInconN.1, pCongP.1, pInconP.1, pCongR.1, pInconR.1)
        pct.celdas <- data.frame(apply(pct.celdas, c(1,2), function(x) round(x, 2)))
        
        ## Porcentajes correctas: meh
        pct.meh <- mutate(count, 
                          pCong.1  = ( nCongN.1+ nCongP.1+ nCongR.1)/( nCongN.1+ nCongP.1+ nCongR.1+ nCongN.0+ nCongP.0+ nCongR.0),
                          pIncon.1 = (nInconN.1+nInconP.1+nInconR.1)/(nInconN.1+nInconP.1+nInconR.1+nInconN.0+nInconP.0+nInconR.0),
                          pN.1 = (nCongN.1 + nInconN.1)/20,
                          pP.1 = (nCongP.1 + nInconP.1)/20,
                          pR.1 = (nCongR.1 + nInconR.1)/20) 
        pct.meh <- select(pct.meh, pCong.1, pIncon.1, pN.1, pP.1, pR.1)
        pct.meh <- data.frame(apply(pct.meh, c(1,2), function(x) round(x, 2)))
        
        # ---- RT Todas las celdas ---------------------------------------------------------------
        rt <- data.frame(t(stats$rt))
        names(rt) <- c("mCongN.0", "mCongN.1", "mInconN.0", "mInconN.1",
                       "mCongP.0", "mCongP.1", "mInconP.0", "mInconP.1",
                       "mCongR.0", "mCongR.1", "mInconR.0", "mInconR.1")
        
        
        # ---- RT no estimulo: solo "Congruencia X Respuesta
        rtNE <- group_by(data, congruencia, respuesta)
        rtNE <- summarize(rtNE, rt = mean(rtime, na.rm=TRUE))
        rtNE <- as.data.frame(mutate(rtNE, id = paste(congruencia, respuesta)))
        rtNE <- select(rtNE, id, rt)
        
        restats <- data.frame(congru = c(rep("congruent",2), rep("incongruent", 2)), resp = c(0,1,0,1))
        restats <- mutate(restats, id = paste(congru, resp))
        
        rtNE <- merge(restats, rtNE, by="id", all.x=TRUE )
        rtNE <- select(rtNE, congruencia = congru, respuesta = resp, rt) %>% arrange(congruencia, respuesta)
        rtNE <- mutate(rtNE, rt = ifelse(is.na(rt) == TRUE, NA, rt))
        
        rtNE <- data.frame(t(rtNE$rt))
        names(rtNE) <- c("mCong.0", "mCong.1", "mIncon.0", "mIncon.1")
        rtNE <- data.frame(apply(rtNE, c(1,2), function(x) round(x, 1)))
        
        # ---- RT no congruencia: solo "Estimulo X Respuesta
        rtNC <- group_by(data, estimulo, respuesta)
        rtNC <- summarize(rtNC, rt = mean(rtime, na.rm=TRUE))	
        rtNC <- as.data.frame(mutate(rtNC, id = paste(estimulo, respuesta)))
        rtNC <- select(rtNC, id, rt)
        
        restats <- data.frame(estimulo = c(rep("neutral",2),rep("punish",2),rep("reward",2)), respuesta = c(0,1,0,1,0,1))
        restats <- mutate(restats, id = paste(estimulo, respuesta))
        
        rtNC <- merge(restats, rtNC, by="id", all.x=TRUE )	
        rtNC <- select(rtNC, estimulo, respuesta, rt) %>% arrange(estimulo, respuesta)	
        rtNC <- mutate(rtNC, rt = ifelse(is.na(rt) == TRUE, NA, rt))
        
        rtNC <- data.frame(t(rtNC$rt))
        names(rtNC) <- c("mN.0", "mN.1", "mP.0", "mP.1", "mR.0", "mR.1")
        rtNC <- data.frame(apply(rtNC, c(1,2), function(x) round(x, 1)))
        
        
        # ---- Juntar todo ------------------------------------------------------------
        stats <- cbind(count, pct.celdas, pct.meh,    # Grupo conteos
                       rt,    rtNE,       rtNC)       # Grupo medias
        
        # Agregar identificadores
        idData <- data.frame(id = tidyData[1, "sujeto"], 
                             hora = tidyData[1, "hora"], 
                             experimento = tidyData[1, "exp"], 
                             session = tidyData[1, "session"],
                             file = tidyData[1, "file"], stringsAsFactors = FALSE)
        stats <- bind_cols(select(idData, -file),
                           stats,
                           select(idData, file))
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
saveWorkbook(excel, "StroopChile_Resonancia NIH 21y Stats.xlsx", overwrite = TRUE)

