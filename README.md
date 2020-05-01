# CS-432-Formula-1-Statistics-2019
Formula One Statistics from 2019 on MongoDB using Swift


I.    PROBLEM
    Information is a power in the world of Formula 1 racing. Victories are often decided by one hundredth of a second, one good pit stop, and one more degree of tilt on the front wing. Minor details could mean the difference of a podium or major accident on the track. Each of the ten teams in Formula 1 spend millions developing every one of their cars and statistics is what influence the initial design and future development and upgrades. 2020 race season is about to start and with test beginning in late February, this application aims to be an easy to use collection of statistics that can give teams a direction for their development for the upcoming season. For a fan watching the sport, this database can be easily converted into a mobile app so fans can compare their favorite team’s performance to their previous year’s record. 
II.    SOFTWARE DESIGN AND IMPLEMENTATION
The data will be collected from various site, such as the official Formula 1 website as well as alternative fan sites if necessary. The data will feature data of every race such as the track information (name, dates, and round #) , podium winners for each track, overall race result for each track, and overall season performance for each of the twenty drivers and 10 teams. 
A.    Software Design and NoSQL-Database and Tools Used
The idea is to start out by collecting and importing data from offical formula 1 website and implement then under a document-based struture using MongoDB. I represented each of the twenty one tracks, twenty drivers and ten teams with their own respective collection in the Mongo database. Each collection have their respective documents for a specific query.
With a database setup, the next step was to create a GUI application. I used XCode as an IDE and used Swift UI as the language of choice to create the Mac OS application. The application has a sidebar with three  different categories: Track, Driver and Team. Underneath each of the headers, there list the respective options. These clickable options serve as indexes for the queries and returns the result in the main portion of the application.

B.    Supported Queries/Functionalities that You Implemented
result(track) - outputs general race result on track
podium(track) - outputs race leader statistics for that race
driver(driver) – outputs driver’s overall statistics for the 2019 season
driver_stat_r(driver,track) – outputs driver’s result for the specific race
team_stat_o(team) – output team’s overall performance for the 2019 season
