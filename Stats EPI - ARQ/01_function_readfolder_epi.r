## Funcion de lectura de folder
# Lee la carpeta donde están los archivos *.epi y cada uno de  estos se procesan con la función
# "leer.data" que es la que procesa el archivo individual. Esta función está dentro de la función
# que lee todo el folder.

# Esta es una actualización para los datos de la Cata, se va a leer desde un data.frame ya cargado
# asi se puede usar de forma más extensiva que solo leer el folder que es más estático.

# basicamente es el EPI que en lugar de "nombre de sujeto" tiene un id numérico y se le borra la
# nota al final, el resto se deja igual.
# Para evitar problemas tendré que pasar a csv primero

# epicsv <- "EPI_12m_fds_todos.csv"
# epicsv <- "EPI_6m.csv"

function_read.epi <- function(epicsv){
    library(dplyr); library(lubridate)
    df <- read.table(epicsv, header = TRUE, sep = ",", stringsAsFactors = FALSE)
    
    # Chequear n de columnas
    if (ncol(df) != 9){
        stop("Debe tener 9 columnas")
    }
    
    # Adaptar nombres
    names(df) <- c("id", "periodo", "hora", "estado", "actividad", 
                   "dur_min", "mean_act_min", "num_epi", "epi_estado")
    
    # sacar las comas a duracion y mean
    df <- mutate(df, dur_min = str_replace(dur_min, ",", "."), mean_act_min = str_replace(mean_act_min, ",", "."))
    df <- mutate(df, dur_min = as.numeric(dur_min), mean_act_min = as.numeric(mean_act_min))

    # Pasar la hora a formato
    df <- mutate(df, hora = dmy_hm(hora))

    # La key para el merge
    df <- distinct(df, id, periodo, hora, estado, actividad, dur_min, mean_act_min, .keep_all = TRUE)
    df <- mutate(df, key = paste0(id, "_", periodo))
    
    # Borrar variable actividad porque el sistema no lo considera y quedó el id como "int"
    # df <- select(df, -actividad)
    df <- mutate(df, id = as.numeric(id))
    
    return(df)
}


