# 1. Cargar librerias
# Objetivo: cargar todas las librerías que usa el proyecto
# Uso     : se ejecuta al inicio de cada script con
#           source(here::here("scripts", "01_cargar_librerias.R"))
# install.packages(c("here", "readxl", "dplyr", "readr", "tidyr", "ggplot2"))
library(here)      # rutas relativas a la raíz del proyecto
library(readxl)    # leer archivos Excel
library(dplyr)     # manipulación de datos
library(readr)     # leer y escribir CSV
library(tidyr)     # reorganizar tablas (formato largo/ancho)
library(purrr)     # aplicar funciones a cada grupo (map)
library(ggplot2)   # gráficos  
