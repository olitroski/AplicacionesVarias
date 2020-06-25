# ----------------------------------------------------------------------------------------------- #
# ---- Funcion para capturar Duracion de Siestas y Despertares para cada semi periodo ----------- #
# ---- en epi.data ------ v1.0 01.04.2019 ------------------------------------------------------- #
# ----------------------------------------------------------------------------------------------- #
# Usa un epi data. Hace el calculo para un semi periodo y calcula el tiempo de vigilia o sueno 
# segun corresponda y asigna a todo, mitad y tercio.  Para ello usa la data expandida y lo hace
# de por sujeto. 
# Futuro desarrollador... si sé que la función es lenta, pero si uso la librería data.table caga todo
# porque se superpone a dplyr y funciones del base y adaptar me dio lata enorme.

function_duration <- function(epi){
    # Checar la data y expand function
    options(warn = 2)    
    check.epidata(epi)
    contador <- 0
    
    # ---- Funcion Conteos globales ----------------------------------------------------- #
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
    
    
    # ---- Data de Test ---- #
    # s <- 10648; p <- "Noche 02"
    # ---------------------- #

    ## Loopeo sobre sujetos
    sujetos <- unique(epi$id)
    BASE.total <- NULL
    for (s in sujetos){
        # print(s)
        if (contador < 50){
            cat(".")
            contador <- contador + 1
        } else {
            cat("\n")
            contador <- 0
        }
        
        # Filtrar sujeto
        subj.data <- filter(epi, id == s) %>% arrange(fec.hora)
        subj.data <- mutate(subj.data, periodo = paste(dia.noc, seq.dia))
        
        # Loopeo sobre los periodos de un sujeto
        BASE.subj <- NULL
        periodos <- unique(subj.data$periodo)
        for (p in periodos){
            # Filtrar periodo.
            periodData <- filter(subj.data, periodo == p)
            semip.name <- unique(periodData$dia.noc)
            
            # ----- Inicio captura de datos -------------------------------------------------------
            ## Variables de info
            info <- select(periodData, id, semi = dia.noc, periodo = periodo, wday = dia)
            info <- slice(info, 1)
            
            ## Duracones generales
            fulltime <- data.frame(Stime = sum(periodData$dur_min[which(periodData$estado == "S")]),
                                   Wtime = sum(periodData$dur_min[which(periodData$estado == "W")]))
            fulltime <- mutate(fulltime, Stime = as.numeric(Stime), Wtime = as.numeric(Wtime)) 
            fulltime <- mutate(fulltime, Ttime = Stime + Wtime, 
                               Spct = round(Stime/Ttime, 3)*100, 
                               Wpct = round(Wtime/Ttime, 3)*100)
            
            # Conteos para calcular los promedios
            conteos <- getCount(periodData)
            conteos <- select(conteos, nS, nW, nTot)
            
            # Ahora si promedios
            fulltime <- bind_cols(conteos, fulltime)
            fulltime <- mutate(fulltime, 
                               Smean = round(ifelse(nS > 0, Stime/nS, NA), 1), 
                               Wmean = round(ifelse(nW > 0, Wtime/nW, NA), 1),
                               Tmean = round(ifelse(Ttime > 0, Ttime/nTot, NA), 1))

            # ----- Expansion de datos ---------------------
            periodData <- select(periodData, -periodo)
            periodData <- function_expand.epidata(periodData)
            # -----------------------------------------------
            
            ## Tercios
            TerData <- data.frame(summarize(group_by(periodData, estado, ter), time = n()))
            TerData <- mutate(TerData, TStage = paste("T", ter, estado, sep = ""))
            
            # Corregir si faltan
            categorias <- c("T1S", "T2S", "T3S", "T1W", "T2W", "T3W")
            categorias <- categorias[!(categorias %in% TerData$TStage)]
            if (length(categorias) > 0){
                temp <- data.frame(TStage = categorias)
                temp <- mutate(temp, time = NA, ter = substr(TStage, 2, 2), estado = substr(TStage, 3, 3))
                temp <- ordervar(temp, c("estado", "ter", "time"))
                TerData <- rbind(TerData, temp)
            }
            
            # DM y dejar lista
            TerData <- arrange(TerData, ter, estado)
            TerData <- select(TerData, TStage, time)
            
            TerData <- as.data.frame(t(TerData), stringsAsFactors = FALSE)
            names(TerData) <- TerData[1, ]
            TerData <- slice(TerData, -1)
            row.names(TerData) <- NULL
            
            for (j in 1:6){TerData[[j]] <- as.numeric(TerData[[j]])}
            TerData <- mutate(TerData, 
                              T1tot = sum(T1S,T1W,na.rm=TRUE), T1Sp = round(T1S/T1tot, 3)*100, T1Wp = round(T1W/T1tot, 3)*100,
                              T2tot = sum(T2S,T2W,na.rm=TRUE), T2Sp = round(T2S/T2tot, 3)*100, T2Wp = round(T2W/T2tot, 3)*100,
                              T3tot = sum(T3S,T3W,na.rm=TRUE), T3Sp = round(T3S/T3tot, 3)*100, T3Wp = round(T3W/T3tot, 3)*100)
            
            ## Datos Mitades
            MidData <- data.frame(summarize(group_by(periodData, estado, mit), time = n()))
            MidData <- mutate(MidData, MStage = paste("M", mit, estado, sep = ""))
            
            # Corregir si faltan
            # Deberia siempre tener todos los datos, dejo por si pasara no m?s
            categorias <- c("M1S", "M1W", "M2S", "M2W")
            categorias <- categorias[!(categorias %in% MidData$MStage)]
            if (length(categorias) > 0){
                temp <- data.frame(MStage = categorias)
                temp <- mutate(temp, time = NA, mit = substr(MStage, 2, 2), estado = substr(MStage, 3, 3))
                temp <- ordervar(temp, c("estado", "mit", "time"))
                MidData <- rbind(MidData, temp)
            }
            
            # DM y dejar lista
            MidData <- arrange(MidData, mit, estado)
            MidData <- select(MidData, MStage, time)
            
            MidData <- as.data.frame(t(MidData), stringsAsFactors = FALSE)
            names(MidData) <- MidData[1, ]
            MidData <- slice(MidData, -1)
            row.names(MidData) <- NULL
            
            for (j in 1:4){MidData[[j]] <- as.numeric(MidData[[j]])}
            MidData <- mutate(MidData, M1tot = sum(M1S,M1W,na.rm=TRUE), M1Sp = round(M1S/M1tot, 3)*100, M1Wp = round(M1W/M1tot, 3)*100,
                                       M2tot = sum(M2S,M2W,na.rm=TRUE), M2Sp = round(M2S/M2tot, 3)*100, M2Wp = round(M2W/M2tot, 3)*100)
            
            ## Juntar la data
            BASE.subj <- bind_rows(BASE.subj, cbind(info, fulltime, TerData, MidData))
        }
        # Juntar datos sujeto con base general
        BASE.total <- bind_rows(BASE.total, BASE.subj)
    }
    
    # Retorno
    # head(BASE.total)
    BASE.total <- mutate(BASE.total, key = paste0(id, "_", periodo), key = str_replace(key, " ", "_"))
    BASE.total <- rename(BASE.total, dia.noc = semi)
    return(BASE.total)
    # paste(names(BASE.total), collapse = " ")
}
# write.xlsx(test, "test.xlsx")
