# Con este script se apilas lan hojas del ARQ, con varios chequeos
# las hojas del excel igual hay que limpiarlas, se dejan con un nombre de hoja que contiene
# la palabra OK como indicador para capturarlas luego

# setwd("D:/OneDrive/INTA/Patricio Peirano/2018.09 Vigilia EPI/6 meses bebes/arq")
# xlsxfile <- dir()[grepl("arq", dir())]
# xlsxfile <- xlsxfile[1] 

# 10.01.2019 se agrega para capturar el folder de una

# Mismo se modifica para que lea un consolidado de los arq en formato csv
# arqcsv <- "ARQ 6m L-D.csv"


function_read.arq <- function(arqcsv = NULL){
    # leer
    df <- read.table(arqcsv, header = TRUE, sep = ",", stringsAsFactors = FALSE)
    names(df) <- c("id", "periodo", "jornada", "hora.arq")
    
    # Pasar la hora a formato
    df <- mutate(df, hora.arq = dmy_hm(hora.arq))
    
    # Sacar repetidos
    df <- distinct(df, id, periodo, jornada, hora.arq)

    # La key para el merge
    df <- mutate(df, key = paste0(id, "_", periodo))
    df <- select(df, -id, -periodo)
    
    return(df)    

}

