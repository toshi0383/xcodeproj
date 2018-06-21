import Foundation
import xcodeproj
import XCTest

final class PBXBuildRuleSpec: XCTestCase {
    var subject: PBXBuildRule!

    override func setUp() {
        super.setUp()
        subject = PBXBuildRule(compilerSpec: "spec",
                               fileType: "type",
                               isEditable: true,
                               filePatterns: "pattern",
                               name: "rule",
                               outputFiles: ["a", "b"],
                               outputFilesCompilerFlags: ["-1", "-2"],
                               script: "script")
    }

    func test_init_initializesTheBuildRuleWithTheRightAttributes() {
        XCTAssertEqual(subject.compilerSpec, "spec")
        XCTAssertEqual(subject.filePatterns, "pattern")
        XCTAssertEqual(subject.fileType, "type")
        XCTAssertEqual(subject.isEditable, true)
        XCTAssertEqual(subject.name, "rule")
        XCTAssertEqual(subject.outputFiles, ["a", "b"])
        XCTAssertEqual(subject.outputFilesCompilerFlags ?? [], ["-1", "-2"])
        XCTAssertEqual(subject.script, "script")
    }

    func test_isa_returnsTheCorrectValue() {
        XCTAssertEqual(PBXBuildRule.isa, "PBXBuildRule")
    }

    func test_equal_shouldReturnTheCorrectValue() {
        let another = PBXBuildRule(compilerSpec: "spec",
                                   fileType: "type",
                                   isEditable: true,
                                   filePatterns: "pattern",
                                   name: "rule",
                                   outputFiles: ["a", "b"],
                                   outputFilesCompilerFlags: ["-1", "-2"],
                                   script: "script")
        XCTAssertEqual(subject, another)
    }
}
