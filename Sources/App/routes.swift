import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    
    // MARK: - CRUD
    
    router.get("api", "acronyms", Acronym.parameter) { req -> Future<Acronym> in
        return  try req.parameters.next(Acronym.self)
    }
    
    router.put("api", "acronyms", Acronym.parameter) { req -> Future<Acronym> in
        return try flatMap(
            to: Acronym.self,
            req.parameters.next(Acronym.self),
            req.content.decode(Acronym.self)) { acronym, updatedAcronym in
                
                acronym.short = updatedAcronym.short
                acronym.long = updatedAcronym.long
                
                return acronym.save(on: req)
        }
    }
    
    router.delete("api", "acronyms", Acronym.parameter) { req -> Future<HTTPStatus> in
        return try req.parameters.next(Acronym.self)
        .delete(on: req)
        .transform(to: .noContent)
    }
    
    
    // MARK: - Queries
    
    router.get("api", "acronyms", "search") { req -> Future<[Acronym]> in
        
        guard let searchString = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        
        return Acronym.query(on: req).group(.or) { or in
            or.filter(\.short == searchString)
            or.filter(\.long == searchString)
            }.all()
    }
    
    router.get("api", "acronyms", "first") { req -> Future<Acronym> in
        
        return Acronym.query(on: req)
        .first()
        .unwrap(or: Abort(.notFound))
    }
    
    router.get("api", "acronyms", "sorted") { req -> Future<[Acronym]> in
        return Acronym.query(on: req)
            .sort(\.short, .ascending)
            .all()
    }
    
    // register controllers
    
    let acronymsController = AcronymsController()
    try router.register(collection: acronymsController)
}
