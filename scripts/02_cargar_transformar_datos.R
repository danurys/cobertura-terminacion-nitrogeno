# Cargar y transformar datos
# Objetivo: cargar el archivo que contiene los datos crudos, explorar su estructura, traducir
#           y ordenar la tabla, y guardarla como CSV
# Entrada : datos/01_datos_crudos/datos_crudos.xlsx  (NO se modifica)
# Salida  : datos/02_datos_procesados/datos_procesados.csv


source(here::here("scripts", "01_cargar_librerias.R"))

# 1. Cargar datos crudos ----------------------------------------
datos_crudos <- read_excel(here("datos", "01_datos_crudos", "datos_crudos.xlsx"))

# 2. Explorar la estructura de los datos crudos -------------------
glimpse(datos_crudos)

# 3. Transformar: nombres, categorías y variables en español ----------------
datos_procesados <- datos_crudos |>
  transmute(
    bloque      = factor(Block),
    parcela     = as.character(Parcel),
    cobertura   = factor(
      recode(Crop, "Oat" = "Avena", "Multispecies" = "Multiespecies",
             "Fallow" = "Barbecho"),
      levels = c("Avena", "Multiespecies", "Barbecho")),
    terminacion = factor(
      recode(Treatment, "Grazing" = "Pastoreo", "Incorporation" = "Incorporación",
             "Soiling" = "Corte y retiro", "Fallow" = "Sin terminación"),
      levels = c("Pastoreo", "Incorporación", "Corte y retiro", "Sin terminación")),
    amonio_mg_kg               = round(`Available ammonium  (mg/kg)`, 1),
    nitrato_mg_kg              = round(`Available nitrate  (mg/kg)`, 1),
    lixiviacion_nitrato_kgN_ha = round(`Leaching of Nitrate (kgN/ha)`, 1)
  )

str(datos_procesados)

# 4. Guardar como CSV (UTF-8) ------------------------------------
write_csv(datos_procesados,
          here("datos", "02_datos_procesados", "datos_procesados.csv"))