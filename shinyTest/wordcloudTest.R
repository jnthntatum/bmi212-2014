require(XML)
require(tm)
require(wordcloud)
require(RColorBrewer)
#u = "http://cran.r-project.org/web/packages/available_packages_by_date.html"
#t = readHTMLTable(u)[[1]]
#ap.corpus <- Corpus(DataframeSource(data.frame(as.character(t[,3]))))

# source("twitteRtest.R")

multipleWordClouds <- function(usernames) {
  uniqueLabels<-unique(usernames$label)
  nLabels<-length(uniqueLabels)
  nRows=ceiling(nLabels/2)*2
  layout(matrix(1:(2*nRows), nrow=nRows), widths =c(2,2),heights=rep(c(1, 4),nLabels))
  
  for (i in 1:nLabels){
    usernameLabel<-uniqueLabels[[i]]
    par(mar=rep(0, 4))
    #Add the label
    plot.new()
    text(x=0.5, y=0.5, usernameLabel, cex=4)
    
    #Add the wordcloud
    twitterWordCloud(usernames[usernames$label == usernameLabel,]$username)
  }
}

twitterWordCloud<-function(usernames) {

  wordVec<-getTimelineTextMultipleUsers(usernames)
  maxLength<-400
  if(length(wordVec) > maxLength) {
    wordVec<-sample(wordVec,maxLength)
  }
  wordString<-paste(wordVec,collapse=" ")
  ap.corpus<-Corpus(VectorSource(wordString))
  ap.corpus <- tm_map(ap.corpus, removePunctuation,lazy=T)
  ap.corpus <- tm_map(ap.corpus, tolower,lazy=T)
  ap.corpus <- tm_map(ap.corpus, function(x) removeWords(x, stopwords("english")),lazy=T)
  ap.tdm <- TermDocumentMatrix(ap.corpus)
  ap.m <- as.matrix(ap.tdm)
  ap.v <- sort(rowSums(ap.m),decreasing=TRUE)
  ap.d <- data.frame(word = names(ap.v),freq=ap.v)
  pal2 <- brewer.pal(8,"Dark2")
  
  #plot layout
  wordcloud(ap.d$word,ap.d$freq, scale=c(8,.2),min.freq=3,
max.words=100, random.order=FALSE, rot.per=.15, colors=pal2)

}