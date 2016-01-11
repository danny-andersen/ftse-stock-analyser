if (!require(shiny)) install.packages('shiny')
library(shiny)
if (!require(DT)) install.packages('DT')
library(DT)
if (!require(XML)) install.packages('XML')
library(XML)
if (!require(RCurl)) install.packages('RCurl')
library(RCurl)
if (!require(dplyr)) install.packages('dplyr')
library(dplyr)
source("process_prices.R")

#FTSE100 stocks
ftse100 <- "https://en.wikipedia.org/wiki/FTSE_100_Index"
refreshData <- function() {
    #Pull down list of stocks to analyse from wikipedia
    xData <- getURL(ftse100)
    #Read web page and scrape table containing FTSE 100 constituents
    stockList<-readHTMLTable(xData)[2]$constituents
    #Create and empty array to hold processed data
    stats <- array(dim=c(nrow(stockList),6))
    for (i in 1:nrow(stockList)) {
        #Process stock
        s<-stockList[i,c("Ticker","Company")]
        stats[i,] <- tryCatch(process_stock(as.character(s[[1]]),as.character(s[[2]])),
                              error = function(e) {
                                  c(as.character(s[[1]]),as.character(s[[2]]),NA,NA,NA,NA)
                              })
    }
    #Add the calculated dividend % 
    stockList$Avg.Dividend <- as.numeric(stats[,3])
    stockList$StdDev.Dividend <- as.numeric(stats[,4])
    stockList$Avg.Price <- as.numeric(stats[,5])
    stockList$StdDev.Price <- as.numeric(stats[,6])
    stockList
    
}

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
    stockList <- reactive({
        input$refreshStocks
        stockList <- refreshData();
    })    
    
#     rows<- reactive({
#         if (input$noOfRows == "999") {
#             rows = nrow(stockList) 
#         } else {
#             rows = as.numeric(input$noOfRows)
#         }
#     })
# output$stockTable <- renderTable({stockList[1:rows(),]})
    output$stockTable <- DT::renderDataTable({stockList()})
})
