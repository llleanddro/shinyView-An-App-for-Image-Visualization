library(shiny)
library(shinyjs)
library(shinyWidgets)
library(leaflet)
library(sf)
library(dplyr)
library(shinyMobile)


# Carregue os dados do CSV da pasta 'data/species_coordinates'
data <- read.csv("data/species_coordinates/species.csv")

# Carregue os limites da Caatinga a partir do shapefile na pasta 'data/caatinga_limites'
caatinga_limites <- st_read("data/caatinga_limites/caatinga.shp")


#---- Defina a função JavaScript para redimensionar o mapa da janela STUDY AREA----
js_code <- '
$(window).on("resize", function() {
  var width = $(window).width();
  if (width < 768) {
    $("#map").css("height", "200px"); // Ajuste a altura para telas menores
  } else {
    $("#map").css("height", "365px"); // Ajuste a altura para telas maiores
  }
});

$(document).ready(function() {
  $(window).trigger("resize"); // Ative o redimensionamento inicialmente
});
'



#---- Defina cores personalizadas para as espécies----

species_colors <- c(
  "Calotropes procera (Ait.) R. Br." = "blue",
  "Coffea arabica Benth." = "green",
  "Dodonaea viscosa Jacq." = "red",
  "Nicotiana glauca Graham" = "black",
  "Catharanthus roseus (L.) G. Don" = "pink",
  "Cyperus rotundus L." = "green",
  "Impatiens walleriana Hook. f." = "blue",
  "Tradescantia zebrina Heynh." = "black",
  "Aristida adscensionis L." = "green",
  "Cenchrus ciliaris L." = "blue",
  "Cenchrus echinatus L." = "gold",
  "Megathyrsus maximus Jacq." = "black",
  "Acacia mearns De Willd." = "black",  
  "Azadirachta indica A. Juss." = "blue", 
  "Leucaena leucocephala (Lam.) de Wit." = "green",  
  "Parkinsonia aculeata L." = "pink", 
  "Prosopis juliflora (Sw.) Dc." = "gold", 
  "Syzygium cumini (L.) Skeels." = "violet",  
  "Tecoma stans (L.) Juss. ex Kunth." = "red"  
)



#----UI----

ui <- fluidPage(
  useShinyjs(),
  tags$script(HTML(js_code)), # Adicione o código JavaScript aqui
  tags$head(
    tags$link(rel = "stylesheet", href = "https://maxcdn.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css"),
    tags$style(
      HTML("
      body {
        background-color: #222; /* Fundo cinza escuro */
      }
      /* Estilo para os ícones de bolinha preta */
    .bullet-icon {
      color: black; /* Cor da bolinha preta */
      font-size: 16px; /* Tamanho do ícone */
      margin-right: 5px; /* Espaço entre o ícone e o nome da espécie */
    }

    /* Estilo para a classe species-icon */
    .species-icon {
      display: flex;
      align-items: center;
    }
      /* Tamanho do cabeçalho da janela INFO */
      .modal-title {
        font-size: 18px;
        font-weight: bold;
        text-align: center;
        margin-bottom: 10px;
        color: black;
      }
      
      /* Estilo para telas menores (max-width: 768px) */
      @media (max-width: 768px) {
        .modal-title {
          font-size: 14px; /* Reduza o tamanho do texto para telas menores */
        }
      }
      /* fontes responsivas para as os botoes principais e suas janelas flutuantes*/
    .responsive-title {
      text-align: center;
      font-size: 1.5vw; /* Usando vw (viewport width) para o tamanho da fonte responsiva */
      font-weight: bold;
      margin-bottom: 9px;
      color: black;
    }
    
    /* Media query para ajustar o tamanho da fonte do título em telas menores */
    @media (max-width: 768px) {
      .responsive-title {
        font-size: 6vw; /* Ajuste o tamanho da fonte para telas menores */
      }
    }
      .modal-content {
        max-width: 50%; /* Defina uma largura máxima para a janela flutuante */
        max-height: 80vh; /* Defina uma altura máxima em relação à altura da tela */
        overflow: auto; /* Adicione barras de rolagem se o conteúdo exceder a altura máxima */
        position: fixed;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        padding: 20px;
        background-color: white;
        box-shadow: 0px 0px 10px rgba(0,0,0,0.5);
      }
      .modal-title {
        font-size: 18px; /* Tamanho do cabeçalho da janela INFO */
        font-weight: bold; /* Texto em negrito */
        text-align: center; /* Centraliza o título */
        margin-bottom: 10px; /* Espaço entre o título e o conteúdo */
        color: black;
      }
      /* Estilo para telas menores (max-width: 768px) */
      @media (max-width: 768px) {
        .modal-title {
          font-size: 14px; /* Reduza o tamanho do texto para telas menores */
        }
      }
      .species-list {
        list-style-type: none;
        padding: 0;
        font-size: 14px; /* Ajuste o tamanho da fonte para dispositivos móveis */
        max-height: 200px; /* Altura máxima da lista */
      }
      
      /* Adicione as classes e estilos para os botões X e Back aqui */
      .close-button {
        background-color: white;
        border: 2px solid black; /* Adiciona um contorno preto */
        color: black; /* Cor do texto */
      }
      .back-button {
        background-color: white;
        border: 1px solid black; /* Adiciona um contorno preto */
        color: black; /* Cor do texto */
      }
      ")
    ),
  ),
  
  fluidRow(
    column(4, offset = 4,
           # Adicione a div com ID "title_div" ao redor do título principal
           div(id = "title_div",
               style = "margin-top: 20px;",  # Adicione esta linha para definir o espaçamento superior
               tags$h1(class = "responsive-title", 
                       style = "color: gold;",  # Defina a cor como gold para o título da aplicação
                       "Caatinga Ecosystem: Non-Native Species in the Future Decades")),
           
           actionButton("info_button", "INFO ℹ", width = "100%", class = "btn btn-primary responsive-title"),
           actionButton("study_area_button", "STUDY AREA 🏜️️", width = "100%", class = "btn btn-primary responsive-title"),
           actionButton("life_forms_button", "LIFE FORMS MODELING 💻", width = "100%", class = "btn btn-primary responsive-title"),
           actionButton("species_modeling_button", "SPECIES MODELING 💻", width = "100%", class = "btn btn-primary responsive-title"),
           actionButton("overlap_button", "SPECIES MAP OVERLAY 💻", width = "100%", class = "btn btn-primary responsive-title")
    )
  ),
  

  
#---- Janela flutuante para INFO----
  
  shinyjs::hidden(
    div(
      id = "info_modal",
      class = "modal-content",
      style = "width: 95%; max-width: 400px; height: 95vh; max-height: 80%;",  # Defina as dimensões máximas
      
      div(
        style = "position: absolute; top: 2px; left: 2px;", # Posiciona os botões de tradução no canto superior esquerdo
        actionButton("btn_pt", "🇧🇷", class = "btn btn-info", style = "font-size: 10px; padding: 0px 3px;"),
        actionButton("btn_in", "🇺🇸", class = "btn btn-info", style = "font-size: 10px; padding: 0px 3px;")
      ),
      uiOutput("dynamic_info_content"),
      div(
        style = "position: absolute; top: 2px; right: 2px;", # Posição do botão X
        actionButton("close_info_modal", "X", class = "close-button", style = "font-size: 10px; padding: 0px 3px;")
      )
    )
  ),
  
  
#---- Conteúdo da "nova página" para STUDY AREA----
  
  shinyjs::hidden(
    div(
      id = "study_area_content",
      class = "modal-content",
      style = "width: 95%; max-width: 400px; height: 95vh; max-height: 90%;",  # Defina as dimensões máximas
      
      # Cabeçalho da janela STUDY AREA
      
      h3(id = "study_area_title", "Caatinga boundaries", class = "responsive-title", style = "text-align: center;"),
      
      # Botão Back
      div(
        style = "position: absolute; top: 3px; left: 3px;",
        actionButton("back_to_main", "Back", class = "close-button", style = "font-size: 10px; padding: 1px 4px;")
      ),
      
      # Botão 'Window contents'
      div(
        style = "position: absolute; top: 0px; right: 2px;",
        actionButton("study_area_info_button", "Window contents", class = "btn btn-info", style = "font-size: 9px; padding: 1px 4px;")
      ),
      
      # Botão janela de informação
      shinyjs::hidden(
        div(
          id = "study_area_info_window",
          class = "modal-content",
          style = "width: 90%; max-width: 300px; height: 30%; max-height: 300px; overflow: auto; position: fixed; top: 83%; left: 50%; transform: translate(-50%, -50%); padding: 10px; background-color: #ccffcc; box-shadow: 0px 0px 10px rgba(0,0,0,0.5); z-index: 100;",
          h3("Information", class = "modal-title"),
          p(
            HTML("The study base for this application focuses on the Caatinga, a Semi-Arid Tropical Dry Forest 
               (SDTF) in Brazil, covering 833,000 km². The Caatinga spans nine states in the Northeast 
               region and extends into the northern part of Minas Gerais in the Southeast. The region often 
               experiences prolonged droughts lasting six to eight months, with precipitation being less 
               than twice the temperature. The climate is predominantly semi-arid, with an average annual 
               rainfall of around 800 mm, exceeding 1,000 mm in coastal areas but dropping below 300 mm
               in some inland regions. The rainy season typically occurs from January to May, though this 
               can vary due to extreme weather and differences in vegetation across the region.Temperatures in the Caatinga 
               fluctuate throughout the year, generally ranging between 22ºC and 30ºC.<br/><br/>
               
               When selecting a life form, you visualize within the Caatinga ecosystem's boundaries in 
               Brazil, the non-native plant species and their georeferenced points collected from the Global 
               Biodiversity Information Facility (GBIF) and 'Species Link' databases from 1999 to 2021. 
               These occurrences, along with temperature and precipitation variables from 'Worldclim.com', 
               were used to model species distribution across four time intervals: 2021 to 2040, 2041 to 2060, 2061 to 2080, and 2081 to 2100.
               The listed non-native species were chosen due to their confirmed presence in natural environments, 
               recognition as invasive in the region, and occurrence in at least three of the ten states constituting Brazil's 
               Northeast region.<br/><br/>
               
               The modeling procedure was performed using the Maximum Entropy Algorithm (MaxEnt). 
               The primary output is habitat suitability maps, reflecting the environmental conditions 
               essential for a species' existence or survival.")
            
          ),
          
          actionButton("close_study_area_info_window", "X", class = "btn btn-danger", style = "position: absolute; top: 3px; right: 3px;")
        )
      ),
      
      fluidRow(
        column(width = 12,
               leafletOutput("map")
        )
      ),
      fluidRow(
        column(width = 5,
               style = "margin-top: 10px;",
               selectInput("life_form_selector", "Choose a life form:", choices = c("", "Shrub", "Forb", "Grassy", "Tree"), selected = NULL, selectize = FALSE)
        )
      ),
      fluidRow(
        column(width = 7,
               div(class = "species-list",
                   uiOutput("species_list")
               )
        )
      )
    )
  ),
  
  
  
#---- Conteúdo da "nova página" para LIFE FORMS MODELING----
  
  shinyjs::hidden(
    div(
      id = "life_forms_content",
      class = "modal-content",
      style = "width: 95%; max-width: 400px; height: 95vh; max-height: 90%;",
      
      # Cabeçalho da janela LIFE FORMS MODELING
      h3(id = "life_forms_title", 
         tags$b("Life Forms modeling"), 
         class = "responsive-title", style = "text-align: center;font-weight: bold;"),
      
      # Botão 'Back' (já existente)
      div(
        style = "position: absolute; top: 2px; left: 2px;",
        actionButton("back_to_main2", "Back", class = "close-button", style = "font-size: 10px; padding: 1px 4px;")
      ),
      
      # Adicionar o botão 'Window contents'
      div(
        style = "position: absolute; top: 0px; right: 2px;",
        actionButton("window_contents_button", "Window contents", class = "btn btn-info", style = "font-size: 9px; padding: 1px 4px;")
      ),
      # conteúdo da janela de informação
      shinyjs::hidden(
        div(
          id = "info_window",
          class = "modal-content",
          style = "width: 90%; max-width: 300px; height: 30%; max-height: 300px; overflow: auto; position: fixed; top: 77%; left: 50%; transform: translate(-50%, -50%); padding: 10px; background-color: #ccffcc; box-shadow: 0px 0px 10px rgba(0,0,0,0.5); z-index: 100;",  # Adicione z-index: 100 aqui        h3("Information", class = "modal-title"),
          h3("Information", class = "modal-title"),
          p("When you select a climate change scenario and life-form, you can view its model in the Caatinga by sliding the timeline.
          The optimistic scenario suggests a world with low greenhouse gas emissions. 
          Conversely, the pessimistic scenario depicts a trajectory of global population growth 
          and high dependence on fossil fuels in the world economy."),
          actionButton("close_info_window", "X", class = "btn btn-danger", style = "position: absolute; top: 3px; right: 3px;")
        )
      ),
      
      fluidRow(
        column(6,
               pickerInput(
                 "scenario_selection",
                 label = "Choose a scenario:",
                 choices = c("Optimistic", "Pessimistic"),
                 selected = NULL,
                 options = list(`actions-box` = TRUE)
               )
        ),
        
        # Coluna para o botão 'Choose a life form:'
        column(6,
               pickerInput(
                 "life_form_selection",
                 label = "Choose a life form:",
                 choices = c("Shrubs", "Forbs", "Grasses", "Trees"),
                 selected = NULL,
                 options = list(`actions-box` = TRUE),
                 multiple = FALSE
               )
        )
      ),
      
      # Barra de rolagem horizontal para selecionar a imagem
      fluidRow(
        column(12,
               sliderInput("image_slider", "Move the time interval slider:",
                           min = 1, max = 4, value = 1, step = 1),
               tags$div(id = "image_slider_labels", style = "text-align: center;")
        )
      ),
      
      div(
        # Espaço para a imagem
        uiOutput("life_forms_image")
      )
    )
  ),
  
#---- Conteúdo da "nova página" para SPECIES MODELING----
  shinyjs::hidden(
    div(
      id = "species_modeling_content",
      class = "modal-content",
      style = "width: 95%; max-width: 400px; height: 95vh; max-height: 90%;",  # Defina as dimensões máximas
      
      # Cabeçalho da janela SPECIES MODELING
      h3(id = "species_modeling_title", 
         tags$b("Species modeling"),  # Modificação para colocar em negrito
         class = "responsive-title", style = "text-align: center;font-weight: bold;"),
      
      # Botão 'Back'
      div(
        style = "position: absolute; top: 3px; left: 3px;", # Ajuste a posição do botão "Back"
        actionButton("back_to_main3", "Back", class = "close-button", style = "font-size: 10px; padding: 1px 4px;")
      ),
      
      # Botão 'Window contents'
      div(
        style = "position: absolute; top: 0px; right: 2px;",
        actionButton("species_modeling_info_button", "Window contents", class = "btn btn-info", style = "font-size: 9px; padding: 1px 4px;")
      ),
      
      # conteúdo da janela de informação
      shinyjs::hidden(
        div(
          id = "species_modeling_info_window",
          class = "modal-content",
          style = "width: 90%; max-width: 300px; height: 30%; max-height: 300px; overflow: auto; position: fixed; top: 77%; left: 50%; transform: translate(-50%, -50%); padding: 10px; background-color: #ccffcc; box-shadow: 0px 0px 10px rgba(0,0,0,0.5); z-index: 100;",  # Adicione z-index: 100 aqui        h3("Information", class = "modal-title"),
          h3("Information", class = "modal-title"),
          p("The listed non-native species were chosen due to their confirmed presence in natural environments, 
               recognition as invasive in the region, and occurrence in at least three of the ten states constituting Brazil's 
               Northeast region."),
          actionButton("close_species_modeling_info_window", "X", class = "btn btn-danger", style = "position: absolute; top: 3px; right: 3px;")
        )
      ),
      
      fluidRow(
        column(6,
               pickerInput(
                 "scenario_selection_species",
                 label = "Choose a scenario:",
                 choices = c("Optimistic", "Pessimistic"),
                 selected = "Optimistic",
                 options = list(`actions-box` = TRUE)
               )
        ),
        column(6,
               pickerInput(
                 "species_selection",
                 label = "Choose a species:",
                 choices = c(
                   "Calotropis procera", "Coffea arabica", "Dodonaea viscosa", "Nicotiana glauca",
                   "Acacia mearnsii", "Azadirachta indica", "Leucaena leucocephala", "Parkinsonia aculeata",
                   "Prosopis juliflora", "Syzygium cumini", "Tecoma stans",
                   "Aristida adscensionis", "Cenchrus echinatus", "Cenchrus ciliaris", "Megathyrsus maximus",
                   "Catharanthus roseus", "Cyperus rotundus", "Impatiens walleriana", "Tradescantia zebrina"
                 ),
                 selected = "Calotropis procera",
                 options = list(`actions-box` = TRUE),
                 multiple = FALSE  # Isso impede a seleção múltipla
               )
        )
      ),
      
      # Barra de rolagem horizontal para selecionar a imagem
      fluidRow(
        column(12,
               sliderInput("image_slider_species", "Move the time interval slider:",
                           min = 1, max = 4, value = 1, step = 1)
        )
      ),
      
      div(
        # Espaço para a imagem
        uiOutput("species_modeling_image")
      )
    )
  ),
  
  
  
#----Conteúdo da "nova página" para SPECIES MAP OVERLAY----
  shinyjs::hidden(
    div(
      id = "species_overlay_modal",
      class = "modal-content",
      style = "width: 95%; max-width: 400px; height: 95vh; max-height: 90%;",  # Defina as dimensões máximas
      
      # Cabeçalho da janela LIFE FORMS MODELING
      h3(id = "overlap_title", 
         tags$b("Species Map Overlay"),  # Modificação para colocar em negrito
         class = "responsive-title", style = "text-align: center;font-weight: bold;"),
      
      # Botão 'Back' (já existente)
      div(
        style = "position: absolute; top: 3px; left: 3px;", # Adjust the position of the "Back" button
        actionButton("back_to_main4", "Back", class = "close-button", style = "font-size: 10px; padding: 1px 4px;")
      ),
      
      # Adicionar o botão 'Window contents'
      div(
        style = "position: absolute; top: 0px; right: 2px;",
        actionButton("overlap_info_button", "Window contents", class = "btn btn-info", style = "font-size: 9px; padding: 1px 4px;")
      ),
      # conteúdo da janela de informação
      shinyjs::hidden(
        div(
          id = "overlap_info_window",
          class = "modal-content",
          style = "width: 90%; max-width: 300px; height: 30%; max-height: 300px; overflow: auto; position: fixed; top: 77%; left: 50%; transform: translate(-50%, -50%); padding: 10px; background-color: #ccffcc; box-shadow: 0px 0px 10px rgba(0,0,0,0.5); z-index: 100;",  # Adicione z-index: 100 aqui        h3("Information", class = "modal-title"),
          h3("Information", class = "modal-title"),
          p("When selecting a climate change scenario, you can view the average regions resulting 
          from the overlay of individual models for each non-native plant species, indicating 
          potential areas of invasion."),
          actionButton("close_overlap_info_window", "X", class = "btn btn-danger", style = "position: absolute; top: 3px; right: 3px;")
        )
      ),
      
      fluidRow(
        column(6,
               style = "margin-top: 20px;", # Add margin to create spacing
               pickerInput(
                 "scenario_selection_overlay",
                 label = "Choose a scenario:",
                 choices = c("Optimistic", "Pessimistic"),
                 selected = "Optimistic",
                 options = list(`actions-box` = TRUE)
               )
        ),
        column(6,
               style = "margin-top: 20px;", # Add margin to create spacing
               sliderInput("time_interval_slider_overlay", "Choose a time interval:",
                           min = 1, max = 4, value = 1, step = 1)
        )
      ),
      fluidRow(
        column(12,
               div(
                 uiOutput("overlay_image"), # Exibe a imagem gerada pela renderUI
                 style = "text-align: center;"
               )
        )
      )
    )
  )
  
  
)



#-----SERVER----

server <- function(input, output, session) {
  
  #---- mapear um diretório local para o URL de recursos do Shiny----
  addResourcePath("www", "www")
  
  #Função para alternar a visibilidade do título
  toggleTitleVisibility <- function(visible) {
    if (visible) {
      shinyjs::show("title_div")
    } else {
      shinyjs::hide("title_div")
    }
  }
  
  observeEvent(input$info_button, {
    shinyjs::hide("title_div") # Tornar o título invisível
    shinyjs::show("info_modal")
  })
  
  #---- Variável reativa TROCA DO IDIOMA ----
  
  current_language <- reactiveVal("EN")
  
  # Alterar o idioma na janela INFO para português
  observeEvent(input$btn_pt, {
    current_language("PT")
  })
  
  # Alterar o idioma na janela INFO para inglês
  observeEvent(input$btn_in, {
    current_language("EN")
  })
  
  # Renderizar o conteúdo da janela INFO
  output$dynamic_info_content <- renderUI({
    if(current_language() == "EN") {
      tagList(
        tags$h3(class = "modal-title", "About this application"),
        p("Welcome to our Shiny app, an interactive platform that showcases the results of our article 
'Caatinga: a future too dry for invasive species'. In this app, we explore the distribution of species in 
the Caatinga ecosystem, located in Northeast Brazil. We have used georeferenced data from 19 
non-native species, along with temperature and precipitation information, to assess the impacts of 
climate change on these species through the end of the 21st century. The app provides 
visualizations of the current and future distribution of these species in this unique ecosystem. For 
more information, you can access the full article through this link: (insert link here)."),
        p("This work was conducted by researchers from the Federal University of Rio Grande do Norte (UFRN) and the Federal University of Santa Catarina (UFSC). Get to know the team behind this project:"),
        tags$strong("Carlos Leandro Costa Silva"),
        tags$ul(
          class = "list-unstyled flex-column",  # Adicione a classe CSS flex-column para criar uma lista vertical
          tags$li("Affiliation: Federal University of Rio Grande do Norte"),
          tags$li("Lattes iD:", tags$a("http://lattes.cnpq.br/1357487756960536", href = "http://lattes.cnpq.br/1357487756960536", target="_blank"))
        ),
        tags$strong("Michele de Sá Dechoum"),
        tags$ul(
          class = "list-unstyled flex-column",  # Adicione a classe CSS flex-column para criar uma lista vertical
          tags$li("Affiliation: Federal University of Santa Catarina, Department of Ecology and Zoology"),
          tags$li("Lattes iD:", tags$a("http://lattes.cnpq.br/8331403389204985", href = "http://lattes.cnpq.br/8331403389204985", target="_blank"))
        ),
        tags$strong("Rebecca Luna Lucena"),
        tags$ul(
          class = "list-unstyled flex-column",  # Adicione a classe CSS flex-column para criar uma lista vertical
          tags$li("Affiliation: Federal University of Rio Grande do Norte, Higher Education Center of Seridó (CERES)"),
          tags$li("Lattes iD:", tags$a("http://lattes.cnpq.br/7007364724379098", href = "http://lattes.cnpq.br/7007364724379098", target="_blank"))
        ),
        tags$strong("Priscila Fabiana Macedo Lopes"),
        tags$ul(
          class = "list-unstyled flex-column",  # Adicione a classe CSS flex-column para criar uma lista vertical
          tags$li("Affiliation: Federal University of Rio Grande do Norte, Center for Biosciences, Department of Ecology"),
          tags$li("Lattes iD:", tags$a("http://lattes.cnpq.br/0025274238475995", href = "http://lattes.cnpq.br/0025274238475995", target="_blank"))
          
        )
      )
    } else {
      tagList(
        tags$h3(class = "modal-title", "Sobre este aplicativo"),
        p("Bem-vindo ao nosso aplicativo Shiny, uma plataforma interativa que demonstra os resultados do nosso artigo
          'Caatinga: um futuro muito seco para espécies invasoras'. Neste aplicativo, exploramos a distribuição de espécies
          no ecossistema da Caatinga, localizado no Nordeste do Brasil. Utilizamos dados georreferenciados de 19 espécies não nativas,
          juntamente com informações sobre temperatura e precipitação, para avaliar os impactos das mudanças climáticas nessas espécies
          até o final do século 21. O aplicativo oferece visualizações da distribuição atual e futura das espécies neste ecossistema único.
          Para obter mais informações, você pode acessar o artigo completo através deste link: (insira o link aqui)."),
        p("Este trabalho foi realizado por pesquisadores da Universidade Federal do Rio Grande do Norte (UFRN) e da Universidade Federal de Santa Catarina (UFSC). Conheça a equipe por trás deste projeto:"),
        tags$strong("Carlos Leandro Costa Silva"),
        tags$ul(
          class = "list-unstyled flex-column",  # Adicione a classe CSS flex-column para criar uma lista vertical
          tags$li("Afiliação: Universidade Federal do Rio Grande do Norte"),
          tags$li("ID Lattes:", tags$a("http://lattes.cnpq.br/1357487756960536", href = "http://lattes.cnpq.br/1357487756960536", target="_blank"))
        ),
        tags$strong("Michele de Sá Dechoum"),
        tags$ul(
          class = "list-unstyled flex-column",  # Adicione a classe CSS flex-column para criar uma lista vertical
          tags$li("Afiliação: Universidade Federal de Santa Catarina, Departamento de Ecologia e Zoologia"),
          tags$li("ID Lattes:", tags$a("http://lattes.cnpq.br/8331403389204985", href = "http://lattes.cnpq.br/8331403389204985", target="_blank"))
        ),
        tags$strong("Rebecca Luna Lucena"),
        tags$ul(
          class = "list-unstyled flex-column",  # Adicione a classe CSS flex-column para criar uma lista vertical
          tags$li("Afiliação: Universidade Federal do Rio Grande do Norte, Centro de Ensino Superior do Seridó (CERES)"),
          tags$li("ID Lattes:", tags$a("http://lattes.cnpq.br/7007364724379098", href = "http://lattes.cnpq.br/7007364724379098", target="_blank"))
        ),
        tags$strong("Priscila Fabiana Macedo Lopes"),
        tags$ul(
          class = "list-unstyled flex-column",  # Adicione a classe CSS flex-column para criar uma lista vertical
          tags$li("Afiliação: Universidade Federal do Rio Grande do Norte, Centro de Ciências Biológicas, Departamento de Ecologia"),
          tags$li("ID Lattes:", tags$a("http://lattes.cnpq.br/0025274238475995", href = "http://lattes.cnpq.br/0025274238475995", target="_blank"))
          
        )
      )
    }
  })
  
  # Fechar a janela flutuante e tornar o título visível quando o botão "X" for pressionado
  observeEvent(input$close_info_modal, {
    shinyjs::show("title_div") # Tornar o título visível
    shinyjs::hide("info_modal")
  })
  
  # Exibir a janela flutuante quando o botão INFO for pressionado
  observeEvent(input$info_button, {
    shinyjs::show("info_modal")
    shinyjs::hide("info_button")
    shinyjs::hide("study_area_button")
    shinyjs::hide("life_forms_button")
    shinyjs::hide("species_modeling_button")
    shinyjs::hide("overlap_button")
  })
  
  # Fechar a janela flutuante quando o botão "X" for pressionado
  observeEvent(input$close_info_modal, {
    shinyjs::hide("info_modal")
    shinyjs::show("info_button")
    shinyjs::show("study_area_button")
    shinyjs::show("life_forms_button")
    shinyjs::show("species_modeling_button")
    shinyjs::show("overlap_button")
  })
  
  
  #----Exibir a "nova página" para STUDY AREA quando o botão STUDY AREA for pressionado----
  observeEvent(input$study_area_button, {
    toggleTitleVisibility(FALSE) # Tornar o título invisível
    shinyjs::hide("info_button")
    shinyjs::hide("study_area_button")
    shinyjs::hide("life_forms_button")
    shinyjs::hide("species_modeling_button")
    shinyjs::hide("overlap_button")
    shinyjs::show("study_area_content")
    
  })
  
  observeEvent(input$study_area_info_button, {
    shinyjs::toggle("study_area_info_window")
  })
  
  observeEvent(input$close_study_area_info_window, {
    shinyjs::hide("study_area_info_window")
  })
  
  
  # Voltar à página inicial quando o botão "Voltar" for pressionado na página STUDY AREA
  observeEvent(input$back_to_main, {
    toggleTitleVisibility(TRUE) # Tornar o título visível
    shinyjs::show("info_button")
    shinyjs::show("study_area_button")
    shinyjs::show("life_forms_button")
    shinyjs::show("species_modeling_button")
    shinyjs::show("overlap_button")
    shinyjs::hide("study_area_content")
  })
  
  
  #----Exibir a "nova página" para LIFE FORMS MODELING quando o botão LIFE FORMS MODELING for pressionado----
  
  observeEvent(input$life_forms_button, {
    toggleTitleVisibility(FALSE) # Tornar o título invisível
    shinyjs::hide("info_button")
    shinyjs::hide("study_area_button")
    shinyjs::hide("life_forms_button")
    shinyjs::hide("species_modeling_button")
    shinyjs::hide("overlap_button")
    shinyjs::show("life_forms_content")
    
    observe({
      image_slider_labels <- switch(input$image_slider,
                                    "1" = "* 1st time interval used for modeling (years 2021 to 2040)",
                                    "2" = "",
                                    "3" = "",
                                    "4" = ""
      )
      shinyjs::html("image_slider_labels", image_slider_labels)
    })
    
    # Deselecionar opções pré-selecionadas
    updatePickerInput(session, "scenario_selection", selected = character(0))
    updatePickerInput(session, "life_form_selection", selected = character(0))
  })
  
  observeEvent(input$window_contents_button, {
    shinyjs::toggle("info_window") # Alternar a visibilidade da janela de informação
  })
  
  observeEvent(input$close_info_window, {
    shinyjs::hide("info_window") # Fechar a janela de informação
  })
  
  # Voltar à página inicial quando o botão "Voltar" for pressionado na página LIFE FORMS MODELING
  observeEvent(input$back_to_main2, {
    toggleTitleVisibility(TRUE) # Tornar o título visível
    shinyjs::show("info_button")
    shinyjs::show("study_area_button")
    shinyjs::show("life_forms_button")
    shinyjs::show("species_modeling_button")
    shinyjs::show("overlap_button")
    shinyjs::hide("life_forms_content")
  })
  
  #----Exibir a "nova página" para SPECIES MODELING quando o botão SPECIES MODELING for pressionado----
  
  
  observeEvent(input$species_modeling_button, {
    toggleTitleVisibility(FALSE) # Tornar o título invisível
    shinyjs::hide("info_button")
    shinyjs::hide("study_area_button")
    shinyjs::hide("life_forms_button")
    shinyjs::hide("species_modeling_button")
    shinyjs::hide("overlap_button")
    shinyjs::show("species_modeling_content")
    
    
    # Deselecionar opções pré-selecionadas
    updatePickerInput(session, "scenario_selection_species", selected = character(0))
    updatePickerInput(session, "species_selection", selected = character(0))
    updateSliderInput(session, "image_slider_species", value = 1) # Reiniciar o slider
  })
  
  observeEvent(input$species_modeling_info_button, {
    shinyjs::toggle("species_modeling_info_window")
  })
  
  observeEvent(input$close_species_modeling_info_window, {
    shinyjs::hide("species_modeling_info_window")
  })
  
  # Voltar à página inicial quando o botão "Voltar" for pressionado na página SPECIES MODELING
  observeEvent(input$back_to_main3, {
    toggleTitleVisibility(TRUE) # Tornar o título visível
    shinyjs::show("info_button")
    shinyjs::show("study_area_button")
    shinyjs::show("life_forms_button")
    shinyjs::show("species_modeling_button")
    shinyjs::show("overlap_button")
    shinyjs::hide("species_modeling_content")
  })
  
  
  #----Exibir a "nova página" para SPECIES MAP OVERLAY quando o botão SPECIES MAP OVERLAY for pressionado----
  
  observeEvent(input$overlap_button, {
    toggleTitleVisibility(FALSE) # Tornar o título invisível
    shinyjs::hide("info_button")
    shinyjs::hide("study_area_button")
    shinyjs::hide("life_forms_button")
    shinyjs::hide("species_modeling_button")
    shinyjs::hide("overlap_button")
    shinyjs::show("species_overlay_modal")
    
    
    # Reset the picker input and slider input values
    updatePickerInput(session, "scenario_selection_overlay", selected = character(0))
    updateSliderInput(session, "time_interval_slider_overlay", value = 1)
  })
  
  observeEvent(input$overlap_info_button, {
    shinyjs::toggle("overlap_info_window")
  })
  
  observeEvent(input$close_overlap_info_window, {
    shinyjs::hide("overlap_info_window")
  })
  
  # Close the SPECIES MAP OVERLAY modal and make the buttons visible again
  observeEvent(input$back_to_main4, {
    toggleTitleVisibility(TRUE) # Make the title visible
    shinyjs::show("info_button")
    shinyjs::show("study_area_button")
    shinyjs::show("life_forms_button")
    shinyjs::show("species_modeling_button")
    shinyjs::show("overlap_button")
    shinyjs::hide("species_overlay_modal")
  })
  #----Mapa e marcadores geo. do botão STUDY AREA----
  
  # Criar um mapa interativo
  output$map <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      setView(lng = -40, lat = -10, zoom = 4) %>% 
      addPolygons(data = caatinga_limites, 
                  color = "black", # Cor das bordas
                  fillOpacity = 0, # Preenchimento transparente
                  weight = 3) # Largura das bordas
  })
  
  
  # Função para adicionar marcadores no mapa com cores diferentes com base na espécie
  observe({
    req(input$life_form_selector)  # Certifique-se de que uma forma de vida foi selecionada
    life_form <- input$life_form_selector
    
    # Defina as cores das espécies
    species_colors <- c(
      "Calotropes procera (Ait.) R. Br." = "blue",
      "Coffea arabica Benth." = "green",
      "Dodonaea viscosa Jacq." = "red",
      "Nicotiana glauca Graham" = "black",
      "Catharanthus roseus (L.) G. Don" = "pink",
      "Cyperus rotundus L." = "green",
      "Impatiens walleriana Hook. f." = "blue",
      "Tradescantia zebrina Heynh." = "black",
      "Aristida adscensionis L." = "green",
      "Cenchrus ciliaris L." = "blue",
      "Cenchrus echinatus L." = "gold",
      "Megathyrsus maximus Jacq." = "black",
      "Acacia mearns De Willd." = "black",  
      "Azadirachta indica A. Juss." = "blue", 
      "Leucaena leucocephala (Lam.) de Wit." = "green",  
      "Parkinsonia aculeata L." = "pink", 
      "Prosopis juliflora (Sw.) Dc." = "gold", 
      "Syzygium cumini (L.) Skeels." = "violet",  
      "Tecoma stans (L.) Juss. ex Kunth." = "red"  
    )
    
    
    
    # Filtre os dados com base na forma de vida selecionada
    selected_data <- data[data$lifeform == life_form, ]
    
    # Crie um dataframe para os marcadores
    markers_df <- data.frame(
      latitude = selected_data$latitude,
      longitude = selected_data$longitude,
      species = selected_data$species,
      color = factor(selected_data$species, levels = names(species_colors)) %>%
        as.numeric() %>%
        species_colors[.]
    )
    
    # Adicione marcadores com cores diferentes com base na espécie
    leafletProxy("map") %>%
      clearMarkers() %>%
      addCircleMarkers(data = markers_df, 
                       lng = ~longitude, lat = ~latitude,
                       radius = 2,  # Tamanho das bolinhas (ajuste conforme necessário)
                       fillOpacity = 1,  # Opacidade de preenchimento (ajuste conforme necessário)
                       color = ~color,
                       stroke = TRUE,
                       weight = 1,
                       group = "species_markers",  # Adicione um grupo para controlar os marcadores
                       popup = ~species)
  })
  
  # Gerar a lista de espécies com base na forma de vida selecionada
  output$species_list <- renderUI({
    selected_life_form <- input$life_form_selector
    if (!is.null(selected_life_form) && selected_life_form != "") {
      species_list <- unique(data[data$lifeform == selected_life_form, "species"])
      if (length(species_list) > 0) {
        species_list <- sort(species_list)
        species_list <- lapply(species_list, function(species_name) {
          tagList(
            div(
              class = "species-icon",
              HTML(paste0('<span class="bullet-icon" style="color:', 
                          species_colors[species_name],  # Use as cores definidas anteriormente
                          '">&#9679;</span>')),
              species_name
            )
          )
        })
        do.call(tagList, species_list)
      } else {
        HTML("<p>No species found for the selected life form.</p>")
      }
    } else {
      HTML("<p>Select a life form to view corresponding occurrences.</p>")
    }
  })
  
  
  
  
  #----Renderizar a imagem com base no cenário, na FORMA DE VIDA e na posição do slider----
  
  # Variável reativa para controlar a visibilidade da imagem
  image_visible <- reactiveVal(FALSE)
  
  # Observar mudanças nos seletores
  observeEvent(c(input$scenario_selection, input$life_form_selection), {
    if (!is.null(input$scenario_selection) && !is.null(input$life_form_selection)) {
      image_visible(TRUE)
    } else {
      image_visible(FALSE)
    }
  })
  
  # Renderizar a imagem se ambos os seletores tiverem sido escolhidos
  output$life_forms_image <- renderUI({
    req(image_visible())
    scenario <- input$scenario_selection
    life_form <- input$life_form_selection
    image_number <- input$image_slider
    
    image_path <- paste0("www/lifeform/", tolower(scenario), "_scenario/", tolower(life_form), "/", tolower(life_form), image_number, ".jpg")
    tags$img(src = image_path, 
             style = "max-width: 55%; height: auto; display: block; margin: 0 auto;")
  })
  
  
  
  #----Renderizar a imagem com base no cenário, na ESPÉCIE e na posição do slider----
  
  output$species_modeling_image <- renderUI({
    req(input$scenario_selection_species, input$species_selection, input$image_slider_species) # Verifica se todas as seleções foram feitas
    
    scenario <- input$scenario_selection_species
    species <- input$species_selection
    image_number <- input$image_slider_species
    
    if (species == "Prosopis juliflora") {
      if (scenario == "Optimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/optimistic_scenario/prosopis_juliflora/1.jpg",
                             "2" = "www/spmodels/scenarios/optimistic_scenario/prosopis_juliflora/2.jpg",
                             "3" = "www/spmodels/scenarios/optimistic_scenario/prosopis_juliflora/3.jpg",
                             "4" = "www/spmodels/scenarios/optimistic_scenario/prosopis_juliflora/4.jpg",
                             return(NULL)
        )
      } else if (scenario == "Pessimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/pessimistic_scenario/prosopis_juliflora/1.jpg",
                             "2" = "www/spmodels/scenarios/pessimistic_scenario/prosopis_juliflora/2.jpg",
                             "3" = "www/spmodels/scenarios/pessimistic_scenario/prosopis_juliflora/3.jpg",
                             "4" = "www/spmodels/scenarios/pessimistic_scenario/prosopis_juliflora/4.jpg",
                             return(NULL)
        )
      }
    } else if (species == "Acacia mearnsii") {
      if (scenario == "Optimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/optimistic_scenario/acacia_mearnsii/1.jpg",
                             "2" = "www/spmodels/scenarios/optimistic_scenario/acacia_mearnsii/2.jpg",
                             "3" = "www/spmodels/scenarios/optimistic_scenario/acacia_mearnsii/3.jpg",
                             "4" = "www/spmodels/scenarios/optimistic_scenario/acacia_mearnsii/4.jpg",
                             return(NULL)
        )
      } else if (scenario == "Pessimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/pessimistic_scenario/acacia_mearnsii/1.jpg",
                             "2" = "www/spmodels/scenarios/pessimistic_scenario/acacia_mearnsii/2.jpg",
                             "3" = "www/spmodels/scenarios/pessimistic_scenario/acacia_mearnsii/3.jpg",
                             "4" = "www/spmodels/scenarios/pessimistic_scenario/acacia_mearnsii/4.jpg",
                             return(NULL)
        )
      }
    } else if (species == "Aristida adscensionis") {
      if (scenario == "Optimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/optimistic_scenario/aristida_adscensionis/1.jpg",
                             "2" = "www/spmodels/scenarios/optimistic_scenario/aristida_adscensionis/2.jpg",
                             "3" = "www/spmodels/scenarios/optimistic_scenario/aristida_adscensionis/3.jpg",
                             "4" = "www/spmodels/scenarios/optimistic_scenario/aristida_adscensionis/4.jpg",
                             return(NULL)
        )
      } else if (scenario == "Pessimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/pessimistic_scenario/aristida_adscensionis/1.jpg",
                             "2" = "www/spmodels/scenarios/pessimistic_scenario/aristida_adscensionis/2.jpg",
                             "3" = "www/spmodels/scenarios/pessimistic_scenario/aristida_adscensionis/3.jpg",
                             "4" = "www/spmodels/scenarios/pessimistic_scenario/aristida_adscensionis/4.jpg",
                             return(NULL)
        )
      }
    } else if (species == "Azadirachta indica") {
      if (scenario == "Optimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/optimistic_scenario/azadirachta_indica/1.jpg",
                             "2" = "www/spmodels/scenarios/optimistic_scenario/azadirachta_indica/2.jpg",
                             "3" = "www/spmodels/scenarios/optimistic_scenario/azadirachta_indica/3.jpg",
                             "4" = "www/spmodels/scenarios/optimistic_scenario/azadirachta_indica/4.jpg",
                             return(NULL)
        )
      } else if (scenario == "Pessimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/pessimistic_scenario/azadirachta_indica/1.jpg",
                             "2" = "www/spmodels/scenarios/pessimistic_scenario/azadirachta_indica/2.jpg",
                             "3" = "www/spmodels/scenarios/pessimistic_scenario/azadirachta_indica/3.jpg",
                             "4" = "www/spmodels/scenarios/pessimistic_scenario/azadirachta_indica/4.jpg",
                             return(NULL)
        )
      }
    } else if (species == "Calotropis procera") {
      if (scenario == "Optimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/optimistic_scenario/calotropis_procera/1.jpg",
                             "2" = "www/spmodels/scenarios/optimistic_scenario/calotropis_procera/2.jpg",
                             "3" = "www/spmodels/scenarios/optimistic_scenario/calotropis_procera/3.jpg",
                             "4" = "www/spmodels/scenarios/optimistic_scenario/calotropis_procera/4.jpg",
                             return(NULL)
        )
      } else if (scenario == "Pessimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/pessimistic_scenario/calotropis_procera/1.jpg",
                             "2" = "www/spmodels/scenarios/pessimistic_scenario/calotropis_procera/2.jpg",
                             "3" = "www/spmodels/scenarios/pessimistic_scenario/calotropis_procera/3.jpg",
                             "4" = "www/spmodels/scenarios/pessimistic_scenario/calotropis_procera/4.jpg",
                             return(NULL)
        )
      }
    } else if (species == "Catharanthus roseus") {
      if (scenario == "Optimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/optimistic_scenario/catharanthus_roseus/1.jpg",
                             "2" = "www/spmodels/scenarios/optimistic_scenario/catharanthus_roseus/2.jpg",
                             "3" = "www/spmodels/scenarios/optimistic_scenario/catharanthus_roseus/3.jpg",
                             "4" = "www/spmodels/scenarios/optimistic_scenario/catharanthus_roseus/4.jpg",
                             return(NULL)
        )
      } else if (scenario == "Pessimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/pessimistic_scenario/catharanthus_roseus/1.jpg",
                             "2" = "www/spmodels/scenarios/pessimistic_scenario/catharanthus_roseus/2.jpg",
                             "3" = "www/spmodels/scenarios/pessimistic_scenario/catharanthus_roseus/3.jpg",
                             "4" = "www/spmodels/scenarios/pessimistic_scenario/catharanthus_roseus/4.jpg",
                             return(NULL)
        )
      }
    } else if (species == "Cenchrus ciliaris") {
      if (scenario == "Optimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/optimistic_scenario/cenchrus_ciliaris/1.jpg",
                             "2" = "www/spmodels/scenarios/optimistic_scenario/cenchrus_ciliaris/2.jpg",
                             "3" = "www/spmodels/scenarios/optimistic_scenario/cenchrus_ciliaris/3.jpg",
                             "4" = "www/spmodels/scenarios/optimistic_scenario/cenchrus_ciliaris/4.jpg",
                             return(NULL)
        )
      } else if (scenario == "Pessimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/pessimistic_scenario/cenchrus_ciliaris/1.jpg",
                             "2" = "www/spmodels/scenarios/pessimistic_scenario/cenchrus_ciliaris/2.jpg",
                             "3" = "www/spmodels/scenarios/pessimistic_scenario/cenchrus_ciliaris/3.jpg",
                             "4" = "www/spmodels/scenarios/pessimistic_scenario/cenchrus_ciliaris/4.jpg",
                             return(NULL)
        )
      }
    } else if (species == "Cenchrus echinatus") {
      if (scenario == "Optimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/optimistic_scenario/cenchrus_echinatus/1.jpg",
                             "2" = "www/spmodels/scenarios/optimistic_scenario/cenchrus_echinatus/2.jpg",
                             "3" = "www/spmodels/scenarios/optimistic_scenario/cenchrus_echinatus/3.jpg",
                             "4" = "www/spmodels/scenarios/optimistic_scenario/cenchrus_echinatus/4.jpg",
                             return(NULL)
        )
      } else if (scenario == "Pessimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/pessimistic_scenario/cenchrus_echinatus/1.jpg",
                             "2" = "www/spmodels/scenarios/pessimistic_scenario/cenchrus_echinatus/2.jpg",
                             "3" = "www/spmodels/scenarios/pessimistic_scenario/cenchrus_echinatus/3.jpg",
                             "4" = "www/spmodels/scenarios/pessimistic_scenario/cenchrus_echinatus/4.jpg",
                             return(NULL)
        )
      }
    } else if (species == "Coffea arabica") {
      if (scenario == "Optimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/optimistic_scenario/coffea_arabica/1.jpg",
                             "2" = "www/spmodels/scenarios/optimistic_scenario/coffea_arabica/2.jpg",
                             "3" = "www/spmodels/scenarios/optimistic_scenario/coffea_arabica/3.jpg",
                             "4" = "www/spmodels/scenarios/optimistic_scenario/coffea_arabica/4.jpg",
                             return(NULL)
        )
      } else if (scenario == "Pessimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/pessimistic_scenario/coffea_arabica/1.jpg",
                             "2" = "www/spmodels/scenarios/pessimistic_scenario/coffea_arabica/2.jpg",
                             "3" = "www/spmodels/scenarios/pessimistic_scenario/coffea_arabica/3.jpg",
                             "4" = "www/spmodels/scenarios/pessimistic_scenario/coffea_arabica/4.jpg",
                             return(NULL)
        )
      }
    } else if (species == "Cyperus rotundus") {
      if (scenario == "Optimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/optimistic_scenario/cyperus_rotundus/1.jpg",
                             "2" = "www/spmodels/scenarios/optimistic_scenario/cyperus_rotundus/2.jpg",
                             "3" = "www/spmodels/scenarios/optimistic_scenario/cyperus_rotundus/3.jpg",
                             "4" = "www/spmodels/scenarios/optimistic_scenario/cyperus_rotundus/4.jpg",
                             return(NULL)
        )
      } else if (scenario == "Pessimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/pessimistic_scenario/cyperus_rotundus/1.jpg",
                             "2" = "www/spmodels/scenarios/pessimistic_scenario/cyperus_rotundus/2.jpg",
                             "3" = "www/spmodels/scenarios/pessimistic_scenario/cyperus_rotundus/3.jpg",
                             "4" = "www/spmodels/scenarios/pessimistic_scenario/cyperus_rotundus/4.jpg",
                             return(NULL)
        )
      }
    } else if (species == "Cyperus rotundus") {
      if (scenario == "Optimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/optimistic_scenario/cyperus_rotundus/1.jpg",
                             "2" = "www/spmodels/scenarios/optimistic_scenario/cyperus_rotundus/2.jpg",
                             "3" = "www/spmodels/scenarios/optimistic_scenario/cyperus_rotundus/3.jpg",
                             "4" = "www/spmodels/scenarios/optimistic_scenario/cyperus_rotundus/4.jpg",
                             return(NULL)
        )
      } else if (scenario == "Pessimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/pessimistic_scenario/cyperus_rotundus/1.jpg",
                             "2" = "www/spmodels/scenarios/pessimistic_scenario/cyperus_rotundus/2.jpg",
                             "3" = "www/spmodels/scenarios/pessimistic_scenario/cyperus_rotundus/3.jpg",
                             "4" = "www/spmodels/scenarios/pessimistic_scenario/cyperus_rotundus/4.jpg",
                             return(NULL)
        )
      }
    } else if (species == "Dodonaea viscosa") {
      if (scenario == "Optimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/optimistic_scenario/dodonaea_viscosa/1.jpg",
                             "2" = "www/spmodels/scenarios/optimistic_scenario/dodonaea_viscosa/2.jpg",
                             "3" = "www/spmodels/scenarios/optimistic_scenario/dodonaea_viscosa/3.jpg",
                             "4" = "www/spmodels/scenarios/optimistic_scenario/dodonaea_viscosa/4.jpg",
                             return(NULL)
        )
      } else if (scenario == "Pessimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/pessimistic_scenario/dodonaea_viscosa/1.jpg",
                             "2" = "www/spmodels/scenarios/pessimistic_scenario/dodonaea_viscosa/2.jpg",
                             "3" = "www/spmodels/scenarios/pessimistic_scenario/dodonaea_viscosa/3.jpg",
                             "4" = "www/spmodels/scenarios/pessimistic_scenario/dodonaea_viscosa/4.jpg",
                             return(NULL)
        )
      }
    } else if (species == "Impatiens walleriana") {
      if (scenario == "Optimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/optimistic_scenario/impatiens_walleriana/1.jpg",
                             "2" = "www/spmodels/scenarios/optimistic_scenario/impatiens_walleriana/2.jpg",
                             "3" = "www/spmodels/scenarios/optimistic_scenario/impatiens_walleriana/3.jpg",
                             "4" = "www/spmodels/scenarios/optimistic_scenario/impatiens_walleriana/4.jpg",
                             return(NULL)
        )
      } else if (scenario == "Pessimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/pessimistic_scenario/impatiens_walleriana/1.jpg",
                             "2" = "www/spmodels/scenarios/pessimistic_scenario/impatiens_walleriana/2.jpg",
                             "3" = "www/spmodels/scenarios/pessimistic_scenario/impatiens_walleriana/3.jpg",
                             "4" = "www/spmodels/scenarios/pessimistic_scenario/impatiens_walleriana/4.jpg",
                             return(NULL)
        )
      }
    } else if (species == "Leucaena leucocephala") {
      if (scenario == "Optimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/optimistic_scenario/leucaena_leucocephala/1.jpg",
                             "2" = "www/spmodels/scenarios/optimistic_scenario/leucaena_leucocephala/2.jpg",
                             "3" = "www/spmodels/scenarios/optimistic_scenario/leucaena_leucocephala/3.jpg",
                             "4" = "www/spmodels/scenarios/optimistic_scenario/leucaena_leucocephala/4.jpg",
                             return(NULL)
        )
      } else if (scenario == "Pessimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/pessimistic_scenario/leucaena_leucocephala/1.jpg",
                             "2" = "www/spmodels/scenarios/pessimistic_scenario/leucaena_leucocephala/2.jpg",
                             "3" = "www/spmodels/scenarios/pessimistic_scenario/leucaena_leucocephala/3.jpg",
                             "4" = "www/spmodels/scenarios/pessimistic_scenario/leucaena_leucocephala/4.jpg",
                             return(NULL)
        )
      }
    } else if (species == "Megathyrsus maximus") {
      if (scenario == "Optimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/optimistic_scenario/megathyrsus_maximus/1.jpg",
                             "2" = "www/spmodels/scenarios/optimistic_scenario/megathyrsus_maximus/2.jpg",
                             "3" = "www/spmodels/scenarios/optimistic_scenario/megathyrsus_maximus/3.jpg",
                             "4" = "www/spmodels/scenarios/optimistic_scenario/megathyrsus_maximus/4.jpg",
                             return(NULL)
        )
      } else if (scenario == "Pessimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/pessimistic_scenario/megathyrsus_maximus/1.jpg",
                             "2" = "www/spmodels/scenarios/pessimistic_scenario/megathyrsus_maximus/2.jpg",
                             "3" = "www/spmodels/scenarios/pessimistic_scenario/megathyrsus_maximus/3.jpg",
                             "4" = "www/spmodels/scenarios/pessimistic_scenario/megathyrsus_maximus/4.jpg",
                             return(NULL)
        )
      }
    } else if (species == "Nicotiana glauca") {
      if (scenario == "Optimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/optimistic_scenario/nicotiana_glauca/1.jpg",
                             "2" = "www/spmodels/scenarios/optimistic_scenario/nicotiana_glauca/2.jpg",
                             "3" = "www/spmodels/scenarios/optimistic_scenario/nicotiana_glauca/3.jpg",
                             "4" = "www/spmodels/scenarios/optimistic_scenario/nicotiana_glauca/4.jpg",
                             return(NULL)
        )
      } else if (scenario == "Pessimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/pessimistic_scenario/nicotiana_glauca/1.jpg",
                             "2" = "www/spmodels/scenarios/pessimistic_scenario/nicotiana_glauca/2.jpg",
                             "3" = "www/spmodels/scenarios/pessimistic_scenario/nicotiana_glauca/3.jpg",
                             "4" = "www/spmodels/scenarios/pessimistic_scenario/nicotiana_glauca/4.jpg",
                             return(NULL)
        )
      }
    } else if (species == "Parkinsonia aculeata") {
      if (scenario == "Optimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/optimistic_scenario/parkinsonia_aculeata/1.jpg",
                             "2" = "www/spmodels/scenarios/optimistic_scenario/parkinsonia_aculeata/2.jpg",
                             "3" = "www/spmodels/scenarios/optimistic_scenario/parkinsonia_aculeata/3.jpg",
                             "4" = "www/spmodels/scenarios/optimistic_scenario/parkinsonia_aculeata/4.jpg",
                             return(NULL)
        )
      } else if (scenario == "Pessimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/pessimistic_scenario/parkinsonia_aculeata/1.jpg",
                             "2" = "www/spmodels/scenarios/pessimistic_scenario/parkinsonia_aculeata/2.jpg",
                             "3" = "www/spmodels/scenarios/pessimistic_scenario/parkinsonia_aculeata/3.jpg",
                             "4" = "www/spmodels/scenarios/pessimistic_scenario/parkinsonia_aculeata/4.jpg",
                             return(NULL)
        )
      }
    } else if (species == "Syzygium cumini") {
      if (scenario == "Optimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/optimistic_scenario/syzygium_cumini/1.jpg",
                             "2" = "www/spmodels/scenarios/optimistic_scenario/syzygium_cumini/2.jpg",
                             "3" = "www/spmodels/scenarios/optimistic_scenario/syzygium_cumini/3.jpg",
                             "4" = "www/spmodels/scenarios/optimistic_scenario/syzygium_cumini/4.jpg",
                             return(NULL)
        )
      } else if (scenario == "Pessimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/pessimistic_scenario/syzygium_cumini/1.jpg",
                             "2" = "www/spmodels/scenarios/pessimistic_scenario/syzygium_cumini/2.jpg",
                             "3" = "www/spmodels/scenarios/pessimistic_scenario/syzygium_cumini/3.jpg",
                             "4" = "www/spmodels/scenarios/pessimistic_scenario/syzygium_cumini/4.jpg",
                             return(NULL)
        )
      }
    } else if (species == "Tecoma stans") {
      if (scenario == "Optimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/optimistic_scenario/tecoma_stans/1.jpg",
                             "2" = "www/spmodels/scenarios/optimistic_scenario/tecoma_stans/2.jpg",
                             "3" = "www/spmodels/scenarios/optimistic_scenario/tecoma_stans/3.jpg",
                             "4" = "www/spmodels/scenarios/optimistic_scenario/tecoma_stans/4.jpg",
                             return(NULL)
        )
      } else if (scenario == "Pessimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/pessimistic_scenario/tecoma_stans/1.jpg",
                             "2" = "www/spmodels/scenarios/pessimistic_scenario/tecoma_stans/2.jpg",
                             "3" = "www/spmodels/scenarios/pessimistic_scenario/tecoma_stans/3.jpg",
                             "4" = "www/spmodels/scenarios/pessimistic_scenario/tecoma_stans/4.jpg",
                             return(NULL)
        )
      }
    } else if (species == "Tradescantia zebrina") {
      if (scenario == "Optimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/optimistic_scenario/tradescantia_zebrina/1.jpg",
                             "2" = "www/spmodels/scenarios/optimistic_scenario/tradescantia_zebrina/2.jpg",
                             "3" = "www/spmodels/scenarios/optimistic_scenario/tradescantia_zebrina/3.jpg",
                             "4" = "www/spmodels/scenarios/optimistic_scenario/tradescantia_zebrina/4.jpg",
                             return(NULL)
        )
      } else if (scenario == "Pessimistic") {
        image_path <- switch(image_number,
                             "1" = "www/spmodels/scenarios/pessimistic_scenario/tradescantia_zebrina/1.jpg",
                             "2" = "www/spmodels/scenarios/pessimistic_scenario/tradescantia_zebrina/2.jpg",
                             "3" = "www/spmodels/scenarios/pessimistic_scenario/tradescantia_zebrina/3.jpg",
                             "4" = "www/spmodels/scenarios/pessimistic_scenario/tradescantia_zebrina/4.jpg",
                             return(NULL)
        )
      }
    }  
    
    else {
      # Caso contrário, não exibe imagem
      div()
    }
    
    # Exibe a imagem
    tags$img(src = image_path, 
             style = "max-width: 55%; height: auto; display: block; margin: 0 auto;")
  })
  
  
  
  #----Renderizar a imagem com base no cenário e na posição do slider slider----
  output$overlay_image <- renderUI({
    req(input$scenario_selection_overlay, input$time_interval_slider_overlay) # Verifique as seleções
    scenario <- input$scenario_selection_overlay
    image_number <- input$time_interval_slider_overlay
    
    # Construa o caminho da imagem com base no cenário e na posição do slider
    image_folder <- switch(scenario,
                           "Optimistic" = "optimistic_scenario",
                           "Pessimistic" = "pessimistic_scenario")
    
    image_path <- file.path("www", "overlay", "scenarios", image_folder, paste0(image_number, ".jpg"))
    
    # Verifique se o arquivo de imagem existe
    if (file.exists(image_path)) {
      img <- tags$img(src = image_path, 
                      style = "max-width: 60%; height: auto; display: block; margin: 0 auto;")
      return(img)
    } else {
      return(NULL) # Retorne NULL se a imagem não existir
    }
  })
  
  
  
} #fechar o server

shinyApp(ui = ui, server = server)
