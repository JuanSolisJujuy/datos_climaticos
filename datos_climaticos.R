######################################################################
#Información meteorológica y climáticas: Fuentes de pronósticos     ##
#climáticos y meteorológicos                                        ##
#Análisis de series temporales                                      ##
######################################################################

#REPOSITORIO DE R Y RSTUDIO-------------------------------------------
####https://cran.r-project.org/ --------------------------------------
####https://www.rstudio.com/------------------------------------------
#### COMENCEMOS !!!!##################################################
#Definidmos las librerías que vamos a utilizar y luego las cargamos
library("rstudioapi")#"relative path"
library("tidyverse")#manipulación de datos
library("ggplot2")#gráficos
library("stringr")#operacion con textos
library("forecast")#modelos de predicción series temporales
library("tseries")#series de tiempo
library("imputeTS")#imputación datos perdidos
library("Kendall") #test de Mann Kendall
library("xlsx")#importar datos en excel
library("GGally")#gráficos múltiples relaciones
library("utils")
library("rvest")#web scraping 
library(agricolae) #algunas medidas de resumen/dispersión

ls() ##antes, chequeamos los objetos que tengamos creados anteriormente
rm(list=ls()) ### borramos los objetos que tengamos creados anteriormente
ls() ##volvemos a chequear
setwd(dirname(getActiveDocumentContext()$path))#definimos el directorio de trabajo
getwd()#verificamos el directorio de trabajo

# Lo primero es obtener los datos###############################################

#"WEB SCRAPING" ####
enlace<-"http://www.siaj.fca.unju.edu.ar/perspectivas/"
page <- read_html(enlace)
#Exploremos archivos .csv
page %>%
  html_nodes("a") %>%       
  html_attr("href") %>%     
  str_subset(".csv")

#Exploremos archivos .txt
page %>%
  html_nodes("a") %>%       
  html_attr("href") %>%     
  str_subset(".txt")

#Exploremos archivos .xlsx
page %>%
  html_nodes("a") %>%       
  html_attr("href") %>%     
  str_subset(".xlsx")

#Seleccionemos el primer csv de la lista####
ref.csv<-page %>%
  html_nodes("a") %>%       
  html_attr("href") %>%     
  str_subset(".csv")%>%
  .[[1]]
ref.csv
enlace.ref.csv<-paste0("http://www.siaj.fca.unju.edu.ar",ref.csv)
#descargamos el archivo en nuestra carpeta de trabajo
download.file(enlace.ref.csv,destfile = "csvdescargado.csv") #descargamos...
datos.de.prueba<-read.csv("csvdescargado.csv",header = TRUE) ## ..ahora leemos los datos, ups! debemos "saltar" 12 líneas
datos.de.prueba<-read.csv("csvdescargado.csv",
                          skip = 12,
                          check.names = F,
                          header = TRUE) ## OK!!
file.remove("csvdescargado.csv") #borramos el archivo recientemente descargado

# Vamos a leer datos previamente descargados ####
misDatos<-read.csv("datosClimaticos.csv", header = T, dec = ",", sep = ";")
head(misDatos) ##visualizamos los primeros datos
misDatos$Tmedia<-(misDatos$Tmax + misDatos$Tmin)/2 ##calculamos temperatura media
head(misDatos) ##comprobamos la creacion de la nueva columna
class(misDatos) ### averiguamos que "clase" de objeto es misDatos
#"colección de vectores"

# Revisemos si tenemos datos perdidos u omitidos################################
tempmedia<-misDatos$Tmedia
sum(is.na(tempmedia))  ##### ok, tenemos algunos datos perdidos, habra que corregir en la serie de tiempo
# AHORA DEBEMOS CONVERTIR LA SERIE DE DATOS DE LA VARIABLE "Y" EN UN OBJETO "TS" ######
serieTmedia<-ts(misDatos$Tmedia, frequency = 365.25, start = c(1987,1)) ### compensamos por anios bisiestos
head(serieTmedia)
plot.ts(serieTmedia) ###lo primero es visualizar la serie
# Ahora chequeamos valores omitidos o perdidos ####
sum(is.na(serieTmedia)) #### contamos valores perdidos, entonces .....
serieTmediaCompleta <-na_interpolation(serieTmedia, option = "linear")
?na_interpolation
serieTmediaarreglada<-tsclean(serieTmedia,replace.missing = TRUE)
?tsclean #("Friedman Super Smoother" y "Seasonal and Trend decomposition using Loess")
sum(is.na(serieTmediaCompleta)) 
sum(is.na(serieTmediaarreglada))
plot.ts(serieTmediaarreglada)

# Un poco de práctica: "arreglar" y graficar la columna de temperaturas máximas ####


# Ahora si, continuemos..... pero con una serie simplificada
misDatos2<-read.csv("serieTempMedMensuales.csv", header = T, dec = ",", sep = ";")
class(misDatos2$PromedioTmedia)
misDatos2$Mes<-as.factor(misDatos2$Mes)
## Medidas de resumen
summary(misDatos2$PromedioTmedia) #general
tapply(misDatos2$PromedioTmedia,misDatos2$Mes,summary) #por mes

misDatos2%>%
  ggplot(aes(x=PromedioTmedia))+
  geom_histogram(colour="black",binwidth = 1) ## cuidado con los agregados!!! 

misDatos2%>%
  ggplot(aes(x=PromedioTmedia))+
  geom_histogram(colour="black",binwidth = 1)+
  facet_wrap(~Mes,scales = "free")

misDatos%>% #del paso anterior
  ggplot(aes(x=Tmedia))+
  geom_histogram(colour="black",binwidth = 1)+
  facet_wrap(~Mes,scales = "free")

# Un poco de práctica: "reciclemos" las últimas líneas y grafiquemos la variable PP ####


## Variabilidad
sd(misDatos2$PromedioTmedia,na.rm = TRUE)#tener en cuenta los datos faltantes
skewness(misDatos2$PromedioTmedia)

# Volvemos a nuestros datos simplificados
# Asignamos "índices" a nuestra serie ####
serieTmedia2<-ts(misDatos2$PromedioTmedia, start = c(1987,1), frequency = 12) #ojo! la frecuencia
autoplot(serieTmedia2) 
sum(is.na(serieTmedia2))
serieTmedia2<-tsclean(serieTmedia2,replace.missing = TRUE)
autoplot(serieTmedia2)

####VAMOS A DESCOMPONER LA SERIE......
# "Decompose"
serieDescompuesta<-decompose(serieTmedia2, type = "additive")
autoplot(serieDescompuesta)
class(serieDescompuesta)
plot(serieDescompuesta$trend)
abline(reg = lm(serieTmedia2~time(serieTmedia2))) ###visualizamos si existe tendencia lineal
?decompose
plot(serieTmedia2- serieDescompuesta$seasonal)
plot(serieTmedia2- serieDescompuesta$trend)
plot(serieTmedia2)
#"Stl": “Seasonal and Trend decomposition using Loess”. Loess is a method for estimating nonlinear relationships
serieDescompuesta2<-stl(serieTmedia2,t.window=13, 
                        s.window="periodic", robust=TRUE)
autoplot(serieDescompuesta2)

#"Perfil" estacional
ggseasonplot(serieTmedia2,
             year.labels=TRUE, year.labels.left=TRUE)

# Estacionariedad #######################

#¿Nuestra serie cumple con el criterio de "estacionariedad?? ANÁLISIS DE TENDENCIAS####
Acf(serieTmedia2) 
Pacf(serieTmedia2)
adf.test(serieTmedia2) #### p-valor < 0.05, excelente (Dickey Fuller)
kpss.test(serieTmedia2) ##### p-valor > 0.05, tambien excelente!!! (es distinto a adf)
pp.test(serieTmedia2) #### p-valor < 0.05, excelente (el criterio es el mismo que adf)
ndiffs(serieTmedia2) #### es decir, no es necesario diferenciar!!!!!!!!!!!!
?MannKendall #No paramétrico; H0: No hay tendencia
MannKendall(serieTmedia2) ### !!!!!!!!!
SeasonalMannKendall(serieTmedia2)
# y Mann Kendall para pp??
pp<-misDatos$PP
ppts<-ts(pp, start = c(1987,1), frequency = 365.25)
# Realizar la prueba


#VALIDACIÓN DE DATOS CLIMÁTICOS: SENSORES REMOTOS VS OBSERVACIONES EN ESTACIONES ####
##GIOVANNI: JUJUY AERO
vpp<-read.xlsx("validacionPP.xlsx",sheetIndex = 1,header = TRUE,encoding = "UTF-8")
vpp$Mes<-as.factor(vpp$Mes)
ggpairs(vpp[,c(4:6)],upper = list(
  continuous = wrap('cor', method = "pearson")
),aes(alpha=0.65))
#y por mes?
ggpairs(vpp[vpp$Mes=="1",c(4:6)],upper = list( #enero
  continuous = wrap('cor', method = "pearson")
),aes(alpha=0.65))


sup<-vpp$Superficie #valores observados en superficie
trmm<-vpp$TRMM #satélite TRMM
gpm<-vpp$GPM #satélite GPM


#ERROR CUADRÁTICO MEDIO ####
#ECM PARA TRMM
qdtrmm<-mean((trmm-sup)^2)
ecm.TRMM.Sup<-sqrt(qdtrmm)
# ECM PARA GPM??

#SESGO PORCENTUAL ####
#SP para TRMM
sp.TRMM.sup<-sum(trmm-sup)/sum(sup)
#SP para GPM?

#COEFICIENTE DE CORRELACIÓN####
#CC para TRMM
cor.test(trmm,sup,method = "pearson") #Pearson
cor.test(trmm,sup,method = "spearman") #Spearman (n.p.)
cor.test(trmm,sup,method = "kendall") #Kendall (n.p.)
