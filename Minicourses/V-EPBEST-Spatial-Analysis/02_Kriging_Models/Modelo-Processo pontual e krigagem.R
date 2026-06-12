################################
################################
### Carregando pacotes necessários
library(geobr)
library(sf)
library(dplyr)
library(ggplot2)


#########################
#########################
##### Processo pontual #
#########################

# Carregar pacotes
library(geobr)
library(ggplot2)
library(dplyr)

# Obter shapefile de um município ou estado
# Usaremos o estado do Paraná como exemplo
pr_map <- read_state(code_state = "PR", year = 2020)

# Simular dados de pontos com coordenadas dentro do estado

set.seed(6789) # Para reprodutibilidade (aleatoridade)

# Criando dados simulados
n_points <- 50
data_points <- data.frame(
  lon = runif(n_points, min = -54, max = -50),  # Intervalo aproximado para PR
  lat = runif(n_points, min = -26, max = -23), # Intervalo aproximado para PR
  value = runif(n_points, min = 10, max = 100) # Valores para tamanho das bolinhas
)

#Plotar o shapefile com os pontos
ggplot() +
  geom_sf(data = pr_map, fill = "white", color = "black", size = 0.3) + # Mapa base
  geom_point(data = data_points, 
             aes(x = lon, y = lat, size = value), 
             color = "blue", alpha = 0.7) + # Pontos
  scale_size_continuous(range = c(2, 8), name = "Tamanho") + # Controlando escala do tamanho
  labs(title = "Gráfico de Processo Pontual - Paraná",
       x = "Longitude", y = "Latitude") +
  theme_minimal()



################################################################################
### Krigagem (Interpolação de processo pontual)
### Instalar pacotes necessários (caso ainda não tenha)
#install.packages("geoR")

### Carregar pacote
library(geoR)

### Transformar os dados simulados em um objeto `geodata`
geo_data <- as.geodata(data_points, coords.col = c("lon", "lat"), data.col = "value")

### Estimar o semivariograma
vario <- variog(geo_data, max.dist = 1)  # Semivariograma experimental
plot(vario)

### Ajustar um modelo teórico ao semivariograma
vario_model <- variofit(vario, cov.model = "linear", nugget = 5, ini.cov.pars = c(50, 0.5))
summary(vario_model)
lines(vario_model)

#### Realizar a krigagem
# Criar uma grade de pontos para interpolação
lon_range <- seq(min(data_points$lon), max(data_points$lon), length.out = 100)
lat_range <- seq(min(data_points$lat), max(data_points$lat), length.out = 100)
grid <- expand.grid(lon = lon_range, lat = lat_range)

### Krigagem
krige_result <- krige.conv(geo_data, loc = as.matrix(grid), krige = krige.control(obj.model = vario_model))

### Adicionar os resultados da krigagem à grade
grid$value <- krige_result$predict

#### Visualizar os resultados da krigagem
ggplot() +
  geom_sf(data = pr_map, fill = "white", color = "black", size = 0.3) + # Mapa base
  geom_tile(data = grid, aes(x = lon, y = lat, fill = value)) + # Mapa interpolado
  scale_fill_viridis_c(name = "Interpolação") + # Paleta de cores
  geom_point(data = data_points, aes(x = lon, y = lat), color = "red", size = 2) + # Pontos originais
  labs(title = "Krigagem - Interpolação de Processo Pontual no Paraná",
       x = "Longitude", y = "Latitude") +
  theme_minimal()




#################### Interpolação dentro do polígono ###########
####Ajustes Realizados######
#-Grade Regular:
#-A função st_make_grid() cria uma grade de pontos que cobre o polígono completo.
#-O argumento cellsize controla a densidade dos pontos na grade.
#Filtragem pelo Polígono:
#st_filter() remove os pontos fora do limite do estado.
#Conversão da Grade:
#A grade filtrada é convertida em um data.frame com as coordenadas para compatibilidade com a krigagem.



# Carregar pacote
library(sf)

# Criar uma grade de pontos dentro do polígono do Paraná
# Transformar o shapefile em objeto `sf`
pr_sf <- st_as_sf(pr_map)

# Gerar uma grade regular de pontos dentro do polígono
grid <- st_make_grid(pr_sf, cellsize = 0.05, what = "centers") %>% 
  st_as_sf() %>% 
  st_filter(pr_sf)  # Filtrar apenas os pontos dentro do polígono

# Converter a grade para um data frame com coordenadas
grid_coords <- st_coordinates(grid) %>% as.data.frame()
colnames(grid_coords) <- c("lon", "lat")

# Realizar a krigagem nos pontos da grade
krige_result <- krige.conv(geo_data, loc = as.matrix(grid_coords), krige = krige.control(obj.model = vario_model))

# Adicionar os resultados da krigagem à grade
grid_coords$value <- krige_result$predict

# 3. Visualizar os resultados da krigagem cobrindo todo o estado
ggplot() +
  geom_sf(data = pr_map, fill = "white", color = "black", size = 0.3) + # Mapa base
  geom_tile(data = grid_coords, aes(x = lon, y = lat, fill = value)) + # Mapa interpolado
  scale_fill_viridis_c(name = "Interpolação") + # Paleta de cores
  geom_point(data = data_points, aes(x = lon, y = lat), color = "red", size = 2) + # Pontos originais
  labs(title = "Krigagem - Interpolação Completa no Paraná",
       x = "Longitude", y = "Latitude") +
  theme_minimal()

#################################################################### 

#### Deixando as bolinhas proporcionais  
###Ajustes:Bolinhas proporcionais:
#O tamanho dos pontos é definido pela variável value (os valores originais).
#scale_size_continuous() ajusta o intervalo de tamanhos das bolinhas para melhorar a visualização.
#Transparência (alpha):
#Adicionar transparência às bolinhas ajuda a visualizar sobreposições.




ggplot() +
  geom_sf(data = pr_map, fill = "white", color = "black", size = 0.3) + # Mapa base
  geom_tile(data = grid_coords, aes(x = lon, y = lat, fill = value)) + # Mapa interpolado
  scale_fill_viridis_c(name = "Interpolação") + # Paleta de cores
  geom_point(data = data_points, aes(x = lon, y = lat, size = value), 
             color = "red", alpha = 0.7) + # Pontos originais com tamanho proporcional
  scale_size_continuous(range = c(3, 8), name = "Valor Original") + # Controle da escala do tamanho
  labs(title = "Krigagem com Bolinhas Proporcionais - Paraná",
       x = "Longitude", y = "Latitude") +
  theme_minimal()






