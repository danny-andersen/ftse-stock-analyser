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
            p("Adjust num years the stats are calculated and shown"),
            fluidRow(column(12,
                       sliderInput("noOfYears",label="Number of Years", value=8, min=1, max=10))
            ),
            p("Filters stocks by min % dividend"),
            fluidRow(column(12,
                            sliderInput("divCutoff",label="Min Avg Dividend %", value=0, min=0, max=10))
            ),
            fluidRow(column(12,
                            h4("Last update:", title="The last time the data was refreshed"),
                            textOutput("lastUpdateDate"))
            ),
            br(),
            fluidRow(column(12,
                            actionButton("refreshAllData", label = "Refresh All Stock data", 
                                         title="WARNING: This will refresh ALL pricing data and will take a long time to complete. Please be patient"))
            )
        ),
        
        # Show a plot of the generated distribution
        mainPanel(
            fluidRow(column(12,
                h4("This application allows the performance of stocks in the UK FTSE100 index to be interactively analysed."),
                h4("It calculates and shows the dividend and price changes over a user definable period and min dividend."),                        
                p("Click on any row in the below table for detailed plots. Note that all columns are sortable and searchable"))
            ),
            DT::dataTableOutput("stockTable"),
            plotOutput("stockPricePlot"),
            plotOutput("stockDividendPlot")
        )
    )
))
