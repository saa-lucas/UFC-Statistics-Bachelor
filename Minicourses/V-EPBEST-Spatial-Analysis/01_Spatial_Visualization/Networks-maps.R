### Carregamento de bibliotecas
library(assertthat)
library(dplyr)
library(purrr)
library(igraph)
library(ggplot2)
library(ggraph)
library(ggmap)
library(maps)
library(ggrepel) # <-- PACOTE ADICIONADO PARA CORRIGIR OS TEXTOS

################################################################################
### Leitura do banco de dados
nodes <- read.table("data/nodes.txt", header=T)
colnames(nodes) <- c('id', 'lon', 'lat', 'name')
attach(nodes) 

################################################################################
### Configuração de parâmetros aleatórios
set.seed(123) 
N_EDGES_PER_NODE_MIN <- 1
N_EDGES_PER_NODE_MAX <- 4
N_CATEGORIES <- 4

################################################################################
### Geração das arestas (edges)
edges <- map_dfr(nodes$id, function(id) {
  n <- floor(runif(1, N_EDGES_PER_NODE_MIN, N_EDGES_PER_NODE_MAX + 1))
  to <- sample(1:max(nodes$id), n, replace = FALSE)
  to <- to[to != id]
  categories <- sample(1:N_CATEGORIES, length(to), replace = TRUE)
  weights <- runif(length(to))
  tibble(from = id, to = to, weight = weights, category = categories)
})

edges <- edges %>% mutate(category = as.factor(category))

################################################################################
### Criação do objeto grafo (igraph)
g <- graph_from_data_frame(edges, directed = FALSE, vertices = nodes)

################################################################################
### Preparação de dados para o plot (ggplot2)
edges_for_plot <- edges %>%
  inner_join(nodes %>% select(id, lon, lat), by = c('from' = 'id')) %>%
  rename(x = lon, y = lat) %>%
  inner_join(nodes %>% select(id, lon, lat), by = c('to' = 'id')) %>%
  rename(xend = lon, yend = lat)

assert_that(nrow(edges_for_plot) == nrow(edges))

nodes$weight = degree(g)
world_map <- map_data("world")

################################################################################
### Visualização: Criação do mapa com ggplot2 (Visual Dark/Blue)

mapa_plot <- ggplot() +
  
  # 1. Mapa de fundo escuro para destacar as linhas
  geom_polygon(data = world_map, aes(x = long, y = lat, group = group), 
               fill = "#161b22", color = "#30363d", linewidth = 0.2) +
  
  # 2. Conexões
  geom_segment(data = edges_for_plot, 
               aes(x = x, y = y, xend = xend, yend = yend, color = category),
               alpha = 0.6) +
  
  # 3. Pontos (Países) com acento em azul
  geom_point(data = nodes, 
             aes(x = lon, y = lat, size = weight), 
             color = "#000000", fill = "#2f81f7", shape = 21, alpha = 0.9) +
  
  # 4. Textos repulsivos (max.overlaps = Inf garante que TODOS apareçam)
  geom_text_repel(data = nodes, aes(x = lon, y = lat, label = name), 
                  size = 3.5, 
                  color = "#c9d1d9",        
                  box.padding = 0.5,      
                  max.overlaps = Inf,     
                  segment.color = "#555555") + 
  
  # 5. Projeção e Tema
  coord_quickmap() +
  theme_void() +
  
  # Customização fina das cores de fundo e fontes para o estilo Dark
  theme(
    plot.background = element_rect(fill = "#0d1117", color = NA),
    panel.background = element_rect(fill = "#0d1117", color = NA),
    plot.title = element_text(color = "#ffffff", face = "bold", hjust = 0.5, margin = margin(t = 15, b = 5), size = 18),
    plot.subtitle = element_text(color = "#8b949e", hjust = 0.5, margin = margin(b = 15), size = 12),
    legend.text = element_text(color = "#c9d1d9"),
    legend.title = element_text(color = "#ffffff", face = "bold"),
    legend.position = "bottom"
  ) +
  
  # 6. Títulos e Legendas
  labs(title = "Mapa de Conexões Aleatórias",
       subtitle = "O tamanho do nó representa seu número de conexões (grau)",
       size = "Num. de Conexões",
       color = "Categoria")

# Exibe o mapa no RStudio
print(mapa_plot)

################################################################################
### Exportação de Imagem em Alta Resolução para o README
# Gera uma imagem 16:9 cravando a cor de fundo exata do GitHub
ggsave("mapa_conexoes_readme.png", 
       plot = mapa_plot, 
       width = 16, 
       height = 9, 
       dpi = 300, 
       bg = "#0d1117")