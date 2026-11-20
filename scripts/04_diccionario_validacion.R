# Crear diccionarioy validar los datos
# Objetivo: crear el diccionario y validar los datos procesados
# Entrada : datos/02_datos_procesados/datos_procesados.csv
# Salidas : diccionario_validacion/01_diccionario.csv
#           diccionario_validacion/02_validacion_datos.csv

source(here::here("scripts", "01_cargar_librerias.R"))

# 1. Cargar y explorar los datos procesados -----------------------
datos_procesados <- read_csv(
  here("datos", "02_datos_procesados", "datos_procesados.csv"),
  col_types = cols(.default = col_character(), amonio_mg_kg = col_double(),
                   nitrato_mg_kg = col_double(),
                   lixiviacion_nitrato_kgN_ha = col_double()))
glimpse(datos_procesados)

# 2. Reglas (se usan en el diccionario y en la validación) --------
categorias <- list(
  bloque      = as.character(1:4),
  cobertura   = c("Avena", "Multiespecies", "Barbecho"),
  terminacion = c("Pastoreo", "Incorporación", "Corte y retiro", "Sin terminación"))
rangos <- tibble(variable = c("amonio_mg_kg", "nitrato_mg_kg",
                              "lixiviacion_nitrato_kgN_ha"),
                 minimo = 0, maximo = c(20, 30, 50))

# 3. Diccionario de datos -----------------------------------------
diccionario <- tibble(
  nombre_variable = c("bloque", "parcela", "cobertura", "terminacion", rangos$variable),
  etiqueta = c("Bloque", "Parcela", "Cobertura", "Terminación",
               "Amonio disponible", "Nitrato disponible", "Lixiviación de nitrato"),
  descripcion = c(
    "Bloque experimental de la parcela", "Identificador de la parcela",
    "Tipo de cobertura; Barbecho es el control",
    "Forma de terminación; el barbecho no tiene terminación",
    "Amonio (NH₄⁺) disponible en el suelo, por parcela",
    "Nitrato (NO₃⁻) disponible en el suelo, por parcela",
    "Pérdida de nitrato (NO₃⁻) por lixiviación, por parcela"),
  tipo_dato = c("Categórico (factor)", "Texto", rep("Categórico (factor)", 2),
                rep("Numérico", 3)),
  unidad = c(rep("No aplica", 4), "mg/kg", "mg/kg", "kg N/ha"),
  valores_validos = c(
    paste(categorias$bloque, collapse = ", "), "Código de tres dígitos, único",
    paste(categorias$cobertura, collapse = "; "),
    paste(categorias$terminacion, collapse = "; "),
    paste0("> ", rangos$minimo, " y ≤ ", rangos$maximo)),
  valores_faltantes = c(rep("No admite valores faltantes", 4),
                        rep("Admite NA (se codifica como NA)", 3)))

# 4. Validación a partir del diccionario --------------------------
stopifnot(setequal(names(datos_procesados), diccionario$nombre_variable))
ctrl <- function(variable, control, criterio, mal, informativo = FALSE) {
  tibble(variable, control, criterio, n_revisados = length(mal), n_casos = sum(mal),
         resultado = if (informativo) "Informativo" else if (any(mal)) "No cumple"
         else "Cumple",
         detalle = paste(datos_procesados$parcela[mal], collapse = ", "))
}
validacion <- bind_rows(
  lapply(c(names(categorias), "parcela"), function(v) {
    x <- datos_procesados[[v]]
    bind_rows(ctrl(v, "Valores faltantes", "No admite NA", is.na(x)),
              if (v == "parcela") ctrl(v, "Valores únicos", "Sin duplicados",
                                       duplicated(x) | duplicated(x, fromLast = TRUE))
              else ctrl(v, "Categorías válidas", paste(categorias[[v]], collapse = "; "),
                        !is.na(x) & !(x %in% categorias[[v]])))
  }),
  lapply(seq_len(nrow(rangos)), function(i) {
    v <- rangos$variable[i]; x <- datos_procesados[[v]]
    lo <- rangos$minimo[i]; hi <- rangos$maximo[i]
    bind_rows(ctrl(v, "Valores faltantes", "Admite NA (solo se informa)", is.na(x),
                   informativo = TRUE),
              ctrl(v, "Rango válido", paste0("> ", lo, " y ≤ ", hi),
                   !is.na(x) & (x <= lo | x > hi)))
  }),
  ctrl("(todas)", "Datos ausentes", "Filas con algún NA (solo se informa)",
       !complete.cases(datos_procesados), informativo = TRUE),
  ctrl("cobertura / terminacion", "Coherencia", "Sin terminación solo en Barbecho",
       xor(datos_procesados$cobertura == "Barbecho",
           datos_procesados$terminacion == "Sin terminación") %in% TRUE))
print(validacion, n = Inf, width = Inf)
message(if (any(validacion$resultado == "No cumple")) "Hay controles que no se cumplen"
        else "Todos los controles se cumplen")
# 5. Guardar (UTF-8 con BOM para que Excel muestre las tildes) ----
write_excel_csv(diccionario, here("diccionario_validacion", "01_diccionario.csv"))
write_excel_csv(validacion, here("diccionario_validacion", "02_validacion_datos.csv"))