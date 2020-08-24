###########################################################################################
## ---- Funcion captura periodos validos por sujeto ------------------------------------- #
###########################################################################################
# Funcion que captura todo sin distncion dia, noche y eventos, para replicar analisis 
# que hice a las wawas de las encuestas, pero ahora en un epi, asume datos filtrados de 
# actigrafos validos con el ARQ. Recorta en varias caracteristicas
# 
# 1. Filter "Dia 01"
# 2. Drop lineas Repetidos
# 3. Al menos 3 eventos por d?a o noche
# 4. Primer evento correcto seg?n dia o noche
# 
# Actualizacion: Guarda los valores de lo que se saque.
# 
# setwd("D:/OneDrive/INTA/Patricio Peirano/2018.09 Vigilia EPI/6 meses bebes")
# data <- readRDS("epi.data.rds")
# id <- 10207

function_ValidEvents <- function(epi = NULL, drop = TRUE){
    data <- epi
    
	## <<< Funcion para sacar datos por sujeto >>> 
    # id <- 10648; subjdata <- epi; p <- "Noche 02"
    epi.todo <- function(subjdata = NULL, id = NULL){
        # print(id)
        # Nulo para registrar Dropeos del id
        id.drop <- NULL
        
        # Filtraje del id <datos>
        datos <- subjdata[subjdata$id == id, ]
        datos <- select(datos, id, periodo, hora, estado, dur_min, mean_act_min, actividad, num_epi)
        
        
        # <<< 1. Dia 01 >>> WRONG porque el Dia 01 viene despues de la Noche 01 ---------
        # Se saca el periodo "Dia 01" porque no es un dia completo.
        # --- 20.08.2020 --- Modificacion incluye Dia 01--
        # if (nrow(datos) == 0){
        #     next()
        # } else {
        #     datos <- filter(datos, periodo != "Dia 01")
        #     id.drop <- bind_rows(id.drop, 
        #                          data.frame(id = id, drop = "Dia 01", stringsAsFactors = FALSE))
        # }
        
        
        # <<< 2. Repetidos >>> se evaluan los repetidos segun hora y dia ----------------
        # Se ordena por la fechora, se crea una 2da var desplazada 1 fila pa abajo, por si hay repetido
        if (nrow(datos) == 0){
            next()
        } else {
            temp <- nrow(datos)
            datos <- arrange(datos, id, periodo, hora)
            datos <- distinct(datos, id, periodo, hora, estado, dur_min, .keep_all = TRUE)
            
            # Registrar si hay repetidos
            if (temp > nrow(datos)){
                id.drop <- bind_rows(id.drop, 
                                     data.frame(id = id, drop = paste0(temp, " -> ", nrow(datos)), stringsAsFactors = FALSE))
            }
            rm(temp)
        }
        
        
        # 3. Crear variables del periodo
        datos <- select(datos, -num_epi)
        datos <- bind_cols(datos, data.frame(str_split_fixed(datos$periodo, " ", n = 2), stringsAsFactors=FALSE))
        datos <- rename(datos, dia.noc = X1, seq.dia = X2)
        
        
        # <<< 4. Minimo 3 eventos por dia o noche >>> -----------------------------------
        # Se quita, ahora se usa todo, pero se registra
        # Cada periodo (dia o noche completo) debe tener minimo 3 episodios para poder hacer calculos
        if (nrow(datos) == 0){
            next()
        } else {
            datos <- group_by(datos, periodo)
            datos <- mutate(datos, count = n())
            
            # Registrar los periodos con menos de 3 episodios
            temp <- summarize(datos, N = n())
            temp <- filter(temp, N < 3)
            if (nrow(temp) > 0){
                id.drop <- bind_rows(id.drop,
                                     data.frame(id = id, 
                                                drop = paste(temp$periodo, "=", temp$N, collapse = " - "), 
                                                stringsAsFactors = FALSE))
            }
            rm(temp)
            
            # Devolver a data.frame
            datos <- as.data.frame(datos)
            # datos <- filter(datos, count >= 3)
            datos <- select(datos, -count)      
        }

        
        # <<< 5. Primer evento correcto segun dia o noche >>>
        # Esta cosa (actividorm) determina noche o dia cuando ocurre un periodo despues de cierta hora
        # Pero aca interesa (en esta funcion) que en dia inicie con "W" y noche con "S", aca se arregla si no
        temp <- NULL
        periodo <- unique(datos$periodo)      # p <- periodo[3]
        
        for (p in periodo){
            # Captura el periodo
            filtro <- filter(datos, periodo == p)
            filtro <- arrange(filtro, hora)
            estado <- filtro$estado[1]
            dianoc <- filtro$dia.noc[1]
            
            # Guardar el epoch 
            if (dianoc == "Noche" & estado == "W"){
                # Ahora no hace nada, o sea lo quita del compilado
                # filtro <- slice(filtro, -1)
                # temp <- rbind(temp, filtro)               
                
                # Registar error
                id.drop <- bind_rows(id.drop, 
                                     data.frame(id = id, drop = paste(filtro$dia.noc[1], filtro$seq.dia[1], "Bad Ini"), stringsAsFactors = FALSE))
                
            } else if (dianoc == "Dia" & estado == "S"){
                # ahora no se guarda
                # filtro <- slice(filtro, -1)
                # temp <- rbind(temp, filtro)
                
                # Registrar el error
                id.drop <- bind_rows(id.drop, 
                                     data.frame(id = id, drop = paste(filtro$dia.noc[1], filtro$seq.dia[1], "Bad Ini"), stringsAsFactors = FALSE)) 
            
            # Si está ok lo compila
            } else {
                temp <- rbind(temp, filtro)  
            }
            
            # Limpiar
            rm(filtro, estado, dianoc)
        }
        datos <- temp
        
        # Y salir
        return(list(datos = datos, drop = id.drop))
    }

    
    # ---- Parsear a todos los sujetos ----------------------------------------
    sujetos <- unique(data$id)
    datos.todo <- NULL
    datos.drop <- NULL
    contador <- 0

    for (subj in sujetos){
        # Contador
        if (contador < 50){
            cat(".")
            contador <- contador + 1
        } else {
            cat("\n")
            contador <- 0
        }
        
        temp <- epi.todo(data, id = subj)
        datos.todo <- rbind(datos.todo, temp$datos)
        datos.drop <- rbind(datos.drop, temp$drop)
        rm(temp)
    }

    # Terminar la base
    datos.todo <- rename(datos.todo, mean_act = mean_act_min, fec.hora = hora) %>% select(-periodo)
    datos.todo <- mutate(datos.todo, hora = hour(fec.hora) + minute(fec.hora)/60, 
                         dia =  wday(fec.hora, label = TRUE),
                         hora = round(hora, 3), 
                         hora.abs = floor(hora))
    
    # 6. Dia semana en transito
    datos.todo <- arrange(datos.todo, id, fec.hora)
    datos.todo <- mutate(datos.todo, periodo = paste(dia.noc, seq.dia))
    
    datos.todo <- group_by(datos.todo, id, periodo)
    datos.todo <- mutate(datos.todo, hi = min(fec.hora), hidate = as_date(hi), hi = hour(hi) + minute(hi)/60)
    datos.todo <- as.data.frame(datos.todo)
    
    datos.todo <- mutate(datos.todo, inidate = ifelse(hi > 0 & hi < 12 & dia.noc == "Noche", 1, 0))
    datos.todo <- mutate(datos.todo, realini = as_date(ifelse(inidate == 1, hidate - days(1), hidate)))

    datos.todo <- mutate(datos.todo, transito = paste0(wday(realini, label = TRUE), "-", wday(realini+days(1), label = TRUE)))
    datos.todo <- mutate(datos.todo, transito = ifelse(dia.noc == "Dia", as.character(wday(realini, label = TRUE)), transito))
    
    datos.todo <- mutate(datos.todo, dia = transito)
    datos.todo <- select(datos.todo, -transito, -realini, -inidate, -hidate, -hi, -periodo)
    
    # 7. Minutos con decimales x problema con la expansion
    datos.todo <- mutate(datos.todo, dur_min = floor(dur_min))  
    
    # Ajuste segun funcion
    cat("\n")
    print(paste("dim Epi", dim(data)[1], " - dim Datos", dim(datos.todo)[1]))
    print(paste("Se perdieron:", dim(data)[1]-dim(datos.todo)[1], "filas"))
    
    # Retorna todo o un trozo
    if (drop == FALSE){
        return(datos.todo)
    } else {
        return(list(datos = datos.todo, drop = datos.drop))
    }
}

# test <- function_ValidEvents(data, drop = TRUE)
