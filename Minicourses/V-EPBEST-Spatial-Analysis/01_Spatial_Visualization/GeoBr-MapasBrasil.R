################################################################################
### instalação
#install.packages("geobr")


################################################################################
### Carregando pacotes necessários
library(geobr)
library(sf)
library(dplyr)
library(ggplot2)


################################################################################
### bancos de dados disponíveis
datasets <- list_geobr()
head(datasets)

################################################################################
# Estado do Sergige
state <- read_state(
  code_state="SE",
  year=2018,
  showProgress = FALSE
)

ggplot() + 
  geom_sf(data = state, color=NA, fill = 'lightgray') +
  theme_void()
################################################################################
# Municipio de Sao Paulo
muni <- read_municipality(
  code_muni = 3550308, 
  year=2010, 
  showProgress = FALSE
)

ggplot() + 
  geom_sf(data = muni, color=NA, fill = '#1ba185') +
  theme_void()



################################################################################
#Todos os municipios do estado de Minas Gerais
muni <- read_municipality(code_muni = "MG", 
                          year = 2007,
                          showProgress = FALSE)

ggplot() + 
  geom_sf(data = muni, color="black", fill = 'gray60') +
  theme_void()


################################################################################
# todos os setores censitários do RJ
cntr <- read_census_tract(
  code_tract = "RJ", 
  year = 2010,
  showProgress = FALSE
)

ggplot() + 
  geom_sf(data = cntr, color="black", fill = 'gray60') +
  theme_void()



################################################################################
# Regiões intermdiárias (meso regioes)
inter <- read_intermediate_region(
  year = 2017,
  showProgress = FALSE
)

ggplot() + 
  geom_sf(data = inter, color="yellow", fill = 'blue') +
  theme_void()


################################################################################
# Todos os estados brasileiros
states <- read_state(
  year = 2019, 
  showProgress = FALSE
)

ggplot() + 
  geom_sf(data = states, color="yellow", fill = 'blue') +
  theme_void()


# Remove plot axis
no_axis <- theme(axis.title=element_blank(),
                 axis.text=element_blank(),
                 axis.ticks=element_blank())

#Gráfico do brasil por estados
ggplot() +
  geom_sf(data=states, fill="#2D3E50", color="#FEBF57", size=.15, show.legend = FALSE) +
  labs(subtitle="States", size=8) +
  theme_minimal() +
  no_axis



# Download all municipalities of Rio
all_muni <- read_municipality(
  code_muni = "RJ", 
  year= 2010,
  showProgress = FALSE
)

# plot
ggplot() +
  geom_sf(data=all_muni, fill="#2D3E50", color="#FEBF57", size=.15, show.legend = FALSE) +
  labs(subtitle="Municipios do Rio de Janeiro, 2010", size=10) +
  theme_minimal() +
  no_axis


################################################################################ 
# ler data.frame dados com expectativa de vida
df <- utils::read.csv(system.file("extdata/br_states_lifexpect2017.csv", package = "geobr"), encoding = "UTF-8")

states$name_state <- tolower(states$name_state)
df$uf <- tolower(df$uf)

# unir os dados
states <- dplyr::left_join(states, df, by = c("name_state" = "uf"))


################################################################################
####Desenhar mapa temático
ggplot() +
  geom_sf(data=states, aes(fill=ESPVIDA2017), color= NA, size=.15) +
  labs(subtitle="Expectativa de vida ao nascer-Brasil, 2014", size=8) +
  scale_fill_distiller(palette = "Reds", name="Expectativa de vida", limits = c(65,80)) +
  theme_minimal() +
  no_axis



################################################################################
############ Processo pontual


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
###### Usando dados do Censo no pacote censobr
## usar em conjunto o geobr com nosso pacote irmão censobr para mapear a proporção de domicílios 
## conectados a uma rede de esgoto nos municípios brasileiros

###Primeiro, precisamos baixar os dados de domicílios do censo brasileiro usando a função read_households()####


### Carregar os pacotes
library(censobr)
library(arrow)

##dados de domicílios do censo brasileiro
hs <- read_households(year = 2010, 
                      showProgress = FALSE)

#### (a)agrupar as observações por município, 
#### (b) obter o número de domicílios conectados a uma rede de esgoto, 
#### (c) calcular a proporção de domicílios conectados e 
#### (d) coletar os resultados.

esg <- hs |> 
  collect() |>
  group_by(code_muni) |>                                             # (a)
  summarize(rede = sum(V0010[which(V0207=='1')]),                    # (b)
            total = sum(V0010)) |>                                   # (b)
  mutate(cobertura = rede / total) |>                                # (c)
  collect()                                                          # (d)


# Geometria dos municipios
muni_sf <- geobr::read_municipality(year = 2010,
                                    showProgress = FALSE)


# unir os dados
esg_sf <- left_join(muni_sf, esg, by = 'code_muni')


# desenhar um mapa bonito
ggplot() +
  geom_sf(data = esg_sf, aes(fill = cobertura), color=NA) +
  labs(title = "Proporção de domicilios conectados a redes de esgoto") +
  scale_fill_distiller(palette = "Greys", direction = 1, 
                       name='Participação \n de famílias', 
                       labels = scales::percent) +
  theme_void()

