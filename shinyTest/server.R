library(shiny)

source("../twitteRtest.R")

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  
  # Expression that generates a histogram. The expression is
  # wrapped in a call to renderPlot to indicate that:
  #
  #  1) It is "reactive" and therefore should re-execute automatically
  #     when inputs change
  #  2) Its output type is a plot
  
  output$distPlot <- renderPlot({
    totalFollowers<-c()
    for(username in strsplit(input$username,' ')[[1]]) {
      totalFollowers<-c(totalFollowers,getFollowerCount(username))
    }
    
    # draw the histogram with the specified number of bins
    hist(totalFollowers,  col = 'darkgray', border = 'white')
  })
})