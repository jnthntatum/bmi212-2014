

# plot the number of followers
distPlotFunction <- function(usernames) {
labelVec<-c()
dataVec<-c()

for(i in 1:nrow(usernames)) {
  dataVec<-c(dataVec,getFollowerCount(usernames[i,]$username))
  labelVec<-c(labelVec,as.character(usernames[i,]$label))

 }

followerFrame<-data.frame("label"=labelVec,"data"=dataVec)
p<-ggplot(followerFrame,aes(factor(label),data,fill=factor(label))) + guides(fill=FALSE) +geom_violin()+geom_point() + xlab("Group")+ylab("Followers")+ scale_fill_discrete("Group") + labs(title="Number of Followers") + scale_y_log10()
print(p)

}



# plot the number of tweets for each group
tweetPlotFunction <- function(usernames) {
  labelVec<-c()
  tweetsVec<-c() 

  for(i in 1:nrow(usernames)) {
    labelVec<-c(labelVec,as.character(usernames[i,]$label))
    
    u<-getUserCache(usernames[i,]$username)
    num.tweets = u$statusesCount
    
    if (length(num.tweets)==0){
      a = getUser(usernames[i,]$username) 
      num.tweets = a$statusesCount
      
    }
    tweetsVec<-c(tweetsVec, num.tweets)  
    }
    numTweetsFrame<-data.frame("label"=labelVec,"data"=tweetsVec)
    p<-ggplot(numTweetsFrame,aes(factor(label),data, fill=factor(label))) + guides(fill=FALSE)+ scale_fill_discrete("Group")+geom_violin()+geom_point() +xlab("Group")+labs(title="Number of Tweets") +ylab("Number of Tweets") + scale_y_log10()
    print(p) 
}

# plot the length of tweets for each group ( # characters, # words)
tweetLengthPlotFunction <- function(usernames) {
  labelVec<-c()
  wordsVec<-c() 
  charsVec<-c() 
  for(i in 1:nrow(usernames)) {
    labelVec<-c(labelVec,as.character(usernames[i,]$label))
    text<-getTimelineTextSingleUser(usernames[i,]$username)
#     if (length(text)==0){
#       print ("HERE")
#       print(usernames[i,]$username)
#       usrObj = getUser(usernames[i,]$username) 
#       timeline = userTimeline(usrObj)
#       text<-c()
#       for(status in timeline) {
#         text<-c(text,status$text)
#       }
#       
#     }
    num.wordsVec<-c()
    num.charVec<-c()
    
    for (a in 1:length(text)){
      if(length(text)>0){
      num.words = length(strsplit(text[a], " ")[[1]])
      num.wordsVec<-c(num.wordsVec, num.words)
      
      num.chars = length(strsplit(text[a], "")[[1]])
      num.charsVec<-c(num.charVec, num.chars)
      }
      else{
        num.words = 0
        num.chars = 0
      }
    }
    wordsVec<-c(wordsVec, mean(num.words))
    charsVec<-c(charsVec, mean(num.chars)) 
  }
  numWordsFrame<-data.frame("label"=labelVec,"data"=wordsVec)
#   print(numWordsFrame)
  plot1<-ggplot(numWordsFrame,aes(factor(label),data,fill=factor(label)))+geom_violin()+ scale_fill_discrete("Group")+ geom_point() +xlab("Group")+ylab("Words") +labs(title="Average Number of Words Per Tweet") + guides(fill=FALSE) 
  numCharsFrame<-data.frame("label"=labelVec,"data"=charsVec)
#   print(numCharsFrame)
  plot2<-ggplot(numCharsFrame,aes(factor(label),data,  fill=label))+geom_violin()+geom_point() + scale_fill_discrete("Group")+xlab("Group")+labs(title="Average Number of Characters Per Tweet") +ylab("Characters") + guides(fill=FALSE)
  p<-grid.arrange(plot1, plot2, nrow=2)
  print(p) 
}

# plot the number of users each group is following
followingFunction <- function(usernames) {
  labelVec<-c()
  dataVec<-c()
  
  for(i in 1:nrow(usernames)) {
    dataVec<-c(dataVec,getFollowingCount(usernames[i,]$username))
    labelVec<-c(labelVec,as.character(usernames[i,]$label))
  }
  followingFrame<-data.frame("label"=labelVec,"data"=dataVec)
  p<-ggplot(followingFrame,aes(factor(label),data,fill=factor(label)))+geom_violin()+geom_point() + xlab("Group")+ylab("Following")+ scale_fill_discrete("Group") + labs(title="Number of Users Followed") + guides(fill=FALSE) +scale_y_log10()
  print(p)
}
