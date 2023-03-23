

## UI ##
library(shiny)
library(tidyverse)
library(bigrquery)


out <- readRDS("/Users/fuchiyang/203b-hw/submit/mimiciv_shiny/mimic_icu_cohort.rds")


library(shiny)
install.packages(shinydashboard)
library(shinydashboard)
library(shinyWidgets)
library(ggplot2)
library(dplyr)

data <- out %>% 
  count(admission_location)%>%
  rename(count=n)


# APP
ui <- dashboardPage(
  dashboardHeader(title = "Plot Change"),
  dashboardSidebar(),
  dashboardBody(
    fluidRow(
      box(plotOutput("plot1", height = 250)),
      box(radioGroupButtons(
        inputId = "change_plot",
        label = "Visualize:",
        choices = c(
          `<i class='fa fa-bar-chart'></i>` = "bar",
          `<i class='fa fa-pie-chart'></i>` = "pie"
        ),
        justified = TRUE,
        selected = "bar"
      ))
    )
  )
)

server <- function(input, output) {
  output$plot1 <- renderPlot({
    if (input$change_plot %in% "bar") {
      ggplot(data, aes(admission_location, count, fill = admission_location)) +
        geom_bar(stat = "identity")
    } else {
      ggplot(data, aes(x = "", y = count, fill = admission_location)) +
        geom_bar(stat = "identity", width = 1) +
        coord_polar("y", start = 0)
    }
  })
}
shinyApp(ui, server)


##label of variables
##all variables are needed to be included (individual factors, medical records,
biomarkers)
## interactive chart




