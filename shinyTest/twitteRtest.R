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

getFollowerCount<-function(username) {
  usernames<-getUser(username)
  return(usernames$followersCount)
}