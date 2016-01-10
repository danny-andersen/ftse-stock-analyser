
#Pull down list of stocks to analyse from wikipedia

if (!require(XML)) install.packages('XML')
library(XML)
if (!require(RCurl)) install.packages('RCurl')
library(RCurl)
source("process_prices.R")

#FTSE100 stocks
ftse100 <- "https://en.wikipedia.org/wiki/FTSE_100_Index"
xData <- getURL(ftse100)

#Read web page and scrape table containing FTSE 100 constituents
stockList<-readHTMLTable(xData)[2]$constituents
#Create and empty array to hold returned data
stats <- array(dim=c(nrow(stockList),6))

#Process each stock in the list to draw historical graphs and calculate avg dividend
for (i in 1:nrow(stockList)) {
    #Process stock
    s<-stockList[i,c("Ticker","Company")]
    stats[i,] <- tryCatch(process_stock(as.character(s[[1]]),as.character(s[[2]])),
                          error = function(e) {
                              c(as.character(s[[1]]),as.character(s[[2]]),NA,NA,NA,NA)
                          })
}
#Add the calculated dividend % 
stockList$AvgDividend <- as.numeric(stats[,3])
stockList$StdDevDividend <- as.numeric(stats[,4])
stockList$AvgPrice <- as.numeric(stats[,5])
stockList$StdDevPrice <- as.numeric(stats[,6])

save(stockList,file="../data/stockList.RData")

possibleStocks <- filter(stockList, AvgDividend >= 4) %>%
    arrange(desc(AvgDividend))
#Top 10 divi stocks
head(possibleStocks, n=10)
