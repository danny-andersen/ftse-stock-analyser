if (!require(shiny)) install.packages('shiny')
library(shiny)
if (!require(DT)) install.packages('DT')
library(DT)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
    
    # Application title
    titlePanel("FTSE 100 Stock Analyser"),
    
    # Sidebar with a slider input for the number of bins
    sidebarLayout(
        sidebarPanel(
            fluidRow(
                column(4,
                    actionButton("refreshStocks", label = "Refresh Stock List"),
                    h4("Last update:"),textOutput("stockListDate")),
                column(4,
                       actionButton("refreshSelData", label = "Refresh Selected Stock")),
                column(4,
                       actionButton("refreshAllData", label = "Refresh All Stock data"),
                       h4("Oldest update:"),textOutput("oldestDate"))
            )
        ),
        
        # Show a plot of the generated distribution
        mainPanel(
            DT::dataTableOutput("stockTable")
        )
    )
))
