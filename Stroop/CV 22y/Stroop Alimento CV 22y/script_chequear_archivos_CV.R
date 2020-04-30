# ------------------------------------------------------------------------------------- #
# ----- Script para comprobar Stroop Alimento CV 22y en todas sus versiones ----------- #
# ----- se revisan que los archivos sean básicamente los mismos. Usando el hash ------- #
# ----- en cuarentena 30.04.2020, Oliver Rojas, Lab.Sueño - INTA - U.Chile ------------ # 
# ------------------------------------------------------------------------------------- #
# La librería digest calcula el hash SHA1 con ese bastará.
rm(list=ls())
library(digest)
library(dplyr)
library(devtools)
library(stringr)

# Folder donde estan los 3 otros folders
maindir <- "C:/Users/olitr/Desktop/Stroop 20 años/Stroop Alimento/CV"
setwd(maindir)
carpetas <- dir()[dir.exists(dir())]

# Función para sacr los hash
hash <- function(c){
    setwd(file.path(maindir, c))
    archivos <- dir()
    hash <- sapply(archivos, sha1)
    return(data.frame(file = archivos, sha = hash, stringsAsFactors = FALSE))    
}

# De momento está acá en github, en el futuro tendrá su propio package 'cuando ordene'
source_url("https://raw.github.com/olitroski/sources/master/exploratory/omerge.r")
source_url("https://raw.github.com/olitroski/sources/master/exploratory/order.var.r")
stop()


# ----------------------------------------------------------------------------- #
# --- comparar los ERP de Sussanne y los Mios --- CARPETA 1 ------------------- #
# ----------------------------------------------------------------------------- #
print(carpetas)

# Carpeta ERP sussanne
sussanne <- hash("StroopAlimentoCarpeta-1 Sussanne")
row.names(sussanne) <- NULL
sussanne <- rename(sussanne, file_su = file)
head(sussanne)

# Carpeta ERP Oliver
olito <- hash("Stroop CV Alimento 1 Oliver")
row.names(olito) <- NULL
olito <- rename(olito, file_oli = file)
head(olito)

# Carpeta CSV Oliver
olitoCSV <- hash("Stroop CV Alimento 1 CSV Oliver")
row.names(olitoCSV) <- NULL
olitoCSV <- rename(olitoCSV, shaCSV = sha)
olitoCSV <- mutate(olitoCSV, file = str_replace(string = file, pattern = ".csv$|.CSV$", replacement = ""))
head(olitoCSV)

# Combinar Sussanne ERP y Oliver ERP
combinado <- omerge(sussanne, olito, by = "sha", keep = TRUE)
head(olito)
head(sussanne)

# Comprobar olito ERP Y CSV
olito <- rename(olito, file = file_oli)
head(olito)
head(olitoCSV)
combiOlito <- omerge(olito, olitoCSV, by = "file", keep = TRUE)
combiOlito$using


# ----------------------------------------------------------------------------- #
# --- comparar los ERP de Sussanne y los Mios --- CARPETA 2 ------------------- #
# ----------------------------------------------------------------------------- #
print(carpetas)

# Carpeta ERP sussanne
sussanne <- hash("StroopAlimentoCarpeta-2 Sussanne")
row.names(sussanne) <- NULL
sussanne <- rename(sussanne, file_su = file)
head(sussanne)

# Carpeta ERP Oliver
olito <- hash("Stroop CV Alimento 2 Oliver")
row.names(olito) <- NULL
olito <- rename(olito, file_oli = file)
head(olito)

# Carpeta CSV Oliver
olitoCSV <- hash("Stroop CV Alimento 2 CSV Oliver")
row.names(olitoCSV) <- NULL
olitoCSV <- rename(olitoCSV, shaCSV = sha)
olitoCSV <- mutate(olitoCSV, file = str_replace(string = file, pattern = ".csv$|.CSV$", replacement = ""))
head(olitoCSV)

# Combinar Sussanne ERP y Oliver ERP
combinado <- omerge(sussanne, olito, by = "sha", keep = TRUE)
head(olito)
head(sussanne)

# Comprobar olito ERP Y CSV
olito <- rename(olito, file = file_oli)
head(olito)
head(olitoCSV)
combiOlito <- omerge(olito, olitoCSV, by = "file", keep = TRUE)
combiOlito$using




# ------------------------------------------------------------------------------------- #
# ----- Todo listo entonces, se sigue en el README del script ------------------------- # 
# ----- Esto queda como respaldo no más ----------------------------------------------- #
# ------------------------------------------------------------------------------------- #
