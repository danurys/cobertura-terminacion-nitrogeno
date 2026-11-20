# Figuras de las tablas de los scripts 5 y 6 (ggplot2)
# Entradas: tablas/02_promedio_desviacion_estandar.csv, tablas/03_regresion_nitrato_lixiviacion.csv
# Salidas : figuras/01_amonio_nitrato..., 02_lixiviacion_nitrato... y 03_regresion_nitrato_lixiviacion... (.png)
source(here::here("scripts", "01_cargar_librerias.R"))

# 1. Colores (viridis, aptos para daltonismo) y tema ---------------
colores <- c(amonio = "#8F6798", nitrato = "#7ABCBA",
             lixiviacion = "#9EDEA1", regresion = viridisLite::plasma(5)[3])
theme_set(theme_minimal(base_size = 12) +
            theme(legend.position = "bottom", legend.title = element_blank(),
                  panel.grid.minor = element_blank(),
                  plot.caption = element_text(hjust = 0, size = 9, color = "grey30"),
                  plot.caption.position = "plot"))
pie <- function(texto) paste(strwrap(texto, width = 95), collapse = "\n")  # ajusta el texto

# 2. Cargar tablas y datos -------------------------------------------
resumen <- read_csv(here("tablas", "02_promedio_desviacion_estandar.csv"), show_col_types = FALSE) |>
  mutate(cobertura = factor(cobertura, levels = c("Avena", "Multiespecies", "Barbecho")),
         terminacion = factor(terminacion, levels = c("Pastoreo", "Incorporación",
                                                      "Corte y retiro", "Sin terminación"))) |>
  arrange(cobertura, terminacion) |>
  mutate(tratamiento = if_else(cobertura == "Barbecho", "Barbecho (control)",
                               paste(cobertura, terminacion, sep = " + ")),
         tratamiento = factor(tratamiento, levels = unique(tratamiento)))
regresion <- read_csv(here("tablas", "03_regresion_nitrato_lixiviacion.csv"),
                      show_col_types = FALSE)
datos_procesados <- read_csv(here("datos", "02_datos_procesados", "datos_procesados.csv"),
                             show_col_types = FALSE)
nota_n <- sprintf("n = %d parcelas por tratamiento (%d en el barbecho). Datos simulados.",
                  unique(resumen$n[resumen$cobertura != "Barbecho"]),
                  resumen$n[resumen$cobertura == "Barbecho"])

# 3. Amonio y nitrato: promedio ± desviación estándar (barras agrupadas)
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
  labs(title = "Amonio y nitrato disponibles en el suelo",
       subtitle = "Promedio ± desviación estándar por tratamiento",
       x = NULL, y = "Concentración (mg/kg)",
       caption = pie(paste("Figura 1. Concentración promedio de amonio y nitrato disponibles en el",
                           "suelo según cobertura y forma de terminación. Las barras de error",
                           "representan la desviación estándar.", nota_n)))
ggsave(here("figuras", "01_amonio_nitrato.png"), g1, width = 9, height = 6.5, dpi = 300)

# 4. Lixiviación de nitrato: barras horizontales -------------------
g2 <- ggplot(resumen, aes(factor(tratamiento, levels = rev(levels(tratamiento))),
                          lixiviacion_nitrato_kgN_ha_media)) +
  geom_col(fill = colores[["lixiviacion"]], color = "grey25", width = 0.7) +
  geom_errorbar(aes(ymin = lixiviacion_nitrato_kgN_ha_media - lixiviacion_nitrato_kgN_ha_sd,
                    ymax = lixiviacion_nitrato_kgN_ha_media + lixiviacion_nitrato_kgN_ha_sd),
                width = 0.25) +
  coord_flip() +
  labs(title = "Lixiviación de nitrato", subtitle = "Promedio ± desviación estándar por tratamiento",
       x = NULL, y = "Lixiviación de nitrato (kg N/ha)",
       caption = pie(paste("Figura 2. Lixiviación de nitrato (kg N/ha), promedio según cobertura y",
                           "forma de terminación. Las barras de error representan la desviación",
                           "estándar.", nota_n)))
ggsave(here("figuras", "02_lixiviacion_nitrato.png"), g2, width = 8, height = 5.5, dpi = 300)

# 5. Regresión lineal: nitrato vs lixiviación (dispersión + recta) -
etiqueta <- sprintf("y = %.2f %+.2f x\nR² = %.3f\n%s", regresion$intercepto, regresion$pendiente,
                    regresion$r_cuadrado, if (regresion$valor_p_pendiente < 0.001) "p < 0.001"
                    else sprintf("p = %.3f", regresion$valor_p_pendiente))
g3 <- ggplot(datos_procesados, aes(nitrato_mg_kg, lixiviacion_nitrato_kgN_ha)) +
  geom_point(color = colores[["regresion"]], size = 2.5, alpha = 0.8) +
  geom_abline(intercept = regresion$intercepto, slope = regresion$pendiente,
              color = colores[["regresion"]], linewidth = 1) +
  annotate("text", x = Inf, y = Inf, label = etiqueta, hjust = 1.1, vjust = 1.3) +
  labs(title = "Relación entre nitrato disponible y lixiviación de nitrato",
       x = "Nitrato disponible (mg/kg)", y = "Lixiviación de nitrato (kg N/ha)",
       caption = pie(paste0("Figura 3. Relación entre el nitrato disponible en el suelo y la ",
                            "lixiviación de nitrato. Cada punto es una parcela (n = ", regresion$n,
                            "); la línea es el modelo de regresión lineal ajustado con lm(). ",
                            "Datos simulados.")))
ggsave(here("figuras", "03_regresion_nitrato_lixiviacion.png"), g3, width = 7, height = 5.5, dpi = 300)