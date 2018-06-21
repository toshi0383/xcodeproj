import AEXML
import Foundation

extension XCScheme {
    public final class BuildableReference: Equatable {

        // MARK: - Attributes

        public var referencedContainer: String
        public var blueprintIdentifier: String
        public var buildableName: String
        public var buildableIdentifier: String
        public var blueprintName: String

        // MARK: - Init

        public init(referencedContainer: String,
                    blueprintIdentifier: String,
                    buildableName: String,
                    blueprintName: String,
                    buildableIdentifier: String = "primary") {
            self.referencedContainer = referencedContainer
            self.blueprintIdentifier = blueprintIdentifier
            self.buildableName = buildableName
            self.buildableIdentifier = buildableIdentifier
            self.blueprintName = blueprintName
        }

        // MARK: - XML

        init(element: AEXMLElement) throws {
            guard let buildableIdentifier = element.attributes["BuildableIdentifier"] else {
                throw XCSchemeError.missing(property: "BuildableIdentifier")
            }
            guard let blueprintIdentifier = element.attributes["BlueprintIdentifier"] else {
                throw XCSchemeError.missing(property: "BlueprintIdentifier")
            }
            guard let buildableName = element.attributes["BuildableName"] else {
                throw XCSchemeError.missing(property: "BuildableName")
            }
            guard let blueprintName = element.attributes["BlueprintName"] else {
                throw XCSchemeError.missing(property: "BlueprintName")
            }
            guard let referencedContainer = element.attributes["ReferencedContainer"] else {
                throw XCSchemeError.missing(property: "ReferencedContainer")
            }
            self.buildableIdentifier = buildableIdentifier
            self.blueprintIdentifier = blueprintIdentifier
            self.buildableName = buildableName
            self.blueprintName = blueprintName
            self.referencedContainer = referencedContainer
        }

        func xmlElement() -> AEXMLElement {
            return AEXMLElement(name: "BuildableReference",
                                value: nil,
                                attributes: [
                                    "BuildableIdentifier": buildableIdentifier,
                                    "BlueprintIdentifier": blueprintIdentifier,
                                    "BuildableName": buildableName,
                                    "BlueprintName": blueprintName,
                                    "ReferencedContainer": referencedContainer,
            ])
        }

        // MARK: - Equatable

        public static func == (lhs: BuildableReference, rhs: BuildableReference) -> Bool {
            return lhs.referencedContainer == rhs.referencedContainer &&
                lhs.blueprintIdentifier == rhs.blueprintIdentifier &&
                lhs.buildableName == rhs.buildableName &&
                lhs.buildableIdentifier == rhs.buildableIdentifier &&
                lhs.blueprintName == rhs.blueprintName
        }
    }
}
