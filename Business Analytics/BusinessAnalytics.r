#Cam, run lines 106 - 112 and see what it does


library(sqldf)
library(lubridate)
library(stringi)

getwd()
#setwd("ProjectRepos/NBAH18/Business\ Analytics")
setwd("/home/cameron/NBAH18/Business\ Analytics")


#Before pushing, comment out my working directory and uncomment yours

#setwd("ProjectRepos/NBAH18/Business\ Analytics")

########################################################## IMPORTING DATA ####################################################################################################

gameData <- read.csv("game_data.csv", header = T)
playerData <- read.csv("player_data.csv", header = T)
training<-read.csv("training_set.csv", header = T)
numberAllStarsPerTeam2016_2017 <- read.csv("number_all_stars_per_team_2016-2017.csv", header = T)
numberAllStarsPerTeam2015_2016 <- read.csv("number_all_stars_per_team_2015-2016.csv", header = T)
testing<-read.csv("test_set.csv", header = T)

#use rankings2015 from 2015-2016 season for month of October 10/2016 only
rankings2015_2016 <- read.csv("rankings2015_2016.csv", header = T)

hasTopFivePlayer <- read.csv("teams_with_top_players.csv", header = T)

rankings2015_2016 <- read.csv("rankings2015_2016.csv", header = T)

totalViewersPerGame <- sqldf('select Game_ID, Home_Team, Away_Team, Game_Date, sum("Rounded.Viewers") as Tot_Viewers from training group by Game_ID')
#--------------------------------------------------------------------------------------------------------------------------------------------------------------

######################################## Looking at the distributing of totalViewersPerGame-We see that is is heavily skewed right#############################################
qqnorm(totalViewersPerGame$Tot_Viewers, main = "Normal Q-Q Plot for the total viewers")
qqline(totalViewersPerGame$Tot_Viewers)
summary(totalViewersPerGame$Tot_Viewers)
meanNumberTotalViewers <- mean(totalViewersPerGame$Tot_Viewers)
sdTotalViewers <- sd(totalViewersPerGame$Tot_Viewers)
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


######################################## Z TEST FOR CLE'S MEAN VIEWERSHIP #####################################################################################################
#Performing a z-test to see if CLE's average is higher than the overall. First getting only Cleveland games
clevelandGames <- sqldf('select Game_ID, Home_Team, Away_Team, Game_Date, Tot_Viewers from totalViewersPerGame where Home_Team = "CLE" OR Away_Team = "CLE"')

#We notice that the clevelandGames$Tot_Viewers still has a right skew, but since n is so large (129), CLT applies
qqnorm(clevelandGames$Tot_Viewers, main = "Normal Q-Q Plot for Cleveland's Viewership")
qqline(clevelandGames$Tot_Viewers)

#Gathering statistics
sum(clevelandGames$Tot_Viewers)
clevelandMeanViews <- mean(clevelandGames$Tot_Viewers)
clevelandN <- length(clevelandGames$Tot_Viewers)
clevelandSd <- sd(clevelandGames$Tot_Viewers)

zStarCleveland <- qnorm(.95, 0 ,1) #Obtaining critical value to compare to
zStatCleveland <- (clevelandMeanViews - meanNumberTotalViewers)/(clevelandSd/sqrt(clevelandN)) 
#Z statistic is so large (15)..this is compelling evidence that people watch Lebron

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

####################################################################### QUERIES ############################################################################################
#Seeing what dates/games were most popular. We noticed that Christmas/opening day had a large effect, as well as the caliber of the teams playing
sqldf('select* from totalViewersPerGame order by Tot_Viewers desc')

#analyzing specific dates for total viewers
sqldf('select* from totalViewersPerGame order by Tot_Viewers desc')

#specific game query
sqldf('select Home_Team, Away_Team from training where Game_ID = 21700015 and Game_Date = "10/19/2017"')

#Experimenting getting number of all stars for a team from numberAllStarsPerTeam2015_2016
sqldf('select Number_of_All_Stars from numberAllStarsPerTeam2015_2016 where Team = "CLE"')$Number_of_All_Stars
numberAllStarsPerTeam2015_2016[numberAllStarsPerTeam2015_2016$Team == "CLE",]$Number_of_All_Stars

#-------------------------------------------------------------------------------------------------------------------------------------------------------

############################################################ HELPER FUNCTIONS ##########################################################################

getYearFromDate <- function(date)
{
  return(substr(date, 9, stri_length(date)))
}

lookUpAllStarCountFor <- function(team, month, year)
{
  if(year == "16" || (year == "17" && month < 10))
  {
    return(numberAllStarsPerTeam2015_2016[numberAllStarsPerTeam2015_2016$Team == team,]$Number_of_All_Stars)
    
  } else
  {
    return(numberAllStarsPerTeam2016_2017[numberAllStarsPerTeam2016_2017$Team == team,]$Number_of_All_Stars)
  }
}

#-------------------------------------------------------------------------------------------------------------------------------------------------------


#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#################################################################### FUNCTIONS AND APPENDED COLLUMNS #########################################################################

#MONTHS AND TYPES OF GAMES

#-----------------------------------------------------------------------------------------------------------------------------#
#Convert all dates to months of the year
totalViewersPerGame$Month <- month(as.POSIXlt(totalViewersPerGame$Game_Date, format = "%m/%d/%Y"))

#Adding a collumn for GameType
# First determine if it's Christmas or opening day.  Set to C for Christmas, O for opening day, and R for any other game.
totalViewersPerGame$gameType <- NULL
for(i in 1:length(totalViewersPerGame$Game_Date))
{
  if(totalViewersPerGame$Game_Date[i] == "12/25/2016" || totalViewersPerGame$Game_Date[i] == "12/25/2017")
  {
    totalViewersPerGame$gameType[i] = "C"
  }
  
  else if(totalViewersPerGame$Game_Date[i] == "10/25/2016" || totalViewersPerGame$Game_Date[i] == "10/17/2017")
  {
    totalViewersPerGame$gameType[i] = "O"
  }
  else
  {
    totalViewersPerGame$gameType[i] = "R"
  }
}

totalViewersPerGame$gameType <- as.factor(totalViewersPerGame$gameType);

#------------------------------------------------------------------------------------------------------------------------------#


#A Function that will calculate how many All-Stars are playing at the game.
getAllStarCount <- function()
{
  All_Star_Count <- NULL
  for(i in 1:length(totalViewersPerGame$Game_Date))
  {
     year <- getYearFromDate(totalViewersPerGame$Game_Date[i])
     homeAllStarCount <- lookUpAllStarCountFor(totalViewersPerGame$Home_Team[i], totalViewersPerGame$Month[i], year)
     awayAllStarCount <- lookUpAllStarCountFor(totalViewersPerGame$Away_Team[i], totalViewersPerGame$Month[i], year)
     All_Star_Count[i] = (homeAllStarCount + awayAllStarCount)
  }
  return(All_Star_Count)
}

totalViewersPerGame["All_Star_Count"] <- getAllStarCount()


hasLebron <- function()
{
  Has_Lebron <- NULL
  for(i in i:length(totalViewersPerGame$Game_ID))
  {
    if(totalViewersPerGame$Home_Team[i] == "CLE" || totalViewersPerGame$Away_Team[i] == "CLE")
    {
      Has_Lebron[i] = "YES"
    } else {
      Has_Lebron[i] = "NO"
    }
  }
  return (Has_Lebron)
}

totalViewersPerGame["Has_Lebron"] <- hasLebron()


#ranks



#--------------------------------------------------------------------------------------------------------------------------------#
library(data.table)

#Ranking teams partitioned by game date
teamRankings <- data.table(gameData, key = "Game_Date")
teamRankings <- teamRankings[,transform(.SD, teamRanking = rank(-Wins_Entering_Gm, ties.method = "min")), by = Game_Date]
teamRankings <- teamRankings[,c("Game_Date", "Team", "Wins_Entering_Gm", "teamRanking")]
teamRankings

#gameData[91:length(gameData$Game_Date),c(3,4,6)]


#use rankings2015 from 2015-2016 season for month of October 10/2016 only


totalViewersPerGame$bestRankAmongTeams <- NULL;

j <- 1;
while(j < length(totalViewersPerGame$Tot_Viewers))
{
  #if it's the month of October, use the highest ranking team from the previous season
  if(totalViewersPerGame$Month[j] == 10)
  {
    for(i in 1:length(rankings2015_2016$Rk))
    {
      
      if((totalViewersPerGame$Home_Team[j] == rankings2015_2016[i,3] || totalViewersPerGame$Away_Team[j] == rankings2015_2016[i,3]))
      {
        totalViewersPerGame$bestRankAmongTeams[j] <- i;
        break;
      }
      
    }
  }

  else
  {
    
    homeTeam <- totalViewersPerGame$Home_Team[j]
    awayTeam <- totalViewersPerGame$Away_Team[j]
    
    rankHome <- gameData[(which("Game_Date" == totalViewersPerGame$Game_Date[j])) && (which("Team" == homeTeam)),"teamRanking"]
    rankAway <- gameData[(which("Game_Date" == totalViewersPerGame$Game_Date[j])) && (which("Team" == awayTeam)),"teamRanking"]
    
   # print(rankHome)
    
    
    
    if(rankHome > rankAway)
    {
      totalViewersPerGame$bestRankAmongTeams[j] <- rankAway
    }
    
    else
    {
      totalViewersPerGame$bestRankAmongTeams[j] <- rankHome
    }
  }
  j <- j+1
}

totalViewersPerGame$gameType <- as.factor(totalViewersPerGame$gameType)



