# ----------------------------------------------------------------------------------------------- #
# ---- Funcion para capturar el episodio mas largo en cada semi periodo (Dia o Noche) para ------ #
# ---- sueno y vigilia - v1.0 11.03.2019 -------------------------------------------------------- #
# ----------------------------------------------------------------------------------------------- #
# Usa un epi data. Hace el calculo para un semi periodo, no es necesario expandir y se hace por 
# maximos no mas. Mmmm, hay que usar data expandida para calcular a que parte de la noche pertenece
# se puede mas facil pero hay que picar.

function_duracionMax <- function(epi){
    # Checar la data y expand function
    options(warn = 2)
    check.epidata(epi)
    contador <- 0
        
    # ---- Data de Test ---- #
    # s <- 10207; p <- "Noche 07"
    # ---------------------- #
        
    ## Loopeo sobre los sujetos
    sujetos <- unique(epi$id)
    max.todo <- NULL
    for (s in sujetos){
        # print(s)
        if (contador < 50){
            cat(".")
            contador <- contador + 1
        } else {
            cat("\n")
            contador <- 0
        }
        
        # Captura del sujeto 
        subj.data <- filter(epi, id == s) %>% arrange(fec.hora)
        subj.data <- mutate(subj.data, periodo = paste(dia.noc, seq.dia))
        
        ## Segundo loopeo sobre los periodos de un sujeto
        periodos <- unique(subj.data$periodo)
        max.subj <- NULL
        for (p in periodos){
            # print(p)
            # Filtraje del periodo
            periodData <- filter(subj.data, periodo == p)
            
            # Variables de info
            info <- select(periodData, id, semi = dia.noc, periodo = periodo, wday = dia)
            info <- slice(info, 1)
            
            
            # La captura de los conteos que permiten (o no) hacer el calculo de maximo usa 
            # funciones del calculo de conteos, es lo mas facil.
            
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
            
            # ---- Funcion Maximos ------------------------------------------------------------- #
            getMax <- function(maxData){
                countData <- getCount(maxData)
                
                # Sueno
                if (countData$nS > 1){
                    Sdata <- filter(maxData, estado == "S")
                    Sdata <- filter(Sdata, dur_min == max(dur_min))
                    
                    # Por si hay más de 1 maximo
                    if (nrow(Sdata) > 1){
                        Sdata <- mutate(Sdata, temp = runif(nrow(Sdata))) %>% arrange(temp) %>% select(-temp) %>% slice(1)
                    }
                    
                    mid <- Sdata$hora + minutes(floor(Sdata$dur_min/2))
                    mid <- round(hour(mid) + minute(mid)/60, 3)
                    Sdata <- data.frame(durSmax = Sdata$dur_min, locSmax = Sdata$ver2, midSmax = mid)
                    
                    
                } else {
                    Sdata <- data.frame(durSmax = NA, locSmax = NA, midSmax = NA)
                }
                
                # Vigilia
                if (countData$nW > 1){
                    Wdata <- filter(maxData, estado == "W")
                    Wdata <- filter(Wdata, dur_min == max(dur_min))
                    
                    # Por si hay más de 1 maximo
                    if (nrow(Wdata) > 1){
                        Wdata <- mutate(Wdata, temp = runif(nrow(Wdata))) %>% arrange(temp) %>% select(-temp) %>% slice(1)
                    }
                    
                    mid <- Wdata$hora + minutes(floor(Wdata$dur_min/2))
                    mid <- round(hour(mid) + minute(mid)/60, 3)
                    Wdata <- data.frame(durWmax = Wdata$dur_min, locWmax = Wdata$ver2, midWmax = mid)
                    
                } else {
                    Wdata <- data.frame(durWmax = NA, locWmax = NA, midWmax = NA)
                }
                
                # Combina y reparte
                return(bind_cols(Sdata, Wdata))
            }
            
            
            # La data para los calculos
            maxData <- assignMitad(periodData)
            maxData <- select(maxData, -ver1)
            
            # ---- Global -----
            globalMax <- getMax(maxData)
            
            # ---- Mitad 1 ----
            m1Max <- filter(maxData, ver2 == 1)
            m1Max <- getMax(m1Max)
            m1Max <- select(m1Max, -locSmax, -locWmax)
            names(m1Max) <- paste0(names(m1Max), "_M1")
            
            # ---- Mitad 2 ----
            m2Max <- filter(maxData, ver2 == 2)
            m2Max <- getMax(m2Max)
            m2Max <- select(m2Max, -locSmax, -locWmax)
            names(m2Max) <- paste0(names(m2Max), "_M2")
            
            # ---- Juntar todo ----
            max.data <- bind_cols(info, globalMax, m1Max, m2Max)
            max.subj <- bind_rows(max.subj, max.data)
        }
            
        # Pasar a los datos globales
        max.todo <- bind_rows(max.todo, max.subj)
    }
        
    # Pasar afuera
    # head(max.todo)
    max.todo <- mutate(max.todo, key = paste0(id, "_", periodo), key = str_replace(key, " ", "_"))
    max.todo <- rename(max.todo, dia.noc = semi)
    # paste(names(max.todo), collapse = " ")
    return(max.todo)
}


