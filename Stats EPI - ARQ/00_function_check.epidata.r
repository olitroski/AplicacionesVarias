# ----------------------------------------------------------------------------------------------- #
# ----- Funcion que chequea que el archivo es un epi.file de esos ya depurados y listos --------- #
# ----------------------------------------------------------------------------------------------- #
# data <- epi.data
# check.epidata(epi.data)
# check.epidata()

check.epidata <- function(data = NULL){
    # Muestra un ejemplo, no requiere datos
	if (class(data) == "NULL"){
	    cat("\n")
	    cat("+----------------------------------------------------------------------------------------+\n")	
		cat("| Los datos tienen que tener esta forma:                                                 |\n")
		cat("+----------------------------------------------------------------------------------------+\n")	
		cat("|     id            fec.hora estado dur_min mean_act dia.noc seq.dia   hora dia hora.abs |\n")
		cat("|  10013 2016-08-03 07:35:00      W      85    273.4     Dia      01  7.583 Wed        7 |\n")
		cat("|  10013 2016-08-03 09:00:00      S     180     10.8     Dia      01  9.000 Wed        9 |\n")
		cat("|  10013 2016-08-03 12:00:00      W      17    136.7     Dia      01 12.000 Wed       12 |\n")
		cat("|  10013 2016-08-03 12:17:00      S      20      0.1     Dia      01 12.283 Wed       12 |\n")
		cat("|  10013 2016-08-03 12:37:00      W     213    247.4     Dia      01 12.617 Wed       12 |\n")
		cat("|  10013 2016-08-03 16:10:00      S      21     30.1     Dia      01 16.167 Wed       16 |\n")
		cat("+----------------------------------------------------------------------------------------+\n\n")	
		
		# Podrian haber 2 formatos
		formatok <- data.frame(
		    Variables = c("id", "fec.hora", "estado", "dur_min", "mean_act", "dia.noc", "seq.dia", "hora", "dia", "hora.abs"),
		    Formato = c("character", "POSIXct POSIXt", "character", "numeric", "numeric", "character","character", "numeric", "character", "numeric"),
		    stringsAsFactors = FALSE
		)
		formatok$Formato[1] <- "character o numeric"
		
		cat("\n")
		cat("+----------------------------------------------------------------------------------------+\n")	
		cat("| Las variables deben tener los siguientes formatos:                                     |\n")
		cat("+----------------------------------------------------------------------------------------+\n")	
    	print(formatok)
    	cat("+----------------------------------------------------------------------------------------+\n")	
		cat("\n")
        
		
	} else {
	    cat("\n")
	    cat("<<<----------Revisando archivo de datos----------->>>\n")

		# Chequear nombre de variables
		checkvar <- c("id", "fec.hora", "estado", "dur_min", "mean_act", "dia.noc", "seq.dia", "hora", "dia", "hora.abs")
		varmatch <- sum(names(data) %in% checkvar)

		if (length(checkvar) == varmatch){
			cat("      Chequeando nombres de las variables... Ok\n")
		} else {
			cat("Nombres de variables no provienen de un epi.data, se necesitan estas:\n")
			cat(checkvar, sep = " - "); cat("\n")
			stop()
		}
		
		
		# Checar la clase de las variables
		format <- NULL
		for (var in names(data)){
			clase <- class(data[[var]])
			clase <- paste(clase, collapse = " ")
			format <- c(format, clase)
		}
        	        
		# Podrian haber 2 formatos
		if (class(data[,1]) == "character"){
		    formatok = c("character", "POSIXct POSIXt", "character", "numeric", "numeric", "character","character", "numeric", "character", "numeric")
		} else if (class(data[,1]) == "numeric") {
		    formatok = c("numeric",   "POSIXct POSIXt", "character", "numeric", "numeric", "character","character", "numeric", "character", "numeric")
		}
        
		# Esto debia estar arriba, pero wee... aca tira el error cuando sobran variables
		if (length(names(data) %in% checkvar) != length(checkvar)){
            sobra <- names(data)[!(names(data) %in% checkvar)]
            cat("Sobran variables: ", sobra, "\n")
            cat("Debe ser:", paste(checkvar, collapse = ", ")); cat("\n")
            stop("Revisar datos  :)")
            
        } else if (sum(format == formatok) == 10){
			cat("      Chequeando formato de las variables... Ok\n")
			
		} else {
			cat("Class de las variables no hace match con un epi.data, se necesitan estas:\n")
			cat(formatok, sep = " - "); cat("\n")
			stop()
		}
		
		cat("<<<------Archivo de episodios (EPI) correcto------>>>\n")
	}
}
