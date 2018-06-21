import Foundation
@testable import xcodeproj
import XCTest

final class PBXShellScriptBuildPhaseSpec: XCTestCase {
    func test_returnsTheCorrectIsa() {
        XCTAssertEqual(PBXShellScriptBuildPhase.isa, "PBXShellScriptBuildPhase")
    }

    func test_write_showEnvVarsInLog() throws {
        let show = PBXShellScriptBuildPhase(showEnvVarsInLog: true)
        let doNotShow = PBXShellScriptBuildPhase(showEnvVarsInLog: false)
        let proj = PBXProj(rootObjectReference: PBXObjectReference("rootObject"),
                           objectVersion: 48,
                           objects: [show, doNotShow])

        let (_, showPlistValue) = try show.plistKeyAndValue(proj: proj, reference: "ref")
        let (_, doNotShowPlistValue) = try doNotShow.plistKeyAndValue(proj: proj, reference: "ref")

        if case let PlistValue.dictionary(showDictionary) = showPlistValue,
            case let PlistValue.dictionary(doNotShowDictionary) = doNotShowPlistValue {
            XCTAssertNil(showDictionary["showEnvVarsInLog"])
            XCTAssertEqual(doNotShowDictionary["showEnvVarsInLog"]?.string, "0")
        } else {
            XCTAssert(false)
        }
    }

    private func testDictionary() -> [String: Any] {
        return [
            "files": ["files"],
            "inputPaths": ["input"],
            "outputPaths": ["output"],
            "shellPath": "shellPath",
            "shellScript": "shellScript",
        ]
    }
}
