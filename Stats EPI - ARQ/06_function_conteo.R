# ----------------------------------------------------------------------------------------------- #
# ---- Funcion para capturar N de Siestas y Despertares para cada semi periodo en epi.data ------ #
# ---- v1.0 14.03.2019 -------------------------------------------------------------------------- #
# ----------------------------------------------------------------------------------------------- #
# Usa un epi data. Hace el calculo para un semi periodo y asigna siesta en dia y despertar en noche, 
# tambien si es posible hace asignaci?n a mitad o tercio, no usa la data expandida, en su lugar 
# expande luego de filtrar el suejto.

function_conteo <- function(epi){
    # Checar la data y expand function
    options(warn = 2)
    check.epidata(epi)

    # ----  For testing ---------------------------------------------- #
    # s <- 10013; p <- "Noche 02"                                      #
    # subjData <- filter(epi, id == s) %>% arrange(fec.hora)           #
    # subjData <- mutate(subjData, periodo = paste(dia.noc, seq.dia))  #
    # periodData <- filter(subjData, periodo == p)                     #
    # ---------------------------------------------------------------- # 
    
    # ---- Funcion Capturar info -------------------------------------------------------- #
    # Si ya se que no es necesaria, es lenta, pero ya estaba hecha, no la voy a borrar
    getInfo <- function(periodData){
        id <- unique(periodData$id)
        semi <- unique(periodData$dia.noc)
        periodo <- unique(periodData$periodo)
        wday <- unique(periodData$dia)
        
        info <- data.frame(id, semi, periodo, wday, stringsAsFactors = FALSE)
        return(info)
    }
    
    # ---- Funcion Conteos globales ----------------------------------------------------- #
    # getCount(periodData)
    getCount <- function(periodData){
        nS <- length(which(periodData$estado == "S"))
        nW <- length(which(periodData$estado == "W"))
        nTot <- nS + nW
        pS <- round(nS/nTot, 3)*100
        pW <- round(nW/nTot, 3)*100
        pTot <- pS + pW
        
        ntotal <- data.frame(nS = nS, nW = nW, nTot = nTot, pS = pS, pW = pW)
        return(ntotal)
    }
    
    # ---- Funcion asignar mitad v1&2 por hora ------------------------------------------ #
    # assignMitad(periodData)
    assignMitad <- function(periodData){
        # Calcular mitad
        fecmin <- min(periodData$fec.hora)
        fecmax <- max(periodData$fec.hora) 
        durmax <- periodData[which(periodData$fec.hora == fecmax), "dur_min"]
        fecmax <- fecmax + minutes(durmax)
        mitad <- fecmin + (fecmax - fecmin)/2
        
        mdata <- select(periodData, hora = fec.hora, estado, dur_min)
        mdata <- mutate(mdata, mitad = mitad)
        rm(mitad)
        
        # Asignar version 1 por hora de inicio
        mdata <- mutate(mdata, ver1 = ifelse(hora < mitad, 1, 2), indx = 1:nrow(mdata))
        # En caso que partan todos antes de la mitad
        if (length(unique(mdata$ver1)) == 1){
            if (unique(mdata$ver1) == 1){
                mdata$ver1[nrow(mdata)] <- 2
            }
        }
        
        # Asignar verson 2, pa eso hay que buscar el que cruza (contienen la hora en realidad)
        # La hora de fin no calcula bien con el dur_min, usar un lead mejor
        mdata <- mutate(mdata, horafin = lead(hora))
        mdata$horafin[nrow(mdata)] <- fecmax
        mdata <- mutate(mdata, horafin = horafin - seconds(1))
        
        mdata <- mutate(mdata, iniAntes = ifelse(hora <= mitad, 1, 0))
        mdata <- mutate(mdata, finDesp = ifelse(horafin >= mitad, 1, 0))
        
        # El de la mitad es el que empieza antes y termina despues
        mdata <- mutate(mdata, epimitad = ifelse(iniAntes + finDesp == 2, 1, 0))
        mdata <- select(mdata, -iniAntes, -finDesp)
        
        # Ver a que mitad pertenece
        cruza <- which(mdata$epimitad == 1)
        antes <- mdata$mitad[cruza] - mdata$hora[cruza]
        despu <- mdata$horafin[cruza] - mdata$mitad[cruza]
        
        if (antes > despu){
            mitadreal <- 1
        } else {
            mitadreal <- 2
        }
        
        # Ahora si asignar, mismo que version 1 pero reemplaza el que cruza
        mdata <- mutate(mdata, ver2 = ver1)
        mdata$ver2[cruza] <- mitadreal
        
        # Depurar un poco antes de salir
        mdata <- select(mdata, hora, estado, dur_min, ver1, ver2)
        
        # Si se que esta mal hacerlo aca, pero es lo mas facil
        if (nrow(periodData) == 1){
            mdata <- mutate(mdata, ver1 = NA, ver2 = NA)
        }
        return(mdata)
    }

    # ---- Usar data mitades para stats ------------------------------------------------- #
    # temp <- assignMitad(periodData)
    # getMitad(assignMitad(periodData))
    getMitad <- function(temp){
        
        # Version 1
        m1v1 <- filter(temp, ver1 == 1)
        m1v1 <- getCount(m1v1)
        names(m1v1) <- paste(names(m1v1), "M1v1", sep = "_")
        
        m2v1 <- filter(temp, ver1 == 2)
        m2v1 <- getCount(m2v1)
        names(m2v1) <- paste(names(m2v1), "M2v1", sep = "_")
        
        # Version 2
        m1v2 <- filter(temp, ver2 == 1)
        m1v2 <- getCount(m1v2)
        names(m1v2) <- paste(names(m1v2), "M1v2", sep = "_")
        
        m2v2 <- filter(temp, ver2 == 2)
        m2v2 <- getCount(m2v2)
        names(m2v2) <- paste(names(m2v2), "M2v2", sep = "_")
        
        # Mismo, no es el lugar pero es lo mas facil.
        mitadData <- bind_cols(m1v1, m2v1, m1v2, m2v2)
        
        if (nrow(temp) == 1){
            mitadData[1,] <- NA
        }
        
        return(mitadData)
    }
    
    
    # ---- Procesar todo ---------------------------------------------------------------- #
    contador <- 0
    countData <- NULL
    sujetos <- unique(epi$id)
    for (s in sujetos){
        # print(s)
        if (contador < 50){
            cat(".")
            contador <- contador + 1
        } else {
            cat("\n")
            contador <- 0
        }
        
        # Captura de periodos 
        subjData <- filter(epi, id == s) %>% arrange(fec.hora)
        subjData <- mutate(subjData, periodo = paste(dia.noc, seq.dia))
        
        ## Segundo loopeo sobre los periodos de un sujeto
        periodos <- unique(subjData$periodo)
        countSubj <- NULL
        for (p in periodos){
            # print(p)
            # Filtraje (semip = semi periodo, o sea Dia o Noche)
            periodData <- filter(subjData, periodo == p)
            
            # Recoleccion de datos
            info_data <- getInfo(periodData)
            conteo_gral <- getCount(periodData)
            conteo_mitad <- getMitad(assignMitad(periodData))
            temp_data <- bind_cols(info_data, conteo_gral, conteo_mitad)
            
            # Compilar periodos del sujeto
            countSubj <- bind_rows(countSubj, temp_data)
        }
        
        # Juntar datos globales
        countData <- bind_rows(countData, countSubj)
    }
    
    # Resultado
    # head(countData)
    # paste(names(countData), collapse = " ")
    countData <- mutate(countData, key = paste0(id, "_", periodo), key = str_replace(key, " ", "_"))
    countData <- rename(countData, dia.noc = semi)
    return(countData)
}
