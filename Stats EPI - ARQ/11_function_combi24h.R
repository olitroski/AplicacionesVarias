# ----------------------------------------------------------------------------------------------- #
# ---- Funcion para captuar COMBIS de 24 horas, para analisis de causa efecto ------------------- #
# ---- v1 22.06.2020 - Hay que reciclar las funciones ya creadas -------------------------------- #
# ----------------------------------------------------------------------------------------------- #
# 24 horas se entiende como la presencia de períodos consecutivos.
# test <- function_24h(epi) 

function_combi24h <- function(epi){
    # Capturar sujetos y crear contenedor en blanco
    check.epidata(epi)
    contador <- 0

    # Reconstruir periodo
    epi <- mutate(epi, periodo = paste(dia.noc, seq.dia))
    
    # Primer loopeo sobre sujetos  s <- 10546
    combiData <- NULL
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
            combi <- bind_rows(data.frame(id = s, tipo = "Dia a Noche", combi = combiDN, stringsAsFactors = FALSE),
                               data.frame(id = s, tipo = "Noche a Dia", combi = combiND, stringsAsFactors = FALSE))
            
        } else if (length(combiND) > 0 & length(combiDN) == 0){
            combi <- data.frame(id = s, tipo = "Noche a Dia", combi = combiND, stringsAsFactors = FALSE)
            
        } else if (length(combiND) == 0 & length(combiDN) > 0){
            combi <- data.frame(id = s, tipo = "Dia a Noche", combi = combiDN, stringsAsFactors = FALSE)
            
        } else {
            # Ya guardamos lo que no tiene combis
            # sinPar <- bind_rows(sinPar, data.frame(id = unique(subjData$id), drop = "No tiene pares consecutivos (24h)"))
            next()
        }
        
        rm(combiND, combiDN)
        combi <- bind_cols(combi, as.data.frame(str_split(combi$combi, " - ", simplify = TRUE), stringsAsFactors = FALSE))
        combi <- rename(combi, filtro1 = V1, filtro2 = V2)
        
        combiData <- bind_rows(combiData, combi)
    }
        
    # Compilar las combis
    # head(combiData)
    return(combiData)
}
        