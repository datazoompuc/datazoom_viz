#  -------------------------------- Define Parametros da base --------------------------------

# Carrega bibliotecas
library(dplyr)
library(data.table)

# Função para criar lista nomeada hierarquica dos grupos (para que as variáveis apareçam agrupadas no selectinput)
grouped_list <- function(df) {
  # cria lista hierarquica a partir de dataframe, para os selecinputs
  groups <- unique(df$var_group)
  grouped_list <- setNames(
    nm = groups,
    lapply(groups, function(x) {
      setNames(
        nm = df$label[which(df$var_group == x)],
        as.list(df$var[which(df$var_group == x)])
      )
    })
  )
  return(grouped_list)
}

# Função para retornar parâmetros da base
get_db_param <-
  function(param_filename = "param.csv", db_filename = "") {
    # Se arquivo de parametros não existe, cria um vazio
    if (!file.exists(param_filename)) {
      temp_db <- read.csv(db_filename, fileEncoding = "UTF-8") # Convenção importante = UTF-8
      columns <- colnames(temp_db)
      rm(temp_db)
      temp_param_table <- data_frame(
        var = columns,
        x = TRUE,
        y = TRUE,
        color = TRUE,
        size = TRUE,
        slider = TRUE,
        label = columns,
        desc = columns,
        group = ""
      )

      write.csv(temp_param_table, file = param_filename)
    }
    # Carrega arquivo de parâmetros
    param_table <- fread(param_filename, encoding = "UTF-8") # Convenção importante = UTF-8

    # Cria lista de parâmetros
    param <- list(
      table = param_table, # copia tabela de parâmetros na lista
      # define colunas possíveis para cada dimensão
      x_cols = param_table[which(param_table$x)],
      y_cols = param_table[which(param_table$y)],
      color_cols = param_table[which(param_table$color)]
    )

    # Define escolhas agrupadas para cada selectinput
    param$x_choices <- append("", grouped_list(param$x_cols))
    param$y_choices <- append("", grouped_list(param$y_cols))
    param$color_choices <- append("", grouped_list(param$color_cols))

    # Define coluna padrão para cada dimensão
    param$x_def <- ""
    param$y_def <- ""
    param$color_def <- ""
    param$text_def <- ""
    param$slider_def <- ""

    # Retorna lista de parâmetros
    param
  }
