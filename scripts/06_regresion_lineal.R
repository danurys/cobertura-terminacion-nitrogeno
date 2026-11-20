# Relación entre las variables nitrato disponible en el suelo y lixiviación de nitrato
# Objetivo: determinar correlación y regresión lineal entre el nitrato disponible en 
# el suelo y la lixiviación de nitrato
# Entrada: datos/02_datos_procesados/datos_procesados.csv
# Salida : tablas/03_regresion_nitrato_lixiviacion.csv

source(here::here("scripts", "01_cargar_librerias.R"))

# 1. Cargar los datos procesados -----------------------------------
datos_procesados <- read_csv(
  here("datos", "02_datos_procesados", "datos_procesados.csv"),
  show_col_types = FALSE)
glimpse(datos_procesados)

# 2. Modelo lineal: lixiviación (respuesta) ~ nitrato (explicativa) --
modelo <- lm(lixiviacion_nitrato_kgN_ha ~ nitrato_mg_kg, data = datos_procesados)
resumen_modelo <- summary(modelo)
print(resumen_modelo)

# 3. Tabla de resultados -------------------------------------------
coeficientes <- resumen_modelo$coefficients
tabla_regresion <- tibble(
  variable_respuesta       = "lixiviacion_nitrato_kgN_ha",
  variable_explicativa     = "nitrato_mg_kg",
  n                        = nobs(modelo),
  r_cuadrado               = resumen_modelo$r.squared,
  r_cuadrado_ajustado      = resumen_modelo$adj.r.squared,
  intercepto               = coeficientes[1, "Estimate"],
  pendiente                = coeficientes[2, "Estimate"],
  error_estandar_pendiente = coeficientes[2, "Std. Error"],
  valor_p_pendiente        = coeficientes[2, "Pr(>|t|)"]
) |>
  mutate(across(where(is.numeric), ~ signif(.x, 4)))

print(tabla_regresion, width = Inf)

# 4. Guardar la tabla (UTF-8 con BOM para que Excel muestre las tildes)
write_excel_csv(tabla_regresion,
                here("tablas", "03_regresion_nitrato_lixiviacion.csv"))