#Update the twitteR
library(devtools)
#install_github("twitteR", username="geoffjentry")
library(twitteR)

library(yaml)
config=yaml.load_file("keys.cred")

#Get the OAuth, which is loaded into session and ignored
setup_twitter_oauth(config$consumerKey, config$consumerSecret, config$accessKey, config$accessSecret)

# #Query based on username
# username<-getUser('hayneswa')
# 
# #Get some statistics
# username$followersCount
# username$statusesCount
# 
# #Get the timeline (which is a list of statuses)
# timeline<-userTimeline(username)
# 
# #Look at first status in timeline
# statusA<-timeline[[1]]
# 
# #Get some status statistics
# statusA$retweetCount
# statusA$favoriteCount

#Caching
#cache<-list()
#save(cache,file="shinyTest/cache.RData")
print("Loading cache....")
load("modCache.RData")
cache<-modCache
print("Loaded")

getFollowerCount<-function(username) {
  usernames<-getUserCache(username)
  ret = usernames$followersCount
  if (length(ret)==0){
    a = getUser(username) 
    ret = a$followersCount

  }
  return(ret)
}


getFollowingCount<-function(username) {
  usernames<-getUserCache(username)
  ret = usernames$friendsCount
  if (length(ret)==0){
    a = getUser(username) 
    ret = a$friendsCount
    
  }
  return(ret)
}

reduceUser<- function(userObj) {
  a<-list(followersCount=userObj$followersCount, friendsCount=userObj$friendsCount, statusesCount=userObj$statusesCount, 
          utcOffset=userObj$utcOffset)
  return(a)
}

reduceTimeline <- function(timeObj) {
  a<-list()
  if(length(timeObj) > 0) {
    for(i in 1:length(timeObj)) {
      status<-timeObj[[i]]
    #for(status in timeObj) {
      a[[i]] <- list(text=status$text, created=status$created)
      if(is.null(status$created)) {
        a[[i]]$created<- 0
      }
      
    }
  }
  return(a)
}
# 
# modCache<-list()
# for(name in names(cache)) {
#   if(length(grep("user$",name,perl=T))>0) {
#     modCache[[name]]<-reduceUser(cache[[name]])
#   }
#   else { 
#     if(length(grep("timeline$",name,perl=T))>0) {
#     modCache[[name]] <- reduceTimeline(cache[[name]])
#     }
#     
#     else {
#       print(name)
#     }
#   }
# } 
# modCache$vocabularies <-cache$vocabularies
# modCache$possibleUsernames<- cache$possibleUsernames
# save(modCache, file="shinyTest/modCache.RData")

getUserCache<-function(username) {
  cacheIndex<-paste(username,"user",sep="")
  if(cacheIndex %in% names(cache)) {
    userObj<-cache[cacheIndex][[1]]
  }
  else {
    #print(username)
    userObj<-tryCatch( {
    userObj<- getUser(username)
     cache[cacheIndex][[1]]<-reduceUser(userObj)
     assign("cache",cache,envir=globalenv())
    return(userObj)
    }, error=function(err) {
      print("error on user:")
      print(username)
      return(NULL)
    })
  }
  return(userObj)
}

getTimelineCache<- function(username) {
  cacheIndex<-paste(username,"timeline",sep="")
  if(cacheIndex %in% names(cache)) {
    timeline<-cache[cacheIndex][[1]]
  }
  else {
    print(username)
    userObj <- getUserCache(username)
    timeline<- userTimeline(userObj, n=1000)
    cache[cacheIndex][[1]]<-reduceTimeline(timeline)
    assign("cache",cache,envir=globalenv())
#     print("waiting")
#     Sys.sleep(60)
  }
  return(timeline)
}

getTimelineTextSingleUser<-function(username) {
  timeline<-getTimelineCache(username)
  textVector<-c()
  for(status in timeline) {
    textVector<-c(textVector,status$text)
  }
  textVector<- gsub("[^[:alnum:][:punct:][:blank:]]","",textVector)
  return(textVector)
}

getTimelineTextMultipleUsers <- function(usernames) {
  textVec<-c()
  for(username in usernames) {
    textVec<-c(textVec, getTimelineTextSingleUser(username))
  }
  return(textVec)
}

getPossibleUsernames <- function() {
  return(cache$possibleUsernames)
}

getVocabularies <- function() {
  return(cache$vocabularies)
}

##Following were removed
# voicyconusem
# life_sz
# ericadyesebelle
# Becka_Montero
