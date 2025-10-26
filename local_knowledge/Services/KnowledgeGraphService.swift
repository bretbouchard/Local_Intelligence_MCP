import Foundation
import CoreData

class KnowledgeGraphService {

    // MARK: - Properties

    nonisolated(unsafe) private let coreDataStack = CoreDataStack.shared

    // MARK: - Initialization

    init() {
        // Ensure CoreData is properly initialized
        _ = coreDataStack.persistentContainer
    }

    // MARK: - Knowledge Object Management

    func saveKnowledgeObjects(_ objects: [KnowledgeObject]) {
        print("Saving \(objects.count) knowledge objects to local database")
        coreDataStack.saveKnowledgeObjects(objects)
    }

    func saveKnowledgeRelationships(_ relationships: [KnowledgeRelationship]) {
        print("Saving \(relationships.count) knowledge relationships to local database")
        coreDataStack.saveKnowledgeRelationships(relationships)
    }

    func saveKnowledgeExtractionResult(_ result: KnowledgeExtractionResult) {
        print("Saving knowledge extraction result: \(result.knowledgeObjects.count) objects, \(result.relationships.count) relationships")

        coreDataStack.saveInBackground { context in
            // Save knowledge objects
            for object in result.knowledgeObjects {
                self.saveKnowledgeObject(object, in: context)
            }

            // Save relationships
            for relationship in result.relationships {
                self.saveKnowledgeRelationship(relationship, in: context)
            }
        }
    }

    private func saveKnowledgeObject(_ object: KnowledgeObject, in context: NSManagedObjectContext) {
        // Check if object already exists
        let request: NSFetchRequest<KnowledgeObjectEntity> = KnowledgeObjectEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", object.id)

        do {
            let existing = try context.fetch(request)
            let entity = existing.first ?? KnowledgeObjectEntity(context: context)
            entity.populateFromKnowledgeObject(object)
        } catch {
            print("Error checking for existing knowledge object: \(error)")
            let entity = KnowledgeObjectEntity(context: context)
            entity.populateFromKnowledgeObject(object)
        }
    }

    private func saveKnowledgeRelationship(_ relationship: KnowledgeRelationship, in context: NSManagedObjectContext) {
        // Check if relationship already exists
        let request: NSFetchRequest<KnowledgeRelationshipEntity> = KnowledgeRelationshipEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", relationship.id)

        do {
            let existing = try context.fetch(request)
            let entity = existing.first ?? KnowledgeRelationshipEntity(context: context)
            entity.populateFromKnowledgeRelationship(relationship)
        } catch {
            print("Error checking for existing knowledge relationship: \(error)")
            let entity = KnowledgeRelationshipEntity(context: context)
            entity.populateFromKnowledgeRelationship(relationship)
        }
    }

    // MARK: - Search Methods

    func searchKnowledge(
        query: String,
        domain: String? = nil,
        limit: Int = 20,
        includeMetadata: Bool = true
    ) -> [KnowledgeObject] {
        print("Searching for knowledge objects matching: '\(query)'")

        var results = coreDataStack.searchKnowledgeObjects(matching: query, in: domain, limit: limit)

        // If domain filtering is needed and not handled by CoreData, filter manually
        if let domain = domain {
            results = results.filter { object in
                // Simple domain filtering based on document title or content
                return object.sourceReference.documentTitle.lowercased().contains(domain.lowercased()) ||
                       object.content.lowercased().contains(domain.lowercased()) ||
                       object.metadata.values.contains { $0.lowercased().contains(domain.lowercased()) }
            }
        }

        print("Found \(results.count) knowledge objects matching query")
        return results
    }

    func searchKnowledgeByType(
        type: KnowledgeType,
        limit: Int = 20
    ) -> [KnowledgeObject] {
        print("Searching for knowledge objects of type: '\(type.rawValue)'")
        let results = coreDataStack.getKnowledgeObjectsByType(type, limit: limit)
        print("Found \(results.count) knowledge objects of type \(type.rawValue)")
        return results
    }

    func searchKnowledgeByDocument(
        documentTitle: String,
        limit: Int = 50
    ) -> [KnowledgeObject] {
        print("Searching for knowledge objects in document: '\(documentTitle)'")
        let results = coreDataStack.searchKnowledgeObjects(matching: "", in: documentTitle, limit: limit)
        print("Found \(results.count) knowledge objects in document '\(documentTitle)'")
        return results
    }

    func searchRelationships(for documentTitle: String) -> [KnowledgeRelationship] {
        print("Searching for relationships in document: '\(documentTitle)'")
        let results = coreDataStack.getKnowledgeRelationships(for: documentTitle)
        print("Found \(results.count) relationships in document '\(documentTitle)'")
        return results
    }

    // MARK: - Advanced Search

    func advancedSearch(
        query: String,
        types: [KnowledgeType]? = nil,
        documents: [String]? = nil,
        minConfidence: Double? = nil,
        limit: Int = 20
    ) -> [KnowledgeObject] {
        print("Performing advanced search with filters")

        // Start with basic search
        var results = coreDataStack.searchKnowledgeObjects(matching: query, limit: limit * 2) // Get more to filter

        // Apply filters
        if let types = types {
            results = results.filter { types.contains($0.type) }
        }

        if let documents = documents {
            results = results.filter { document in
                documents.contains { documentTitle in
                    document.sourceReference.documentTitle.lowercased().contains(documentTitle.lowercased())
                }
            }
        }

        if let minConfidence = minConfidence {
            results = results.filter { $0.confidence >= minConfidence }
        }

        // Apply limit after filtering
        results = Array(results.prefix(limit))

        print("Advanced search found \(results.count) results")
        return results
    }

    func getSuggestions(for query: String, limit: Int = 5) -> [String] {
        let results = searchKnowledge(query: query, limit: limit * 2)
        let titles = results.map { $0.title }.prefix(limit)
        return Array(titles)
    }

    // MARK: - Knowledge Retrieval

    func getAllKnowledgeObjects() -> [KnowledgeObject] {
        print("Retrieving all knowledge objects")
        let results = coreDataStack.getAllKnowledgeObjects()
        print("Retrieved \(results.count) knowledge objects")
        return results
    }

    func getKnowledgeObject(by id: String) -> KnowledgeObject? {
        let request: NSFetchRequest<KnowledgeObjectEntity> = KnowledgeObjectEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1

        do {
            let entities = try coreDataStack.fetch(request)
            return entities.first?.toKnowledgeObject()
        } catch {
            print("Error fetching knowledge object by ID: \(error)")
            return nil
        }
    }

    func getRelatedKnowledgeObjects(for objectId: String) -> [KnowledgeObject] {
        var relatedObjects: [KnowledgeObject] = []

        // Get the original object
        guard let originalObject = getKnowledgeObject(by: objectId) else {
            return relatedObjects
        }

        // Find objects in the same document
        let documentObjects = searchKnowledgeByDocument(documentTitle: originalObject.sourceReference.documentTitle, limit: 20)

        // Filter out the original object and find related content
        relatedObjects = documentObjects.filter { $0.id != objectId }

        // Simple relevance scoring based on content similarity
        relatedObjects.sort { obj1, obj2 in
            let similarity1 = calculateContentSimilarity(originalObject.content, obj1.content)
            let similarity2 = calculateContentSimilarity(originalObject.content, obj2.content)
            return similarity1 > similarity2
        }

        return Array(relatedObjects.prefix(10))
    }

    // MARK: - Data Management

    func removeDuplicates() {
        print("Removing duplicate knowledge objects")

        coreDataStack.saveInBackground { context in
            // Find duplicates based on ID
            let request: NSFetchRequest<KnowledgeObjectEntity> = KnowledgeObjectEntity.fetchRequest()
            request.propertiesToFetch = ["id"]
            request.returnsDistinctResults = false

            do {
                let allObjects = try context.fetch(request)
                var seenIDs = Set<String>()
                var duplicates: [KnowledgeObjectEntity] = []

                for object in allObjects {
                    if seenIDs.contains(object.id) {
                        duplicates.append(object)
                    } else {
                        seenIDs.insert(object.id)
                    }
                }

                // Remove duplicates
                for duplicate in duplicates {
                    context.delete(duplicate)
                }

                print("Removed \(duplicates.count) duplicate knowledge objects")
            } catch {
                print("Error finding duplicates: \(error)")
            }
        }
    }

    func deleteAllKnowledgeObjects() {
        print("Deleting all knowledge objects")
        let request: NSFetchRequest<KnowledgeObjectEntity> = KnowledgeObjectEntity.fetchRequest()
        do {
            try coreDataStack.batchDelete(request)
            print("Deleted all knowledge objects")
        } catch {
            print("Error deleting knowledge objects: \(error)")
        }
    }

    func deleteKnowledgeObjects(for documentTitle: String) {
        print("Deleting knowledge objects for document: '\(documentTitle)'")

        coreDataStack.saveInBackground { context in
            let request: NSFetchRequest<KnowledgeObjectEntity> = KnowledgeObjectEntity.fetchRequest()
            request.predicate = NSPredicate(format: "documentTitle == %@", documentTitle)

            do {
                let objects = try context.fetch(request)
                for object in objects {
                    context.delete(object)
                }
                print("Deleted \(objects.count) knowledge objects for document '\(documentTitle)'")
            } catch {
                print("Error deleting knowledge objects for document: \(error)")
            }
        }
    }

    // MARK: - Statistics and Analysis

    func getTotalKnowledgeObjectCount() -> Int {
        return coreDataStack.getKnowledgeObjectCount()
    }

    func getStatistics() -> KnowledgeGraphStatistics {
        let objectCount = coreDataStack.getKnowledgeObjectCount()
        let relationshipCount = coreDataStack.getRelationshipCount()
        let documentCount = coreDataStack.getDocumentCount()

        // Get type distribution
        var typeDistribution: [KnowledgeType: Int] = [:]
        for type in KnowledgeType.allCases {
            typeDistribution[type] = coreDataStack.getKnowledgeObjectsByType(type, limit: 1000).count
        }

        return KnowledgeGraphStatistics(
            totalKnowledgeObjects: objectCount,
            totalRelationships: relationshipCount,
            totalDocuments: documentCount,
            typeDistribution: typeDistribution
        )
    }

    // MARK: - Helper Methods

    private func calculateContentSimilarity(_ content1: String, _ content2: String) -> Double {
        let words1 = Set(content1.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let words2 = Set(content2.lowercased().components(separatedBy: .whitespacesAndNewlines))

        let intersection = words1.intersection(words2)
        let union = words1.union(words2)

        guard !union.isEmpty else { return 0.0 }
        return Double(intersection.count) / Double(union.count)
    }
}

// MARK: - Supporting Types

struct KnowledgeGraphStatistics {
    let totalKnowledgeObjects: Int
    let totalRelationships: Int
    let totalDocuments: Int
    let typeDistribution: [KnowledgeType: Int]

    var description: String {
        var desc = "Knowledge Graph Statistics:\n"
        desc += "  Total Knowledge Objects: \(totalKnowledgeObjects)\n"
        desc += "  Total Relationships: \(totalRelationships)\n"
        desc += "  Total Documents: \(totalDocuments)\n"
        desc += "  Type Distribution:\n"

        for (type, count) in typeDistribution.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            desc += "    \(type.rawValue): \(count)\n"
        }

        return desc
    }
}

// KnowledgeType is now defined as CaseIterable in KnowledgeModels.swift