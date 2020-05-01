//
//  Race_Result_View.swift
//  Formula 1 Statistics - 2019
//
//  Created by Henry Chen on 4/25/20.
//  Copyright © 2020 Henry Chen. All rights reserved.
//

import Foundation
import SwiftUI

struct Race_Result_View : View{
    let input_track:String
    let input_track_info: track_info_struct
    let input_podium:Array<podium_struct>
    let input_result:Array<race_result_struct>
    


    
    var body: some View{
        VStack{
            
            Text(input_track).font(.custom("formula1", size: 40)).padding()
            
            VStack(){
                Text(input_track_info.circuit).font(.custom("formula1", size: 20)).padding()
            }
            HStack(){
                Text(input_track_info.date).font(.custom("formula1", size: 20)).padding()
                Text("Round: \(input_track_info.round)").font(.custom("formula1", size: 20)).padding()
            }
            
            
            VStack() {
                Text("Podium").font(.custom("formula1", size: 20)).padding()
                ForEach(input_podium, id: \.position){ index in
                    Text("\(index.position) - \(index.name) (\(index.team)) ---- Time: \(index.time)  | Points: \(index.points)").font(.custom("formula1", size: 12)).padding()
                }

            }.padding()
            
            VStack() {
                Text("Race Result").font(.custom("formula1", size: 20)).padding()
                ForEach(input_result, id: \.position){ index in
                    Text("P\(index.position) - \(index.name) (\(index.team)) ---- Points: \(index.points)").font(.custom("formula1", size: 12)).padding()
                }

            }.padding()
            
            
        
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    
    }
}
