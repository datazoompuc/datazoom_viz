# Dados da PNADC (`data/`)

O script `data-raw/ibge_pnadc.R` gera os datasets de mercado de trabalho da PNAD Contínua trimestral (IBGE), a partir dos microdados, num formato agregado: uma linha por trimestre × recorte geográfico × categoria.
Fonte: PNAD Contínua Trimestral / IBGE, via `datazoom.social::load_pnadc(raw_data = FALSE, panel = "none")`. Séries de 2012 em diante (hoje até 2026-2). Todos os indicadores usam o peso amostral (`V1028`).

## Como atualizar

Na raiz do repositório, rodar `data-raw/ibge_pnadc.R`. Antes, ajustar `source_path` (hoje `F:/PNADC/load_pnadc DZ`, uma pasta local de Windows) para uma pasta com bastante espaço livre.

**Rebaixar todos os trimestres a cada atualização.** O IBGE revisa os deflatores retroativamente a cada divulgação; por isso não se reaproveitam arquivos de execuções anteriores, do contrário a série de rendimento real fica inconsistente.

Escala do processo (medido em nov/2026, para um único trimestre, 2026-2): download de 222 MB (zip), arquivo salvo de 1,3 GB e cerca de 145 s no total. Para os 58 trimestres de 2012 a 2026-2, isso dá algo da ordem de dezenas de GB de arquivos intermediários e várias horas de processamento (estimativa por extrapolação; o processo completo não foi cronometrado).

O script possui uma checagem integrada no começo: ele compara o último ano e trimestre de `data/ibge_pnadc_atividades_ocupacoes.rds` com o último trimestre de microdados publicado no FTP do IBGE (consulta só o primeiro byte do zip, sem baixar nada). Se não há trimestre novo, encerra com status 0 antes de baixar a série. Para rodar mesmo assim (por exemplo, numa revisão de deflator), mudar `forcar_atualizacao` para `TRUE` no topo do bloco.

A verificação também roda automaticamente no GitHub Actions (`.github/workflows/check-pnadc-updates.yml`), todos os dias entre os dias 10 e 28 dos meses de divulgação (fev, abr, mai, ago e nov), às 12:00 UTC. O arquivo de microdados nem sempre aparece no FTP no dia da divulgação dos resultados: em 2026, o do 1º trimestre foi postado em 24/04 e o do 2º em 14/08. O workflow chama `scripts/check_pnadc_updates.R` e avisa no Slack quando algum dataset está desatualizado; ele **não** atualiza a base (ver Pendências).

## Arquivos gerados

Os dois datasets estão em formato largo por indicador: uma coluna por indicador e uma linha por trimestre × `group` × `composicao_demografica` (e `setor`/`id`, no segundo).

- `ibge_pnadc_trabalho.rds`: mercado de trabalho por recorte demográfico. `composicao_demografica` é `Todos`, sexo, faixa etária ou faixa de escolaridade. Dicionário: `ibge_pnadc_trabalho_dic.csv`.
- `ibge_pnadc_atividades_ocupacoes.rds`: o mesmo conjunto de indicadores por atividade e ocupação. A coluna `id` diz o tipo da categoria: `All` (total), `CNAE` (atividade, 2 dígitos) ou `COD` (ocupação, 2 dígitos); `composicao_demografica` traz a categoria. `setor` filtra o universo: `todos`, `formal`, `informal`, `publico` ou `privado`.

| Coluna | O que é |
|---|---|
| `Ano`, `Trimestre`, `time` | Ano, trimestre (1 a 4) e a data do primeiro mês do trimestre (`3 × Trimestre − 2`). |
| `group` | Recorte geográfico: `Brasil`, as 5 regiões, `Amazônia Legal`, `Fora da Amazônia Legal` e as 27 UFs (35 valores). |
| `composicao_demografica` | Categoria do recorte (ver acima). |
| `id`, `setor` | Só em `atividades_ocupacoes`: tipo de categoria e universo. |
| `pia`, `ocupado`, `desocupado`, `forca_trab`, `pea`, `fora_forca_trab`, `idade_de_trabalhar`, `desempregado`, `desalentado`, `nem_nem` | Totais populacionais (soma dos pesos). |
| `formal`, `informal`, `empregado_sc`, `empregado_cc`, `conta_propria`, `conta_propria_contrib`, `conta_propria_nao_contrib`, `empregador`, `militar_estatutario`, `home_office` | Totais de ocupados por tipo de inserção. |
| `rendimento_habitual_real` | Soma ponderada do rendimento habitual real (deflacionado). |
| `taxa_participacao`, `taxa_ocupacao`, `taxa_desemprego`, `taxa_informalidade`, `taxa_desalento`, `taxa_nem_nem` | Taxas: PEA/PIA, ocupados/PIA, desempregados/força de trabalho, informais/ocupados, desalentados/PIA e nem-nem/PIA. |
| `prop_empregado_sc`, `prop_empregado_cc`, `prop_conta_propria`, `prop_conta_propria_contrib`, `prop_conta_propria_nao_contrib`, `prop_empregador`, `prop_militar_estatutario`, `prop_home_office` | Participação de cada tipo de inserção nos ocupados. |
| `rendimento_medio`, `massa_salarial` | Rendimento real médio (por ocupado) e rendimento real total. |

`ibge_pnadc_trabalho.rds` tem ainda a coluna `prop_informal`, cópia de `taxa_informalidade`.

## Sobre os dados

- **Rendimento real.** Vem do deflator do IBGE, revisado a cada divulgação (ver "Como atualizar").
- **Valores ausentes.** As linhas com categoria ausente (por exemplo, sexo ou atividade não informados) são descartadas antes de agregar.
- **Sobreposição dos arquivos antigos.** Os arquivos `ibge_pnadc_cnae.rds` e `ibge_pnadc_cod.rds` são subconjuntos exatos de `ibge_pnadc_atividades_ocupacoes.rds` (`id` igual a `CNAE` ou `COD`), por isso podem ser removidos.

## Pendências

- **Limpeza.** Apagar `ibge_pnadc_cnae.rds`, `ibge_pnadc_cod.rds`, os apps `ts_ibge_pnadc_cnae`, `ts_ibge_pnadc_cod` (e as versões em inglês), os dicionários `cod` e o script legado `data-raw/ibge_pnadc_ranking.R`, e atualizar `app_manifest.csv` e `dataset_registry.csv`. Antes, confirmar que o app unificado `ts_ibge_pnadc_atividades_ocupacoes` oferece CNAE e COD em português e inglês, e se há links externos para os apps antigos.
- **Base longa única.** Definir se `trabalho` e `atividades_ocupacoes` viram uma base longa só, com a coluna `id` cobrindo também sexo, faixa etária e escolaridade (isso afeta o app `ts_ibge_pnadc_trabalho`).
- **Atualização automática.** O workflow só checa e avisa. Para salvar a base no GitHub, como no COMEX, o processamento precisa rodar fora da pasta local `F:/`, trimestre a trimestre (baixa, agrega, apaga), porque o disco do runner (~14 GB) não comporta os arquivos intermediários e o job tem limite de 6 horas. Falta medir se o tempo cabe e o uso de memória.
- **Pacote `datazoom.social`.** O script lista `*.rds` na pasta de download, mas a versão atual de `load_pnadc` salva `.csv`. Confirmar com qual versão o script foi rodado e ajustar.
- **Caminho de saída.** A seção 2 grava `ts_ibge_pnadc_trabalho/ibge_pnadc_trabalho.rds`, mas o cabeçalho do script e este README dizem `data/ibge_pnadc_trabalho.rds`. Confirmar qual é o correto.
- **Tamanho no Git.** `ibge_pnadc_atividades_ocupacoes.rds` tem 67 MB (o limite do GitHub é 100 MB por arquivo) e cada atualização automática guardaria uma nova cópia no histórico.
- **RAIS.** Fica em script e README próprios (ver pendências da RAIS); não faz parte deste.
