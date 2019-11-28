# Crear base de datos 



# Validacion
files
files[1]
files[2]

# id a partir del file
idname(files[2])

# Rawdata
data1A <- read.csvfile(files[1])
data2A <- read.csvfile(files[2])
head(data1A[[1]])
head(data2A[[2]])

# Tidydata
data1B <- tidy.rawdata(data1A)
data2B <- tidy.rawdata(data2A)
head(data2B)

# Validacion statas
data1C <- block.stats(data1B)
data2C <- block.stats(data2B)
data1C; data2C

# Cross validation
View(crossval(data2B))
View(crossval(data1B))




