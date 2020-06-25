# ----------------------------------------------------------------------------------------------- #
# ---- Funcion para captuara la data de la hora de inicio de cada periodo en dia y noche -------- #
# ---- v1.0 08.03.2019 -------------------------------------------------------------------------- #
# ----------------------------------------------------------------------------------------------- #
# Se entiende como hora de inicio y seg?n el ppt al Wakeup time, sleep time como la hora del primer
# evento sueno o vigilia del d?a o noche seg?n corresponda.

function_hi <- function(epi){
    # Checar la data
    library(lubridate)
    check.epidata(epi)
        
    # Capturar sujetos y crear contenedor en blanco
    sujetos <- unique(epi$id)
    hi.data <- NULL
    contador <- 0
    
    # Primer loopeo sobre sujetos  s <- 10546; p <- "Noche 02"
    for (s in sujetos){
        # Contador
        if (contador < 50){
            cat(".")
            contador <- contador + 1
        } else {
            cat("\n")
            contador <- 0
        }
        
        # Captura de periodos
        hi.subj <- filter(epi, id == s) %>% arrange(fec.hora)
        hi.subj <- mutate(hi.subj, periodo = paste(dia.noc, seq.dia))
        periodos <- unique(hi.subj$periodo)
        
        # Segundo loopeo sobre los periodos de un sujeto
        for (p in periodos){
            
            # Filtraje
            hi.period <- filter(hi.subj, periodo == p)
        
            ## Inicio de extraccion de los datos
            
            # Tipo de semi periodo y chequeoque el 1er evento corresponda
            semiper <- unique(hi.period$dia.noc)
            if (semiper == "Dia"){
                if (hi.period$estado[1] != "W"){ stop(paste("1er estado incorrecto", s, p)) }
            } else if (semiper == "Noche"){
                if (hi.period$estado[1] != "S"){ stop(paste("1er estado incorrecto", s, p)) }
            }
            
            # Hora del 1er evento (decimal)
            hora <- hi.period$hora[1]
            hora.abs <- hi.period$hora.abs[1]
            fec <- as_date(hi.period$fec.hora[1])
            
            hora2 <- ifelse(hora > 0 & hora < 6, hora + 24, hora)
            hora.abs2 <- floor(hora2)
            
            # Dia de la semana y estado y hora de fin
            wday <- hi.period$dia[1]
            sw <- hi.period$estado[1]
            
            # Hora de fin del periodo
            horaf <- arrange(hi.period, desc(fec.hora))
            horaf.min <- horaf$dur_min[1]
            horaf <- horaf$fec.hora[1]
            horaf <- horaf + minutes(horaf.min)      # Hora del episodio + duracion
            horaf <- hour(horaf) + minute(horaf)/60
            
            if (semiper == "Dia"){
                horaf2 <- ifelse(horaf < 5 & horaf > 0, horaf + 24, horaf)
                horaf2 <- round(horaf2, 3)
            } else if (semiper == "Noche"){
                horaf2 <- ifelse(horaf < 12 & horaf > 0, horaf + 24, horaf)
                horaf2 <- round(horaf2, 3)
            }
            
            # Hora mitad de la noche
            fecmin <- min(hi.period$fec.hora)
            fecmax <- max(hi.period$fec.hora) 
            durmax <- hi.period[which(hi.period$fec.hora == fecmax), "dur_min"]
            fecmax <- fecmax + minutes(durmax)
            mitad <- fecmin + (fecmax - fecmin)/2
            mitad <- round(hour(mitad) + minute(mitad)/60, 3)
            
            mitad2 <- ifelse(mitad > 0 & mitad < 12 & semiper == "Noche", mitad + 24, mitad)
            
            ## Tabulacion data.frame periodo
            df <- data.frame(id = s,
                             period = p,
                             dia_noc = semiper,
                             stage_ini = sw,
                             hi = hora,
                             # hi2 = hora2,
                             hi_abs = hora.abs,
                             # hi_abs2 = hora.abs2,
                             hi_m = mitad, 
                             # hi_m2 = mitad2,
                             hf = round(horaf, 3),
                             hf2 = horaf2,
                             wday = wday,
                             fecha = fec)
            
            # Agregar a la base general
            hi.data <- rbind(hi.data, df)
        
        }
    }

    # Retorno de resultado
    # head(hi.data)
    hi.data <- mutate(hi.data, key = paste0(id, "_", period), key = str_replace(key, " ", "_"))
    hi.data <- rename(hi.data, periodo = period)
    return(hi.data)
}


