# --------------------------------------------------------------------------------- #
# ---- 20.06.2018 - Nuevas formas para Stroop de comida ya pasado por script ------ #
# ---- Oliver Rojas - Lab.Sueño - INTA - U.Chile ---------------------------------- #
# --------------------------------------------------------------------------------- #
rm(list=ls())
source("https://raw.githubusercontent.com/olitroski/sources/master/exploratory/sources.r")
rm(pwcorr, ttest.indep, ttest.pair)
setwd("D:/Varios INTA/Bases de datos 21y/Scripts/DM stroop alimentos")
library(dplyr); library(stringr)


## Leer el archivo, Base
# Se arreglan los ids y bloques, el resto en Stata los merges
stroop.stats <- read.xlsx("data.stat.xlsx")
head(stroop.stats)
id.block <- str_split_fixed(stroop.stats$id.block, "_", 2)
id.block <- data.frame(id.block, stringsAsFactors = FALSE)
id.block <- mutate(id.block, id = as.numeric(X1), block = as.numeric(X2)) %>% select(id, block)

stroop.stats <- cbind(id.block, stroop.stats)
write.xlsx(stroop.stats, "NIH21y_stroop_alimento_stats.xlsx")


## Versión Wide
stroop.wide <- select(stroop.stats, -"id.block", -"file")
stroop.wide <- reshape(stroop.wide, timevar = "block", idvar = "id", direction = "wide")
# View(stroop.wide)
write.xlsx(stroop.wide, "NIH21y_stroop_alimento_wide.xlsx")


## Versión promedios
stroop.mean <- select(stroop.stats, -"id.block", -"block", -"file")
stroop.mean <- group_by(stroop.mean, id)
stroop.mean <- summarise_all(stroop.mean, funs(mean(., na.rm = TRUE)))
stroop.mean <- mutate_all(stroop.mean, funs(ifelse(is.na(.), NA, .)))
# View(stroop.mean)
write.xlsx(stroop.mean, "NIH21y_stroop_alimento_mean.xlsx")


