# ----------------------------------------------------------------------------------------------- #
# ----- Script para hacer la expansión de episodios de sueño o vigilia basandose en duración ---- #
# ----- y la hora de inicio del mismo 11.03.2019 ------------------------------------------------ #
# ----------------------------------------------------------------------------------------------- #
# Ejemplo del epi.data, expande una semiperiodo (dia o noche), agrega tercio y mitad 
#     data <- epi.valid
#     s <- 10013
#     p <- "Noche 02"
#     test <- expand.epidata(epi.data)
#     head(test, 30)

function_expand.epidata <- function(data){
    # Checar que la data sea un epidata
    # source("D:/OneDrive/INTA/Patricio Peirano/2018.09 Vigilia EPI/00_check.epidata.r")
    # check.epidata(data)
    
    # Sujetos y NULL df
    sujetos <- unique(data$id)
    expand.data <- NULL
    # counter <- data.frame(sujetos, n = 1:length(sujetos))

    # Loop sobre sujetos
    for (s in sujetos){
        # Contador
        # cat(as.numeric(filter(counter, sujetos == s) %>% select(n))/144*100, "\n")
            
        # Fitrar id
        sdata <- filter(data, id == s) %>% arrange(fec.hora)
        sdata <- mutate(sdata, periodo = paste(dia.noc, seq.dia))
        periodos <- unique(sdata$periodo)
        
        # Loop sobre periodos
        expand.period <- NULL
        for (p in periodos){
            
            # Filtraje y corregir y agregar contador ... naaa mejor uso el row.names
            pdata <- filter(sdata, periodo == p)
            pdata <- mutate(pdata, fec.hora = fec.hora - second(fec.hora), dur_min = floor(dur_min))
            
            # Expandir
            row.names(pdata) <- NULL
            pdata <- pdata[rep(row.names(pdata), times = pdata$dur_min), 1:11]
            
            # Arreglar la expansion
            pdata <- mutate(pdata, minseq = row.names(pdata))
            
            temp <- str_split_fixed(pdata$minseq, "\\.", 2)
            temp <- data.frame(minseq = temp[,2], stringsAsFactors = FALSE)
            temp <- mutate(temp, minseq = ifelse(minseq == "", "0", minseq), minseq = as.numeric(minseq))
            
            pdata <- cbind(select(pdata, -"minseq"), temp); rm(temp)
            pdata <- mutate(pdata, newhr = fec.hora + 60 * minseq)
            pdata <- mutate(pdata, hora.dec = hour(newhr) + minute(newhr)/60)
            pdata <- select(pdata, -fec.hora, -minseq, -hora) %>% rename(fec.hora = newhr, hora = hora.dec)
            pdata <- ordervar(pdata, names(data))   # :)
            
            # Corregir horas por el tema angular
            periodo <- unique(pdata$dia.noc)
                        
            if (periodo == "Noche"){
                pdata <- mutate(pdata, hora = ifelse(hora < 16, hora + 24, hora))
            } else if (periodo == "Dia"){
                pdata <- mutate(pdata, hora = ifelse(hora < 4 & hora >= 0, hora + 24, hora))
            }
            
            # Asignar epochs a mitad y tercio de su noche
            hr.range <- max(pdata$hora) - min(pdata$hora)
            T1 <- hr.range/3 + min(pdata$hora)
            T2 <- hr.range/3*2 + min(pdata$hora)
            M  <- hr.range/2 + min(pdata$hora)
            
            pdata <- mutate(pdata, ter = ifelse(hora < T1, 1, ifelse(hora >= T2, 3, 2)))
            pdata <- mutate(pdata, mit = ifelse(hora < M , 1, 2))
            
            
            # Agregar a la base final
            expand.period <- bind_rows(expand.period, pdata)
        }
    expand.data <- bind_rows(expand.data, expand.period)
    }
    return(expand.data)
}
