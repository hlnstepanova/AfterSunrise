# AfterSunrise
<i>Scraping and plotting sunrise times in R.</i>

If you don't like to get up when it's still dark, use this script to see, how many days per year you can get up after sunrise depending on what city you choose to live in.

<b>The script works as follows:</b>
1) User inputs his usual get up time
2) User is asked to consider up to 6 cities
3) The script scrapes <a href=http://timeanddate.com>timeanddate.com</a> for necessary information
4) The script plots sunrise times across year 2017, calculates how many days pro year the user would get up after sunrise in each city and returns the best city

<b>External data:</b><a href="https://drive.google.com/open?id=1v4dA0NqJqCrImaRL3QnViqN56aq46OGq"> cities_base.txt, countries_base.txt (Google Drive) </a><br/>
<b>Libraries:</b> XML, httr, chron

![Plot example](/example_plot.png)
