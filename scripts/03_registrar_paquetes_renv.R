# Registrar paquetes usando renv
# Objetivo: registrar los paquetes y sus versiones para que el
#           proyecto sea reproducible

# 1. Instalar renv (una sola vez) -------------------------------
install.packages("renv")

# 2. Inicializar renv en el proyecto (una sola vez) -------------
renv::init()

# 3. Registrar los paquetes y sus versiones ---------------------
renv::snapshot()

# 4. Comprobar el estado del proyecto ---------------------------
renv::status()

# Más adelante:
# - Después de instalar un paquete nuevo o terminar una etapa:
#   renv::snapshot()
# - Si alguien clona el proyecto en otro computador:
#   renv::restore()