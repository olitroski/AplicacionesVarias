# ----------------------------------------------------------------------------------------------- #
# ---- Funcion para capturar la latencia al primer W y al 2do si es que hay, ademas del --------- #
# ---- tiempo 2do sueno si es que hay - v1.0 12.04.2019 ------------------------------------------ #
# ----------------------------------------------------------------------------------------------- #
# Usa un epi data. Hace el calculo para un periodo y calcula latencias como se describe en la 
# documentacion.

function_latencia <- function(epi){
    # Checar la data y expand function
    options(warn = 2)
    check.epidata(epi)
    contador <- 0

    # ----Datos para prueba --------- #
    # s <- 11465; p <- "Noche 02"     #
    # ------------------------------- #
    
    
    ## Loopeo sobre los sujetos
    waso.todo <- NULL
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
        
        # Filtrar sujeto
        subj.data <- filter(epi, id == s) %>% arrange(fec.hora)
        subj.data <- mutate(subj.data, periodo = paste(dia.noc, seq.dia))
        
        ## Segundo loopeo sobre los periodos de un sujeto
        waso.subj <- NULL
        periodos <- unique(subj.data$periodo)
        for (p in periodos){
            # Filtrar periodo
            # print(p)
            periodData <- filter(subj.data, periodo == p)
            periodData <- arrange(periodData, fec.hora)
            
            # ----- Inicio captura de datos -------------------------------------------------------
            ## Variables de info
            N <- nrow(periodData)
            info <- select(periodData, id, semi = dia.noc, periodo = periodo, wday = dia)
            info <- slice(info, 1)
            info <- mutate(info, n_epi = N)
            
            # ----- Capturar la data --------------------------------------------------------------
            if (N == 1){
                latencia <- data.frame(lat_date = NA, 
                                       lat1_hora = NA, lat1_dur = NA,
                                       lat2_hora = NA, lat2_dur = NA,
                                       lat3_hora = NA, lat3_dur = NA,
                                       durEpi2 = NA , durEpi3 = NA)
                
            # 2 epis para la app nueva
            } else if (N == 2){
                hora1 <- periodData$fec.hora[2]
                dura1 <- periodData$dur_min[1]
                
                dur2 <- periodData$dur_min[2]
                
                latencia <- data.frame(lat_date = as_date(periodData$fec.hora[1]),  
                                       lat1_hora = hora1, lat1_dur = dura1,
                                       lat2_hora = NA, lat2_dur = NA,
                                       lat3_hora = NA, lat3_dur = NA,
                                       durEpi2 = dur2 , durEpi3 = NA)
            
            # 3 epis
            } else if (N == 3){
                hora1 <- periodData$fec.hora[2]
                dura1 <- periodData$dur_min[1]
                
                hora2 <- periodData$fec.hora[3]
                dura2 <- periodData$dur_min[1] + periodData$dur_min[2]
                
                dur2 <- periodData$dur_min[2]
                dur3 <- periodData$dur_min[3]
                
                latencia <- data.frame(lat_date = as_date(periodData$fec.hora[1]),  
                                       lat1_hora = hora1, lat1_dur = dura1,
                                       lat2_hora = hora2, lat2_dur = dura2,
                                       lat3_hora = NA, lat3_dur = NA,
                                       durEpi2 = dur2 , durEpi3 = dur3)
                
            # 5 epis
            } else if (N >= 5){
                hora1 <- periodData$fec.hora[2]
                dura1 <- periodData$dur_min[1]
                
                hora2 <- periodData$fec.hora[3]
                dura2 <- periodData$dur_min[1] + periodData$dur_min[2]   
                
                hora3 <- periodData$fec.hora[4]
                dura3 <- periodData$dur_min[1] + periodData$dur_min[2] + periodData$dur_min[3]
                
                dur2 <- periodData$dur_min[2]
                dur3 <- periodData$dur_min[3]
                
                latencia <- data.frame(lat_date = as_date(periodData$fec.hora[1]), 
                                       lat1_hora = hora1, lat1_dur = dura1,
                                       lat2_hora = hora2, lat2_dur = dura2,
                                       lat3_hora = hora3, lat3_dur = dura3,
                                       durEpi2 = dur2 , durEpi3 = dur3)
                
            } else {
                stop("Algo raro paso en el numero de episodios")
            }
            
            # ----- Registar la del último episodios -----------------------
            periodData <- arrange(periodData, desc(fec.hora))
            
            if (N == 1){
                ultimo <- data.frame(latU_hora = NA, latU_dur = NA)
            } else {
                ultimo <- data.frame(latU_hora = periodData$fec.hora[1], latU_dur = periodData$dur_min[1])
                ultimo <- mutate(ultimo, latU_hora = round(hour(latU_hora) + minute(latU_hora)/60, 3))
            }
            
            # Junta sujeto
            temp <- bind_cols(info, latencia, ultimo)
            temp <- mutate(temp, 
                           lat1_hora = round(hour(lat1_hora) + minute(lat1_hora)/60, 3),
                           lat2_hora = round(hour(lat2_hora) + minute(lat2_hora)/60, 3),
                           lat3_hora = round(hour(lat3_hora) + minute(lat3_hora)/60, 3))
            waso.subj <- bind_rows(waso.subj, temp)
        }
        
        # Junta todo
        waso.todo <- bind_rows(waso.todo, waso.subj)
    }
        
    # Saca pa fuera
    # head(waso.todo)
    waso.todo <- mutate(waso.todo, key = paste0(id, "_", periodo), key = str_replace(key, " ", "_"))
    waso.todo <- rename(waso.todo, dia.noc = semi)
    # paste(names(waso.todo), collapse = " ")
    return(waso.todo)
}
