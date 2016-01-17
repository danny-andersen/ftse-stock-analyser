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
if (!require(ggplot2)) install.packages('ggplot2')
library(ggplot2)
source("process_prices.R")

ftse100 <- "https://en.wikipedia.org/wiki/FTSE_100_Index"
#Pull down list of stocks to analyse from wikipedia
ftse100list <- NULL
getftse100 <- function(force = FALSE) {
    if (force || is.null(ftse100list)) {
        xData <- getURL(ftse100)
        #Read web page and scrape table containing FTSE 100 constituents
        ftse100list<-readHTMLTable(xData)[2]$constituents
    } 
    ftse100list
}

#FTSE100 stocks
refreshData <- function(numOfYears=8, force = FALSE, min_dividend) {
    #Create and empty array to hold processed data
    stockList <- getftse100(force)
    stats <- array(dim=c(nrow(stockList),6))
    for (i in 1:nrow(stockList)) {
        #Process stock
        s<-stockList[i,c("Ticker","Company")]
        stats[i,] <- tryCatch(process_stock(as.character(s[[1]]),as.character(s[[2]]), numOfYears, force),
                              error = function(e) {
                                  c(as.character(s[[1]]),as.character(s[[2]]),NA,NA,NA,NA)
                              })
    }
    #Add the calculated dividend % 
    stockList$Avg.Dividend <- round(as.numeric(stats[,3]),2)
    stockList$StdDev.Dividend <- round(as.numeric(stats[,4]),2)
    stockList$Avg.Price <- round(as.numeric(stats[,5]),2)
    stockList$StdDev.Price <- round(as.numeric(stats[,6]),2)
    #Return stocks filtered by min divi
    filter(stockList, Avg.Dividend >= min_dividend)
}

plotStockDividends<- function(ticker, name, numOfYears = 8) {
    prices<-getPrices(ticker,name,numOfYears)
    meanPrice <- round(mean(prices$Close,na.rm = TRUE),0)
    sdPrice <- sd(prices$Close,na.rm = TRUE)
    
    yearlyDivs <- getYearlyDivs(ticker, name, numOfYears)
    avgDivi <- round(mean(yearlyDivs$percent,na.rm = T),2)
    sdDivi <- sd(yearlyDivs$percent, na.rm = T)
    #Plot dividend
    cols<-c("Div_%_Yr_Price"="black","Div_%_8yr_price" = "red")
    gd <- ggplot(yearlyDivs, aes(x=year, y=percent))
    gd <- gd + labs(x="Year", y="Total Div as % of avg price", title=paste(name,"Dividend as a percentage of avg price"))
    gd <- gd + ylim(c(0, max(yearlyDivs$avgpercent,yearlyDivs$percent,na.rm = TRUE)+2))
    gd <- gd + geom_line(aes(colour="Div_%_Yr_Price"))
    gd <- gd + geom_point()
    gd <- gd + geom_line(aes(x=year, y=avgpercent, colour="Div_%_8yr_price"))
    gd <- gd + geom_hline(yintercept = avgDivi, linetype=2, colour="blue")
    gd <- gd + geom_text(aes(min(year)+1,avgDivi,label=paste("Avg Div",avgDivi)),vjust=-1,colour="blue")
    gd <- gd + scale_colour_manual(name="", values=cols)
    gd
}    

plotStockPrices <- function(ticker, name, numOfYears = 8) {
    prices<-getPrices(ticker,name,numOfYears)
    meanPrice <- round(mean(prices$Close,na.rm = TRUE),0)
    sdPrice <- sd(prices$Close,na.rm = TRUE)
    
    yearlyDivs <- getYearlyDivs(ticker, name, numOfYears)

        #Plot prices
    cols<- c("Weekly_closing_price" = "black", "4%_Div_Price" = "red")
    g<-ggplot(prices, aes(x=Date, y=Close))
    g <- g + geom_line(aes(colour="Weekly_closing_price"))
    g <- g + labs(x="Year", y="Closing price (pence)", title = paste(name, "Weekly Prices last 8 yrs"))
    g <- g + ylim(c(min(prices$Close, yearlyDivs$divPrice),max(prices$Close, yearlyDivs$divPrice)))
    g <- g + geom_hline(yintercept = meanPrice, linetype=2, colour="blue")
    g <- g + geom_text(aes(min(prices$Date)+365,meanPrice,label=paste("Avg Price",meanPrice),vjust=-1))
    g <- g + geom_line(data=yearlyDivs, aes(x=date, y=divPrice,colour="4%_Div_Price" ))
    g <- g + scale_colour_manual(name="", values=cols)
    g
}

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
    numOfYears <- reactive({
        numOfYears <- input$noOfYears
    })
    
    stocks <- reactive({
        min_dividend <- input$divCutoff
        years <- numOfYears()
        stocks <- refreshData(years, force = FALSE, min_dividend);
        stocks
    })
    
    output$lastUpdateDate <- renderText({
        count <- input$refreshAllData
        if (count != 0) {
            print("Refresh")
            stocks <- refreshData(8, force = TRUE, 0);
        }
        files <- list.files("data")
        t <- rep(Sys.time(), length(files))
        i=0
        for( f in files) {
            i<-i+1
            t[i]<-file.mtime(paste("data",file,sep="/"))
        }
        format(max(t,na.rm = T))
    })

    output$stockTable <- DT::renderDataTable({datatable(stocks(),selection='single')})
    
    output$stockPricePlot <- renderPlot({        
        i <- input$stockTable_row_last_clicked
        if (!is.null(i) && i != 0) {
            stock<-stocks()[i,c("Ticker", "Company")]
            rPlot <- plotStockPrices(stock[[1]], stock[[2]],numOfYears())
        } else {
            rPlot = NULL
        }
        rPlot
    })

    output$stockDividendPlot <- renderPlot({        
        i <- input$stockTable_row_last_clicked
        if (!is.null(i) && i != 0) {
            stock<-stocks()[i,c("Ticker", "Company")]
            rPlot <- plotStockDividends(stock[[1]], stock[[2]],numOfYears())
        } else {
            rPlot = NULL
        }
        rPlot
    })
})
