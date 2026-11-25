# Dados do MapBiomas (`data/`)

O script `data-raw/mapbiomas_cobertura_base.R` gera a base central de cobertura e uso da terra do MapBiomas, num único arquivo longo, para o Brasil inteiro.
Fonte: MapBiomas Collection 10, série completa 1985-2024, via `datazoom.amazonia::load_mapbiomas(dataset = "mapbiomas_cover", geo_level = "municipality")`. Áreas em hectares.

## Como atualizar

Na raiz do repositório:

```r
setwd("~/datazoom_viz")
source("data-raw/mapbiomas_cobertura_base.R")
```

O script precisa da versão de desenvolvimento do pacote (`devtools::install_github("datazoompuc/datazoom.amazonia")`) e de internet (planilha do MapBiomas e API de localidades do IBGE, usada para os nomes de município com acento). Se o download da planilha cair no meio (erro "transfer closed"), rode `options(timeout = 3600)` antes e tente de novo.

Ao final, o script confere que as tabelas largas montadas a partir da base (`cobertura_larga()`) são idênticas às montadas direto da tabela longa, e para se algo não fechar. A conferência contra os arquivos antigos (Collection 9) só roda se eles ainda existirem; hoje ficam só no histórico do Git.

Não há checagem de atualização no script nem workflow no GitHub Actions, e não precisa: a cada coleção nova o MapBiomas publica um arquivo novo no Dataverse, e o resolver do `datazoom.amazonia` troca o link no manifest do pacote (com um PR lá). Quando esse link mudar, rode o script de novo.

## Arquivos gerados

`mapbiomas_cobertura_base.rds` é a **base central**, em formato longo, com uma linha por ano × município × classe. Substitui `mapbiomas_cobertura_munic.rds`, `_est.rds` e os dicionários por nível e idioma. O nível estadual não é mais guardado: é a soma dos municípios.

| Coluna | O que é |
|---|---|
| `ano` | Ano da cobertura (1985 a 2024). |
| `cod_municipio` | Código IBGE do município. |
| `municipio` | Nome do município com acento (API do IBGE). |
| `uf` | Nome do estado. |
| `amazonia_legal` | `TRUE` para os 772 municípios da Amazônia Legal. |
| `classe_en`, `classe_pt` | Classe de cobertura em inglês e em português (legenda oficial da Collection 10). |
| `nivel` | Nível hierárquico da classe (0 a 4). |
| `area_ha` | Área da classe no município e ano, em hectares. |
| `area_municipio_km2` | Área total do município, em km² (de `global/area_municipios.rds`). |

Outros arquivos:

- `mapbiomas_cobertura_base_dic.csv` e `mapbiomas_cobertura_base_dic_en.csv`: dicionários dos apps de cobertura (PT e EN). Têm só as classes que existem na Amazônia Legal, porque os apps filtram por ela.
- `mapbiomas_legenda.csv`: legenda EN/PT/nível, lida também pelos apps de transição.
- `global/mapbiomas_cobertura_larga.R`: função `cobertura_larga(base, "munic" | "est")`, que monta a tabela larga (uma coluna por classe) usada pelos apps.

## Outros arquivos do MapBiomas em `data/` (não gerados por este script)

- **Transição** (`mapbiomas_transicao_*`): `est`, `est_tab`, `munic`, `munic_5`, `rk_est`, `rk_munic`, `sankey_est`, `sankey_munic` e os dicionários `_dic` e `_dic_en` de cada um. Vêm da Collection 9 e não podem ser regerados por município (ver Pendências).
- **Mapa de cobertura**: `map_mapbiomas_cover_dic.csv` e `_dic_en.csv`.
- **Gado** (`censoagro_mapbiomas_gado.rds`) e **PPM** (`dz_munic_ppm_mapbiomas.rds`), com dicionários `_dic` e `_dic_en`: cruzam o MapBiomas com o Censo Agropecuário e com a PPM.
- `mapbiomas_cobertura.parquet`: base antiga em parquet, mantida a pedido do Antonio.

## Sobre os dados

- **Níveis.** Os níveis 0 a 4 são cortes diferentes da **mesma** área (ex.: "Forest" no nível 1, "Forest Formation" no 2). **Não somar classes de níveis diferentes.** Os níveis 3 e 4 (tipos de lavoura) cobrem só parte da área.
- **Sem linhas de área zero.** A ausência de uma classe vale zero; `cobertura_larga()` preenche com zero ao montar a tabela larga.
- **Brasil inteiro.** São 5.569 municípios, 43 classes e cerca de 4,7 milhões de linhas (carga de nov/2026). Fernando de Noronha (PE, código 2605459) não tem dado no MapBiomas e fica fora da base e da área do estado.
- **Collection 10 reprocessou a série.** Os valores de 1985 a 2023 podem diferir dos gerados antes com a Collection 9.
- **Apps.** `ts_mapbiomas_cobertura` e `rk_mapbiomas_cobertura` leem a base nacional e filtram `amazonia_legal` ao carregar. A base foi conferida: o recorte da Amazônia Legal (682.926 linhas, 772 municípios) é idêntico ao da base anterior.
- **Nomes em português.** Vêm de um vetor fixo no script (legenda oficial). Se o MapBiomas criar uma classe nova, o script avisa "Classes sem PT oficial" e usa o nome em inglês até o vetor ser atualizado.

## Pendências

- **Transição por município.** Os dados de transição dependiam da Collection 9, cujo link hoje retorna 403. A Collection 10 só traz a transição por **bioma**, e o MapBiomas informou que não vai republicar a série por município. É preciso decidir o que fazer com os apps de transição.
- **Scripts dos outros arquivos.** Não identifiquei, para cada arquivo de transição, gado e mapa de cobertura listados acima, qual script os gera; conferir e documentar aqui.
- **Outros produtos derivados da base.** O mapa de cobertura (`mapbiomas_cobertura_map.R`), o mapa do gado e o script de PPM não foram ligados à base nova. O script de PPM usa um link de bucket da Collection 10 que retorna 403, e a origem exata do `.rds` do mapa do gado (provavelmente Collection 9) precisa ser confirmada.
- **Peso nos apps.** A base nacional faz o app carregar mais memória na abertura (pico de ~655 MB, contra ~242 MB com a base só da Amazônia; o limite do shinyapps.io é 1 GB). Vale reavaliar no app novo de cobertura.
- **App novo de cobertura.** Os apps atuais filtram a Amazônia Legal; o desenho do app novo, com o Brasil inteiro, ainda não foi feito.
