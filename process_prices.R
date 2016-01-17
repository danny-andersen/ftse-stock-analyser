
getYearlyDivs <- function(ticker, name, numOfYears = 8) {
    divsFile <- paste("data/",ticker,"_divs.RData", sep="")
    if (file.exists(divsFile)) {
        load(divsFile)
    } else {
        return
    }    
    cutoff <- as.POSIXlt(Sys.Date())
    cutoff$year <- cutoff$year - numOfYears
    cutoff <- as.Date(cutoff)
    divs <- filter(divs, Date > cutoff)
    closing <- function(d) {
        dt <- as.Date(d)
        cl <- vector(mode="numeric", length = 0)
        for(d in dt) {
            p <- prices[(prices$Date >= d - 7) & (prices$Date < d + 7), c("Close")]
            cl <- append(cl, p[1])
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
    yearlyDivs
}

getPrices <-function(ticker, name, numOfYears = 8) {
    pricesFile <- paste("data/",ticker,"_prices.RData", sep="")
    if (file.exists(pricesFile)){
        load(pricesFile)
    } else {
        return
    }
    cutoff <- as.POSIXlt(Sys.Date())
    cutoff$year <- cutoff$year - numOfYears
    cutoff <- as.Date(cutoff)
    
    prices <- filter(prices, Date > cutoff)
    prices
}


process_stock <- function(stock, name = stock, numOfYears = 8, force = FALSE) {
    library(dplyr)
    if (!require(XML)) install.packages('XML')
    library(XML)
    if (!require(RCurl)) install.packages('RCurl')
    library(RCurl)
    
    price_url="http://real-chart.finance.yahoo.com/table.csv?s=XXX.L&a=06&b=1&c=2004&d=11&e=31&f=2020&g=w&ignore=.csv"
    div_url="http://real-chart.finance.yahoo.com/table.csv?s=XXX.L&a=06&b=1&c=2004&d=11&e=31&f=2016&g=v&ignore=.csv"
    keyStats_url="https://uk.finance.yahoo.com/q/ks?s=XXX.L"
    
    #Load and process price data  
    pricesFile <- paste("data/",stock,"_prices.RData", sep="")
    if (force){
        prices <- tryCatch(read.csv(file=sub("XXX",stock,price_url),header=T),
                           error=function(e) { 
                               print(paste(stock," prices not found")); 
                               stop(e)
                           })
        prices$Date <- as.Date(prices$Date)
        #Save the data
        save(prices,file=paste("data/",stock,"_prices.RData", sep=""))
    }
    
    getPrices(stock, name, numOfYears)
    meanPrice <- mean(prices$Close)
    sdPrice <- sd(prices$Close)
    
    #Load and process dividend data
    divsFile <- paste("data/",stock,"_divs.RData", sep="")
    if (force) {
        divs <- tryCatch(read.csv(file=sub("XXX",stock,div_url),header=T),
                         error=function(e) { 
                             print(paste(stock," dividends not found")); 
                             stop(e)
                         })
        divs$Date <- as.Date(divs$Date)
        #Save the raw data
        save(divs,file=paste("data/",stock,"_divs.RData", sep=""))
    }
    #Analyse dividend data
    yearlyDivs <- getYearlyDivs(stock, name, numOfYears)
    avgDivi <- mean(yearlyDivs$percent)
    sdDivi <- sd(yearlyDivs$percent)
    
    
    #Retrieve Key statsxData <- getURL(ftse100)
    
    #Read web page and scrape table containing FTSE 100 constituents
    #xData <- tryCatch(getURL(sub("XXX",stock,keyStats_url)),
    #                   error=function(e) { 
    #                     print(paste(stock," key stats not found")); 
    #                     stop(e)
    #                   })
    #keyData<-readHTMLTable(xData)[2]$constituents
    
    #Return the key stats
    c(name, stock, avgDivi, sdDivi, meanPrice, sdPrice)
}
