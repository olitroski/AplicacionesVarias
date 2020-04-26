#####################################################################################
#### Script para leer stroop comida                                  ################
#### Soledad R. - Creado por Oliver Rojas 29.04.2016                 ################
#### Revision 1: 09.05.2016 se a?ade progreso y check de nombre y file ##############
#####################################################################################
# Setear el working directory y cargar los paquetes
wd = choose.dir()
setwd(wd)
library(dplyr); library(xlsx)


## Algunos catches 
# Captura archivos
files <- dir()


# Antecedente de nombres mal puestos
filtro <- !(grepl("^[0-9]+_[0-9]cv a.[Cc][Ss][Vv]", files))
badname <- files[filtro]


# Antecedentes Archivos corruptos
# file <- files[1]
firstline <- NULL

for (file in files) {
    first <- read.table(file, header=FALSE, nrows=1, stringsAsFactors=FALSE)
    first <- select(first, 1)
    first$file <- file
    names(first) <- c("texto_linea_1", "file")
    firstline <- rbind(firstline, first)
}

filtro2 <- !(grepl("^[0-9]+_[0-9]cv.erp Properties$", firstline$texto_linea_1))
malos <- firstline[filtro2,]
malos <- as.character(malos$file)


# Index para el informe de progreso
xfiles <- data.frame(files, stringsAsFactors=FALSE)
nfiles <- dim(xfiles)[1]
xfiles$n <- 1:nfiles



# Condicionalidades para que esta cosa ande ---------------
# PRIMERO: nombres de archivo
if (length(badname) > 0) {
    badname <- paste("<", badname, "> ", sep="")
    cat("Esto archivos tienen mal puesto el nombre\n")
    cat(badname)
    
    
    # SEGUNDO: posibles archivos corruptos
} else if (length(malos) > 0) {
    malos <- paste("<", malos, "> ", sep="")
    cat("Esto archivos pueden estar corruptos\n")
    cat(malos)
    
    
    # TERCERO: Si todo lo anterior esta ok haga la funcion
} else {
    
    
    ## 1.- Lectura de datos --------------------------------------------
    # Data frames en blanco para combinar resultado de cada archivo, se usa al final
    BaseStats <- NULL
    
    # loop ------------------------------------
    for (file in files) {
        
        # Mensaje de progreso
        pct <- subset(xfiles, files==file) 
        pct <- pct[1,2]
        pct <- round(pct/nfiles*100,2)
        cat("Cargando archivo: <", file, "> \t Progreso: ", pct, "%\n", sep="")
        
        
        # Leer datos
        lines <- readLines(file)
        ini <- grep("All presses", lines)
        fin <- grep("Correct presses", lines)
        datos <- read.table(file, header=TRUE, sep=",", skip=ini, nrows=fin-3-ini, stringsAsFactors=FALSE)
        datos
        
        
        # Leer nombra para el id y trial
        name <- file
        name <- strsplit(name, "cv")
        name <- name[[1]][1]
        name <- strsplit(name, "_")
        id <- name[[1]][1]
        trial <- name[[1]][2]
        # id; trial
        
        
        # Indizar Trials repetidos a una variable nueva
        n <- dim(datos)[1] - 1
        datos$Repeated <- 0
        for (i in 1:n) {
            if (datos$Trial[i] == datos$Trial[i + 1]) {
                # Si encuentra el negativo pone -1, sino 1
                if (datos$Pressed[i] < 0) {
                    datos$Repeated[i]   <- 1
                    datos$Repeated[i+1] <- 2
                    
                # Si el primer repetido es > 0
                } else if (datos$Pressed[i] > 0) {
                    datos$Repeated[i]   <- 3
                    datos$Repeated[i+1] <- 4
                }	
            }
        }
        
        
        ## 2.- Archivar el tipo de respuesta -------------------------------------------
        # 0 = Correcta
        # 1 = Omitidas (arregladas al principio)
        # 2 = Incorrecta por comision
        # 3 = Correctiva
        
        # 1) Incorporar las omitidas ----------------------------------
        miss <- !(1:20 %in% datos$Trial) 
        miss <- c(1:20)[miss]
        
        if (length(miss)!=0) {
            miss <- data.frame(miss, NA, NA, NA, NA, "Omitted", 0, 1)
            # Incorporo la respuesta en datos
            datos$Code <- NA
            names(miss) <- names(datos)
            datos <- rbind(datos, miss)
            datos <- arrange(datos, Trial)
        }
        
        # Para el resto de respuestas
        n <- dim(datos)[1]
        for (i in 1:n) {
            
            # 2) Lidiar con los Repetido (-) -> (+) --------------------------------
            # Repeated=1 & Response=Incorrect
            if (datos$Repeated[i] == 1 & datos$Response[i] == "Incorrect") {
                datos$Code[i] <- 2
                datos$Pressed[i] <- NA
                
            # Repeated=2 & Response=Correct
            } else if (datos$Repeated[i] == 2 & datos$Response[i] == "Correct") {
                datos$Code[i] <- 3
                
            # Repeated=2 & Response=Incorrect
            } else if (datos$Repeated[i] == 2 & datos$Response[i] == "Incorrect") {
                datos$Code[i] <- 777			#Se equivoc? 2 veces ?qu? hago con la latencia?
                
                
            # 2) Repetido (+) -> (+) -----------------------------------------------
            # Repeated=3 & Correct & Latencia>100  
            } else if (datos$Repeated[i] == 3 & datos$Response[i] == "Correct" & datos$Pressed[i] > 100) {
                datos$Code[i] <- 0
                # La siguiente se salta
                datos$Code[i+1] <- 666    
                i <- i + 1                
                
            # Repeated=3 & Response=Incorrect
            } else if (datos$Repeated[i]==3 & datos$Response[i]=="Incorrect") {
                datos$Code[i] <- 2
                
            # Repeated=4 & Response=Correct
            } else if (datos$Repeated[i]==4 & datos$Response[i]=="Correct") {
                datos$Code[i] <- 3
                
            # Repeated=4 & Response=Incorrect
            } else if (datos$Repeated[i]==4 & datos$Response[i]=="Incorrect") {
                datos$Code[i] <- 888
                
            # 3) Respuestas puras y solitarias de la vida --------------------------
            # Response = correctas
            } else if (datos$Response[i]=="Correct") {
                datos$Code[i] <- 0
                
            # Response = Incorrect
            } else if (datos$Response[i]=="Incorrect") {	
                datos$Code[i] <- 2
                
            # Response = Omitidas
            } else if (datos$Response[i]=="Omitted") {	
                datos$Code[i] <- 1
                
            # 4) Codigo de error por otra alternativa no cubierta ------------------
            } else {datos$Code[i] <- 999}
        }
        
        
        ## Data management de los datos
        # Poner factores al Code
        nivel <- c(0, 1, 2, 3, 666, 777, 888, 999)
        etiqueta <- c("Correcta", "Inc.Omision", "Inc.Comision", "Inc.Correctiva", 
                      "(-+)2da.Incorr", "(++)1raOk2daBorra", "(++)1raInc2Inc", "ERROR_FATAL_DESESPERARSE")
        datos$CodeLabel <- factor(datos$Code, levels=nivel, labels=etiqueta)
        
        
        # Guardar el original
        original <- datos
        
        
        # 666<-Evento#6, 888<-Evento#9, 777<-Evento#4
        # Original filtrado === DATOS
        datos <- filter(datos, !(Code %in% c(666,777,888)))
        datos <- select(datos, Trial, Latency=Pressed, Code, CodeLabel)
        
        
        
        ## 3.- Crear una funcion para estadisticas  --------------------------------------------
        calculos <- function(data) {
            # Test y funcion para desviacion poblacional
            # data <- datos    # <<< prueba
            ds <- function(vec) {sqrt(sum((vec-mean(vec, na.rm=TRUE))^2, na.rm=TRUE)/length(vec))}
            
            
            # Stat basicas -PCT
            group <- group_by(data, Code)
            stats <- summarize(group, Media=mean(Latency, na.rm=TRUE), Count=n(), Sd=ds(Latency))
            stats <- as.data.frame(stats)
            stats <- mutate(stats, Sd=ifelse(Sd==0, NA, Sd))
            
            
            # Arreglar stats para que siempre tenga cuatro categorias
            miss2 <- !(0:3 %in% stats$Code) 
            miss2 <- c(0:3)[miss2]
            if (length(miss2)!=0) {
                miss2 <- data.frame(miss2, NA, NA, NA)
                names(miss2) <- names(stats)
                stats <- rbind(stats, miss2)
                stats <- arrange(stats, Code)
            }
            
            
            # Calcular porcentajes
            pctCorr <- (stats$Count[1]/20)*100
            pctInc  <- ((stats$Count[2]+stats$Count[3])/20)*100
            pctCtva <- (stats$Count[4]/stats$Count[2])*100
            
            
            # Reestructuracion de las stats
            code <- c("cta", "incO", "incC", "ctva")
            
            # Media
            names <- paste("lat_", code, sep="")
            mu <- stats$Media
            mu <- t(mu)
            mu <- data.frame(mu)
            names(mu) <- names
            
            # Conteo
            names <- paste("n_", code, sep="")
            n <- stats$Count
            n <- t(n)
            n <- data.frame(n)
            names(n) <- names     
            
            # Desviacion
            names <- paste("sd_", code, sep="")
            Sd <- stats$Sd
            Sd <- t(Sd)
            Sd <- data.frame(Sd)
            names(Sd) <- names      
            
            # Conteo
            pct <- c(pctCorr, pctInc, pctCtva)
            names <- c("pctCorr", "pctInc", "pctCtva")
            pct <- data.frame(t(pct))
            names(pct) <- names  
            
            
            # Crear el data frame final
            idtrial <- data.frame(id=as.numeric(id), trial=as.numeric(trial))
            base <- cbind(idtrial, mu, Sd, n, pct)
            return(base)
        }
        
        
        ## 4.- Parse Calculos function and save all the stuff------------------------------
        # Original
        nameOrig <- paste("original", id, trial, "CV.txt",sep="_")
        write.table(original, file=nameOrig, quote=FALSE, sep=",", row.names=FALSE)
        
        # El arreglado con el que se hacen las stats
        nameDatos <- paste("datos", id, trial, "CV.txt", sep="_")
        write.table(datos, file=nameDatos, quote=FALSE, sep=",", row.names=FALSE)
        
        # Apilar las stats
        calc <- calculos(datos)
        BaseStats <- rbind(BaseStats, calc)
        
    }  # <<<<<<<<<<<<<< FINAL DE LOS CALCULOS POR ARCHIVO >>>>>>>>>>>>>>>>>>
    
    
    # Terminar la base de stats
    BaseStats <- mutate(BaseStats, Tercio=ifelse(trial<=2, 1, ifelse(trial>=6,3,2)))
    write.xlsx(BaseStats, "BaseStats.xlsx", sheetName="Stroop", row.names=FALSE, showNA=FALSE)
    
    
    # Recopilar archivos para borrar y dejar en un zip
    # txt <- dir()
    # orig <- grepl("original", txt)
    # orig <- txt[orig]
    # dat <- grepl("datos", txt)
    # dat <- txt[dat]
    # 
    # zip("originales.zip", files)
    # zip("originales_v2.zip", orig)
    # zip("datos_tabulados.zip", dat)
    # 
    # # Borrar tales archivos
    # file.remove(orig)
    # file.remove(dat)
    # file.remove(files)
    
    
} # Fin de la tercera if de chequeo, o sea funcion ejecutada