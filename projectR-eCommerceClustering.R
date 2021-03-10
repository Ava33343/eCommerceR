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
