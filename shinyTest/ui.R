library(shiny)

#groupsCustom=NULL
#c = unique(getPossibleUsernames()$label)
#c = factor(c(as.character(c),groupsCustom))
# Define UI for application 
shinyUI(fluidPage(
  
  # Application title
  titlePanel("Twitter Cohort Analysis"),  
  
  # Sidebar with a slider input for the number of bins

  sidebarLayout(
    
    sidebarPanel(
      conditionalPanel(condition="$('li.active').text().trim()=='Vocabulary'",
                  #helpText("Content Panel")     
                       checkboxGroupInput("vocab", label = h3("Select Vocabularies"), 
                                          choices = unique(getVocabularies()$label),
                                         selected = c("Schizophrenia","Schizophrenia Drugs", "Smileys", "Profanities")),
                       textInput("vocabCustom","Custom (min length 5):","") 
                       
      ),
      
     # helpText("Select cohorts from predefined sets and/or enter your own"),
      #selectInput("groups","Predefined:", unique(getPossibleUsernames()$label), 
       #           selected= unique(getPossibleUsernames()$label), multiple=TRUE),
 
      checkboxGroupInput("groups", label = h3("Select Cohorts"), 
                         choices = unique(getPossibleUsernames()$label),
                         selected = c("Control", "Control- age matched", "Schizophrenia- larger")),
      textInput("groupsCustom","Custom (min length 5):",""),
    #  helpText("Select vocabulary from predefined sets and/or enter your own"),
      #selectInput("vocab","Predefined:", unique(getVocabularies()$label), 
       #           selected=unique(getVocabularies()$label), multiple=TRUE),
      
      submitButton()
    ),
    
    # Show a plot of the generated distribution
    mainPanel( 
      
      tabsetPanel( id="tab1",type="tabs",
                   tabPanel("Summary",value="sum", fluidPage(fluidRow(
                     column(6,  plotOutput("distPlot")),
                     column(6,  plotOutput("followingPlot"))),
                     fluidRow(
                     column(6,  plotOutput("tweetPlot")),
                     column(6,  plotOutput("tweetLengthPlot"))
                  ))),
                  tabPanel("Word Cloud",value="cloud", fluidPage(fluidRow(
                    column(12, plotOutput("wordPlot", height="700px"))
                  ))),
                  tabPanel("Time", fluidPage(fluidRow(
                    column(8, plotOutput("burstPlot"))),
                    fluidRow(
                    column(12, plotOutput("timePlot"))))),
                  tabPanel("Vocabulary",value="voc", fluidPage(

           #           wellPanel( 
            #          checkboxGroupInput("vocab", label = h3("Select Vocabularies"), 
             #         choices = unique(getVocabularies()$label),
              #        selected = unique(getVocabularies()$label)),
               #       textInput("vocabCustom","Custom (min length 5):","") ,
                #      submitButton()
                 #   ),

                    column(12, plotOutput("vocabPlot", height="1000px")))),
         
                  tabPanel("Model",value="ML", fluidPage(
                    actionButton("fakeAction", "Update models"),
                    fluidRow(
                   # column(10, plotOutput("modelPlot"))
                     plotOutput("staticModelPlot", height="600px")
                           )),
                   p("Under development. Image is static."))
      
     ))
  )
))
#c = factor(c(as.character(c),groupsCustom))
