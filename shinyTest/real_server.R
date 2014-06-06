library(shiny)
library(ggplot2)

source("twitteRtest.R")
source("wordcloudTest.R")

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  
  # Expression that generates a histogram. The expression is
  # wrapped in a call to renderPlot to indicate that:
  #
  #  1) It is "reactive" and therefore should re-execute automatically
  #     when inputs change
  #  2) Its output type is a plot
  
  usernames<-data.frame(label=c("musicians","musicians","musicians","musicians","politicians","politicians","politicians","politicians"),
    username=c("ladygaga","justinbieber","taylorswift13","ladygaga","BarackObama","hilaryclinton","JoeBiden","SenRandPaul"))
  
  vocabularies<-data.frame(label=c("happy","happy","happy","happy","happy","sad","sad","sad","sad","sad"), 
    word=c("happy","ecstatic","smile",":)","proud","sad",":(","frustrated","disappointed","hurt"))
  
  output$distPlot <- renderPlot({
#     totalFollowers<-c()
#     for(username in strsplit(input$usernamesA,' ')[[1]]) {
#       totalFollowers<-c(totalFollowers,getFollowerCount(username))
#     }
#     followerFrameA<-data.frame(label=rep('A',length(totalFollowers)), data=totalFollowers)
#     totalFollowers<-c()
#     for(username in strsplit(input$usernamesB,' ')[[1]]) {
#       totalFollowers<-c(totalFollowers,getFollowerCount(username))
#     }
#     followerFrameB<-data.frame(label=rep('B',length(totalFollowers)), data=totalFollowers)
#     followerFrame<-rbind(followerFrameA,followerFrameB)
    #Load with sample data
   # followerFrame<-data.frame(label=c('Schizophrenic','Schizophrenic','Schizophrenic','Control','Control','Control'),
  #    data=c(100,50,75,300,400,230))
    
    labelVec<-c()
    dataVec<-c()

    for(i in 1:nrow(usernames)) {
      dataVec<-c(dataVec,getFollowerCount(usernames[i,]$username))
      labelVec<-c(labelVec,as.character(usernames[i,]$label))

    }
    followerFrame<-data.frame("label"=labelVec,"data"=dataVec)
   
    
    # draw the histogram with the specified number of bins
    #hist(totalFollowers,  col = 'darkgray', border = 'white')
    p<-ggplot(followerFrame,aes(factor(label),data))+geom_violin()+geom_point() +xlab("Group")+ylab("Followers")
    print(p)
  })
  output$wordPlot <- renderPlot({
    #twitterWordCloud(strsplit(input$usernamesB,' ')[[1]])
    twitterWordCloud(c("hayneswa","sfexaminer","nytimes"))
  })
})