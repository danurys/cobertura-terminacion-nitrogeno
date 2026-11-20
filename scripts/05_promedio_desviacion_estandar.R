# Promedio y desviación estándar
# Objetivo: determinar promedio y desviación estándar por tratamiento
# Entrada: datos/02_datos_procesados/datos_procesados.csv
# Salida : tablas/01_promedio_desviacion.csv
source(here::here("scripts", "01_cargar_librerias.R"))

# 1. Cargar los datos procesados -----------------------------------
datos_procesados <- read_csv(
  here("datos", "02_datos_procesados", "datos_procesados.csv"),
  col_types = cols(
    bloque      = col_factor(),
    parcela     = col_character(),
    cobertura   = col_factor(c("Avena", "Multiespecies", "Barbecho")),
    terminacion = col_factor(c("Pastoreo", "Incorporación", "Corte y retiro",
                               "Sin terminación")),
    .default    = col_double()))
glimpse(datos_procesados)

# 2. Datos anidados: group_by + nest ---------------------------------
# Una fila por tratamiento; la columna 'data' guarda las parcelas de cada uno
datos_anidados <- datos_procesados |>
  group_by(cobertura, terminacion) |>
  nest() |>
  ungroup()

print(datos_anidados)
# View(datos_anidados)       # abre la tabla anidada en el visor de RStudio

# Guardar la tabla anidada; el .csv lista las parcelas de cada grupo
datos_anidados |>
  mutate(n_parcelas = map_int(data, nrow),
         parcelas = map_chr(data, ~ paste(.x$parcela, collapse = ", "))) |>
  select(-data) |>
  write_excel_csv(here("tablas", "01_datos_anidados.csv"))


# 3. Promedio y desviación estándar con map ------------------------
resumen <- datos_anidados |>
  mutate(
    n = map_int(data, nrow),
    estadisticos = map(data, ~ summarise(.x, across(
      c(amonio_mg_kg, nitrato_mg_kg, lixiviacion_nitrato_kgN_ha),
      list(media = ~ mean(.x, na.rm = TRUE), sd = ~ sd(.x, na.rm = TRUE)))))) |>
  select(-data) |>
  unnest(estadisticos) |>
  mutate(across(where(is.numeric), ~ round(.x, 2)))

print(resumen, width = Inf)

# 4. Guardar la tabla (UTF-8 con BOM para que Excel muestre las tildes)
write_excel_csv(resumen, here("tablas", "02_promedio_desviacion_estandar.csv"))