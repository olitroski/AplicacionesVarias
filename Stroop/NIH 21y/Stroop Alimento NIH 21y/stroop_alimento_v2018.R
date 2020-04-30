# ---------------------------------------------------------------------------------- #
# --- Script para leer stroop comida  ---------------------------------------------- #
# --- Soledad R. - Creado por Oliver Rojas 29.04.2016 ------------------------------ #
# --- Revision 1: 09.05.2016 se a?ade progreso y check de nombre y file ------------ #
# --- Revision 2: 11.05.2017 revision y actualizacion ------------------------------ #
# --- Revision 3: 18.05.2018 Se hace de nuevo, con nuevas directrices -------------- #
# --- Revision 4: 29.04.2020 Se revisa y documenta en github ----------------------- #
# ---------------------------------------------------------------------------------- #
# Setear el working directory y cargar los paquetes
rm(list=ls())
library(dplyr)
library(openxlsx)
library(stringr)
library(tidyr)

# maindir = choose.dir()
maindir <- "D:/OneDrive/INTA/AplicacionesVarias/Stroop/NIH 21y/Stroop Alimento NIH 21y"
filedir <- "D:/OneDrive/INTA/AplicacionesVarias/Stroop/NIH 21y/Stroop Alimento NIH 21y/Stroop NIH Archivos Inta Oliver CSV"
setwd(filedir)

# Captura archivos
archivos <- dir()

# ---------------------------------------------------------------------------------- #
# --- 1. Funciones ----------------------------------------------------------------- #
# ---------------------------------------------------------------------------------- #

# --- Lectura de archivo -----------------------------------------------------------
# Toma un archivo, captura la seccion Trials y Button events      file <- archivos[939]
read.file <- function(file = NULL){
	lines <- readLines(file)
	
	# Capturar preses
	ini <- grep("All presses", lines)
	fin <- grep("Correct presses", lines)
	if (fin-3-ini == 0){ 	# Porque en los de prueba a veces no aprietan nada y no se importa nada
		press = NULL
	} else {
		press <- read.table(file, header=TRUE, sep=",", skip=ini, nrows=fin-3-ini, stringsAsFactors=FALSE)
	}

	# Capturar Trials (para indicar los omitidos)
	ini <- grep("Trials", lines)[1]
	fin <- grep("Button events", lines)
	trials <- read.table(file, header=TRUE, sep=",", skip=ini, nrows=fin-3-ini, stringsAsFactors=FALSE)
	trials
	
	# Mensaje por si hay cero press y el id != 3
	if (class(press) == "NULL" & trials$ID[1] != 3){
		error <- paste("File con problemas, todo omitido e ID diferente de 3:", file)
		stop(error)
	}
		
	# Captura nombre archvio e Id
	name <- file
	name <- sub(".txt|.TXT", "", name)
	name <- sub(".csv|.CSV", "", name)
	name <- sub(".erp|.ERP", "", name)
	name <- data.frame(file = file, id.block = name, stringsAsFactors = FALSE)
	
	# output
	return(list(press = press, trials = trials, name = name))
}
# data <- read.file(archivos[1])
# data


# --- Tidy up the readed file ------------------------------------------------------
# Toma el archivo ya leido y lo hemosea para poder hacerle algún análisis
tidy.data <- function(data = NULL){
	# Primero tratar los repetidos la regla es: borrar el primero, etiquetarlo como
	# "Incorrect" y conservar la latencia de la segunda repeticion.
	# data <- read.file(archivos[2])
	press <- data$press
	
	# Si es que press esta nulo, salir (porque es uno de prueba o algo pas?)
	if (class(press) == "NULL"){
		return(NULL)
		
	} else {
		# Identificar Trials repetidos en una variable nueva "Repeated"
		press$repeated <- 0
		for (i in 1:(dim(press)[1]-1)) {
			# Si no alcanza el n de trials, debe estar malo
			if (dim(press)[1] < 2){
				break()
			# Si esta repetido se anota.
			} else if (press$Trial[i] == press$Trial[i+1]) {
				press$repeated[i]   <- 1
				press$repeated[i+1] <- 2
			}
		}
		
		# Borra trial y corrige a incorrect
		press <- filter(press, repeated !=1)
		press$Response[press$repeated==2] <- "Incorrect"
				
		# Con el df Trials se agregan los omitidos junto con su id
		trials <- data$trials
		trials <- select(trials, Trial, ID)
		trials <- merge(trials, press, by="Trial", all = TRUE)
		
		# Se depura el trials en el mismo objeto
		trials <- select(trials, Trial, id = ID.x, Pressed, Response)
		trials <- mutate(trials, Response = ifelse(is.na(Response)==TRUE, "Omitted", Response))
		names(trials) <- c("trial","estimulo","latency","respuesta")
		
		# Hacer los factores como corresponde
		trials <- mutate(trials, response = ifelse(respuesta == "Correct", 1, ifelse(respuesta == "Incorrect", 2, 3)))
		trials$response <- factor(trials$response, levels = c(1,2,3), labels = c("Correct", "Incorrect", "Omitted"))
		trials$estimulo <- factor(trials$estimulo)
				
		# Pegarle el id y demas datos
		names <- data$name
		stroop <- mutate(trials, file = names$file[1], id.block = names$id.block[1])
		stroop <- arrange(stroop, trial)
		stroop <- select(stroop, id.block, trial, estimulo, latency, response, file)
		
		
		# <<< Arreglar si la latencia es negatiga y el response incorrect >>>
		stroop <- mutate(stroop, latency = ifelse(latency < 0 & response == "Incorrect", NA, latency))
		stroop <- mutate(stroop, estimulo = as.character(estimulo), response = as.character(response))
		return(stroop)
	}
}
# data <- read.file(file); data
# data <- tidy.data(data); data


# --- Funcion para estadisticas  ---------------------------------------------------
# Ahora procesar lo que salió de las otras dos funciones 'file > tidy > stats'
stats <- function(data=NULL) {
	# Puede que data venga en blanco porque omiti? todo, si asi fuera, el sistema paro antes, 
	# pero si no se salta aca.
	if (class(data) == "NULL"){
		return(NULL)
	
	# El bloque cero tiene un estimulo = 3, imagino es el de prueba, no lo archivo asi que
	# si aparece se sale de esta cosa. Preguntar que hacer a Sussanne.
	} else if (data$estimulo[1] == 3) { 
		return(NULL) 
	
	# Continuar
	} else {
	
		# Capturar conteos y porcentajes, hacer factores primero
        data <- mutate(data, response = ifelse(response == "Correct", 1, ifelse(response == "Incorrect", 2, 3)))
        data <- mutate(data, response = factor(response, levels = c(1,2,3), labels = c("Correct", "Incorrect", "Omitted")))
		table <- table(data$response, data$estimulo)
		
		freq <- data.frame(table)
		freq <- mutate(freq, cname = paste0("n.", str_to_lower(str_sub(Var1, 1, 4)), Var2), id = 1)
		freq <- select(freq, id, cname, Freq)
		freq <- spread(freq, cname, Freq) %>% select(-id)
		freq <- mutate(freq, n.etotal1 = n.inco1 + n.omit1, n.etotal2 = n.inco2 + n.omit2)
        freq <- select(freq, n.corr1, n.inco1, n.omit1, n.etotal1, n.corr2, n.inco2, n.omit2, n.etotal2)
        
		prop <- prop.table(table, margin = 2)
		prop <- data.frame(prop*100)
		prop <- mutate(prop, pname = paste0("p.", str_to_lower(str_sub(Var1, 1, 4)), Var2), id = 1)
		prop <- select(prop, id, pname, Freq)
		prop <- spread(prop, pname, Freq) %>% select(-id)
		prop <- mutate(prop, p.etotal1 = p.inco1 + p.omit1, p.etotal2 = p.inco2 + p.omit2)
		prop <- select(prop, p.corr1, p.inco1, p.omit1, p.etotal1, p.corr2, p.inco2, p.omit2, p.etotal2)
		prop <- as.data.frame(apply(prop, c(1,2), function(x) round(x, 1)))
        
		table <- cbind(freq, prop)
		
        # Hago un df de transición para asignar bien los factores, igual esta malo hacer esto.	
        temp <- data.frame(est = c(1,1,1,2,2,2), resp = c(rep(c("Correct", "Incorrect", "Omitted"), 2)))
        temp <- mutate(temp, merge = paste(est, resp)) %>% select(merge)
        
		stats <- group_by(data, estimulo, response)
		stats <- summarize(stats, m = mean(latency, na.rm=TRUE), sd = sd(latency, na.rm=TRUE))
		stats <- mutate(stats, merge = paste(estimulo, response))
		stats <- merge(temp, stats, by="merge", all = TRUE)
		stats <- mutate(stats, response = str_to_lower(str_sub(response, 1, 4)))
		stats <- filter(stats, merge != "1 Omitted", merge != "2 Omitted")
		stats <- arrange(stats, merge)
        
		# Me da lata hacerlo como corresponde con un reshape, dejo el sistem antiguo
		mean <- data.frame(t(stats$m))
		names(mean) <- c("m.corr1", "m.inco1", "m.corr2", "m.inco2")
		sd <- data.frame(t(stats$sd))
		names(sd) <- c("s.corr1", "s.inco1", "s.corr2", "s.inco2")
		stats <- cbind(mean, sd)
		
		# Comprueba el NA, no sé porqué
		for (j in 1:ncol(stats)){
		    ifelse(is.na(stats[1, j])==TRUE,
		           stats[1, j] <- NA,
		           stats[1, j] <- round(stats[1, j], 1))
		}
		# Ya se porqué, a veces queda NaN y en Excel tira error.
		# -Conclusión- No dudar de mi código si se ve rarito, por algo será   :)
		
		# Resultado
		resultado <- data.frame(id.block = data[1, "id.block"], file = data[1, "file"], stringsAsFactors = FALSE)
		resultado <- cbind(resultado, table, stats)
		return(resultado)
	}
}
# Test 
# data <- read.file(archivos[2]); data
# data <- tidy.data(data); data
# data <- stats(data); data

	
	
# ---------------------------------------------------------------------------------- #
# --- 2. Captura ------------------------------------------------------------------- #
# ---------------------------------------------------------------------------------- #
options(warn = 2)
# Data final    file <- archivos[4]
data.orig.press <- NULL
data.orig.trial <- NULL
data.tidy <- NULL
data.stats <- NULL
colados <- NULL

for (file in archivos){
    # Original
    print(paste("leyendo", file))
    data <- read.file(file)
    
    # Por si hay colados
    if (data$press[1,5] == "Go"){
        colados <- bind_rows(colados, data.frame(colados = file, stringsAsFactors = FALSE))
        
    } else {
    
        # Original press
        print(paste("en original", file))
        orig.press <- data$press
        orig.press <- mutate(orig.press, file = data$name[["file"]], id.block = data$name[["id.block"]])
        data.orig.press <- bind_rows(data.orig.press, orig.press)
        
        # Original Trials
        print(paste("en trial", file))
        orig.trial <- data$trials
        orig.trial <- mutate(orig.trial, file = data$name[["file"]], id.block = data$name[["id.block"]])
        data.orig.trial <- bind_rows(data.orig.trial, orig.trial)
        
        # Tidy
        print("en tidy")
        tidy <- tidy.data(data)
        data.tidy <- bind_rows(data.tidy, tidy)
        
        # Procesado
        print(paste("en stats", file))
        stats.data <- as.data.frame(stats(tidy))
        if (ncol(stats.data) > 26){stop(file)}
        data.stats <- bind_rows(data.stats, stats.data)
    
    	# Limpieza
    	rm(data, orig.press, orig.trial, tidy, stats.data)
    }
}
# stop()


# ---------------------------------------------------------------------------------- #
# --- 3. Armar el Excel ------------------------------------------------------------ #
# ---------------------------------------------------------------------------------- #
setwd(maindir)
excel <- createWorkbook()

addWorksheet(excel, "stats")
writeData(excel, "stats", data.stats)

addWorksheet(excel, "tidy")
writeData(excel, "tidy",  data.tidy)

addWorksheet(excel, "trial")
writeData(excel, "trial", data.orig.trial)

addWorksheet(excel, "press")
writeData(excel, "press", data.orig.press)

addWorksheet(excel, "Colados")
writeData(excel, "Colados", colados)

saveWorkbook(excel, "stats_stroop.alimento_NIH21y.xlsx", overwrite = TRUE)


