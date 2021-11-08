General View:
The datazoom_viz repository is used for developing visualizations in shiny R codes and fueling the https://datazoomamazonia.com.br/ website.

Repository organization:
 Main Directories:
 - "./data": contains all the .rds databases and .csv files that are used in the generation of the visualizations. The files' names are organized in order to follow a pattern: xxxx.rds for the databases and xxxx_dic for the .csv dictionaries that correspond to the same database.
 
 - "./data-raw": contains .R scripts that generates both the .rds databases and the .csv files that are recorded in the "./data" directory. In order to generate the databases, the scripts use the datazoom.amazonia R package, developed by the Datazoom team. Each .R script is responsible for generating the .rds and .csv files for specific geographic aggregation of the researches. 
 
 - "./scripts": 