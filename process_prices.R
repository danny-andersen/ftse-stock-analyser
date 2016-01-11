
process_stock <- function(stock, name = stock) {
    library(dplyr)
    if (!require(XML)) install.packages('XML')
    library(XML)
    if (!require(RCurl)) install.packages('RCurl')
    library(RCurl)
    
    price_url="http://real-chart.finance.yahoo.com/table.csv?s=XXX.L&a=06&b=1&c=2004&d=07&e=31&f=2015&g=w&ignore=.csv"
    div_url="http://real-chart.finance.yahoo.com/table.csv?s=XXX.L&a=06&b=1&c=2004&d=07&e=31&f=2015&g=v&ignore=.csv"
    keyStats_url="https://uk.finance.yahoo.com/q/ks?s=XXX.L"
    
    min_perc <- 4
    #Only look back 8 years
    cutoff <- as.POSIXlt(Sys.Date())
    cutoff$year <- cutoff$year - 8
    cutoff <- as.Date(cutoff)
    
    #Load and process price data  
    pricesFile <- paste("data/",stock,"_prices.RData", sep="")
    if (file.exists(pricesFile)){
        load(pricesFile)
    } else {
        prices <- tryCatch(read.csv(file=sub("XXX",stock,price_url),header=T),
                           error=function(e) { 
                               print(paste(stock," prices not found")); 
                               stop(e)
                           })
        prices$Date <- as.Date(prices$Date)
        #Save the data
        save(prices,file=paste("data/",stock,"_prices.RData", sep=""))
    }
    prices <- filter(prices, Date > cutoff)
    meanPrice <- mean(prices$Close)
    sdPrice <- sd(prices$Close)
    
    #Load and process dividend data
    divsFile <- paste("data/",stock,"_divs.RData", sep="")
    if (file.exists(divsFile)) {
        load(divsFile)
    } else {
        divs <- tryCatch(read.csv(file=sub("XXX",stock,div_url),header=T),
                         error=function(e) { 
                             print(paste(stock," dividends not found")); 
                             stop(e)
                         })
        divs$Date <- as.Date(divs$Date)
        #Save the raw data
        save(divs,file=paste("data/",stock,"_divs.RData", sep=""))
    }
    divs <- filter(divs, Date > cutoff)
    
    #Retrieve Key statsxData <- getURL(ftse100)
    
    #Read web page and scrape table containing FTSE 100 constituents
    #xData <- tryCatch(getURL(sub("XXX",stock,keyStats_url)),
    #                   error=function(e) { 
    #                     print(paste(stock," key stats not found")); 
    #                     stop(e)
    #                   })
    #keyData<-readHTMLTable(xData)[2]$constituents
    
    #Analyse dividend data
    
    #Find price for divi date
    closing <- function(d) {
        dt <- as.Date(d)
        cl <- vector(mode="numeric", length = 0)
        for(d in dt) {
            p <- prices[prices$Date >= d & prices$Date < d + 7, c("Close")]
            cl <- append(cl, p)
        }
        cl
    }
    divs <- mutate(divs, close=closing(Date))
    
    #Summarise by year and avg price and percentage divi
    yearlyDivs <- mutate(divs, year=as.numeric(as.character(Date, "%Y")))  %>%
        group_by(year) %>%
        summarise(totalDiv = sum(Dividends), avgPrice=mean(close)) %>%
        mutate(percent = 100*totalDiv/avgPrice, 
               avgpercent = 100*totalDiv/meanPrice,
               date = as.Date(as.character(year), "%Y"),
               divPrice = totalDiv/0.04)  #Div price is the price the share needs to be to give a 4% return
    
    avgDivi <- mean(yearlyDivs$percent)
    sdDivi <- sd(yearlyDivs$percent)
    
    #Return the key stats
    c(name, stock, avgDivi, sdDivi, meanPrice, sdPrice)
}
