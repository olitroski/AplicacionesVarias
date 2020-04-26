# ---------------------------------------------------------------------------------- #
# --- Script para leer stroop comida  ---------------------------------------------- #
# --- Soledad R. - Creado por Oliver Rojas 29.04.2016 ------------------------------ #
# --- Revision 1: 09.05.2016 se añade progreso y check de nombre y file ------------ #
# --- Revision 2: 11.05.2017 revision y actualizacion ------------------------------ #
# --- Revision 3: 18.05.2018 Se hace de nuevo, con nuevas directrices -------------- #
# ---------------------------------------------------------------------------------- #
# Setear el working directory y cargar los paquetes
# wd = choose.dir(); setwd(wd)
rm(list=ls())
library(dplyr); library(openxlsx); library(data.table)
source("https://raw.githubusercontent.com/olitroski/sources/master/exploratory/sources.r")
rm(pwcorr, ttest.indep, ttest.pair)
setwd("D:/Varios INTA/Bases de datos 21y/NIH21y/Stroop Alimento CSV")

# Captura archivos
archivos <- dir()



# ---------------------------------------------------------------------------------- #
# --- 1. Funciones ----------------------------------------------------------------- #
# ---------------------------------------------------------------------------------- #
## Lectura de archivo ----------------------------------------------------------------
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
# data <- read.file(archivos[939])



## Tidy up the readed file -----------------------------------------------------------
tidy.data <- function(data = NULL){
	# Primero tratar los repetidos la regla es: borrar el primero, etiquetarlo como
	# "Incorrect" y conservar la latencia de la segunda repeticion.
	# data <- read.file(archivos[2])
	press <- data$press
	
	# Si es que press esta nulo, salir (porque es uno de prueba o algo pasó)
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
		return(stroop)
	}
}
# data <- read.file(archivos[5]); data
# data <- tidy.data(data); data
# stop("hooli")
	

	
## 3.- Crear una funcion para estadisticas  ------------------------------------------
stats <- function(data=NULL) {
	# Puede que data venga en blanco porque omitió todo, si asi fuera, el sistema paro antes, 
	# pero si no se salta aca.
	if (class(data) == "NULL"){
		return(NULL)
	
	# El bloque cero tiene un estimulo = 3, imagino es el de prueba, no lo archivo asi que
	# si aparece se sale de esta cosa. Preguntar que hacer a Sussanne.
	} else if (data$estimulo[1] == 3) { 
		return(NULL) 
	
	# Continuar
	} else {
	
		# Capturar procentajes
		table <- table(data$response, data$estimulo)
		
		freq <- data.frame(table)
		freq <- data.frame(t(freq$Freq))
		names(freq) <- c("n.corr1", "n.inco1", "n.omit1", "n.corr2", "n.inco2", "n.omit2")
		freq <- mutate(freq, n.etotal1 = n.inco1 + n.omit1, n.etotal2 = n.inco2 + n.omit2)
		freq <- ordervar(freq, "n.etotal1", after = "n.omit1")
				
		prop <- prop.table(table, margin = 2)
		prop <- data.frame(prop*100)
		prop <- data.frame(t(prop$Freq))
		names(prop) <- c("p.corr1", "p.inco1", "p.omit1", "p.corr2", "p.inco2", "p.omit2")
          prop <- mutate(prop, p.etotal1 = p.inco1 + p.omit1, p.etotal2 = p.inco2 + p.omit2)
          prop <- ordervar(prop, "p.etotal1", after = "p.omit1")
                    
		table <- cbind(freq, prop)
		
		# Stats a la latencia
		stats <- group_by(data, estimulo, response)
		stats <- summarize(stats, mean = mean(latency, na.rm=TRUE), sd = sd(latency, na.rm=TRUE))
		stats <- mutate(stats, merge = paste(estimulo, response))
		
		temp <- data.frame(est = c(1,1,1,2,2,2), resp = c(rep(c("Correct", "Incorrect", "Omitted"), 2)))
		temp <- mutate(temp, merge = paste(est, resp)) %>% select(merge)
		
		stats <- merge(temp, stats, by="merge", all = TRUE)
		stats <- slice(stats, -c(3,6))
		
		mean <- data.frame(t(stats$mean))
		names(mean) <- c("m.corr1", "m.inco1", "m.corr2", "m.inco2")
		sd <- data.frame(t(stats$sd))
		names(sd) <- c("s.corr1", "s.inco1", "s.corr2", "s.inco2")
		
		stats <- cbind(mean, sd)
		for (j in 1:dim(stats)[2]){ifelse(is.na(stats[1,j])==TRUE, stats[1,j] <- NA, stats[1,j])}
			
		# Resultado
		resultado <- cbind(table, stats)
		resultado <- mutate(resultado, id.block = data[1,1], file = data[1,6])
		resultado <- ordervar(resultado, "id.block")
		return(resultado)
	}
}
# data <- read.file(archivos[980]); data
# data <- tidy.data(data); data
# data <- stats(data); data
stop("holiiiii")	
	
	
	
# ---------------------------------------------------------------------------------- #
# --- 2. Captura ------------------------------------------------------------------- #
# ---------------------------------------------------------------------------------- #
# Directorios
# setwd("D:/Varios INTA/Bases de datos 21y/NIH21y/Stroop Alimento CSV")
# setwd("D:/Varios INTA/Bases de datos 21y/CV21y/Stroop Alimento/Stroop Alimento 1 CSV")
# setwd("D:/Varios INTA/Bases de datos 21y/CV21y/Stroop Alimento/Stroop Alimento 2 CSV")


# Files
archivos <- dir()
archivos <- archivos[grep("ERP", archivos)]
archivos <- archivos[grep("csv|CSV", archivos)]
archivos <- archivos[grep("_", archivos)]


# Data final    file <- archivos[5]
data.raw <- NULL
data.tidy <- NULL
data.stat <- NULL

for (file in archivos){
     # Raw data
	data.list <- read.file(file)
	raw <- data.list$press
	raw <- mutate(raw, id.block = data.list$name[1,2], file = data.list$name[1,1])
	data.raw <- rbind(data.raw, raw)

	# Tidy data
	tidy <- tidy.data(data.list)
	data.tidy	<- rbind(data.tidy, tidy)
	
	# Stats data
	stat <- stats(tidy)
	data.stat <- rbind(data.stat, stat)
	
	# Limpieza
	rm(raw, tidy, stat, data.list)
}


#  Exportado
write.xlsx(data.raw,  "data.raw.xlsx")
write.xlsx(data.tidy, "data.tidy.xlsx")
write.xlsx(data.stat, "data.stat.xlsx")
