library(shiny)
library(ggplot2)
library(wordcloud)
#install.packages("gridExtra")
library(gridExtra)

source("twitteRtest.R")
source("Rachel.R")
source("wordcloudTest.R")
source("timePlots.R")
source("staticPlot.R")

shinyServer(function(input, output) {

  possibleUsernames <-getPossibleUsernames()
  possibleVocabularies <- getVocabularies()
  
  output$value <- renderPrint({ input$checkGroup })
  
  getUsernames <- function(input) {
    usernames<-possibleUsernames[possibleUsernames$label %in% input$groups,]
    if(!is.null(input$groupsCustom)) {
     groupWords<-strsplit(input$groupsCustom,split="[ ,]", perl=T)[[1]]
     if(length(groupWords)>=5) {
       catVec<-rep("custom",length(groupWords))
       tempFrame<-data.frame(label=catVec, username=groupWords)
       usernames<-rbind(usernames,tempFrame)
     }
    }
    return(usernames)
  }
  
  getVocabularies <- function(input) {
    vocabularies <- possibleVocabularies[possibleVocabularies$label %in% input$vocab,]
    if(!is.null(input$vocabCustom)) {
      groupWords<-strsplit(input$vocabCustom,split="[ ,]", perl=T)[[1]]
      if(length(groupWords)>=5) {
        catVec<-rep("custom",length(groupWords))
        tempFrame<-data.frame(label=catVec, word=groupWords)
        vocabularies<-rbind(vocabularies,tempFrame)
      }
    }
    return(vocabularies)
  }
    
  output$distPlot <- renderPlot({
    distPlotFunction(getUsernames(input))   
  })
  
  output$tweetPlot <- renderPlot({
    tweetPlotFunction(getUsernames(input))
  })
  
  output$tweetLengthPlot <- renderPlot({
    tweetLengthPlotFunction(getUsernames(input))
   })

  output$followingPlot <- renderPlot({
    followingFunction(getUsernames(input))
  })
  
  output$wordPlot <- renderPlot({
   multipleWordClouds(getUsernames(input))
  })

output$timePlot <- renderPlot({
  tweetsOverTime(getUsernames(input))
})
output$vocabPlot <- renderPlot({
  dictionaryUse(getUsernames(input),getVocabularies(input))
})
output$burstPlot <- renderPlot({
  burstActivity(getUsernames(input))
})
output$modelPlot <-renderPlot({
  staticPlot()
})
output$staticModelPlot <- renderImage({
  list(src= "model_scatter_plot_2.png")
}, deleteFile=F)

})