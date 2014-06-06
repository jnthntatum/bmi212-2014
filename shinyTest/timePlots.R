library(ggplot2)
library(gridExtra)
library(scales)
# source("twitteRtest.R")

minTime<-function(prev) {
  posix<- as.POSIXlt(prev$created)
  return(posix$hour*60 + posix$min)
}

fullTime<-function(prev) {
  posix<- as.POSIXlt(prev$created)
  return(posix$hour*60 + posix$min + posix$yday*1440 + (posix$year-100)*(525600))
}

#Input:
#   df: data frame object with label and username as columns
tweetsOverTime<-function(df) {
  
  curTime<-proc.time()
  hourVec <- c()
  catVec <- c()
  
  for(j in 1:nrow(df)) {
    curUsername<-df$username[[j]]
    timeline<- getTimelineCache(curUsername)
    userObj<-getUserCache(curUsername)
    
    #Account for the UTC offset
    offSet <- 0
    posOffset<-  userObj$utcOffset
    if(exists("posOffset") && length(posOffset) ==1 && ! is.na(posOffset)) {
      offSet<- posOffset
    }
    #Offset in minutes
    offSet<- offSet/60
    
    if(length(timeline)>0) {
        #timelineDF <- twListToDF(timeline)

        #Calculate the minutes, adjust for offset
        timeVals <- sapply(timeline, minTime) + offSet
        
        #Convert to hours
        hourVals <- (timeVals / 60.0) %%24
        hourVec <- c(hourVec, hourVals)
        catVec <- c(catVec, rep(as.character(df$label[[j]]), length(hourVec)-length(catVec)))
    }
  }
  print(proc.time()-curTime)
  curTime<-proc.time()
  
  #Add time on both sides to smooth the density plots
  #We will calculate the density for each label and keep only the 0-24 labels
  timeFrame<-data.frame(hour=c(hourVec,hourVec-24,hourVec+24), label=rep(as.factor(catVec),3))
  densityFrame<-data.frame(hour=c(), density=c(), label=c())
  for(label in levels(timeFrame$label)) {
    labelHours<-timeFrame$hour[timeFrame$label==label]
    dens<- density(c(labelHours,labelHours+24,labelHours-24))
    indices<- dens$x>0 & dens$x<24
    selectedDensity<- dens$y[indices]
    selectedDensity<- selectedDensity/sum(selectedDensity)* length(selectedDensity)
    tempFrame<-data.frame(hour=dens$x[indices], density=selectedDensity, label=rep(label,sum(indices)))
    densityFrame<- rbind(densityFrame, tempFrame)
  }
  print(proc.time()-curTime)
  curTime<-proc.time()
  
  #polar plot
  q <- ggplot(densityFrame, aes(x=hour, y=density ,group=label, color=label, fill=label)) +geom_area(alpha=0.3) + coord_polar(start=0)
  q <- q+ ggtitle("Tweet Time of Day")+ guides(fill=F, color=F) +scale_x_continuous(breaks=c(6,12,18,23.9), labels=c("6am","noon","6pm","midnight"))
  q <- q + xlab("")
  
  #Line plot
  p <-ggplot(timeFrame, aes(hour, fill=label, color=label)) +geom_density(alpha=0.3) +coord_cartesian(xlim=c(0,24)) + ggtitle("Tweet Time of Day") 
  p <- p + guides(fill=F, color=F) +scale_x_continuous(breaks=c(0,6,12,18,24), labels=c("midnight","6am","noon","6pm","midnight"))
  p <- p + xlab("")
  grid.arrange(p, q, nrow=1, ncol=2)
  
  print(proc.time()-curTime)
}

burstActivity <-function(df) {
  
  curTime<-proc.time()
  diffVec <- c()
  catVec <- c()
  
  for(j in 1:nrow(df)) {
    curUsername<-df$username[[j]]
    timeline<- getTimelineCache(curUsername)
    
    if(length(timeline)>1) {
      testTime<-sapply(timeline,fullTime)
      timeDiff<-testTime[1:(length(testTime)-1)]-testTime[2:length(testTime)]
      diffVec<-c(diffVec,timeDiff)
      catVec <- c(catVec, rep(as.character(df$label[[j]]), length(diffVec)-length(catVec)))
    }
  }
  print(proc.time()-curTime)
  curTime<-proc.time()

  timeFrame<-data.frame(hour=diffVec/24, label=as.factor(catVec))
  
  #Line plot
  p<-ggplot(timeFrame, aes(hour,color=label,fill=label)) +geom_density(alpha=0.3) + xlab("") +
    ggtitle("Time Between Tweets") + guides(color=F) + scale_x_log10(breaks=c(1.0/24,1,7,30,365), label=c("Hour","Day", "Week", "Month", "Year"))
  print(p)
  
  print(proc.time()-curTime)
}

dictionaryUse <- function(userDf, vocabDf) {
  curTime<-proc.time()
  gridElements<-list()
  for(label in unique(vocabDf$label)) {
    print(label)
    diffVec <- c()
    catVec <- c()
    print(label)
    vocab<-vocabDf$word[vocabDf$label==label]
    
    for(j in 1:nrow(userDf)) {
      curUsername<-userDf$username[[j]]
      timeline<- tolower(getTimelineTextSingleUser(curUsername))
      timelineText<- paste(timeline, collapse=" ")
      words <- strsplit(timelineText, split=" ")
      overlapWords <- sum(words[[1]] %in% vocab)
      newDiff<-0
      if(length(words[[1]])>0) {
        newDiff <- overlapWords / length(words[[1]]) *100
      }
      diffVec <- c(diffVec, newDiff)
      catVec <- c(catVec, rep(as.character(userDf$label[[j]]), length(diffVec)-length(catVec)))
    }
    print(proc.time()-curTime)
    curTime<-proc.time()
    
    zeroVal <- 1e-2
    if(length(diffVec[! diffVec==0])>0) {
      zeroVal<- min(diffVec[! diffVec==0])
    }
    #For those that are zero, add a trvial amount of random noise so that the violin plots don't blow up
    diffVec[diffVec==0] <- zeroVal + zeroVal*1e-7*runif(length(diffVec[diffVec==0]))
    
    timeFrame<-data.frame(usePerc=diffVec, label=as.factor(catVec))
    
    #Line plot
    p<-ggplot(timeFrame, aes(label,usePerc, fill=factor(label)))+ geom_violin() + geom_point()  + ggtitle(label) + 
      ylab("% of Words Used") + guides(fill=F) +xlab("Group") + scale_y_log10()
    gridElements[[label]]<-p
  }
  do.call("grid.arrange",c(gridElements,nrow=ceiling(length(gridElements)/2), ncol=2))
  print(proc.time()-curTime)
}

# cdf of time delay between tweets
# Update selected boxes
# Update cache
# install.packages("/home//hayneswa/Dropbox//bmi212/bmi212-2014/twitteR_1.1.8.tar.gz",repos=NULL)
