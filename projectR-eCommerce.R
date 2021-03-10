# eCommerce

install.packages('readr')
library('readr')
install.packages('dplyr')
library('dplyr')
install.packages('ggplot2')
library('ggplot2')
install.packages('DataExplorer')
library('DataExplorer')
install.packages('lubridate')
library('lubridate')
install.packages('agricolae')
library('agricolae')
install.packages('heatmaply')
library('heatmaply')

## KMeans clustering
install.packages('factoextra')
library('factoextra')


# Read data
custData<- read.csv(file.choose(), header=T)

# Descriptive statistics
head(custData)
glimpse(custData)
summary(custData)
dim(custData)

# Plot missing values using the DataExplorer package
options(repr.plot.width=7, repr.plot.height=3)
plot_missing(custData)

# Drop missing values and check dimensions
drop  <- c("X")
custData = custData[!names(custData)%in%drop]
custData <- na.omit(custData)
dim(custData)
head(custData)


# create date, month and year components of invoice date
custData$date <- sapply(custData$InvoiceDate, FUN = function(x) {strsplit(x, split = '[-]')[[1]][1]})
custData$month <- sapply(custData$InvoiceDate, FUN = function(x) {strsplit(x, split = '[-]')[[1]][2]})
custData$year <- sapply(custData$InvoiceDate, FUN = function(x) {strsplit(x, split = '[-]')[[1]][3]})

# check the first three entries
head(custData, n =3)

# Convert date variable into datetime format
custData$dateIndex <- as.Date(custData$InvoiceDate, format="%d-%b-%y")
head(custData)

# Create dayOfWeek variable
custData <- custData %>% mutate(lineTotal = Quantity * UnitPrice)
custData$dayOfWeek <- wday(custData$dateIndex, label=TRUE)
head(custData)

# Convert variables into factors
custData$Country <- as.factor(custData$Country)
custData$date <- as.factor(custData$date)
custData$month <- as.factor(custData$month)
custData$year <- as.factor(custData$year)
range(custData$InvoiceDate)
levels(custData$year) <- c(2016,2017)
custData$dayOfWeek <- as.factor(custData$dayOfWeek)

head(custData, n=5)

#------------------ Clustering ----------------------#

#-------KMeans Best Cluster Model with Four Clusters------------------#

# Converting more variables into factors in the processed dataset custData
custData$InvoiceNo <- as.factor(custData$InvoiceNo)
custData$StockCode <- as.factor(custData$StockCode)
custData$CustomerID <- as.factor(custData$CustomerID)
custData$Description <- as.factor(custData$Description)
custData$InvoiceDate <- as.factor(custData$InvoiceDate)

# Convert factors into numeric values
cust_convert <- sapply(custData, is.factor)
custNum <- sapply(custData[,cust_convert], unclass)
custNumData <- cbind(custData[,!cust_convert],custNum)

# Check the new processed data set
head(custNumData, n=5)

# Pick numeric variables that are believed to be impactful
custNumeric <- custNumData %>% select(InvoiceNo, StockCode, Description, InvoiceDate, CustomerID, Country, date, month, dayOfWeek)
head(custNumeric, n=5)

# standardisation (or normalization)
cust_stand<-scale(custNumeric)

## KMeans clustering
#install.packages('factoextra')
#library('factoextra')

# Create 4 clusters
km <- kmeans(cust_stand, 4)
head(km)

cust_kmeans<-data.frame(cust_stand, km$cluster)
head(cust_kmeans)

# cluster profiling
names(cust_kmeans)
aggregate(cust_kmeans[,-1],by=list(cust_kmeans$km.cluster),FUN=mean)
aggregate(cust_kmeans[,-1],by=list(cust_kmeans$km.cluster),FUN=min)
aggregate(cust_kmeans[,-1],by=list(cust_kmeans$km.cluster),FUN=max)

#cluster visualization
names(cust_kmeans)

fviz_cluster(km, data = cust_kmeans,
             palette = c("#2E9FDF", "#00AFBB", "#E7B800", "#00ff83"), 
             geom = "point",
             ellipse.type = "convex", 
             ggtheme = theme_bw()
)

#----------KMeans First Trial with Three Clusters and Numeric Only Factors------------#

# standardisation (or normalization)
cust <- custData %>% select(UnitPrice, Quantity, lineTotal)
head(cust)

fit<-hclust(custData, method='complete')
groups<-cutree(fit,k=3)
groups

## KMeans clustering

km <- kmeans(custData, 3)
head(km)

cust_kmeans<-data.frame(custData, km$cluster)
cust_kmeans

#cluster visualization
names(km)

fviz_cluster(km, data = cust,
             palette = c("#2E9FDF", "#00AFBB", "#E7B800"), 
             geom = "point",
             ellipse.type = "convex", 
             ggtheme = theme_bw()
)

#---------------------------Clustering End ----------------------------#

# Plot revenue in over time
options(repr.plot.width=8, repr.plot.height=3)
custData %>%
  group_by(dateIndex) %>%
  summarise(revenue = sum(lineTotal)) %>%
  ggplot(aes(x = dateIndex, y = revenue)) + geom_line() + geom_smooth(method = 'auto', se = FALSE) + labs(x = 'Date', y = 'Revenue (£)', title = 'Revenue by Date')

# Plot revenue by dayOfWeek
custData %>%
  group_by(dayOfWeek) %>%
  summarise(revenue = sum(lineTotal)) %>%
  ggplot(aes(x = dayOfWeek, y = revenue)) + geom_col() + labs(x = 'Day of Week', y = 'Revenue (£)', title = 'Revenue by Day of Week')

# Transaction table by dayOfWeek
weekdaySummary <- custData %>%
  group_by(dateIndex, dayOfWeek) %>%
  summarise(revenue = sum(lineTotal), transactions = n_distinct(InvoiceNo)) %>%
  mutate(aveOrdVal = (round((revenue / transactions),2))) %>%
  ungroup()

head(weekdaySummary, n = 10)

# Box plot of revenue by day of week
ggplot(weekdaySummary, aes(x = dayOfWeek, y = revenue)) + geom_boxplot() + labs(x = 'Day of the Week', y = 'Revenue', title = 'Revenue by Day of the Week')
ggplot(weekdaySummary, aes(x = dayOfWeek, y = transactions)) + geom_boxplot() + labs(x = 'Day of the Week', y = 'Number of Daily Transactions', title = 'Number of Transactions by Day of the Week')
ggplot(weekdaySummary, aes(x = dayOfWeek, y = aveOrdVal)) + geom_boxplot() + labs(x = 'Day of the Week', y = 'Average Order Value', title = 'Average Order Value by Day of the Week')

# Density plot of transactions by day of week
ggplot(weekdaySummary, aes(transactions, fill = dayOfWeek)) + geom_density(alpha = 0.2)

# Apply non-parametric test for distributions other than normal based on skewness of the density plot
kruskal.test(transactions ~ dayOfWeek, data = weekdaySummary)
# Discover which day of a week incurs significantly higher or lower revenues
kruskal(weekdaySummary$transactions, weekdaySummary$dayOfWeek, console = TRUE)


# Valued Customer Analysis by Month
custData %>%
  group_by(month) %>%
  summarise(revenue = sum(lineTotal)) %>%
  ggplot(aes(x = month, y = revenue)) + geom_col() + labs(x = 'Month', y = 'Revenue (£)', title = 'Revenue by Month Of Year')

custData %>%
  group_by(month) %>%
  summarise(transactions = n_distinct(InvoiceNo)) %>%
  ggplot(aes(x = month, y = transactions)) + geom_col() + labs(x = 'Month', y = 'Number of Transactions', title = 'Transactions by Month Of Year')

# Most valuable customers by country
countrySummary <- custData %>%
  group_by(Country) %>%
  summarise(revenue = sum(lineTotal), transactions = n_distinct(InvoiceNo)) %>%
  mutate(aveOrdVal = (round((revenue / transactions),2))) %>%
  ungroup() %>%
  arrange(desc(revenue))

head(countrySummary, n = 10)
unique(countrySummary$Country)

countryCustSummary <- custData %>%
  group_by(Country) %>%
  summarise(revenue = sum(lineTotal), customers = n_distinct(CustomerID)) %>%
  mutate(aveCustVal = (round((revenue / customers),2))) %>%
  ungroup() %>%
  arrange(desc(revenue))

head(countryCustSummary, n = 10)

# Top five most valued countries
topFiveCountries <- custData %>%
  filter(Country == 'United Kingdom' | Country == 'Netherlands' | Country == 'EIRE' | Country == 'Germany' | Country == 'France')

topFiveCountrySummary <- topFiveCountries %>%
  group_by(Country, dateIndex) %>%
  summarise(revenue = sum(lineTotal), transactions = n_distinct(InvoiceNo), customers = n_distinct(CustomerID)) %>%
  mutate(aveOrdVal = (round((revenue / transactions),2))) %>%
  ungroup() %>%
  arrange(desc(revenue))

head(topFiveCountrySummary)

ggplot(topFiveCountrySummary, aes(x = Country, y = revenue)) + geom_col() + labs(x = ' Country', y = 'Revenue (£)', title = 'Revenue by Country')
ggplot(topFiveCountrySummary, aes(x = dateIndex, y = revenue, colour = Country)) + geom_smooth(method = 'auto', se = FALSE) + labs(x = ' Country', y = 'Revenue (£)', title = 'Revenue by Country over Time')
ggplot(topFiveCountrySummary, aes(x = Country, y = aveOrdVal)) + geom_boxplot() + labs(x = ' Country', y = 'Average Order Value (£)', title = 'Average Order Value by Country') + scale_y_log10()
ggplot(topFiveCountrySummary, aes(x = Country, y = transactions)) + geom_boxplot() + labs(x = ' Country', y = 'Transactions', title = 'Number of Daily Transactions by Country')

# Segmentation
custSummary <- custData %>%
  group_by(CustomerID) %>%
  summarise(revenue = sum(lineTotal), transactions = n_distinct(InvoiceNo)) %>%
  mutate(aveOrdVal = (round((revenue / transactions),2))) %>%
  ungroup() %>%
  arrange(desc(revenue))

head(custSummary, n = 10)

# Revenue per customer
ggplot(custSummary, aes(revenue)) + geom_histogram(binwidth = 10) + labs(x = 'Revenue', y = 'Count of Customers', title = 'Histogram of Revenue per customer')
ggplot(custSummary, aes(revenue)) + geom_histogram() + scale_x_log10() + labs(x = 'Revenue', y = 'Count of Customers', title = 'Histogram of Revenue per customer (Log Scale)')
ggplot(custSummary, aes(transactions)) + geom_histogram() + scale_x_log10() + labs(x = 'Number of Transactions', y = 'Count of Customers', title = 'Histogram of Transactions per customer')

# Group B
custSummaryB <- custData %>%
  group_by(CustomerID, InvoiceNo) %>%
  summarise(revenue = sum(lineTotal), transactions = n_distinct(InvoiceNo)) %>%
  mutate(aveOrdVal = (round((revenue / transactions),2))) %>%
  ungroup() %>%
  arrange(revenue) %>%
  mutate(cumsum=cumsum(revenue))

head(custSummaryB, n =10)

custData %>% filter(CustomerID == 16446)

custSummaryB <- custData %>%
  group_by(InvoiceNo, CustomerID, Country, dateIndex, month, year, dayOfWeek) %>%
  summarise(orderVal = sum(lineTotal)) %>%
  mutate(recent = Sys.Date() - dateIndex) %>%
  ungroup()

custSummaryB$recent <- as.character(custSummaryB$recent)
custSummaryB$recentDays <- sapply(custSummaryB$recent, FUN = function(x) {strsplit(x, split = '[-]')[[1]][1]})
custSummaryB$recentDays <- as.integer(custSummaryB$recentDays)

head(custSummaryB, n = 5)

# Customer Breakdown
customerBreakdown <- custSummaryB %>%
  group_by(CustomerID, Country) %>%
  summarise(orders = n_distinct(InvoiceNo), revenue = sum(orderVal), meanRevenue = round(mean(orderVal), 2), medianRevenue = median(orderVal),
            mostDay = names(which.max(table(dayOfWeek))), mostMonth = names(which.max(table(month))),
            recency = min(recentDays))%>%
  ungroup()

head(customerBreakdown)

custBreakSum <- customerBreakdown %>%
  filter(orders > 1, revenue > 50)

head(custBreakSum)
dim(custBreakSum)

# Heatmap

custMat <- custBreakSum %>%
  select(recency, revenue, meanRevenue, medianRevenue, orders) %>%
  as.matrix()

rownames(custMat) <- custBreakSum$CustomerID

head(custMat)
class(custMat)

options(repr.plot.width=12, repr.plot.height=7)
heatmap(scale(custMat), cexCol = 0.7)



# Reference
# https://www.kaggle.com/chrisbow/e-commerce-eda-and-segmentation-with-r
# https://www.datanovia.com/en/blog/k-means-clustering-visualization-in-r-step-by-step-guide/
