# ------------------------------------------------------------------------------------- #
# ----- Script para comprobar Stroop Reward NIH 21y en carpeta "Stroop-Chile2013 ------ #
# ----- se revisan que los archivos sean básicamente los mismos. Usando el hash ------- #
# ----- en cuarentena 03.05.2020, Oliver Rojas, Lab.Sueño - INTA - U.Chile ------------ # 
# ------------------------------------------------------------------------------------- #
# La librería digest calcula el hash SHA1 con ese bastará.
rm(list=ls())
library(digest)
library(dplyr)
library(devtools)
library(stringr)

# Folder donde estan los 3 otros folders
maindir <- "C:/Users/olitr/Desktop/Stroop 20 años/Stroop-Chile2013 NIH 21y"
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

# Carpeta stroop sussanne
sussanne <- hash("Stroop-Chile2013 NIH 21y Sussanne")
row.names(sussanne) <- NULL
sussanne <- rename(sussanne, file_su = file)
head(sussanne)

# Carpeta stroop Oliver
olito <- hash("Stroop-Chile2013 NIH 21y Oliver")
row.names(olito) <- NULL
olito <- rename(olito, file_oli = file)
head(olito)

# Combinar Sussanne ERP y Oliver ERP
combinado <- omerge(sussanne, olito, by = "sha", keep = TRUE)
head(olito)
head(sussanne)




# ------------------------------------------------------------------------------------- #
# ----- Todo listo entonces, se sigue en el README del script ------------------------- # 
# ----- Esto queda como respaldo no más ----------------------------------------------- #
# ------------------------------------------------------------------------------------- #
