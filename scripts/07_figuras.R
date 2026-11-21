# Figuras de las tablas de los scripts 5 y 6 (ggplot2)
# Entradas: tablas/02_promedio_desviacion_estandar.csv
#           tablas/03_regresion_nitrato_lixiviacion.csv y 04_regresion_amonio_lixiviacion.csv
# Salidas : figuras/01_amonio_nitrato, 02_lixiviacion_nitrato, 03_regresion_nitrato_lixiviacion y 
#           04_regresion_amonio_lixiviacion (.png)
source(here::here("scripts", "01_cargar_librerias.R"))
dir.create(here("figuras"), showWarnings = FALSE)  # crea la carpeta si no existe

# 1. Colores, tema y medidas de las figuras --------------------------
colores <- c(amonio = "#8F6798", nitrato = "#7ABCBA",
             reg_nitrato = viridisLite::plasma(5)[3], reg_amonio = "#BE81D3")
theme_set(theme_minimal(base_size = 12) +
            theme(legend.position = "bottom", legend.title = element_blank(),
                  panel.grid.minor = element_blank(), plot.title.position = "plot",
                  plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5),
                  plot.caption = element_text(hjust = 0, size = 9, color = "grey30"),
                  plot.caption.position = "plot"))
anchos <- list(g1 = 9, g2 = 8, reg = 7)  # ancho de cada figura en pulgadas
# Pie de figura: el texto se corta para ocupar todo el ancho de la figura
pie <- function(texto, ancho) paste(strwrap(texto, width = floor((ancho - 0.4) * 16)),
                                    collapse = "\n")

# 2. Cargar tablas y datos -------------------------------------------
leer <- function(archivo) read_csv(here("tablas", archivo), show_col_types = FALSE)
resumen <- leer("02_promedio_desviacion_estandar.csv") |>
  mutate(cobertura = factor(cobertura, levels = c("Avena", "Multiespecies", "Barbecho")),
         terminacion = factor(terminacion, levels = c("Pastoreo", "Incorporación",
                                                      "Corte y retiro", "Sin terminación"))) |>
  arrange(cobertura, terminacion) |>
  mutate(tratamiento = if_else(cobertura == "Barbecho", "Barbecho (control)",
                               paste(cobertura, terminacion, sep = " + ")),
         tratamiento = factor(tratamiento, levels = unique(tratamiento)))
reg_nitrato <- leer("03_regresion_nitrato_lixiviacion.csv")
reg_amonio  <- leer("04_regresion_amonio_lixiviacion.csv")
datos_procesados <- read_csv(here("datos", "02_datos_procesados", "datos_procesados.csv"),
                             show_col_types = FALSE)
nota_n <- sprintf("n = %d parcelas por tratamiento (%d en el barbecho). Datos simulados.",
                  unique(resumen$n[resumen$cobertura != "Barbecho"]),
                  resumen$n[resumen$cobertura == "Barbecho"])

# 3. Subtítulos con la conclusión (se calculan a partir de las tablas) ---
mejor_n <- slice_max(resumen, amonio_mg_kg_media + nitrato_mg_kg_media, n = 1, with_ties = FALSE)
mejor_l <- slice_min(resumen, lixiviacion_nitrato_kgN_ha_media, n = 1, with_ties = FALSE)
sub1 <- sprintf("%s, con la mayor disponibilidad de nitrógeno mineral",
                as.character(mejor_n$tratamiento))
sub2 <- sprintf("%s, con la menor lixiviación de nitrato (%.1f kg N/ha)",
                as.character(mejor_l$tratamiento), mejor_l$lixiviacion_nitrato_kgN_ha_media)
relacion <- function(tabla, variable) {
  if (tabla$valor_p_pendiente >= 0.05)
    return(sprintf("Sin relación significativa entre %s y la lixiviación (p = %.2f)",
                   variable, tabla$valor_p_pendiente))
  sprintf("Relación %s %s: a mayor %s %s lixiviación (R² = %.2f)",
          if (tabla$pendiente < 0) "negativa" else "positiva",
          if (tabla$r_cuadrado >= 0.7) "fuerte" else if (tabla$r_cuadrado >= 0.4) "moderada" else "débil",
          variable, if (tabla$pendiente < 0) "menor" else "mayor", tabla$r_cuadrado)
}

# 4. Amonio y nitrato: barras agrupadas con desviación estándar ------
mg_kg <- resumen |>
  pivot_longer(c(starts_with("amonio"), starts_with("nitrato")),
               names_to = c("variable", ".value"),
               names_pattern = "(amonio|nitrato)_mg_kg_(media|sd)") |>
  mutate(variable = recode(variable, amonio = "Amonio disponible",
                           nitrato = "Nitrato disponible"))
g1 <- ggplot(mg_kg, aes(tratamiento, media, fill = variable)) +
  geom_col(position = position_dodge(0.8), width = 0.7) +
  geom_errorbar(aes(ymin = media - sd, ymax = media + sd),
                position = position_dodge(0.8), width = 0.25) +
  scale_fill_manual(values = c("Amonio disponible" = colores[["amonio"]],
                               "Nitrato disponible" = colores[["nitrato"]])) +
  scale_x_discrete(guide = guide_axis(angle = 30)) +
  labs(title = "Amonio y nitrato disponibles en el suelo", subtitle = sub1,
       x = NULL, y = "Concentración (mg/kg)",
       caption = pie(paste("Figura 1. Concentración promedio de amonio y nitrato disponibles en el",
                           "suelo según cobertura y forma de terminación. Las barras de error",
                           "indican la desviación estándar.", nota_n), anchos$g1))
ggsave(here("figuras", "01_amonio_nitrato.png"), g1, width = anchos$g1, height = 6.5, dpi = 300)

# 5. Lixiviación de nitrato: barras horizontales (degradado azul-verde) ---
lim_y <- ceiling(max(resumen$lixiviacion_nitrato_kgN_ha_media +
                       resumen$lixiviacion_nitrato_kgN_ha_sd, na.rm = TRUE) / 5) * 5
# Colores de viridis en tonos pastel (mezclados con 45 % de blanco). El azul queda abajo y el verde arriba
paleta <- viridisLite::viridis(nlevels(resumen$tratamiento), begin = 0.25, end = 0.8)
paleta <- rgb(t(col2rgb(paleta) * 0.55 + 255 * 0.45), maxColorValue = 255)
barras_sd <- aes(ymin = lixiviacion_nitrato_kgN_ha_media - lixiviacion_nitrato_kgN_ha_sd,
                 ymax = lixiviacion_nitrato_kgN_ha_media + lixiviacion_nitrato_kgN_ha_sd)
g2 <- resumen |>
  mutate(tratamiento = factor(tratamiento, levels = rev(levels(tratamiento)))) |>
  ggplot(aes(tratamiento, lixiviacion_nitrato_kgN_ha_media, fill = tratamiento)) +
  geom_col(width = 0.6) +
  geom_errorbar(barras_sd, width = 0.25) + 
  scale_fill_manual(values = paleta, guide = "none") +
  scale_y_continuous(limits = c(0, lim_y), breaks = seq(0, lim_y, by = 5),
                     expand = expansion(mult = c(0, 0.02))) +
  coord_flip() +
  labs(title = "Lixiviación de nitrato", subtitle = sub2,
       x = NULL, y = "Lixiviación de nitrato (kg N/ha)",
       caption = pie(paste("Figura 2. Lixiviación de nitrato (kg N/ha), promedio según cobertura y",
                           "forma de terminación. Las barras de error indican la desviación",
                           "estándar.", nota_n), anchos$g2))
ggsave(here("figuras", "02_lixiviacion_nitrato.png"), g2, width = anchos$g2, height = 5.5, dpi = 300)

# 6. Regresiones lineales: dispersión + recta del modelo -----------
grafico_regresion <- function(x, tabla, color, variable, figura, archivo) {
  etiqueta <- sprintf("y = %.2f %+.2f x\nR² = %.3f\n%s", tabla$intercepto, tabla$pendiente,
                      tabla$r_cuadrado, if (tabla$valor_p_pendiente < 0.001) "p < 0.001"
                      else sprintf("p = %.3f", tabla$valor_p_pendiente))
  g <- ggplot(datos_procesados, aes(.data[[x]], lixiviacion_nitrato_kgN_ha)) +
    geom_point(color = color, size = 2.6, alpha = 0.8) +
        geom_abline(intercept = tabla$intercepto, slope = tabla$pendiente,
                color = color, linewidth = 1.2) +
    annotate("text", x = Inf, y = Inf, label = etiqueta, hjust = 1.1, vjust = 1.3) +
    labs(title = sprintf("Relación entre %s y lixiviación de nitrato", variable),
         subtitle = relacion(tabla, variable),
         x = paste0(toupper(substr(variable, 1, 1)), substring(variable, 2), " (mg/kg)"),
         y = "Lixiviación de nitrato (kg N/ha)",
         caption = pie(paste0("Figura ", figura, ". Relación entre el ", variable,
                              " en el suelo y la lixiviación de nitrato. Cada punto es una parcela (n = ",
                              tabla$n, "); la línea es el modelo de regresión lineal ajustado con lm(). ",
                              "Datos simulados."), anchos$reg))
  ggsave(here("figuras", archivo), g, width = anchos$reg, height = 5.5, dpi = 300)
  g
}
g3 <- grafico_regresion("nitrato_mg_kg", reg_nitrato, colores[["reg_nitrato"]],
                        "nitrato disponible", 3, "03_regresion_nitrato_lixiviacion.png")
g4 <- grafico_regresion("amonio_mg_kg", reg_amonio, colores[["reg_amonio"]],
                        "amonio disponible", 4, "04_regresion_amonio_lixiviacion.png")