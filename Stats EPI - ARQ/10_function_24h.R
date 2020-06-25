# ----------------------------------------------------------------------------------------------- #
# ---- Funcion para captuar data de 24 horas, lo mas relevante y lo juntamos en una sola -------- #
# ---- v1 20.06.2020 - Hay que reciclar las funciones ya creadas -------------------------------- #
# ----------------------------------------------------------------------------------------------- #
# 24 horas se entiende como la presencia de períodos consecutivos.
# test <- function_24h(epi) 

function_24h <- function(epi){
    # Capturar sujetos y crear contenedor en blanco
    check.epidata(epi)
    contador <- 0
    
    # Función pa sacar conteos
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

    # Función para los maximos
    getMax <- function(parData){    
        countData <- getCount(parData)
        
        # ---- Sueno ---- #
        if (countData$nS > 1){
            Sdata <- filter(parData, estado == "S")
            Sdata <- filter(Sdata, dur_min == max(dur_min))
            
            # Por si hay más de 1 maximo
            if (nrow(Sdata) > 1){
                Sdata <- mutate(Sdata, temp = runif(nrow(Sdata))) %>% arrange(temp) %>% select(-temp) %>% slice(1)
            }
            
            # Datos del maximo
            ini <- format(Sdata$fec.hora, format = "%H:%M")
            mid <- Sdata$hora + minutes(floor(Sdata$dur_min/2))
            mid <- round(hour(mid) + minute(mid)/60, 3)
            Sdata <- data.frame(iniSMax = ini, iniSMax2 = Sdata$hora, midSMax = mid, perSmax = Sdata$dia.noc, durSmax = Sdata$dur_min, stringsAsFactors = FALSE)
            
        } else {
            Sdata <- data.frame(iniSMax = NA, iniSMax2 = NA, midSMax = NA, perSmax = NA, durSmax = NA)
        }
        
        # ---- Vigilia ---- #
        if (countData$nW > 1){
            Wdata <- filter(parData, estado == "W")
            Wdata <- filter(Wdata, dur_min == max(dur_min))
            
            # Por si hay más de 1 maximo
            if (nrow(Wdata) > 1){
                Wdata <- mutate(Wdata, temp = runif(nrow(Wdata))) %>% arrange(temp) %>% select(-temp) %>% slice(1)
            }
            
            # Datos del maximo
            ini <- format(Wdata$fec.hora, format = "%H:%M")
            mid <- Wdata$hora + minutes(floor(Wdata$dur_min/2))
            mid <- round(hour(mid) + minute(mid)/60, 3)
            Wdata <- data.frame(iniWMax = ini, iniWMax2 = Wdata$hora, midWMax = mid, perWmax = Wdata$dia.noc, durWmax = Wdata$dur_min, stringsAsFactors = FALSE)
            
        } else {
            Wdata <- data.frame(iniWMax = NA, iniWMax2 = NA, midWMax = NA, perWmax = NA, durWmax = NA)
        }
        
        # Combina y reparte
        return(bind_cols(Sdata, Wdata))
    }
 
       
    # Reconstruir periodo
    epi <- mutate(epi, periodo = paste(dia.noc, seq.dia))
    
    # Primer loopeo sobre sujetos  s <- 10546
    par24data <- NULL
    sinPar <- NULL
    sujetos <- unique(epi$id)
    for (s in sujetos){
        # print(s)
        # Contador
        if (contador < 50){
            cat(".")
            contador <- contador + 1
        } else {
            cat("\n")
            contador <- 0
        }
        
        # Capturar el sujeto
        subjData <- filter(epi, id == s) %>% arrange(fec.hora)
        subjData <- mutate(subjData, periodo = paste(dia.noc, seq.dia))
        subjData <- arrange(subjData, fec.hora)
        
        
        # ---- Hay que buscar combinaciones que sirvan ----------------------------------
        # Todas las combinacioens con lo disponible
        periodos <- unique(subjData$periodo)
        diaseq <- periodos[grep("^[D]", periodos)]
        nocseq <- periodos[grep("^[N]", periodos)]
        
        combiND <- expand.grid(nocseq, diaseq)
        combiND <- arrange(combiND, Var1, Var2)
        combiND <- mutate(combiND, par = paste(Var1, "-", Var2))
        combiND <- combiND$par
        
        combiDN <- expand.grid(diaseq, nocseq)
        combiDN <- arrange(combiDN, Var1, Var2)
        combiDN <- mutate(combiDN, par = paste(Var1, "-", Var2))
        combiDN <- combiDN$par
        
        # Combinaciones posibles entre 1 y 70 periodos (debiera ser suficiente)
        seqper <- 1:70
        seqper <- ifelse(seqper < 10, paste0("0", seqper), seqper)
        diaseq <- paste("Dia", seqper)
        nocseq <- paste("Noche", seqper)
        
        nocdia <- paste(nocseq, "-", diaseq)
        dianoc <- paste(diaseq, "-", c(nocseq[-1], "Noche 71"))
        
        # Ver que hay
        combiND <- combiND[combiND %in% nocdia]
        combiDN <- combiDN[combiDN %in% dianoc]
        rm(seqper, diaseq, nocseq, dianoc, nocdia)
        
        # Crea un iterable
        if (length(combiND) > 0 & length(combiDN) > 0){
            combi <- bind_rows(data.frame(tipo = "Dia a Noche", combi = combiDN, stringsAsFactors = FALSE),
                               data.frame(tipo = "Noche a Dia", combi = combiND, stringsAsFactors = FALSE))
        
        } else if (length(combiND) > 0 & length(combiDN) == 0){
            combi <- data.frame(tipo = "Noche a Dia", combi = combiND, stringsAsFactors = FALSE)
            
        } else if (length(combiND) == 0 & length(combiDN) > 0){
            combi <- data.frame(tipo = "Dia a Noche", combi = combiDN, stringsAsFactors = FALSE)
            
        } else {
            sinPar <- bind_rows(sinPar, data.frame(id = unique(subjData$id), drop = "No tiene pares consecutivos (24h)", stringsAsFactors = FALSE))
            next()
        }
        
        rm(combiND, combiDN)
        combi <- bind_cols(combi, as.data.frame(str_split(combi$combi, " - ", simplify = TRUE), stringsAsFactors = FALSE))
        combi <- rename(combi, filtro1 = V1, filtro2 = V2)
        
        
        # ----- Par 24 horas ------------------------------------------------------------
        par24combi <- NULL
        for (i in 1:nrow(combi)){           # i <- 1
            # print(i)
            # Data del segmento    
            parInfo <- combi[i, ]
            parData <- filter(subjData, periodo == parInfo[["filtro1"]] | periodo == parInfo[["filtro2"]])
            
            # Info 
            parInfo <- mutate(parInfo, id = unique(parData$id))
            parInfo <- select(parInfo, id, tipo, filtro1, filtro2, combi)
            parInfo <- mutate(parInfo, fecini = min(as_date(parData$fec.hora)))
            
            dia1 <- filter(parData, periodo == parInfo[["filtro1"]])
            dia1 <- unique(dia1$dia)
            dia2 <- filter(parData, periodo == parInfo[["filtro2"]])
            dia2 <- unique(dia2$dia)
            parInfo <- mutate(parInfo, dias = paste(dia1, ">", dia2))
            rm(dia1, dia2)
            
            # Conteos
            conteo <- getCount(parData)
            names(conteo) <- paste0(names(conteo), "_24")
            
            # Duraciones
            fulltime <- data.frame(Stime = sum(parData$dur_min[which(parData$estado == "S")]),
                                   Wtime = sum(parData$dur_min[which(parData$estado == "W")]))
            fulltime <- mutate(fulltime, Stime = as.numeric(Stime), Wtime = as.numeric(Wtime)) 
            fulltime <- mutate(fulltime, Ttime = Stime + Wtime, Spct = round(Stime/Ttime, 3)*100, Wpct = round(Wtime/Ttime, 3)*100)
            names(fulltime) <- c("Sdur", "Wdur", "Tdur", "Spct", "Wpct")
            names(fulltime) <- paste0(names(fulltime), "_24")
            
            # Maximos
            maximo <- getMax(parData)
            names(maximo) <- paste0(names(maximo), "_24")
            
            # Compilar
            temp <- bind_cols(parInfo, conteo, fulltime, maximo)
            par24combi <- bind_rows(par24combi, temp)
        }
        
        # Compilar sujeto
        par24data <- bind_rows(par24data, par24combi)
    }
    
    # Listo :)
    # head(par24data)
    # paste(names(par24data), collapse = " ")
    return(list(conpar = par24data, sinpar = sinPar))
}
    
    
    