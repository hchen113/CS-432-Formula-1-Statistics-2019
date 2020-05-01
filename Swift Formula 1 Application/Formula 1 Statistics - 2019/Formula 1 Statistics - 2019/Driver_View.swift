//
//  Driver_View.swift
//  Formula 1 Statistics - 2019
//
//  Created by Henry Chen on 4/26/20.
//  Copyright © 2020 Henry Chen. All rights reserved.
//

import Foundation
import SwiftUI

struct Driver_View : View{
    let input_driver:String
    let input_result:Array<driver_overall_stat_struct>
    
    var body: some View{
        VStack(){
            
            Text(input_driver).font(.custom("formula1", size: 40)).padding()
            Text(input_result[0].team).font(.custom("formula1", size: 30)).padding().padding()
            
            VStack() {
                ForEach(input_result, id: \.track){ index in
                    Text("Track: \(index.track) -    Position: \(index.position) ---- Points: \(index.points)").font(.custom("formula1", size: 12)).padding()
                }

            }.padding()
            
            
        
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    
    }
}

