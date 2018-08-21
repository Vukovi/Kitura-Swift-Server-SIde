import Kitura
import HeliumLogger
import SwiftyJSON
import SwiftKuery
import SwiftKueryPostgreSQL

// ovo nam pruza informaciju o radu naseg servera
HeliumLogger.use()

// pravim instancu Router klase, koja je odgovorna za network requestove
let router = Router()


// upisivanjem u web browser localhost:8080 dobijam "Pozdrav sa servera!" odgovor servera
// s'obzirom da ce biti get request, koristicemo sledecu metodu kojoj dajem url
router.get("/") { request, response, next in
    response.send("Pozdrav sa servera!")
    next()
}



// upisivanjem u web browser localhost:8080/potrosac dobijam {"prezime":"Knezevic","ime":"Vuk"} odgovor servera
router.get("potrosac") { (request, response, next) in
    let potrosac = Potrosac(prezime: "Knezevic", ime: "Vuk")
//    response.send(json: ["prezime":"Knezevic", "ime":"Vuk"])
    response.send(json: potrosac.toDictionary())
    next()
}


// reading url parameters
// kreiranje dinamickog nastavka url-a
router.get("/filmovi/:dinamickiZanr") { (request, response, next) in
    guard let dinamickiZanr = request.parameters["dinamickiZanr"] else {
        try response.status(.badRequest).end()
        return
    }
    
    response.send("Izabrali ste \(dinamickiZanr)")
    next()
}



// visestruki dinamicki url paramteri tj nastavci
router.get("/filmovi/:dinamickiZanr/godina/:dinamickaGodina") { (request, response, next) in
    guard let zanr = request.parameters["dinamickiZanr"],
          let godina = request.parameters["dinamickaGodina"] else {
        try response.status(.badRequest).end()
        return
    }
    
    response.send("Izabrali ste \(zanr) godine \(godina)")
    next()
}




// postovanje && reading URL encoded from parameters
// helper za kituru da bi mogla lakse da parsira request
router.post(middleware: BodyParser())
router.post("registracija") { (request, response, next) in
    guard let body = request.body, // moramo izvaditi BODY iz requesta
          let values = body.asURLEncoded,
          let ime = values["ime"],
          let prezime = values["prezime"] else {
            try response.status(.badRequest).end()
            return
    }
    
    // ako su ove vrednosti dobro postavljene, treba ih vratiti korisniku
    response.send("Ime = \(ime) Prezime = \(prezime)")
    next()
}



// postavljanje pretrage pomocu QUERY STRING parametara u URL-u
router.get("pretrazivanje") { (request, response, next) in
    guard let porudzbina = request.queryParameters["porudzbina"],
          let cena = request.queryParameters["cena"] else {
          try response.status(.badRequest).end()
          return
    }
    
    if let jela = Jelo.pretraga(porudzbina: Porudzbina(rawValue: porudzbina)!, cena: Double(cena)!) {
        response.send(json: jela.map({ $0.toDictionary() }))
    }
    
    next()
}
// http://localhost:8080/pretrazivanje?porudzbina=dezert&cena=200



// za parsiranje json request-ova kitura favorizuje swiftyjson
// za slanje json post request-a opet cu upotrebiti postman-a
router.post("jela-po-porudzbini") { (request, response, next) in
    guard let parsedBody = request.body else {
        try response.status(.badRequest).end()
        return
    }
    
    switch parsedBody {
    case .json(let jsonBody):
        let porudzbina = jsonBody["porudzbina"] as? String ?? ""
        if let odabranaPorudzbina = Porudzbina(rawValue: porudzbina), let jela = Jelo.pretraga(porudzbina: odabranaPorudzbina) {
            response.send(json: jela.map({ $0.toDictionary() }))
        }
    default:
        break
    }
    
    next()
    // u postmanu u header-u umesto trenutnog value-a [{"key":"Content-Type","value":"application/x-www-form-urlencoded"}] upisi value "application/json"
    // i u body-ju umesto x-www-form-urlencoded odaberi raw i onda tamo ubaci neki json npr {"porudzbina":"glavnoJelo"} i ovaj ce vratiti sve sto imam od glavnih jela
}


// POSTGRE SQL DATABASE
// https://www.postgresql.org  -  THE WORLD'S MOST ADVANCED OPEN SOURCE RELATIONAL DATABASE
// downloadovacu postges app jer je najjednostavniji nacin za rad sa bazom
// downloadovacu i Postico - A Modern PostgreSQL Client for the Mac  https://eggerapps.at/postico/ 
// u postges app, kad se inicijalizuje baza i otvori terminal, unosi sledece:
//      CREATE DATABASE nadiasgarden;
//      \connect nadiasgarden;
//      \i /Users/vuknez/Desktop/projectKitura/nadiasgarden.sql   ubacio sam bazu u postrges app
//      brew install postgresql pre instaliranja SwiftKueryPostgreSQL da bi se instalirale sve neophodne stvari za SwiftKueryPostgreSQL


router.all("/", middleware: BodyParser())

let connection = PostgreSQLConnection(host: "localhost", port: 5432, options: [ConnectionOptions.databaseName("nadiasgarden")])

let dishes = Dishes()  // ovo je struktura baze

//fetching records from database
func getAllDishes(callBack: @escaping ([Dish]) -> ()) { // escaping ke zato sto cemo iz ovog klozera predati informacije nekoj drugoj metodi
    let query = Select(dishes.key, dishes.title, dishes.description, dishes.course, dishes.imageURL, dishes.price, from: dishes)
    
    var dishesList = [Dish]()
    
    connection.connect { (error) in
        if error != nil {
            return
        }
        connection.execute(query: query, onCompletion: { (result) in
            if let rows = result.asRows {
                for row in rows {
                    var dictionary = [String: Any]()
                    for (title,value) in row {
                        dictionary[title] = value
                    }
                    if let dish = Dish(dictionary: dictionary) {
                        dishesList.append(dish)
                    }
                }
            }
            callBack(dishesList)
        })
    }
}

router.get("/dishes") { (request, response, next) in
    getAllDishes(callBack: { (dishes) in
        response.send(json: dishes.map{ $0.toDictionary() })  // vrati sta se trazi sa url-om /dishes
    })
}
// http://localhost:8090/dishes  pozovi i vidi sta dobijes iz posgreSQL baze




// inserting records into database
router.post("/dish") { (request, response, next) in
    guard let parsedBody = request.body else {
        next()
        return
    }
    
    switch parsedBody {
    case .json(let jsonBody):
        guard let dish = Dish(dictionary: jsonBody) else {
            return
        }
    let insertQuery = Insert(into: dishes, columns: [dishes.title, dishes.price, dishes.description, dishes.course, dishes.imageURL], values: [dish.title, dish.price, dish.description, dish.course, dish.imageURL])
        connection.connect(onCompletion: { (error) in
            connection.execute(query: insertQuery, onCompletion: { (result) in
                response.send(json: ["success" : true, "message":"Dish has been inserted"])
            })
        })
    default:
        response.status(.badRequest).send("Bad request")
    }
    
    next()
}
// localhost:8090/dish  postman - POST
// Content-Type  application/json
// Body -> raw



// deleting records from database
router.delete("/dish") { (request, response, next) in
    guard let parsedBody = request.body else {
        next()
        return
    }
    switch parsedBody {
    case .json(let jsonBody):
        let dishId = jsonBody["id"] as! Int
        let deleteQuery = Delete(from: dishes).where(dishes.key == Int(dishId))
        connection.connect(onCompletion: { (error) in
            if error != nil {
                return
            }
            connection.execute(query: deleteQuery, onCompletion: { (result) in
                response.send(json: ["success": true])
            })
        })
    default:
        response.status(.badRequest).send("Bad request")
    }
}



// filtering records in database
func getDishesByCourse(course: String, callBack: @escaping ([Dish]) -> ()) { // escaping ke zato sto cemo iz ovog klozera predati informacije nekoj drugoj metodi
    let query = Select(dishes.key, dishes.title, dishes.description, dishes.course, dishes.imageURL, dishes.price, from: dishes).where(dishes.course == course)
    
    var dishesList = [Dish]()
    
    connection.connect { (error) in
        if error != nil {
            return
        }
        connection.execute(query: query, onCompletion: { (result) in
            if let rows = result.asRows {
                for row in rows {
                    var dictionary = [String: Any]()
                    for (title,value) in row {
                        dictionary[title] = value
                    }
                    if let dish = Dish(dictionary: dictionary) {
                        dishesList.append(dish)
                    }
                }
            }
            callBack(dishesList)
        })
    }
}

router.get("/dishes-by-course") { (request, response, next) in
    let course = request.queryParameters["course"] ?? ""
    if course.isEmpty {
        getAllDishes(callBack: { (dishes) in
            response.send(json: dishes.map{ $0.toDictionary() })
        })
        next()
        return
    }
    
    getDishesByCourse(course: course, callBack: { (dishes) in
        response.send(json: dishes.map{ $0.toDictionary() })
    })
    next()
}



// sad definisem port na kom ce raditi ovaj server
//Kitura.addHTTPServer(onPort: 8080, with: router)
Kitura.addHTTPServer(onPort: 8090, with: router) // ovo je promena zbog baze jer je port 8080 defaultni port, a za bazu treba naravno drugaciji od defaulutnog
Kitura.run()


