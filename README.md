
<!-- README.md is generated from README.Rmd. Please edit that file -->

# datazoom_viz



The datazoom_viz repository is used for developing visualizations in shiny R codes and fueling the https://datazoomamazonia.com.br/ website.

All the apps are listed in this sheet. (https://docs.google.com/spreadsheets/d/1oSR_vybaRs9JEy8NC7MuBFfOlE6mA2Mxf_Ugm4E_HgA/edit?usp=sharing). It shows if there are any issues related to the app, if it is updated, translated, published and working well. 

Main Directories:
 - "./data": contains all the .rds databases and .csv files that are used in the generation of the visualizations. The files' names are organized in order to follow a pattern: xxxx.rds for the databases and xxxx_dic for the .csv dictionaries that correspond to the same database.
 
 - "./data-raw": contains .R scripts that generates both the .rds databases and the .csv files that are recorded in the "./data" directory. In order to generate the databases, the scripts use the datazoom.amazonia R package, developed by the Datazoom team. Each .R script is responsible for generating the .rds and .csv files for specific geographic aggregation of the researches. 
 
 - "./scripts": contains .R scripts that generate the visualizations using the Shiny Apps technology.


## Installation (NEEDS CHANGES)

You can install the released version of `datazoom.amazonia` from
[CRAN](https://CRAN.R-project.org/package=datazoom.amazonia) with:

``` r
install.packages("datazoom.amazonia")
```

And the development version from GitHub with:

``` r
# install.packages("devtools")
devtools::install_github("datazoompuc/datazoom.amazonia")
```

**[1 - Environmental data](#environmental-data)**

<table>
<tr>
<td>

|                       |                                        |
|-----------------------|----------------------------------------|
| **[PRODES](#prodes)** | *Yearly deforestation*                 |
| **[MapBiomas](#mapbiomas)**       | *Land cover and land use*           |
| **[SEEG](#seeg)**                 | *Greenhouse gas emission estimates* |


</td>
</tr>
</table>

**[2 - Social data](#social-data)**

<table>
<tr>
<td>

|                               |                                                         |
|-------------------------------|---------------------------------------------------------|
| **[IPS](#ips)**               | *Amazon Social Progress Index*                          |
| **[DATASUS](#datasus)**       | *Causes of mortality and availability of hospital beds* |

</td>
</tr>
</table>

**[3 - Economic data](#economic-data)**

<table>
<tr>
<td>

|                             |                                 |
|-----------------------------|---------------------------------|
| **[COMEX](#comex)**         | *Brazilian international trade* |
| **[BACI](#baci)**           | *Global international trade*    |
| **[PIB-Munic](#pib-munic)** | *Municipal GDP*                 |
| **[CEMPRE](#cempre)**       | *Central register of companies* |
| **[PAM](#pam)**             | *Agricultural production*       |

</td>
<td>

|                         |                           |
|-------------------------|---------------------------|
| **[PEVS](#pevs)**       | *Forestry and extraction* |
| **[PPM](#ppm)**         | *Livestock farming*       |
| **[SIGMINE](#sigmine)** | *Mining*                  |
| **[ANEEL](#aneel)**     | *Energy development*      |
| **[EPE](#epe)**         | *Energy consumption*      |

</td>
</tr>
</table>

**[4 - Other tools](#other-tools)**

<table>
<tr>
<td>

|                                                                 |                                                                             |
|-----------------------------------------------------------------|-----------------------------------------------------------------------------|
| **[Legal Amazon Municipalities](#legal-amazon-municipalities)** | *Dataset with brazilian cities and whether they belong to the Legal Amazon* |
| **[The ‘googledrive’ package](#googledrive)**                   | *Troubleshooting and information for downloads from Google Drive*           |

</table>

# Environmental Data

## PRODES

The PRODES project uses satellites to monitor deforestation in Brazil’s
Legal Amazon. The raw data reports total and incremental (year-by-year)
low-cut deforested area at the municipality level, going back to the
year 2000.

Data is collected based on the PRODES-year, which starts at August 1st
and ends on July 31st. Accordingly, 2018 deforestation data covers the
period from 01/08/2017 to 31/07/2018.

INPE’s most recent data is now published at
[TerraBrasilis](http://terrabrasilis.dpi.inpe.br/downloads/). We have
refrained from updating to this new source, as it only contains detailed
spatial data, rather than agregated, municipality-level data.

------------------------------------------------------------------------


**Files:**

- `app_map_dz_munic_prodes`: map of deforestation, hydrogaphy and forest data at the municipality level. (english version: `app_map_dz_munic_prodes_en`)
  
- `app_rkstatic_dz_munic`: ranking of deforestation champion states. (english version: `app_rkstatic_dz_munic_en`)




## MapBiomas

The MapBiomas project gathers data reporting the type of land covering
each year by area, that is, for example, the area used for a temporary
crop of soybeans. It also reports the transitions in land coverage
between years.

The data has yearly frequency and is available starting from the year
1989.

------------------------------------------------------------------------

**Files:**

- `app_hist_mapbiomas_bovinos`: histogram graphic about the distribution of municipalities according to cattle per hectares of grazing areas. (english version: `app_hist_mapbiomas_bovinos_en`)
  
- `app_map_cattle`: map of heads of cattle and pasture area data. (english version: `app_map_cattle_en`)

- `app_map_mapbiomas_cover`: map of annual land use and land cover in brazil. (english version: `app_map_mapbiomas_cover_en`)

- `app_rk_mapbiomas_cobertura_est`: ranking of annual land use and cover at state level. (english version: `app_rk_mapbiomas_cobertura_est_en`)

- `app_rk_mapbiomas_cobertura_munic`: ranking of annual land use and cover at the municipality level. (english version: `app_rk_mapbiomas_cobertura_munic_en`)

- `app_rk_mapbiomas_cobertura_munic_percentual`: ????como diferenciar do de cima???? (english version: `app_rk_mapbiomas_cobertura_munic_percentual_en`)

- `app_rk_mapbiomas_transicao_est`: ranking of transition/change of soil cover and use at state level through the years. (english version: `app_rk_mapbiomas_transicao_est_en`)

- `app_rk_mapbiomas_transicao_munic_5`: ranking of transition/change of soil cover and use at the municipality level through the years. (english version: `app_rk_mapbiomas_transicao_munic_5_en`)

- `app_tab_mapbiomas_transicao_est`: table of transition/change of soil cover and use at state level through the years.

- `app_ts_mapbiomas_cobertura_est`: graphic of annual mapping of land use and coverage at state level. (english version: `app_ts_mapbiomas_cobertura_est_en`)

- `app_ts_mapbiomas_cobertura_munic`: graphic of annual mapping of land use and coverage at the municipality level. (english version: `app_ts_mapbiomas_cobertura_munic_en`)

- `app_ts_mapbiomas_transicao_est`: graphic of transition/ change of land cover and use at state level. (english version: `app_ts_mapbiomas_transicao_est_en`)



## SEEG

Loads estimates of emission of greenhouse gases of Brazilian cities and
states from SEEG. SEEG is the System of Estimates of Emissions and
Removals of Greenhouse Gases (SEEG), an initiative of the Observatório
do Clima, a network of institutions focused on climate change research
in Brazil.

The data provided in SEEG’s Collection 9 is a series covering the period
from 1970 to 2020, except for the Land Use Change Sector that has the
series from 1990 to 2020.

Using data collected from government entities, institutes, research
centers, NGOs and other institutions, the estimates are created using
the methodology of the Brazilian Inventory of Anthropic Emissions and
Removals of Greenhouse Gases, assembled by the Ministry of Science,
Technology and Innovation (MCTI), and the directives of
Intergovernmental Panel on Climate Change (IPCC)

Emissions are divided in five main sources: Agricultural and Cattle
Raising, Energy, Changes in Use of Land, Industrial Processes and
Residues. All greenhouse gases contained in the national inventory are
considered, encompassing CO2, CH4, N2O and the HFCs, with the conversion
to carbon equivalence (CO2e) also included, both in the metric of GWP
(Global Warming Potential) and GTP (Global Temperature Potential).


------------------------------------------------------------------------

**Files:**

- `app_ts_seeg_state_energy`: graphic of greenhouse gas emissions in the energy sector at state level. (english version: `app_ts_seeg_state_energy_en`)

- `app_ts_seeg_state_farming`: graphic of greenhouse gas emissions in farming at state level. (english version: `app_ts_seeg_state_farming_en`)

- `app_ts_seeg_state_industry`: graphic of greenhouse gas emissions in industry at state level. (english version: `app_ts_seeg_state_industry_en`)



# Social Data

## IPS

Loads information on the social and environmental performance of the
Legal Amazon.

Data from the Amazon Social Progress Index, an initiative from Imazon
with support from the Social Progress Imperative that measures the
social and environmental progress of its locations. Namely, the 772
municipalities in the Amazon region. Survey is done at the municipal
level and data is available in 2014 and 2018.

------------------------------------------------------------------------

**Files:**

- `app_mapstatic_ips`: map of compiled data from the Institute of Man and Environment of the Amazon (IMAZON). (english version: `app_mapstatic_ips_en`)



## DATASUS

DATASUS is the IT department of SUS – the Brazilian Unified Health
System. They provide data on health establishments, mortality, access to
health services and several health indicators nationwide. 

------------------------------------------------------------------------

**Files:**

- `app_map_saude_mortalidade`: health conditions at amazon: mortality at the municipal level. (english version: `app_map_saude_mortalidade_en`)

- `app_ts_saude_municipality`: health data at the municipal level. (english version: `app_ts_saude_municipality_en`)



# Economic Data

## COMEX

The Comex dataset gathers data extracted from [Siscomex (Integrated
System of Foreign
Trade)](https://www.gov.br/produtividade-e-comercio-exterior/pt-br/assuntos/comercio-exterior/estatisticas/base-de-dados-bruta/),
which is a database containing information from all products that are
imported to or exported from Brazil. Using data reported from the
companies which are responsible for the process of transporting the
products, the system adheres to internationally standardized
nomenclatures, such as the Harmonized System and the Mercosul Common
Nomenclature (which pertains to members of the Mercosul organization).

The data has a monthly frequency and is available starting from the year
1989. From 1989 to 1996, a different system of nomenclatures was
adopted, but all conversions are available on a dictionary in the Comex
website
(<https://www.gov.br/produtividade-e-comercio-exterior/pt-br/assuntos/comercio-exterior/estatisticas/base-de-dados-bruta/>).
Systems of nomenclature vary in the degree of detail in terms of the
product involved, as well as other characteristics, such as unit and
granularity of location.

------------------------------------------------------------------------

**Options:**

1.  **dataset**: there are four choices:

    - `"comex_export_mun"`: selects exports data by municipality
    - `"comex_import_mun"`: selects imports data by municipality
    - `"comex_export_prod"`: selects exports data by producer
    - `"comex_import_prod"`: selects imports data by producer

2.  **raw_data**: there are two options:

    - `TRUE`: if you want the data as it is originally.
    - `FALSE`: if you want the treated version of the data.

3.  **time_period**: picks the years for which the data will be
    downloaded

4.  **language**: you can choose between Portuguese `("pt")` and English
    `("eng")`

------------------------------------------------------------------------

**Examples:**

``` r
# download treated (raw_data = FALSE) exports data by municipality (dataset = "comex_export_mun")
# from 2020 to 2021 (time_period = 2020:2021)
data <- load_br_trade(
  dataset = "comex_export_mun",
  raw_data = FALSE,
  time_period = 2020:2021
)
# download treated(raw_data = FALSE) imports data by municipality (dataset = "comex_import_mun")
# from 2020 to 2021 (time_period = 2020:2021)
data <- load_br_trade(
  dataset = "comex_import_mun",
  raw_data = FALSE,
  time_period = 2020:2021
)
```

## BACI

Loads disaggregated data on bilateral trade flows for more than 5000
products and 200 countries. The data is from the
[CEPII](http://www.cepii.fr/CEPII/en/bdd_modele/bdd_modele_item.asp?id=37)
and is built from data directly reported by each country to the United
Nations Statistical Division (Comtrade).

As all of the data is packed into one single .zip file in the website,
data on all years must be downloaded, even if not all of it is used.
Therefore, downloading the data can take a long time.

------------------------------------------------------------------------

**Options:**

1.  **dataset**: there is one choice:

    - `"HS92"` which follows the Harmonized System method

2.  **raw_data**: there are two options:

    - `TRUE`: if you want the data as it is originally.
    - `FALSE`: if you want the treated version of the data.

3.  **time_period**: picks the years for which the data will be
    downloaded

4.  **language**: you can choose between Portuguese `("pt")` and English
    `("eng")`

------------------------------------------------------------------------

**Examples:**

``` r
# download treated data for 2016 (takes a long time to download)
clean_baci <- load_baci(
  raw_data = FALSE,
  time_period = 2016
)
```

## PIB-Munic

Loads IBGE information on gross domestic product at current prices,
taxes, net of subsidies, on products at current prices and gross value
added at current prices, total and by economic activity, and respective
shares. Data is available at country, state and municipality level and
from 2002 to 2018.

------------------------------------------------------------------------

**Options:**

1.  **dataset**: `"pibmunic"`

2.  **raw_data**: there are two options:

    - `TRUE`: if you want the data as it is originally.
    - `FALSE`: if you want the treated version of the data.

3.  **geo_level**: `"country"`, `"state"`, or `"municipality"`

4.  **time_period**: picks the years for which the data will be
    downloaded

5.  **language**: you can choose between Portuguese `("pt")` and English
    `("eng")`

------------------------------------------------------------------------

**Examples:**

``` r
# download treated municipal GDP data at the state level for 2010 to 2012
data <- load_pibmunic(
  raw_data = FALSE,
  geo_level = "state",
  time_period = 2010:2012
)
```

## CEMPRE

Employment, salary and firm data from IBGE’s [Cadastro Central de
Empresas (CEMPRE)](https://sidra.ibge.gov.br/pesquisa/cempre/tabelas).
Loads information on companies and other organizations and their
respective formally constituted local units, registered with the CNPJ -
National Register of Legal Entities. Data is available between 2006 and
2019.

------------------------------------------------------------------------

**Options:**

1.  **dataset**: `"cempre"`

2.  **raw_data**: there are two options:

    - `TRUE`: if you want the data as it is originally.
    - `FALSE`: if you want the treated version of the data.

3.  **geo_level**: `"country"`, `"state"` or `"municipality"`

4.  **time_period**: picks the years for which the data will be
    downloaded

5.  **language**: you can choose between Portuguese `("pt")` and English
    `("eng")`

6.  **sectors**: defines if the data will be return separated by sectors
    (`sectors = TRUE`) or not (`sectors = FALSE`)

------------------------------------------------------------------------

**Examples:**

``` r
# Download raw data (raw_data = TRUE) at the country level
# from 2008 to 2010 (time_period = 2008:2010).
data <- load_cempre(
  raw_data = TRUE,
  geo_level = "country",
  time_period = 2008:2010
)
# Download treted data (raw_data = FALSE) by state (geo_level = "state")
# from 2008 to 2010 (time_period = 2008:2010) in portuguese (language = "pt").
# In this example, data is split by sector (sectors = TRUE)
data <- load_cempre(
  raw_data = FALSE,
  geo_level = "state",
  time_period = 2008:2010,
  language = "pt",
  sectors = TRUE
)
```

## PAM

[Municipal Agricultural
Production](https://www.ibge.gov.br/en/statistics/economic/agriculture-forestry-and-fishing/16773-municipal-agricultural-production-temporary-and-permanent-crops.html?=&t=o-que-e)
(PAM, in Portuguese) is a nationwide annual survey conducted by IBGE
(Brazilian Institute of Geography and Statistics) which provides
information on agricultural products, such as quantity produced, area
planted and harvested, average quantity of output and monetary value of
such output. The products are divided in permanent and temporary farmed
land, as well as dedicated surveys to the four products that yield
multiple harvests a year (beans, potato, peanut and corn), which all sum
to a total survey of 64 agricultural products (31 of temporary tillage
and 33 of permanent tillage). Output, however, is only included in the
dataset if the planted area occupies over 1 acre or if output exceeds
one tonne.

Permanent farming is characterized by a cycle of long duration, whose
harvests may be done multiple times across the years without the need of
planting seeds again. Temporary farming, on the other hand, consists of
cycles of short and medium duration, which after harvesting require
planting seeds again.

The data also has multiple aggregation levels, such as nationwide, by
region, mesoregion and microregion, as well as state and municipality.

The data available has a yearly frequency and is available from 1974 to
the present, with the exception of the four multiple-harvest products,
which are only available from 2003. More information can be found on
[this
link](https://www.ibge.gov.br/estatisticas/economicas/agricultura-e-pecuaria/9117-producao-agricola-municipal-culturas-temporarias-e-permanentes.html#:~:text=A%20pesquisa%20Produ%C3%A7%C3%A3o%20Agr%C3%ADcola%20Municipal,s%C3%A3o%20da%20cesta%20b%C3%A1sica%20do)
(only in Portuguese).

------------------------------------------------------------------------

**Options:**

1.  **dataset**: See tables below

2.  **raw_data**: there are two options:

    - `TRUE`: if you want the data as it is originally.
    - `FALSE`: if you want the treated version of the data.

3.  **geo_level**: `"country"`, `"region"`, `"state"`, or
    `"municipality"`

4.  **time_period**: picks the years for which the data will be
    downloaded

5.  **language**: you can choose between Portuguese `("pt")` and English
    `("eng")`

------------------------------------------------------------------------

The datasets supported are shown in the tables below, made up of both
the original databases and their narrower subsets. Note that downloading
only specific crops is considerably faster.

<details>
<summary>
Full datasets provided by IBGE:
</summary>

| dataset         |
|:----------------|
| all_crops       |
| temporary_crops |
| permanent_crops |
| corn            |
| potato          |
| peanut          |
| beans           |

</details>
<details>
<summary>
Datasets generated from Temporary Crops:
</summary>

| dataset           |          Name (pt)           |          Name (eng)           |
|:------------------|:----------------------------:|:-----------------------------:|
| pineapple         |           Abacaxi            |           Pineapple           |
| alfafa            |        Alfafa Fenada         |         Alfafa Fenada         |
| cotton_herbaceous | Algodao Herbaceo (em Caroco) | Herbaceous Cotton (in Caroco) |
| garlic            |             Alho             |            Garlic             |
| peanut_temporary  |     Amendoim (em Casca)      |      Peanuts (in Shell)       |
| rice              |       Arroz (em Casca)       |        Rice (in husk)         |
| oats              |       Aveia (em Grao)        |        Oats (in grain)        |
| sweet_potato      |         Batata Doce          |         Sweet potato          |
| potato_temporary  |        Batata Inglesa        |        English potato         |
| sugar_cane        |        Cana de Acucar        |          Sugar cane           |
| forage_cane       |      Cana para Forragem      |          Forage cane          |
| onion             |            Cebola            |             Onion             |
| rye               |      Centeio (em Grao)       |        Rye (in grain)         |
| barley            |       Cevada (em Grao)       |       Barley (in Grain)       |
| pea               |      Ervilha (em Grao)       |        Pea (in Grain)         |
| broad_bean        |        Fava (em Grao)        |     Broad Bean (in Grain)     |
| beans_temporary   |       Feijao (em Grao)       |       Beans (in Grain)        |
| tobacco           |       Fumo (em Folha)        |       Smoke (in Sheet)        |
| sunflower_seeds   |      Girassol (em Grao)      |     Sunflower (in Grain)      |
| jute_fiber        |         Juta (Fibra)         |         Jute (Fiber)          |
| linen_seeds       |       Linho (Semente)        |         Linen (Seed)          |
| malva_fiber       |        Malva (Fibra)         |         Malva (Fiber)         |
| castor_bean       |        Mamona (Baga)         |      Castor bean (Berry)      |
| cassava           |           Mandioca           |            Cassava            |
| watermelon        |           Melancia           |          watermelon           |
| melon             |            Melao             |             Melon             |
| corn_temporary    |       Milho (em Grao)        |        corn (in grain)        |
| ramie_fiber       |         Rami (Fibra)         |         Ramie (Fiber)         |
| soybean           |        Soja (em Grao)        |      Soybean (in grain)       |
| sorghum           |       Sorgo (em Grao)        |      Sorghum (in Grain)       |
| tomato            |            Tomate            |            Tomato             |
| wheat             |       Trigo (em Grao)        |        Wheat in grain)        |
| triticale         |     Triticale (em Grao)      |     Triticale (in grain)      |
| temporary_total   |            Total             |             Total             |

</details>
<details>
<summary>
Datasets generated from Permanent Crops:
</summary>

| dataset                 |          Name (pt)          |         Name (eng)         |
|:------------------------|:---------------------------:|:--------------------------:|
| avocado                 |           Abacate           |          Avocado           |
| cotton_arboreo          | Algodao Arboreo (em Caroco) | Arboreo cotton (in Caroco) |
| acai                    |            Acai             |            Acai            |
| olive                   |          Azeitona           |           Olive            |
| banana                  |       Banana (Cacho)        |       Banana (Bunch)       |
| rubber_coagulated_latex | Borracha (Latex Coagulado)  | Rubber (Coagulated Latex)  |
| rubber_liquid_latex     |  Borracha (Latex Liquido)   |   Rubber (Liquid Latex)    |
| cocoa_beans             |     Cacau (em Amendoa)      |     Cocoa (in Almonds)     |
| coffee_total            |    Cafe (em Grao) Total     |  Coffee (in Grain) Total   |
| coffee_arabica          |   Cafe (em Grao) Arabica    |   Cafe (in Grao) Arabica   |
| coffee_canephora        |  Cafe (em Grao) Canephora   | Cafe (in Grain) Canephora  |
| cashew                  |            Caju             |           Cashew           |
| khaki                   |            Caqui            |           Khaki            |
| cashew_nut              |      Castanha de Caju       |        Cashew Nuts         |
| india_tea               | Cha da India (Folha Verde)  |      India Tea (Leaf)      |
| coconut                 |        Coco da Baia         |          Coconut           |
| coconut_bunch           |    Dende (Cacho de Coco)    |       Coconut Bunch        |
| yerba_mate              |   Erva Mate (Folha Verde)   |      Mate Herb (Leaf)      |
| fig                     |            Figo             |            Fig             |
| guava                   |           Goiaba            |           Guava            |
| guarana_seeds           |      Guarana (Semente)      |       Guarana (Seed)       |
| orange                  |           Laranja           |           Orange           |
| lemon                   |            Limao            |           Lemon            |
| apple                   |            Maca             |           Apple            |
| papaya                  |            Mamao            |           Papaya           |
| mango                   |            Manga            |           Mango            |
| passion_fruit           |          Maracuja           |       Passion fruit        |
| quince                  |           Marmelo           |           Quince           |
| walnut                  |      Noz (Fruto Seco)       |     Walnut (Dry Fruit)     |
| heart_of_palm           |           Palmito           |         Palm heart         |
| pear                    |            Pera             |            Pear            |
| peach                   |           Pessego           |           Peach            |
| black_pepper            |      Pimenta do Reino       |        Black pepper        |
| sisal_or_agave          |   Sisal ou Agave (Fibra)    |   Sisal or Agave (Fiber)   |
| tangerine               |          Tangerina          |         Tangerine          |
| tung                    |     Tungue (Fruto Seco)     |      Tung (Dry Fruit)      |
| annatto_seeds           |      Urucum (Semente)       |       Annatto (Seed)       |
| grape                   |             Uva             |           Grape            |
| permanent_total         |            Total            |           Total            |

</details>

**Examples:**

``` r
# download treated data at the state level from 2010 to 2011 for all crops
data <- load_pam(
  dataset = "all_crops",
  raw_data = FALSE,
  geo_level = "state",
  time_period = 2010:2011,
  language = "eng"
)
```

## PEVS

Loads information on the amount and value of the production of the
exploitation of native plant resources and planted forest massifs, as
well as existing total and harvested areas of forest crops.

Data is from the Silviculture and Forestry Extraction Production (PEVS,
in Portuguese), a nationwide annual survey conducted by IBGE (Brazilian
Institute of Geography and Statistics). The data also has multiple
aggregation levels, such as nationwide, by region, mesoregion and
microregion, as well as state and municipality.

The data available has a yearly frequency and is available from 1986 to
the present, with the exception of the data on total area for
production, which are only available from 2013 onwards. More information
can be found in [this
link](https://www.ibge.gov.br/en/statistics/economic/agriculture-forestry-and-fishing/18374-forestry-activities.html?=&t=o-que-e).

------------------------------------------------------------------------

**Options:**

1.  **dataset**: there are three choices:

    - `"pevs_forest_crops"`: provides data related to both quantity and
      value of the forestry activities. The data goes from 1986 to 2019
      and it is divided by type of product.
    - `"pevs_silviculture"`: provides data related to both quantity and
      value of the silviculture. The data goes from 1986 to 2019 and it
      is divided by type of product.
    - `"pevs_silviculture_area"`: total existing area used for
      silviculture in 12/31.The data goes from 2013 to 2019 and it is
      divided by forestry species.

2.  **raw_data**: there are two options:

    - `TRUE`: if you want the data as it is originally.
    - `FALSE`: if you want the treated version of the data.

3.  **geo_level**: `"country"`, `"region"`, `"state"`, or
    `"municipality"`

4.  **time_period**: picks the years for which the data will be
    downloaded

5.  **language**: you can choose between Portuguese `("pt")` and English
    `("eng")`

------------------------------------------------------------------------

**Examples:**

``` r
# Download treated (raw_data = FALSE) silviculture data (dataset = 'pevs_silviculture')
# by state (geo_level = 'state') from 2012 (time_period =  2012)
# in portuguese (language = "pt")
data <- load_pevs(
  dataset = "pevs_silviculture",
  raw_data = FALSE,
  geo_level = "state",
  time_period = 2012,
  language = "pt"
)

# Download raw (raw_data = TRUE) forest crops data by region
# from 2012 to 2013 in english
data <- load_pevs(
  dataset = "pevs_forest_crops",
  raw_data = TRUE,
  geo_level = "region",
  time_period = 2012:2013
)
```

## PPM

Data on livestock inventories (e.g:cattle, pigs and hogs) in Brazilian
Municipalities, as well as amount and value of animal products
(e.g:output of milk, hen eggs, quail eggs, honey).

The periodicity of the survey is annual. The geographic coverage is
national, with results released for Brazil, Major Regions, Federation
Units, Mesoregions, Microregions and Municipalities.

The data available has a yearly frequency and is available from 1974 to
the present. More information can be found in [this
link](https://www.ibge.gov.br/en/statistics/economic/agriculture-forestry-and-fishing/17353-municipal-livestock-production.html?=&t=o-que-e).

------------------------------------------------------------------------

**Options:**

1.  **dataset**: there are five possible choices: \*
    `"ppm_livestock_inventory"` \* `"ppm_sheep_farming"` \*
    `"ppm_animal_orig_production"` \* `"ppm_cow_farming"` \*
    `"ppm_aquaculture"`

2.  **raw_data**: there are two options:

    - `TRUE`: if you want the data as it is originally.
    - `FALSE`: if you want the treated version of the data.

3.  **geo_level**: `"country"`, `"region"`, `"state"`, or
    `"municipality"`

4.  **time_period**: picks the years for which the data will be
    downloaded

5.  **language**: you can choose between Portuguese `("pt")` and English
    `("eng")`

------------------------------------------------------------------------

**Examples:**

``` r
# Download treated data (raw_data = FALSE) about aquaculture (dataset = "ppm_aquaculture")
# from 2013 to 2015 (time_period = 2013:2015) in english
# with the level of aggregation being the country (geo_level = "country").
data <- load_ppm(
  dataset = "ppm_aquaculture",
  raw_data = FALSE,
  geo_level = "country",
  time_period = 2013:2015
)

# Download raw data about sheep farming by state from 1980 to 1995 in portuguese (language = "pt")
data <- load_ppm(
  dataset = "ppm_sheep_farming",
  raw_data = TRUE,
  geo_level = "state",
  time_period = 1980:1995,
  language = "pt"
)
```

## SIGMINE

Loads information the mines being explored legally in Brazil, including
their location, status, product being mined and area in square meters
etc. Survey is done at municipal and state level. The National Mining
Agency (ANM) is responsible for this survey.

------------------------------------------------------------------------

**Options:**

1.  **dataset**: `"sigmine_active"`

2.  **raw_data**: there are two options:

    - `TRUE`: if you want the data as it is originally.
    - `FALSE`: if you want the treated version of the data.

3.  **language**: you can choose between Portuguese `("pt")` and English
    `("eng")`

------------------------------------------------------------------------

**Examples:**

``` r
# Download treated data (raw_data = FALSE) in portuguese (language = "pt").
data <- load_sigmine(
  dataset = "sigmine_active",
  raw_data = FALSE,
  language = "pt"
)
```

## ANEEL

Loads data from the National Electrical Energy Agency (ANEEL), a
Brazilian independent federal agency linked to the Ministry of Mines and
Energy (MME). ANEEL works to provide favorable conditions for the
Electrical Energy Market to develop with balance and for the benefit of
society.

As for now, there are three different datasets available for download:
the Energy Development Budget and the Energy Generation.

#### Energy Development Budget

The Energy Development Budget dataset showcases the Energy Development
Account’s (CDE) anual budget expenses. The CDE is designed to promote
the Brazilian energy development and is managed by the Electrical Energy
Commercialization Chamber (CCEE).

The dataset makes available the year of the observation – from 2013 to
2022 –, the type of expense, its value in R\$ (Reais) and its share over
the total amount of CDE budget expenses on the year\*.

\*Note that ‘share_of_total’ values sum to 1 for each year available.

#### Energy Generation

The Energy Generation dataset showcases information about ANEEL’s
Generation Informations System (SIGA). SIGA provides information about
the Brazilian electrical energy generation installed capacity.

The dataset provides information at the individual venture/entity level.
It contains information about the power, source, stage, type of
permission, origin and final fuel with which each venture/entity
operates, as well as other legal, technical and geographical
information.\* Operation start dates contained in the dataset go as far
back as 1924 up to 2022.

\* For more details on each variable, access [This
link](https://app.powerbi.com/view?r=eyJrIjoiNjc4OGYyYjQtYWM2ZC00YjllLWJlYmEtYzdkNTQ1MTc1NjM2IiwidCI6IjQwZDZmOWI4LWVjYTctNDZhMi05MmQ0LWVhNGU5YzAxNzBlMSIsImMiOjR9)
and select “Manual do Usuario”.

#### Energy Enterprises

The Energy Enterprises dataset showcases information about distributed
micro and mini generators, covered by the Regulatory Resolution nº
482/2012. The list of projects is classified by variables that make up
their identification, namely: connected distributor, project code,
numerical nucleus of the project code, owner name, production class,
subgroup, name of the owner, number of consumer units that receive
credits, connection date, type of generating unit, source, installed
power, municipality, and federative unit where it is located.

The data is expressed in quantities and installed power in kW
(kilowatt). The quantity corresponds to the number of distributed micro
or mini generators installed in the specified period. The installed
power is defined by the sum of the nominal active electric power of the
generating units.

\* For more details on each variable, access [This
link](https://dadosabertos.aneel.gov.br/dataset/relacao-de-empreendimentos-de-geracao-distribuida)
and select “Dicionário de dados”.

------------------------------------------------------------------------

**Options:**

1.  **dataset**: there are three choices:
    - `"energy_development_budget"`: government spending towards energy
      sources
    - `"energy_generation"`: energy generation by entity/corporation
    - `"energy_enterprises_distributed"`: distributed micro and mini
      generators
2.  **raw_data**: there are two options:
    - `TRUE`: if you want the data as it is originally.
    - `FALSE`: if you want the treated version of the data.
3.  **language**: you can choose between Portuguese `("pt")` and English
    `("eng")`

------------------------------------------------------------------------

**Examples:**

``` r
# download treated data about energy generation
clean_aneel <- load_aneel(
  dataset = "energy generation",
  raw_data = FALSE
)
```

## EPE

Loads data from the Energy Research Company (EPE), a Brazilian public
company that works closely with the Brazilian Ministry of Mines and
Energy (MME) and other agencies to ensure the sustainable development of
Brazil’s energy infrastructure. EPE’s duty on that mission is to support
MME with quality research and studies in order to aid Brazil’s energy
infrastructure planning.

As for now, there are two different datasets available for download: the
Energy Consumption Per Class and the National Energy Balance. Both of
them were obtained from the [EPE
website](https://www.epe.gov.br/sites-pt/publicacoes-dados-abertos/publicacoes/).

#### Energy Consumption Per Class

The Energy Consumption Per Class dataset provides monthly data about
energy consumption and consumers from 2004 to 2022, for each class of
energy consumption.

The different classes are Total consumption (and consumers), Industrial
consumption (and consumers), Residential consumption (and consumers),
Commercial consumption (and consumers), Captive consumption\* and Other
consumption (and consumers).\*\*

\*Note that there is no consumer data for ‘Captive’ class at all.

\*\*There is also no consumer data for ‘Industrial’, ‘Commercial’ and
‘Other’ classes when the geographical level is ‘Subsystem’ or ‘Region’.

There are three different aggregation levels: The Region level
encompasses the five Brazilian geographical regions (North, Northeast,
Midwest, Southeast and South). The Subsystem level encompasses the five
Brazilian Electric Subsystems (North, Northeast, Southeast/Midwest,
South, Isolated Systems). The State level encompasses the 26 Brazilian
States and the Federal District.

#### National Energy Balance

The National Energy Balance is a thorough and extensive research
developed and published by EPE that contains useful data about energy
consumption, generation, exportation and many more subjects.

As for now, the National Energy Balance dataset provides yearly data
about energy generation per source of production. The sources can be
divided into two groups: the renewable sources (hydro, wind, solar,
nuclear, thermal, sugar_cane_bagasse, firewood, black_liquor) and the
non-renewable sources (steam_coal, natural_gas, coke_oven_gas, fuel_oil,
diesel).

The dataset has information at the Brazilian state level, including the
Federal District, from 2011 to 2021 and also indicates whether the state
is in the Legal Amazon or not.

------------------------------------------------------------------------

**Options:**

1.  **dataset**: there are two choices:
    - `"energy_consumption_per_class"`: monthly energy consumption and
      consumers by State, Region or Electric Subsystem
    - `"national_energy_balance"`: yearly energy generation per source,
      by State
2.  **raw_data**: there are two options:
    - `TRUE`: if you want the data as it is originally.
    - `FALSE`: if you want the treated version of the data.
3.  **geo_level**: only applies to the `"energy_consumption_per_class"`
    dataset.
    - `"state"`
    - `"subsystem"`
4.  **language**: you can choose between Portuguese `("pt")` and English
    `("eng")`

------------------------------------------------------------------------

**Examples:**

``` r
# download treated data about energy consumption at the state level
clean_epe <- load_epe(
  dataset = "energy_consumption_per_class",
  geo_level = "state",
  raw_data = FALSE
)
```

# Other tools

## Legal Amazon Municipalities

Many of our functions use a dataset with Brazilian municipalities, their
municipality codes, whether they belong to the Legal Amazon, their
state, and some more variables. It was constructed from the [IBGE
spreadsheet](https://www.ibge.gov.br/geociencias/cartas-e-mapas/mapas-regionais/15819-amazonia-legal.html?=&t=acesso-ao-produto)
with Legal Amazon municipalities, along with a data frame from the
‘geobr’ package. For more information on the columns, run
`??datazoom.amazonia::municipalities`.

``` r
# load Brazilian municipalities dataset
data <- datazoom.amazonia::municipalities
```

## <a name="googledrive"></a> The ‘googledrive’ package

For some of our functions, the original data is stored in Google Drive
and exceeds the file size limit for which direct downloads are possible.
As a result, the `googledrive` package is required to download the data
though the Google Drive API and run the function.

The first time the package is called, it requires you to link your
Google account and grant permissions to be able to download data through
the Google Drive API.

You **must** tick all boxes when the permissions page opens, or else the
following error will occur:

``` r
# Error in `gargle_abort_request_failed()`:
# ! Client error: (403) Forbidden
# Insufficient Permission: Request had insufficient authentication scopes.
# • domain: global
# • reason: insufficientPermissions
# • message: Insufficient Permission: Request had insufficient authentication
#  scopes.
# Run `rlang::last_error()` to see where the error occurred.
```

For further information, click
[here](https://googledrive.tidyverse.org/) to access the official
package page.

## Credits

DataZoom is developed by a team at Pontifícia Universidade Católica do
Rio de Janeiro (PUC-Rio), Department of Economics. Our official website
is at: <https://www.econ.puc-rio.br/datazoom/>.

To cite package `datazoom.amazonia` in publications use:

> Data Zoom (2023). Data Zoom: Simplifying Access To Brazilian
> Microdata.  
> <https://www.econ.puc-rio.br/datazoom/english/index.html>

A BibTeX entry for LaTeX users is:

    @Unpublished{DataZoom2023,
        author = {Data Zoom},
        title = {Data Zoom: Simplifying Access To Brazilian Microdata},
        url = {https://www.econ.puc-rio.br/datazoom/english/index.html},
        year = {2023},
    }
