# load libraries
library(shiny)
library(markdown)
library(bslib)
library(tidyverse)
library(tidytext)
library(markovchain)
library(dplyr)

# load necessary data saved as rds files.
markov_uni <- read_rds("MC_data.rds")
bad_words <- read_rds("bad_words.rds")

# clean input data function
clean <- function(input) {input <- tibble(line = 1:(length(input)), text = input) %>%
  unnest_tokens(word, text) %>% filter(!str_detect(word, "\\d+")) %>%
  mutate_at("word", str_replace, "[[:punct:]]", "") %>% # remove punctuation
  anti_join(bad_words, by = "word") %>% # remove bad words words
  pull(word)
input
}

# Actual MC function -> where the magic happens ;-)
next_word <- function(word, num = 3) {
  word <- clean(word)
  length <- length(word)
  if (length == 0){return("Please enter a word")}
  if (length > 1) {word <- word[length]}
  # MC Sequence
  pred <- try(markovchainSequence(
    n = 1, markovchain = markov_uni$estimate,
    t0 = word, include.t0 = F), silent=T)
  if (nchar(pred[1]) > 100) {return("Sorry, no predictions are available!")}
  
  sents <- c()
  for (i in 1:num) {
    set.seed(i)
    {sent <- markovchainSequence(
      n = 1, markovchain = markov_uni$estimate,
      t0 = word,include.t0 = F
    ) %>%
        paste(collapse = " ")
      sents <- c(sents, sent)
    }
  }
  unique(sents)
}

# User Interface
ui <- fluidPage(navbarPage(
  title="Coursera Project: Next Word Predictor",
  fluidPage(sidebarLayout(
    sidebarPanel(
      textInput(
        inputId = "str",
        label = h3("Enter text:"),
        value = "You are"),
      numericInput(
        inputId = "n",
        label = h3("# predictions"),
        min = 1,
        max = 15,
        value = 10,
        step = 1)),
    
    mainPanel(
      h2("The predictions are:"),
      h3(textOutput("pred", container = pre))
    )
  )
  )
))

# server code for shiny
server <- function(input, output, session) {
  output$pred <- renderText({
    preds <- next_word(input$str, input$n)
    paste(preds, collapse="\n")
  })
}

# run app
shinyApp(ui, server)