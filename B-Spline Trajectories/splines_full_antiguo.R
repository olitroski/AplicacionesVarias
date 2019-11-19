# ---------------------------------------------------------------------------- #
# ---- Ejemplo para implementar el calculo de trayectorias combinando el ----- #
# ---- splines package del R y el TRAJ del Stata. v1. 09.08.2019 ------------- #
# ---------------------------------------------------------------------------- #
# La secuencia del proceso es la siguiente (En general)
# 1. Tener un Excel con datos en formato wide
# 2. Leer esos datos y quedarse solo con el id, tiempo y medici?n
# 3. Hacer un reshape a long 
# 4. Calcular el 'spline basis' con el comando bs
# 5. Aplicar data management para exportar el 'spline basis' a formato stata
# 6. Cargar en Stata y calcular trayectorias
# 
# Estrategia de an?lisis
# * En R estimar un spline basis con 4 df (1 spline) y llevar a Stata
# * En Stata calcular 1, 2, 3, 4, 5 trayectorias, anotar BIC y AIC
# 
# * En R estimar un spline basis con 5 df (2 spline) y llevar a Stata
# * En Stata calcular 1, 2, 3, 4, 5 trayectorias, anotar BIC y AIC
# 
# * En R estimar un spline basis con 6 df (3 spline) y llevar a Stata
# * En Stata calcular 1, 2, 3, 4, 5 trayectorias, anotar BIC y AIC
# Y as?, con unos 5 splines maximo estimo queda bien.
# Si se hace as? se tendr?n 25 BIC

# <<< Para instalar paquetes se usa el comando install.packages("package") >>>>

# ---------------------------------------------------------------------------- #
# ---- Preparar el archivo para calcular el Spline Basis --------------------- #
# ---------------------------------------------------------------------------- #
# Setear directorio de trabajo
setwd("D:/")
library(dplyr)

# Leer el Excel en foramto wide, si no se tiene la libreria hay que instalar
# con el comando     install.packages("readxl")
library("readxl")
datos <- data.frame(read_xlsx("OPPOSITN.xlsx", sheet = "OPPOSITN"))
head(datos)

# En R transformar de wide a long requiere el tiempo separado de la variable,
# asi que cambiamos los nombres de las varaibles
names(datos) <- sub("0", ".", names(datos))
head(datos)

# Hacemos el reshape
datos <- reshape(data = datos, varying = 2:15, direction = "long")
head(datos)

# Cambiamos los nombres de las variables ordenamos y renombramos las filas
datos <- rename(datos, epoch = time, data = V, time = T)
datos <- arrange(datos, id, time)
head(datos)



# ---------------------------------------------------------------------------- #
# ---- Calculamos el spline basis con 1 a 5 splines -------------------------- #
# ---------------------------------------------------------------------------- #
# Cargar la libreria
library(splines)


# Calculamos todos los splines de una
spline1 <- bs(datos$time, df=4)
spline2 <- bs(datos$time, df=5)
spline3 <- bs(datos$time, df=6)
spline4 <- bs(datos$time, df=7)
spline5 <- bs(datos$time, df=8)
head(spline2)  # Miremos el spline2. Ojo cada spline agrega una variable


# Los splines calculados son matrices y hay que transformar en data.frame 
spline1 <- data.frame(spline1)
spline2 <- data.frame(spline2)
spline3 <- data.frame(spline3)
spline4 <- data.frame(spline4)
spline5 <- data.frame(spline5)
head(spline2)


# Cambiar los nombres de variables para que se puedan usar en Stata
names(spline1) <- c("sp_uno", "sp_dos", "sp_tre", "sp_cua")
names(spline2) <- c("sp_uno", "sp_dos", "sp_tre", "sp_cua", "sp_cin")
names(spline3) <- c("sp_uno", "sp_dos", "sp_tre", "sp_cua", "sp_cin", "sp_six")
names(spline4) <- c("sp_uno", "sp_dos", "sp_tre", "sp_cua", "sp_cin", "sp_six", "sp_sep")
names(spline5) <- c("sp_uno", "sp_dos", "sp_tre", "sp_cua", "sp_cin", "sp_six", "sp_sep", "sp_oct")
head(spline2)


# Crear 5 bases de datos, con los datos originales + uno de los spline basis
datos1 <- bind_cols(datos, spline1)
datos2 <- bind_cols(datos, spline2)
datos3 <- bind_cols(datos, spline3)
datos4 <- bind_cols(datos, spline4)
datos5 <- bind_cols(datos, spline5)
head(datos2)


# Hacemos reshape para pasar a de long a wide
datos1 <- reshape(datos1, direction = "wide", idvar = "id", timevar = "epoch")
datos2 <- reshape(datos2, direction = "wide", idvar = "id", timevar = "epoch")
datos3 <- reshape(datos3, direction = "wide", idvar = "id", timevar = "epoch")
datos4 <- reshape(datos4, direction = "wide", idvar = "id", timevar = "epoch")
datos5 <- reshape(datos5, direction = "wide", idvar = "id", timevar = "epoch")
head(datos2)   # Hay como mil variables, cada sujeto tiene 1 fila que es lo imporante


# Estamos listos para guardar en Stata, cargamos libreria y guardamos
library(foreign)
write.dta(datos1, "OPPOSITN_spline_1.dta")
write.dta(datos2, "OPPOSITN_spline_2.dta")
write.dta(datos3, "OPPOSITN_spline_3.dta")
write.dta(datos4, "OPPOSITN_spline_4.dta")
write.dta(datos5, "OPPOSITN_spline_5.dta")


# <<< Listo el R >>> 
#       XD






