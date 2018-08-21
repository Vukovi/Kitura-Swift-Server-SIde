//
//  potrosac.swift
//  projectKitura
//
//  Created by Vuk Knezevic on 8/16/18.
//

import Foundation

class Potrosac {
    var prezime: String
    var ime: String
    
    init(prezime: String, ime: String) {
        self.prezime = prezime
        self.ime = ime
    }
    
    func toDictionary() -> [String: Any] {
        return ["prezime": self.prezime, "ime": self.ime]
    }
}
