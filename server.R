library(shiny)
if (!require(XML)) install.packages('XML')
library(XML)
if (!require(RCurl)) install.packages('RCurl')
library(RCurl)
if (!require(dplyr)) install.packages('dplyr')
library(dplyr)
#FTSE100 stocks
ftse100 <- "https://en.wikipedia.org/wiki/FTSE_100_Index"

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
    #Pull down list of stocks to analyse from wikipedia
    xData <- getURL(ftse100)
    
    #Read web page and scrape table containing FTSE 100 constituents
    stockList<-readHTMLTable(xData)[2]$constituents
    rows<- reactive({
        if (input$noOfRows == "999") {
            rows = nrow(stockList) 
        } else {
            rows = as.numeric(input$noOfRows)
        }
    })
    output$stockTable <- renderTable({stockList[1:rows(),]})
})
