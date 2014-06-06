#This file is just a list of things which have been done to expand the cache. Not intended for programmatic access

#Expand dictionaries

vocab <- cache$vocabularies

words<-read.table("schizophrenia_words.txt")
words<-as.vector(words[,1])
addFrame<-data.frame(word=words, label=rep("Schizophrenia",length(words)))

words<-read.csv("../schizo_drugs.dat",header=F)
words<-unlist(as.character(words))
words<-as.character(words[!words==""])
addFrame<-data.frame(word=words, label=rep("Schizophrenia Drugs",length(words)))

words<-read.table("../smileys.txt",header=F)
words<-unlist(as.character(t(words)))
addFrame<-data.frame(word=words, label=rep("Smileys",length(words)))

words<-read.table("../profanities_mod.txt",header=F)
words<-unlist(as.character(t(words)))
addFrame<-data.frame(word=words, label=rep("Profanities",length(words)))


vocab<-rbind(vocab, addFrame)

#Remove some that gave issues
vocab<-vocab[! vocab$label %in% c("Smileys", "Schizophrenia Drugs"),]

cache$vocabularies <-vocab

modCache<-cache
save(modCache,file="shinyTest/modCache.RData")

########## More cache updating ###############

load("shinyTest/modCache.RData")
pu<-modCache$possibleUsernames
pu$label<-as.character(pu$label)
pu[pu$label=="schizophrenia_initial",]$label <- "Schizophrenia"
pu[pu$label=="control_initial",]$label <- "Control"
pu[pu$label=="politicians",]$label <- "Politicians"
pu[pu$label=="musicians",]$label <- "Musicians"

unique(pu$label)
nrow(pu[pu$label=="Schizophrenia",])

modCache$possibleUsernames <- pu
save(modCache,file="shinyTest/modCache.RData")

### RUN ME ####

schizoIds<-read.table("../schizoUsers.txt")
schizoIds<-d
head(schizoIds)
usernameVec<-c()
rowNums<-c(1:11,13:52,54:nrow(schizoIds))
rowNums<-c(87:nrow(schizoIds))

rowNums <- 27:100
for(i in rowNums) {
  print(i)  
#  userName<-getUser(as.character(schizoIds$V1[[i]]))
  userName<-getUser(as.character(schizoIds[[i]]))
  getTimelineCache(userName$screenName)
  usernameVec<-c(usernameVec,userName$screenName)
}
usernameVec<- unique(usernameVec)
pu<-rbind(pu,data.frame("label"=rep("Schizophrenia- larger", length(usernameVec)), "username"=usernameVec))
pu<-rbind(pu,data.frame("label"=rep("Russ' followers", length(usernameVec)), "username"=usernameVec))

usernameVec<-c("rbaltman", "atulbutte", "drnigam", "dpwall00", "micheldumontier")
for(username in usernameVec) {
  getTimelineCache(username)
}
modCache<-cache
modCache$possibleUsernames <- pu
save(modCache,file="shinyTest/modCache.RData")

unique(modCache$vocabularies$label)

install.packages("qdap")
library(qdap)
stem_words(c("apples grappling apple grappe :)"))

vocab<-modCache$vocabularies
a<-stemmer(vocab[! vocab$label %in% c("Smileys"),]$word)
rbaltman atulbutte drnigam dpwall00 micheldumontier