### Script que toma:
# Un folder con archivos ERP para exportar a CSV en el ERPw ---> Se guarda el vector de archivos
# Un script de Pulover's Macro Creator que hace toda la operatoria
# 	tiene 2 lineas en donde introducir la ruta completa del archivo y el nombre del archivo
# Luego hace tantos de estos como ids hay y los junta
rm(list=ls())


## --- Sacar los files names ---------------------------------------------------------------
setwd("D:/Varios INTA/Bases de datos 21y/NIH21y/Stroop Alimento")
archivos <- dir()

# Queda este working directory
# Para probar
# archivos <- archivos[1:4]
# file <- archivos[2]



## --- Leer y dejar listo para reemplazo el macro ------------------------------------------
# Lineas
setwd("D:/Varios INTA/Bases de datos 21y/CV21y/Stroop Alimento")
pmc <- readLines("template stroop.pmc")


# Cabecera
head <- pmc[1:2]
head <- c(substring(head[1],4), head[2])


# Capturar macro y borrar numero de inicio (parte en 1)
macro <- pmc[3:48]
macro <- sub("^[0-9]|^[0-9][0-9]", "", macro)


# Lineas leer archivo (20) y salvar csv (37)
ruta.leer <- "D:\\Varios INTA\\Bases de datos 21y\\NIH21y\\Stroop Alimento\\"
leer1 <- "|[Text]|"
leer2 <- "|1|0|SendRaw|||||"

ruta.csv <- "D:\\Varios INTA\\Bases de datos 21y\\NIH21y\\Stroop Alimento CSV\\"
csv1 <- "|[Text]|"
csv2 <- ".csv|1|100|SendRaw|||||"   


full.macro <- NULL
for (file in archivos){
	# Reemplazar 
	temp.macro <- macro
	
	lectura <- paste(leer1, ruta.leer, file, leer2, sep="")
	temp.macro[20] <- lectura
	
	escrito <- paste(csv1, ruta.csv, file, csv2, sep="")
	temp.macro[37] <- escrito
	
	# Combinar
	full.macro <- c(full.macro, temp.macro)
}


# Pegar correlativos y encabezado
correl <- 1:length(full.macro)
full.macro <- paste(correl, full.macro, sep="")
full.macro <- c(head, full.macro)
length(full.macro)



## --- Guardar en el folder de trabajo---------------------------------------------------
setwd("D:/Varios INTA/Bases de datos 21y/NIH21y")
writeLines(full.macro, "full_macro_2.pmc")







