//
//  jelovnik.swift
//  projectKitura
//
//  Created by Vuk Knezevic on 8/20/18.
//

import Foundation

enum Porudzbina: String {
    case predjelo
    case glavnoJelo
    case dezert
}

class Jelo {
    var naziv: String
    var cena: Double
    var porudzbina: Porudzbina
    
    init(naziv: String, cena: Double, porudzbina: Porudzbina) {
        self.naziv = naziv
        self.cena = cena
        self.porudzbina = porudzbina
    }
    
    func toDictionary() -> [String: Any] {
        return ["naziv": self.naziv, "cena": self.cena, "porudzbina": self.porudzbina.rawValue]
    }
    
    static func all() -> [Jelo] {
        return [Jelo(naziv: "Omlet", cena: 300, porudzbina: .predjelo),
                Jelo(naziv: "Przenice", cena: 250, porudzbina: .predjelo),
                Jelo(naziv: "Punjene paprike", cena: 450, porudzbina: .glavnoJelo),
                Jelo(naziv: "Gulas", cena: 500, porudzbina: .glavnoJelo),
                Jelo(naziv: "Palacinke", cena: 300, porudzbina: .dezert),
                Jelo(naziv: "Krofne", cena: 250, porudzbina: .dezert),
                Jelo(naziv: "Sladoled", cena: 200, porudzbina: .dezert)]
    }
    
    static func pretraga(porudzbina: Porudzbina, cena: Double = 0) -> [Jelo]? {
        return all().filter({ $0.porudzbina.rawValue.lowercased() == porudzbina.rawValue.lowercased() && $0.cena >= cena })
    }
    
}
