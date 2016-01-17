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
        sidebarPanel(width=2,
            fluidRow(column(12,
                     actionButton("refreshAllData", label = "Refresh All Stock data"))
            ),
            fluidRow(column(12,
                     h4("Last update:"))
            ),
            fluidRow(column(12,
                     textOutput("lastUpdateDate"))
            ),
            br(),
            fluidRow(column(12,
                       sliderInput("divCutoff",label="Min Avg Dividend %", value=0, min=0, max=10))
            ),
            fluidRow(column(12,
                       sliderInput("noOfYears",label="Number of Years", value=8, min=1, max=10))
            )
        ),
        
        # Show a plot of the generated distribution
        mainPanel(
            fluidRow(column(12,
                h4("Click on any row for detailed plots"))
            ),
            DT::dataTableOutput("stockTable"),
            plotOutput("stockPricePlot"),
            plotOutput("stockDividendPlot")
        )
    )
))
