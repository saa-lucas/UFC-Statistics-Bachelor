################################
################################
### Carregando pacotes necessários
library(geobr)    # Para obter shapes do Brasil
library(sf)       # Para trabalhar com dados espaciais
library(dplyr)    # Para manipulação de dados
library(ggplot2)  # Para visualização
library(geoR)     # Para análise geoestatística

#########################
#########################
##### Processo Pontual ##
#########################

# PASSO 1: OBTER O MAPA BASE
# Buscamos o shapefile do Paraná para usar como área de estudo
pr_map <- read_state(code_state = "PR", year = 2020)

# Visualização rápida do mapa
ggplot() +
  geom_sf(data = pr_map, fill = "lightblue", color = "black", size = 0.5) +
  labs(title = "Mapa Base - Estado do Paraná",
       x = "Longitude", y = "Latitude")


# PASSO 2: SIMULAR DADOS ESPACIAIS
# Criamos pontos aleatórios com valores associados para simular dados reais
set.seed(6789) # Define semente para reproduzir os mesmos resultados

n_points <- 50
data_points <- data.frame(
  lon = runif(n_points, min = -54, max = -50),   # Longitude dentro do PR
  lat = runif(n_points, min = -26, max = -23),   # Latitude dentro do PR
  value = runif(n_points, min = 10, max = 100)   # Valores simulados
)

# PASSO 3: VISUALIZAR PROCESSO PONTUAL
# Mostra os pontos no mapa, com tamanho proporcional ao valor
ggplot() +
  geom_sf(data = pr_map, fill = "white", color = "black", size = 0.3) +
  geom_point(data = data_points, 
             aes(x = lon, y = lat, size = value), 
             color = "blue", alpha = 0.7) +
  scale_size_continuous(range = c(2, 8), name = "Valor") +
  labs(title = "Processo Pontual - Dados Simulados no Paraná",
       x = "Longitude", y = "Latitude") +
  theme_minimal()

################################################################################
### ANÁLISE GEOESTATÍSTICA - VARIOGRAMA E KRIGAGEM- Parte 01
################################################################################

# PASSO 4: CONVERTER PARA OBJETO GEOESTATÍSTICO
# O geoR precisa dos dados no formato 'geodata' para análise
geo_data <- as.geodata(data_points, coords.col = c("lon", "lat"), data.col = "value")

# PASSO 5: CALCULAR O SEMIVARIOGRAMA EXPERIMENTAL
# O variograma medida como a dissimilaridade entre pontos muda com a distância (processo estocástico espacial)

vario <- variog(geo_data, 
                max.dist = 1,    # Distância máxima para análise
                bin.cloud = TRUE) # Mostra nuvem de pontos

# Visualizar o variograma experimental
plot(vario, main = "Semivariograma Experimental")
# Pontos: semivariância calculada para cada distância
# Linha: tendência geral da dependência espacial

# PASSO 6: AJUSTAR MODELO TEÓRICO AO VARIOGRAMA
# Encontramos a curva matemática que melhor descreve o padrão espacial

vario_model <- variofit(vario, 
                        cov.model = "linear",  # Tipo de modelo (linear, exponencial, etc.)
                        nugget = 5,            # Efeito pepita (variação em distância zero)
                        ini.cov.pars = c(50, 0.5)) # Valores iniciais para ajuste

summary(vario_model) # Mostra parâmetros do modelo ajustado
lines(vario_model, col = "red") # Adiciona modelo ao gráfico

?variofit


####### PARÂMETROS DO VARIOFIT EXPLICADOS:

# • `cov.model = "linear"`: 
#   - Modelo de covariância linear - crescimento constante sem patamar definido
#   - Fórmula: γ(h) = nugget + psill × h
#   - Use quando a dependência espacial não satura no alcance estudado

# • `nugget = 5`:
#   - Efeito pepita fixo em 5 unidades
#   - Representa variabilidade em escala muito pequena (erro + micro-escala)
#   - Em modelos mais robustos, deixamos `fix.nugget = FALSE` para estimar automaticamente

# • `ini.cov.pars = c(50, 0.5)`:
#   - Valores iniciais para o algoritmo de otimização
#   - c(psill = 50, range = 0.5)
#   - Psill = patamar parcial (variabilidade estruturada espacialmente)
#   - Range = alcance (distância de influência espacial)

####### MODELOS ALTERNATIVOS RECOMENDADOS:

# Para uma análise mais robusta, considere usar:
#
# vario_model_robusto <- variofit(vario,
#     cov.model = "exponential",    # Modelo mais flexível com patamar definido
#     ini.cov.pars = c(50, 0.5),    # Valores iniciais (psill, range)
#     fix.nugget = FALSE,           # DEIXE estimar o nugget automaticamente!
#     nugget = 1,                   # Valor inicial para nugget
#     weights = "cressie",          # Pesos estatisticamente otimizados
#     minimisation.function = "optim") # Algoritmo robusto
#
# VANTAGENS DO MODELO ROBUSTO:
# 1. Exponential modela bem diversos tipos de dependência espacial
# 2. Nugget estimado é mais realista que nugget fixo
# 3. Pesos de Cressie dão menos peso a bins com poucos pares
# 4. Algoritmo 'optim' é menos sensível a valores iniciais





# COMPONENTES DO VARIOGRAMA:
# - Efeito Pepita (Nugget): Variabilidade em distância zero (erro + micro-escala)
# - Patamar (Sill): Variabilidade máxima quando a correlação espacial desaparece  
# - Alcance (Range): Distância onde atinge o patamar (limite da dependência espacial)

## INTERPRETAÇÃO DOS RESULTADOS:

# Os parâmetros do variograma ajustado nos dizem:
#
# • NUGGET (Efeito Pepita): Variabilidade em distância zero
#   - Exemplo: nugget = 2.5 → 2.5 unidades de variância não explicadas espacialmente
#
# • PSILL (Patamar Parcial): Variabilidade estruturada espacialmente  
#   - Exemplo: psill = 45.3 → 45.3 unidades de variância com padrão espacial
#
# • RANGE (Alcance): Distância onde a correlação espacional desaparece
#   - Exemplo: range = 0.62 → Pontos a mais de 0.62 graus são independentes
#
# • SILL (Patamar Total): nugget + psill → Variabilidade máxima

################################################################################
### INTERPOLAÇÃO POR KRIGAGEM

# PASSO 7: CRIAR GRADE REGULAR PARA INTERPOLAÇÃO
# Vamos criar pontos onde queremos estimar valores

# Grade retangular simples (para demonstração)
lon_range <- seq(min(data_points$lon), max(data_points$lon), length.out = 100)
lat_range <- seq(min(data_points$lat), max(data_points$lat), length.out = 100)
grid_rect <- expand.grid(lon = lon_range, lat = lat_range)

# PASSO 8: EXECUTAR KRIGAGEM NA GRADE RETANGULAR
# A krigagem usa o modelo do variograma para fazer interpolação ótima
krige_result_rect <- krige.conv(geo_data, 
                                loc = as.matrix(grid_rect), 
                                krige = krige.control(obj.model = vario_model))

grid_rect$value <- krige_result_rect$predict

# PASSO 9: VISUALIZAR MALHA DE INTERPOLAÇÃO INTERMEDIÁRIA
# Mostra a grade retangular com a interpolação
ggplot() +
  geom_tile(data = grid_rect, aes(x = lon, y = lat, fill = value), alpha = 0.7) +
  geom_sf(data = pr_map, fill = NA, color = "black", size = 0.5) +
  scale_fill_viridis_c(name = "Valor Interpolado") +
  geom_point(data = data_points, aes(x = lon, y = lat), color = "red", size = 1.5) +
  labs(title = "Malha de Interpolação - Grade Retangular",
       subtitle = "Pontos vermelhos: dados originais | Cores: valores interpolados",
       x = "Longitude", y = "Latitude") +
  theme_minimal()

################################################################################
### INTERPOLAÇÃO DENTRO DO POLÍGONO

# PASSO 10: CRIAR GRADE DENTRO DOS LIMITES DO ESTADO
# Método mais realista - só interpola dentro da área de interesse

pr_sf <- st_as_sf(pr_map) # Converter para formato sf

# Criar grade regular dentro do polígono
grid_polygon <- st_make_grid(pr_sf, 
                             cellsize = 0.05,  # Tamanho da célula em graus
                             what = "centers") %>% # Criar pontos no centro das células
  st_as_sf() %>% 
  st_filter(pr_sf)  # Manter apenas pontos dentro do polígono

# Extrair coordenadas
grid_coords <- st_coordinates(grid_polygon) %>% as.data.frame()
colnames(grid_coords) <- c("lon", "lat")

# PASSO 11: KRIGAGEM NA GRADE DO POLÍGONO
krige_result_poly <- krige.conv(geo_data, 
                                loc = as.matrix(grid_coords), 
                                krige = krige.control(obj.model = vario_model))

grid_coords$value <- krige_result_poly$predict

# PASSO 12: VISUALIZAÇÃO FINAL
ggplot() +
  geom_sf(data = pr_map, fill = "white", color = "black", size = 0.3) +
  geom_tile(data = grid_coords, aes(x = lon, y = lat, fill = value)) +
  scale_fill_viridis_c(name = "Interpolação") +
  geom_point(data = data_points, aes(x = lon, y = lat, size = value), 
             color = "red", alpha = 0.7) +
  scale_size_continuous(range = c(3, 8), name = "Valor Original") +
  labs(title = "Krigagem com Bolinhas Proporcionais - Paraná",
       subtitle = "Interpolação dentro do polígono com dados originais sobrepostos",
       x = "Longitude", y = "Latitude") +
  theme_minimal()






################################################################################
### VERIFICAÇÃO DO MODELO GEOESTATÍSTICO
################################################################################

# PASSO 13: VALIDAÇÃO CRUZADA (CROSS-VALIDATION)
# A validação cruzada remove cada ponto um por um e estima seu valor usando os demais
################################################################################
### VERIFICAÇÃO DO MODELO GEOESTATÍSTICO - VERSÃO CORRIGIDA
################################################################################

# PASSO 13: VALIDAÇÃO CRUZADA (CROSS-VALIDATION) - CORRIGIDO
cat("=== VALIDAÇÃO CRUZADA DO MODELO ===\n")

# Executar validação cruzada
xvalid <- xvalid(geo_data, model = vario_model)

# Verificar a estrutura do objeto xvalid
cat("Estrutura do objeto xvalid:\n")
print(names(xvalid))
cat("Número de predições:", length(xvalid$predicted), "\n")

# PASSO 14: ANÁLISE DOS RESÍDUOS DA VALIDAÇÃO CRUZADA - CORRIGIDO

# CORREÇÃO: Calcular os resíduos manualmente pois xvalid não tem $residuals
validation_df <- data.frame(
  observed = geo_data$data,           # Valores observados reais
  predicted = xvalid$predicted,       # Valores preditos na validação
  # residuals = observed - predicted (calculamos manualmente)
  std_error = sqrt(xvalid$krige.var)  # Erro padrão (raiz da variância)
)

# CALCULAR RESÍDUOS MANUALMENTE
validation_df$residuals <- validation_df$observed - validation_df$predicted

# Verificar se as dimensões estão corretas
cat("\n=== VERIFICAÇÃO DE DIMENSÕES ===\n")
cat("Número de observações:", nrow(validation_df), "\n")
cat("Primeiras linhas do validation_df:\n")
print(head(validation_df))

# PASSO 15: CÁLCULO DAS MÉTRICAS DE QUALIDADE
MSE <- mean(validation_df$residuals^2)          # Mean Squared Error
RMSE <- sqrt(MSE)                               # Root Mean Squared Error
MAE <- mean(abs(validation_df$residuals))       # Mean Absolute Error
bias <- mean(validation_df$residuals)           # Viés (deve ser próximo de zero)
correlation <- cor(validation_df$observed, validation_df$predicted) # Correlação

cat("\n=== MÉTRICAS DE VALIDAÇÃO ===\n")
cat("RMSE:", round(RMSE, 3), "\n")
cat("MAE:", round(MAE, 3), "\n") 
cat("Viés (Bias):", round(bias, 3), "\n")
cat("Correlação (Obs vs Pred):", round(correlation, 3), "\n")

# PASSO 16: GRÁFICOS DIAGNÓSTICOS

# Gráfico 1: Valores Observados vs Preditos
plot_obs_vs_pred <- ggplot(validation_df, aes(x = observed, y = predicted)) +
  geom_point(alpha = 0.7, color = "blue", size = 2) +
  labs(title = "Validação Cruzada: Observados vs Preditos",
       subtitle = paste("Correlação =", round(correlation, 3), 
                        "| RMSE =", round(RMSE, 3)),
       x = "Valores Observados", 
       y = "Valores Preditos") +
  theme_minimal()

print(plot_obs_vs_pred)

# Gráfico 2: Resíduos vs Valores Preditos
plot_residuals <- ggplot(validation_df, aes(x = predicted, y = residuals)) +
  geom_point(alpha = 0.7, color = "purple", size = 2) +
  geom_hline(yintercept = 0, color = "red", linetype = "dashed", size = 1) +
  labs(title = "Análise de Resíduos",
       subtitle = paste("Viés =", round(bias, 3), "| Ideal: resíduos centrados em zero"),
       x = "Valores Preditos", 
       y = "Resíduos (Observado - Predito)") +
  theme_minimal()

print(plot_residuals)

# Gráfico 3: Histograma dos Resíduos
plot_hist_residuals <- ggplot(validation_df, aes(x = residuals)) +
  geom_histogram(aes(y = ..density..), bins = 12, fill = "lightblue", alpha = 0.7) +
  geom_density(color = "darkblue", size = 1) +
  geom_vline(xintercept = 0, color = "red", linetype = "dashed", size = 1) +
  labs(title = "Distribuição dos Resíduos",
       subtitle = "Distribuição deve ser aproximadamente normal centrada em zero",
       x = "Resíduos", 
       y = "Densidade") +
  theme_minimal()

print(plot_hist_residuals)

# PASSO 17: ANÁLISE ESPACIAL DOS RESÍDUOS
spatial_residuals <- data.frame(
  lon = geo_data$coords[,1],
  lat = geo_data$coords[,2],
  residuals = validation_df$residuals,
  abs_residuals = abs(validation_df$residuals)
)

plot_spatial_residuals <- ggplot() +
  geom_sf(data = pr_map, fill = "white", color = "black", size = 0.3) +
  geom_point(data = spatial_residuals, 
             aes(x = lon, y = lat, color = residuals, size = abs_residuals), 
             alpha = 0.7) +
  scale_color_gradient2(low = "blue", mid = "white", high = "red", 
                        midpoint = 0, name = "Resíduos") +
  scale_size_continuous(range = c(2, 8), name = "|Resíduos|") +
  labs(title = "Distribuição Espacial dos Resíduos",
       subtitle = "Resíduos devem ser aleatórios no espaço (sem padrões)",
       x = "Longitude", y = "Latitude") +
  theme_minimal()

print(plot_spatial_residuals)

# PASSO 18: TESTES ESTATÍSTICOS
shapiro_test <- shapiro.test(validation_df$residuals)

cat("\n=== TESTES ESTATÍSTICOS ===\n")
cat("Teste de Normalidade de Shapiro-Wilk:\n")
cat("Estatística W:", round(shapiro_test$statistic, 4), "\n")
cat("Valor-p:", round(shapiro_test$p.value, 4), "\n")

if(shapiro_test$p.value > 0.05) {
  cat("Conclusão: Resíduos seguem distribuição normal (p > 0.05)\n")
} else {
  cat("Conclusão: Resíduos NÃO seguem distribuição normal (p <= 0.05)\n")
}

# PASSO 19: MAPA DE INCERTEZA
grid_coords$variance <- krige_result_poly$krige.var

plot_uncertainty <- ggplot() +
  geom_sf(data = pr_map, fill = "white", color = "black", size = 0.3) +
  geom_tile(data = grid_coords, aes(x = lon, y = lat, fill = variance)) +
  scale_fill_viridis_c(name = "Variância", option = "plasma") +
  geom_point(data = data_points, aes(x = lon, y = lat), color = "red", size = 1.5, alpha = 0.6) +
  labs(title = "Mapa de Incerteza da Krigagem",
       subtitle = "Áreas com maior variância têm maior incerteza nas predições",
       x = "Longitude", y = "Latitude") +
  theme_minimal()

print(plot_uncertainty)

# PASSO 20: INTERPRETAÇÃO FINAL
cat("\n=== INTERPRETAÇÃO DOS RESULTADOS ===\n")
cat("CRITÉRIOS DE AVALIAÇÃO:\n")
cat("1. RMSE e MAE: Quanto menor, melhor o modelo prediz\n")
cat("2. Viés (Bias): Idealmente entre -2 e 2 (próximo de zero)\n") 
cat("3. Correlação: Quanto mais próxima de 1, melhor\n")
cat("4. Resíduos: Devem ser aleatórios, sem padrões espaciais\n")
cat("5. Normalidade: Resíduos normais indicam modelo adequado\n")

# Avaliação prática do modelo
cat("\nAVALIAÇÃO DO SEU MODELO:\n")
if(abs(bias) < 10 && correlation > 0.3 && RMSE < sd(geo_data$data)) {
  cat("✅ MODELO CONSIDERADO ADEQUADO!\n")
  if(abs(bias) < 5) cat(" - Viés baixo (bom)\n") else cat(" - Viés moderado\n")
  if(correlation > 0.7) cat(" - Boa correlação\n") else cat(" - Correlação moderada\n")
  if(shapiro_test$p.value > 0.05) cat(" - Resíduos normais (bom)\n")
} else {
  cat("⚠️ MODELO PODE PRECISAR DE AJUSTES!\n")
  if(abs(bias) >= 10) cat(" - Viés muito alto\n")
  if(correlation <= 0.3) cat(" - Correlação muito baixa\n")
  if(RMSE >= sd(geo_data$data)) cat(" - Erro muito alto\n")
}

# Comparação com desvio padrão dos dados
cat("Desvio padrão dos dados originais:", round(sd(geo_data$data), 3), "\n")
cat("RMSE em relação ao desvio padrão:", round(RMSE/sd(geo_data$data), 3), "\n")

# PASSO 21: ANÁLISE DO VARIOGRAMA DOS RESÍDUOS
# Se o modelo for bom, os resíduos não devem ter estrutura espacial

# Converter resíduos para objeto geodata
residuals_geodata <- as.geodata(cbind(geo_data$coords, validation_df$residuals))

# Calcular variograma dos resíduos
vario_residuals <- variog(residuals_geodata, max.dist = 1)

plot(vario_residuals, main = "Variograma dos Resíduos",
     sub = "Se o modelo for bom, não deve mostrar estrutura espacial")
abline(h = var(validation_df$residuals), col = "red", lty = 2)
legend("topleft", legend = "Variância total dos resíduos", col = "red", lty = 2)

cat("\n=== ANÁLISE DO VARIOGRAMA DOS RESÍDUOS ===\n")
cat("Se o variograma dos resíduos for plano (sem estrutura), o modelo capturou\n")
cat("toda a dependência espacial dos dados. Se mostrar estrutura, o modelo\n") 
cat("pode estar mal especificado.\n")