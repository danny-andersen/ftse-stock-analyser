library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
    
    # Application title
    titlePanel("FTSE 100 Stock Analyser"),
    
    # Sidebar with a slider input for the number of bins
    sidebarLayout(
        sidebarPanel(
            radioButtons("noOfRows",label="No of Stocks", choices = list("10" = 10, 
                                                                            "25" = 25,
                                                                            "50" = 50,
                                                                            "all" = 999), selected = 25),
            actionButton("refresh", label = "Refresh"),
            br()
        ),
        
        # Show a plot of the generated distribution
        mainPanel(
            tableOutput("stockTable")
        )
    )
))
