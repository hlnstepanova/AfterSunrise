library(XML)
library(httr)
library(chron)


# upload the cities and countries databases
cities_base <- read.csv("sunrise/cities_base.txt",
                      sep = "\t",quote = "",
                      header = TRUE,
                      stringsAsFactors = FALSE)
countries_base <- read.csv("sunrise/countries_base.txt",
                         sep = "\t", quote = "", header = TRUE,
                         stringsAsFactors = FALSE)

# make all lowercase and replace spaces with hyphens
cities_base[,2] <- tolower(cities_base[,2])
cities_base[,2] <- gsub(" ", "-", cities_base[,2])
countries_base[,4] <- tolower(countries_base[,4])
countries_base[,4] <- gsub(" ", "-", countries_base[,4])



{
# create an empty vector for the future list of chosen cities
cities_list <- character()

# ask the user, when he prefers to wake up 
getup <- as.POSIXct(
                    readline(prompt="When do you prefer to get up?
                    Time format HH:MM:SS 
                    (e.g., 07:00:00): "), 
         format="%H:%M:%S")


# create an empty vector for user's answers
answer <- "42"


# ask the user, what cities (max. 6) he wants to analyze
   while (length(cities_list) < 6){
     
       if (answer == "n"){break} # if he once answered, that he doesn't want another city, 
                                 # the interrogation stops
     
       # adding new cities to an exisiting vector of chosen cities
       len <- length(cities_list)
       cities_list[len+1] <- readline(prompt="Enter a city: ")
  
       # continue adding new cities until there're 6 or
       # until the user doesn't want any more cities
       while(length(cities_list) < 6){
           answer <- readline(prompt = "Another city? 
                             (If no, press n): ")

           if (answer != "n"){
               len <- length(cities_list)
               cities_list[len+1] <- answer
           } 
           else if (answer == "n"){
               break
           } 
           else {
               next
           }
        }
    }


    # trimming primary user input
    cities_list <- tolower(cities_list)
    cities_list <- gsub(" ", "-", cities_list)


    # count how many matches for all cities
    total_length <- 0
    len <- length(cities_list)
   
     for (i in 1:len){
      cities_number <- length(which(cities_list[i] == cities_base[,2]))
      total_length <- total_length + cities_number
     }
    
    # create empty vector for future countries_list
    country <- character()
    
    # if there're several cities with the same name in different countries, the user gets to pick one
    
    if (total_length > len){
        for (r in 1:len){
            # spot homonymous cities
            homonymous_cities <- which(cities_list[r] == cities_base[,2]) 
            
            if (length(homonymous_cities) > 1) {
                # find all possible countries and make the user choose one
                possible_country_codes <- cities_base[homonymous_cities, 1] 
                country_match <- match(possible_country_codes, 
                                       countries_base[,1])
                possible_countries <- countries_base[country_match, 4]
                names(possible_countries) <- seq_along(possible_countries)
                print(paste("There are several ",
                            cities_list[r],"s in the world in:", sep = ""))
                print(possible_countries)
                chosen_one <- readline(prompt="Which do you chose? 
                                     Enter the corresponding number: ")
            
            }else if (length(homonymous_cities) == 0) {
              print(paste("There is no ", 
                          cities_list[r],
                          " on planet Earth"))
              
            # if there's only one country for each city, do vlookup
            }else {
              city_match <- match(cities_list[r], 
                                  cities_base[,2])
              country_index <- cities_base[city_match, 1]
              country_match <- match(country_index,
                                     countries_base[,1])
              possible_countries <- countries_base[country_match, 4]
              chosen_one <- 1
            }   
        chosen_one <- as.integer(chosen_one)
        country[r] <- possible_countries[chosen_one]
        }
    }



# scraping data from the timeanddate website
monthly <- data.frame()

# create path for each country+city combination
for (r in 1:length(country)){
    url_part1 <- paste("https://www.timeanddate.com/sun/",
                       country[r],"/",cities_list[r],sep="")
    
    # add months to the path 
    for (i in 1:12){
        url_part2 <- paste(url_part1, "?month=", i , 
                           "&year=2018", sep="")
        print(url_part2)
        sun_data <- GET(url_part2)
        stop_for_status(sun_data)
        doc <- content(sun_data)
        sun_data <- doc['//table']
        perftable <- readHTMLTable(sun_data[[1]], stringsAsFactors = F)
        if (i==1){used_colnames <- colnames(perftable)}
        str(perftable)
        if(ncol(perftable) == 11){
          perftable1 <- perftable[,1:6]
          perftable1[,7] <- rep("-",nrow(perftable1))
          perftable1[,8] <-perftable[,7]
          perftable1[,9] <- rep("-",nrow(perftable1))
          perftable1[,10:13]<-perftable[,8:11]
          perftable<-perftable1
          colnames(perftable)<-used_colnames
        }
        ### cleaning data
        if(ncol(perftable) == 12){
        rest_of_night <- which(perftable[,6] == "Rest of night")
        len_rest <- length(rest_of_night)
        if (len_rest > 0) {
            perftable[rest_of_night,13] <- rep(("Rest of night"), 
                                               len_rest)
            perftable[rest_of_night,] <- perftable[rest_of_night, 
                                                   c(1:6, 13, 7:12)] 
            colnames(perftable)=used_colnames
        }
        }

        perftable[,14] <- as.integer(rep(i, 
                                         nrow(perftable))) # add months number
        perftable[,15] <- rep(country[r], 
                              nrow(perftable)) # add country name
        perftable[,16] <- rep(cities_list[r], 
                              nrow(perftable)) # add city name
        monthly <- rbind(monthly,perftable) # grow table
    }

}

str(monthly)

# delete rows with notes
monthly <- monthly[which(monthly[,1] != 
                            "Note: hours shift because clocks change forward 1 hour. (See the note below this table for details)"),]
monthly <- monthly[which(monthly[,1] != 
                            "Note: hours shift because clocks change backward 1 hour. (See the note below this table for details)"),]

# add dates
monthly[,17] <- paste(monthly[,1], ".", monthly[,14], 
                      ".2018", sep = "")



# extracting only sunrise times
dates <- monthly[which(monthly[,16] == cities_list[1]), 17]
total_sunrise <- data.frame(dates)

for (i in 1:length(cities_list)){
  cities_match <- which(monthly[,16] == cities_list[i])
    sunrise <- monthly[cities_match, 2]
    total_sunrise <- cbind(total_sunrise, sunrise)
}

colnames(total_sunrise) <- c("dates", cities_list)

# convert to characters
total_sunrise[,] <- data.frame(lapply(total_sunrise[,], as.character), stringsAsFactors=FALSE)

# cut the string with sunrise times
total_sunrise[,-1] <- sapply(total_sunrise[,-1], substr, 1, 5) 

# convert to date type
total_sunrise[,1] <- as.Date(total_sunrise[,1], "%d.%m.%Y") 

# add seconds to time
total_sunrise[,-1] <- lapply(total_sunrise[,-1], function(x) paste(x, ":00", sep="")) 

# convert to time type
total_sunrise[,-1] <- lapply(total_sunrise[,-1], function(x) as.POSIXct(x, format = "%H:%M:%S"))


# plotting sunrise time along the year in the first city
plot(x = total_sunrise[,1], y = total_sunrise[,2], 
     xlab="Date", ylab="Time", 
     main="Sunrise times in different cities", 
     col=2, type="l")

# adding plots for other cities (if any)
if (len > 1){
    for (i in 3:(len+1)){
points(x = total_sunrise[,1], y=total_sunrise[,i], 
       xlab = "Date", ylab = "Time", 
       col = i, type = "l")
    }
}

legend("bottomleft", colnames(total_sunrise)[2:(len+1)], 
       col=2:(len+1), lty=1, cex=.65)

# set an abline equal to preferable getup time, asked in the beginning
abline(h = getup) 

#find difference for every city
sun_dif <- as.data.frame(lapply(total_sunrise[,-1], 
                                function(x) as.integer(x - getup))) 
#0 differences would mess abline-plot crossover signs
sun_dif <- as.data.frame(lapply(sun_dif, 
                                function(x) as.integer(gsub(0,1,x)))) 
#transform sunrise difference to spot sign change
sun_crossover <- as.data.frame(lapply(sun_dif, function(x) diff(sign(x)))) 

# create empty vector
sun_days <- as.integer()

# calculate number of days in every city when the sun rises before the user gets up
for (i in 1:len)
{
  upward_cross <- which(sun_crossover[,i] > 0) #plot crosses the abline upward
  downward_cross <- which(sun_crossover[,i] < 0) #plot crosses the abline downward
  dif_crosses <- total_sunrise[upward_cross,1] - total_sunrise[downward_cross,1]
  days <- sum(as.integer(dif_crosses))
 sun_days<-c(sun_days, days)
}

sun_days[sun_days == 0] <- 365 #if no crosses, the sum is 0, which is always sun
sun_days[sun_days < 0] <- 365 + sun_days[sun_days < 0] #if southern hemisphere
names(sun_days) <- cities_list #attribute city names to sunny days
print(sun_days)
#cities with the most sunny days win
best_cities <- cities_list[which(sun_days == max(sun_days))] 
names(best_cities) <- 1:length(best_cities)
print("You will get up after sunrise most of the time in:")
print(best_cities)
}
