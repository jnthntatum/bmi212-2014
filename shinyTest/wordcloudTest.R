require(XML)
require(tm)
require(wordcloud)
require(RColorBrewer)
#u = "http://cran.r-project.org/web/packages/available_packages_by_date.html"
#t = readHTMLTable(u)[[1]]
#ap.corpus <- Corpus(DataframeSource(data.frame(as.character(t[,3]))))

source("twitteRtest.R")

twitterWordCloud<-function(usernames) {
  ap.corpus <- Corpus(VectorSource(getTimelineTextMultipleUsers(usernames)))
  ap.corpus <- tm_map(ap.corpus, removePunctuation)
  ap.corpus <- tm_map(ap.corpus, tolower)
  ap.corpus <- tm_map(ap.corpus, function(x) removeWords(x, stopwords("english")))
  ap.tdm <- TermDocumentMatrix(ap.corpus)
  ap.m <- as.matrix(ap.tdm)
  ap.v <- sort(rowSums(ap.m),decreasing=TRUE)
  ap.d <- data.frame(word = names(ap.v),freq=ap.v)
  table(ap.d$freq)
  pal2 <- brewer.pal(8,"Dark2")
  print("b")
  wordcloud(ap.d$word,ap.d$freq, scale=c(8,.2),min.freq=3,
    max.words=100, random.order=FALSE, rot.per=.15, colors=pal2)
}