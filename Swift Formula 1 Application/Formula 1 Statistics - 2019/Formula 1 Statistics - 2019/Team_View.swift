//
//  Team_View.swift
//  Formula 1 Statistics - 2019
//
//  Created by Henry Chen on 4/26/20.
//  Copyright © 2020 Henry Chen. All rights reserved.
//

import Foundation
import SwiftUI

struct Team_View : View{
    let input_team:String
    let input_result:Array<team_overall_stat_struct>
    
    @State var on = true
    
    
    var body: some View{
        VStack{
            
            Text(input_team).font(.custom("formula1", size: 40)).padding()
            
            VStack() {
                ForEach(input_result, id: \.track){ index in
                    Text("Track: \(index.track)  ----  Points: \(index.points)").font(.custom("formula1", size: 12)).padding()
                }

            }.padding()
            
           

        
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    
    }
}
