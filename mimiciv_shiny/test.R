library(shiny)
library(dplyr)
library(ggplot2)
library(markdown)
library(gtsummary)

# FAKE DATAFRAME

out <- readRDS("/Users/fuchiyang/203b-hw/submit/mimiciv_shiny/mimic_icu_cohort.rds")

data <- out %>%
  select(WBC, Sodium, Calcium)



ui <- fluidPage(
  navbarPage("",
             tabPanel("Data Exploration",
                      sidebarLayout(
                        sidebarPanel(
                          selectInput("variable",
                                      "Variable:",
                                      colnames(data))
                        ),
                        mainPanel(
                          tableOutput("table")
                        )
                      )
             )
  )
)

server <- function(input, output, session) {
  sum <- reactive({
    data <- data %>%
      select(input$variable) %>%
      summary()
  })
  
    
  output$table <- renderTable(sum())

}

shinyApp(ui, server)
# START APP
