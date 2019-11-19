# ----------------------------------------------------------------------- #
# ---- Estadío intermedio entre Stata, para calcular el spline basis ---- #
# ----------------------------------------------------------------------- #

# Setear directorio de trabajo donde estan los archivos
setwd("D:/...../TRAJ/Ejemplo Splines")

# Cargar los datos con el paquete haven
library(haven)
datos <- read_dta("OPPOSITN_long.dta")

# Mirar los datos
head(datos, 7)

# Calculamos un spline basis cúbico 
library(splines)
spline <- bs(datos$time, df=4)

# El resultado es una matriz, lo transformamos en data frame
# y ponemos nombres a las variables
spline <- data.frame(spline)
names(spline) <- c("sp_uno", "sp_dos", "sp_tre", "sp_cua")
head(spline, 7)

# Juntamos los datos y los splines
datos_spline <- cbind(datos, spline)
head(datos_spline, 7)

# Listo, ahora exporetamos a stata
write_dta(datos_spline, "OPPOSITN_longSpline.dta")