//
//  Dishes.swift
//  ConfigurePostgreSQL
//
//  Created by Mohammad Azam on 8/22/17.
//
//

import Foundation
import SwiftKuery
import SwiftKueryPostgreSQL

class Dishes : Table {
    
    let tableName = "dishes"
    let key = Column("id")
    let title = Column("title")
    let price = Column("price")
    let description = Column("description")
    let course = Column("course")
    let imageURL = Column("imageurl")
}

