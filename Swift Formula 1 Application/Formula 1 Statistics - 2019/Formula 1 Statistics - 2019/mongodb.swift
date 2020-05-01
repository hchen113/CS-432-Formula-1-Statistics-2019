//
//  mongodb.swift
//  Formula 1 Statistics - 2019
//
//  Created by Henry Chen on 4/23/20.
//  Copyright © 2020 Henry Chen. All rights reserved.
//

import Foundation
import MongoSwiftSync


let client = try! MongoClient("mongodb://localhost:27017")
let db = client.db("f1_2019")

/* -------------------------------------------------------------------TRACK---------------------------------------------------------------------*/
struct race_result_struct{
    var name:String
    var position:Int
    var team: String
    var points: Int
    
    init(name: String, position: Int, team: String, points: Int) {
        self.name = name
        self.position = position
        self.team = team
        self.points = points
    }
}


func race_result(track: String) -> Array<race_result_struct>{
    var retArr = [race_result_struct] ()
    let collection = db.collection(track)
    let query: Document = ["doc_type":"race_result"]
    let document = try! collection.findOne(query)
    let entry_it = document?.makeIterator()
    
    var count = -1
    while let entry = entry_it?.next(){
        if (count > 0){
            let tempstr = "p" + String(count)
            let key = entry.key
            if (key == tempstr){
                let buffer = entry.value.stringValue
                var char_count = 1
                var name:String = ""
                var team:String = ""
                var points:String = ""
                for char in buffer!{
                    if (char == "_"){
                        char_count += 1
                        continue
                    }
                    if (char_count == 1){
                        name.append(char)
                    }
                    if (char_count == 2){
                        team.append(char)
                    }
                    if (char_count == 3){
                        points.append(char)
                    }
                }
                //print("Position: " + count + ", Name: " + name + " , Team: " + team + " , Point(s)" + points)
                let temp = race_result_struct(name: name, position: count, team: team, points: Int(points)!)
                retArr.append(temp)
                
            }
        }
        count += 1
    }
    
    
    return retArr
}

/*
struct race_winner_struct {
    var name:String
    var points:Int
    var team:String
    var fastest_lap:String
    
    init(name:String, team:String, points:Int, fastest_lap:String) {
        self.name = name
        self.team = team
        self.points = points
        self.fastest_lap = fastest_lap
    }
}

func race_winner(track: String) -> race_winner_struct {
    let collection = db.collection(track)
    let query: Document = ["doc_type":"race_winner"]
    let document = try! collection.findOne(query)
    let entry_it = document?.makeIterator()
    
    let keyArr = ["name", "team", "point", "fastest_lap"]
    var name:String = ""
    var team:String = ""
    var points:String = ""
    var fastest_lap:String = ""
    
    var count = -2
    while let entry = entry_it?.next(){
        
        name = ""
        team = ""
        points = ""
        fastest_lap = ""
        
        let tempstr = keyArr[count]
        let key = entry.key
        if (key == tempstr){
            let buffer = entry.value.stringValue
            var key_buffer = ""
            
            for char in buffer!{
                if (key_buffer == "name"){
                    name.append(char)
                    continue
                }
                if (key_buffer == "team"){
                    team.append(char)
                    continue
                }
                if (key_buffer == "name"){
                    points.append(char)
                    continue
                }
                if (key_buffer == "fastest_lap"){
                    fastest_lap.append(char)
                    continue
                }
                key_buffer.append(char)
            }
        }
        count += 1
    }
    
    let retStruct = race_winner_struct(name: name, team: team,points: Int(points)!, fastest_lap: fastest_lap)
    
    return retStruct
}
*/

struct track_info_struct {
    var circuit:String
    var date:String
    var round:Int
    
    init(circuit:String, date:String, round:Int) {
        self.circuit = circuit
        self.date = date
        self.round = round
    }
}

func track_info(track: String) -> track_info_struct {
    let collection = db.collection(track)
    let query: Document = ["doc_type":"track_info"]
    let document = try! collection.findOne(query)
    let entry_it = document?.makeIterator()

    var circuit:String = ""
    var date:String = ""
    var round:String = ""

    while let entry = entry_it?.next(){
        if (entry.key == "_id"){
            continue;
        }
        if (entry.key == "doc_type"){
            continue;
        }
        if (entry.key == "circuit"){
            circuit.append(entry.value.stringValue!)
            continue
        }
        if (entry.key == "date"){
            date.append(entry.value.stringValue!)
            continue
        }
        if (entry.key == "round"){
            round.append(entry.value.stringValue!)
        }
    }
    let temp = track_info_struct(circuit: circuit, date: date, round: Int(round)!)
    
    return temp
}

struct podium_struct {
    var position:String
    var name:String
    var team:String
    var time:String
    var points:Int
    
    init(position:String, name:String, team:String, time:String, points:Int) {
        self.position = position
        self.name = name
        self.team = team
        self.time = time
        self.points = points
    }
}

func podium(track: String) -> Array<podium_struct> {
    var retVal = [podium_struct]()
    let collection = db.collection(track)
    let query: Document = ["doc_type":"podium"]
    let document = try! collection.findOne(query)
    let entry_it = document?.makeIterator()

    while let entry = entry_it?.next(){
        if (entry.key == "_id"){
            continue
        }
        if (entry.key == "doc_type"){
            continue
        }
        let buffer = entry.value.stringValue!
        var name = ""
        var team = ""
        var time = ""
        var points = ""
        var count = 1
        for char in buffer{
            if (char == "_"){
                count += 1
                continue
            }
            if (count == 1){
                name.append(char)
            }
            if (count == 2){
                team.append(char)
            }
            if (count == 3){
                time.append(char)
            }
            if (count == 4){
                points.append(char)
            }
        }
        let temp = podium_struct(position: entry.key, name: name, team: team, time: time, points: Int(points)!)
        retVal.append(temp)
    }
    return retVal
}


/* -------------------------------------------------------------------DRIVER---------------------------------------------------------------------*/
struct driver_overall_stat_struct {
    var track:String
    var team:String
    var position:Int
    var points:Int
    
    init(track:String, team:String, position:Int, points:Int) {
        self.track = track
        self.team = team
        self.position = position
        self.points = points
    }
}

func driver_overall_stat(driver: String) -> Array<driver_overall_stat_struct> {
    var retVal = [driver_overall_stat_struct]()
    let collection = db.collection(driver)
    let query: Document = ["doc_type":"overall_stats"]
    let document = try! collection.findOne(query)
    let entry_it = document?.makeIterator()
    
    var team:String = ""
    while let entry = entry_it?.next(){
        
        var temp_track:String = ""
        var temp_position:String = ""
        var temp_points:String = ""
        
        if (entry.key == "_id"){
            continue
        }
        if (entry.key == "doc_type"){
            continue
        }
        if (entry.key == "team"){
            team = entry.value.stringValue!
            continue
        }
        temp_track = entry.key
        let buffer = entry.value.stringValue
        
        var count = 0
        for char in buffer!{
            if (char == "_"){
                count += 1
                continue
            }
            if (count == 0){
                temp_position.append(char)
            }
            if (count == 1){
                temp_points.append(char)
            }
        }
        let temp_struct = driver_overall_stat_struct(track: temp_track, team: team, position: Int(temp_position)!, points: Int(temp_points)!)
        retVal.append(temp_struct)
    }
    return retVal
}


/* -------------------------------------------------------------------TEAM---------------------------------------------------------------------*/
struct team_overall_stat_struct {
    var track:String
    var points:Int
    
    init(track:String, points:Int) {
        self.track = track
        self.points = points
    }
}

func team_overall_stats(team:String) -> Array<team_overall_stat_struct> {
    var retVal = [team_overall_stat_struct]()
    let collection = db.collection(team)
    let query: Document = ["doc_type":"team_overall_stats"]
    let document = try! collection.findOne(query)
    let entry_it = document?.makeIterator()
    
    while let entry = entry_it?.next(){
        
        var temp_track:String = ""
        var temp_points:String = ""
        
        if (entry.key == "_id"){
            continue
        }
        if (entry.key == "doc_type"){
            continue
        }
        temp_track = entry.key
        temp_points = entry.value.stringValue!
        
        let temp_struct = team_overall_stat_struct(track: temp_track, points: Int(temp_points)!)
        retVal.append(temp_struct)
    }
    return retVal
}
