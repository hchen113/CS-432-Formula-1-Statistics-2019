//
//  ContentView.swift
//  Formula 1 Statistics - 2019
//
//  Created by Henry Chen on 4/01/20.
//  Copyright © 2020 Henry Chen. All rights reserved.
//
import SwiftUI
import MongoSwiftSync


struct ContentView: View {

    var tracks = ["Australia", "Bahrain", "China", "Azerbaijan", "Spain", "Monaco", "Canada", "France", "Austria", "Great Britain", "Germany", "Hungary", "Belgium", "Italy", "Singapore", "Russia", "Japan", "Mexico", "United States", "Brazil", "Abu Dhabi"]
    
    var drivers = ["Lewis Hamilton", "Valtteri Bottas", "Max Verstappen", "Charles Leclerc", "Sebastian Vettel", "Carlos Sainz", "Pierre Gasly", "Alexander Albon", "Daniel Ricciardo", "Sergio Perez", "Lando Norris", "Kimi Räikkönen", "Daniil Kvyat", "Nico Hulkenberg", "Lance Stroll","Kevin Magnussen", "Antonio Giovinazzi", "Romain Grosjean", "Robert Kubica", "George Russell"]
    
    var teams = ["Mercedes",  "Ferrari", "Red Bull Racing Honda", "McLaren Renault", "Renault", "Scuderia Toro Rosso Honda" , "Racing Point BWT Mercedes","Alfa Romeo Racing Ferrari", "Haas Ferrari", "Williams Mercedes"]
    
    var body: some View{
        NavigationView{
            List{
                Section(header: Text("Tracks").font(.custom("formula1", size: 20))){
                  
                    ForEach(tracks, id: \.self) { index in
                        NavigationLink(destination: Race_Result_View(input_track: index, input_track_info: track_info(track: index), input_podium: podium(track: index), input_result: race_result(track: index))) {
                            Text("\(index)").font(.custom("formula1", size: 12))
                        }
                    }
                 
                }
                .padding()
                Section(header: Text("Drivers").font(.custom("formula1", size: 20))){
                    ForEach(drivers, id: \.self) { index in
                        NavigationLink(destination: Driver_View(input_driver: index, input_result: driver_overall_stat(driver: index))) {
                            Text("\(index)").font(.custom("formula1", size: 12))
                        }
                    }
                 
                }
                .padding()
                Section(header: Text("Teams").font(.custom("formula1", size: 20))){
                    ForEach(teams, id: \.self) { index in
                        NavigationLink(destination: Team_View(input_team: index, input_result: team_overall_stats(team: index))) {
                            Text("\(index)").font(.custom("formula1", size: 12))
                        }
                    }
                 
                }
                .padding()

                
            }
            .listStyle(SidebarListStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        
        
    }
    
        
        

}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
