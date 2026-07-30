library(dplyr)
library(jsonlite)
library(geojsonio)
library(sf)
library(lwgeom)
# remotes::install_github("RodrigoAgronomia/PAR")
library(PAR)

##################################
## Terras indígenas brasileiras ##
##################################

# Lido com ENCODING=WINDOWS-1252 para preservar os acentos corretamente
# em português (o .dbf original está nesse encoding).
dat <- sf::read_sf(
    "data-raw/abya_yala_raw/tis_poligonaisPolygon.shp",
    options = "ENCODING=WINDOWS-1252"
)

geom_munduruku <- dat %>%
    sf::st_make_valid() %>%
    filter(etnia_nome == "Mundurukú") %>%
    summarise(geometry = sf::st_union(geometry)) %>%
    mutate(
        etnia = "Mundurukú",
        nome = "Ytanajé Coelho Cardoso",
        label = "ytanaje_cardoso",
        temporada = 1
    )

geom_xucuru <- dat %>%
    sf::st_make_valid() %>%
    filter(etnia_nome == "Xucuru - Kariri") %>%
    summarise(geometry = sf::st_union(geometry)) %>%
    mutate(
        etnia = "Xucuru-Kariri",
        nome = "Rafael Xucuru-Kariri",
        label = "rafael_xucuru_kariri",
        temporada = 1
    )

geom_wassu <- dat %>%
    sf::st_make_valid() %>%
    filter(terrai_nom == "Wassu-Cocal") %>%
    summarise(geometry = sf::st_union(geometry)) %>%
    mutate(
        etnia = "Wassu-Cocal",
        nome = "Ellen Lima Wassu",
        label = "ellen_lima",
        temporada = 1
    )

geom_pataxo <- dat %>%
    sf::st_make_valid() %>%
    filter(etnia_nome == "Pataxó") %>%
    summarise(geometry = sf::st_union(geometry)) %>%
    mutate(
        etnia = "Pataxó",
        nome = "Kâhu Pataxó",
        label = "kahu_pataxo",
        temporada = 1
    )

geom_karapoto <- dat %>%
    sf::st_make_valid() %>%
    filter(etnia_nome == "Karapotó") %>%
    summarise(geometry = sf::st_union(geometry)) %>%
    mutate(
        etnia = "Karapotó",
        nome = "Ziel Karapotó",
        label = "ziel_karapoto",
        temporada = 2
    )

geom_macuxi <- dat %>%
    sf::st_make_valid() %>%
    filter(etnia_nome == "Makuxí") %>%
    summarise(geometry = sf::st_union(geometry)) %>%
    mutate(
        etnia = "Macuxi",
        nome = "Trudruá Dorrico",
        label = "trudrua_dorrico",
        temporada = 2
    )

geom_kayapo <- dat %>%
    sf::st_make_valid() %>%
    filter(etnia_nome == "Kayapó") %>%
    summarise(geometry = sf::st_union(geometry)) %>%
    mutate(
        etnia = "Mẽbengôkre Kayapó",
        nome = "Edson Kayapó",
        label = "edson_kayapo",
        temporada = 2
    )

geom_tupinamba <- dat %>%
    sf::st_make_valid() %>%
    filter(terrai_nom == "Tupinambá de Olivença") %>%
    summarise(geometry = sf::st_union(geometry)) %>%
    mutate(
        etnia = "Tupinambá de Olivença",
        nome = "Juliana Tupinambá",
        label = "juliana_tupinamba",
        temporada = 2
    )

geom_mura <- dat %>%
    sf::st_make_valid() %>%
    filter(etnia_nome == "Múra") %>%
    summarise(geometry = sf::st_union(geometry)) %>%
    mutate(
        etnia = "Mura",
        nome = "Marcia Mura",
        label = "marcia_mura",
        temporada = 3
    )

geom_xoco <- dat %>%
    sf::st_make_valid() %>%
    filter(terrai_nom %in% c("Caiçara/Ilha de São Pedro", "Kariri-Xokó")) %>%
    summarise(geometry = sf::st_union(geometry)) %>%
    mutate(
        etnia = "Xokó",
        nome = "Ivanilson Martins dos Santos Xokó",
        label = "ivanilson_xoko",
        temporada = 3
    )

geom_tukano <- dat %>%
    sf::st_make_valid() %>%
    filter(terrai_nom %in% c("Médio Rio Negro I", "Médio Rio Negro II")) %>%
    summarise(geometry = sf::st_union(geometry)) %>%
    mutate(
        etnia = "Tukano",
        nome = "João Rivelino Rezende Barreto",
        label = "joao_rivelino",
        temporada = 3
    )

dat_ven <- sf::read_sf("data-raw/abya_yala_raw/240808_TI_VEN_WGS84.shp")

geom_anu <- dat_ven %>%
    sf::st_make_valid() %>%
    filter(etnias %in% c("Añú", "Añú, Wayúu")) %>%
    summarise(geometry = sf::st_union(geometry)) %>%
    mutate(
        etnia = "Añú",
        nome = "José Ángel Quintero Weir",
        label = "jose_angel_quintero",
        temporada = 3
    )

geom_anu <- geom_anu %>%
    sf::st_transform(crs = sf::st_crs(dat))

# Aline Pachamama (Puri): não há TI demarcada oficialmente.
# Usamos um polígono aproximado (buffer de 5km) ao redor da Serrinha do
# Alambari (Resende, RJ), local de referência de memória do povo Puri.
# Isso é sinalizado explicitamente no Rmd correspondente.
ponto_serrinha <- sf::st_sfc(sf::st_point(c(-44.5538, -22.3869)), crs = 4326)

geom_puri <- sf::st_sf(geometry = sf::st_buffer(ponto_serrinha, dist = 5000)) %>%
    sf::st_transform(crs = sf::st_crs(dat)) %>%
    mutate(
        etnia = "Puri",
        nome = "Aline Rochedo Pachamama",
        label = "aline_pachamama",
        temporada = 3
    )

regions <- bind_rows(
    geom_munduruku, geom_xucuru, geom_wassu, geom_pataxo,
    geom_karapoto, geom_macuxi, geom_kayapo, geom_tupinamba,
    geom_mura, geom_xoco, geom_tukano, geom_anu, geom_puri
)

regions <- regions %>%
    sf::st_transform(crs = 4326)

#####################################
## Terras indigenas fora do brasil ##
#####################################

# api da native-lands

api_key <- "HYEZKGu91PzNsxBXqV44J"

lands <- list(
    maia = list(
        etnia = "Maya",
        nome = "Bella Flor Canche Teh",
        label = "bella_flor",
        temporada = 1,
        url = "https://native-land.ca/api/index.php?maps=territories&name=maya-yucateco"
    ),
    wayuu = list(
        etnia = "Wayuu",
        nome = "Sindri Tatiana González Ipuana",
        label = "sindri_tatiana",
        temporada = 1,
        url = "https://native-land.ca/api/index.php?maps=territories&name=wayuu"
    ),
    omaguaca = list(
        etnia = "Omaguaca",
        nome = "Maryta de Humahuaca",
        label = "maryta_de_humahuaca",
        temporada = 1,
        url = "https://native-land.ca/api/index.php?maps=territories&name=omaguaca"
    ),
    mapuche = list(
        etnia = "Mapuche",
        nome = "Natalia Caniguan Velarde",
        label = "natalia_caniguan",
        temporada = 1,
        url = "https://native-land.ca/api/index.php?maps=territories&name=mapuche"
    ),
    mapuche2 = list(
        etnia = "Mapuche",
        nome = "Enrique Antileo",
        label = "enrique_antileo",
        temporada = 2,
        url = "https://native-land.ca/api/index.php?maps=territories&name=mapuche"
    ),
    mapuche3 = list(
        etnia = "Mapuche",
        nome = "Claudio Alvarado Lincopi",
        label = "claudio_alvarado",
        temporada = 3,
        url = "https://native-land.ca/api/index.php?maps=territories&name=mapuche"
    ),
    charrua = list(
        etnia = "Charrua",
        nome = "Martin Delgado Cultelli",
        label = "martin_delgado",
        temporada = 2,
        url = "https://native-land.ca/api/index.php?maps=territories&name=charruas"
    ),
    quechua = list(
        etnia = "Quéchua",
        nome = "Luciana Quispe",
        label = "luciana_quispe",
        temporada = 2,
        url = "https://native-land.ca/api/index.php?maps=territories&name=quechua"
    ),
    maya_kiche = list(
        etnia = "Maya K'iche",
        nome = "Ana Lucia Ixchiu",
        label = "ana_lucia_ixchiu",
        temporada = 2,
        url = "https://native-land.ca/api/index.php?maps=territories&name=qeqchi"
    ),
    cree = list(
        etnia = "Cree/Nehiyaw",
        nome = "Omeasoo Wahpasiw",
        label = "omeasoo_wahpasiw",
        temporada = 3,
        url = "https://native-land.ca/api/index.php?maps=territories&name=cree"
    ),
    pemon = list(
        etnia = "Pemón",
        nome = "Lisa Henrito",
        label = "lisa_henrito",
        temporada = 3,
        url = "https://native-land.ca/api/index.php?maps=territories&name=pemon"
    )
)

dat <- purrr::map(
    lands,
    function(x) {
        url <- paste0(x$url, "&key=", api_key)
        
        json <- fromJSON(url)
        
        lon <- json$geometry$coordinates[[1]][,,1]
        
        lat <- json$geometry$coordinates[[1]][,,2]
        
        coords <- cbind(lon, lat)
        
        poly_sf <- st_sf(geometry = st_sfc(st_polygon(list(coords))), crs = 4326)
        
        poly_sf %>%
            mutate(
                etnia = x$etnia,
                nome = x$nome,
                label = x$label,
                temporada = x$temporada
            )
    }
) %>%
    bind_rows()

#################
## Manipulação ##
#################

regions <- bind_rows(regions, dat)

# Um problema: tem mais de um entrevistado na região Mapuche (3, na
# temporada 3). Fatio a região em 3 partes para separar.

slice_polygon_bbox <- function(polygon, n_slices = 10) {
    bbox <- st_bbox(polygon)
    xmin <- bbox["xmin"]
    xmax <- bbox["xmax"]
    ymin <- bbox["ymin"]
    ymax <- bbox["ymax"]
    
    slice_width <- (xmax - xmin) / n_slices
    
    slices <- list()
    
    for (i in 1:n_slices) {
        x_left <- xmin + (i - 1) * slice_width
        x_right <- xmin + i * slice_width
        
        slice_coords <- matrix(c(
            x_left, ymin,
            x_right, ymin,
            x_right, ymax,
            x_left, ymax,
            x_left, ymin
        ), ncol = 2, byrow = TRUE)
        
        slice_poly <- st_polygon(list(slice_coords))
        slices[[i]] <- slice_poly
    }
    
    slices_sf <- st_sfc(slices, crs = st_crs(polygon))
    
    return(slices_sf)
}

poly <- regions %>%
    filter(etnia == "Mapuche") %>%
    slice(1) %>%
    sf::st_geometry()

slices <- slice_polygon_bbox(poly, 9)

slices_1 <- slices %>% 
    st_as_sf() %>%
    filter(row_number() %% 3 == 0)

slices_2 <- slices %>%
    st_as_sf() %>%
    filter(row_number() %% 3 == 1)

slices_3 <- slices %>%
    st_as_sf() %>%
    filter(row_number() %% 3 == 2)

geom_1 <- st_intersection(poly, slices_1) %>%
    sf::st_union()

geom_2 <- st_intersection(poly, slices_2) %>%
    sf::st_union()

geom_3 <- st_intersection(poly, slices_3) %>%
    sf::st_union()

regions[regions$etnia == "Mapuche",]$geometry <- c(geom_1, geom_2, geom_3)

##############
## Salvando ##
##############

readr::write_rds(regions, "data/abya_yala_terras_indigenas.rds")
