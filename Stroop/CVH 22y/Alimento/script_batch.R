# Directorio
wd = choose.dir()
setwd(wd)
#setwd("C:/Users/Oliver/Desktop")

# Cargar paquete
require(xlsx)


# Cargar el excel
files <- dir()
read.xlsx(files[1], sheetIndex=1)
#read.xlsx("auto.xlsx", sheetIndex=1)


# Make some stats
ini <- head(mtcars, 5)
write.xlsx(ini, "file_2.xlsx")















