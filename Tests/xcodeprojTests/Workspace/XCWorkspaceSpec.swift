import Basic
import Foundation
import xcodeproj
import XCTest

final class XCWorkspaceIntegrationSpec: XCTestCase {
    func test_initTheWorkspaceWithTheRightPropeties() {
        let path = fixturesPath().appending(RelativePath("iOS/Project.xcodeproj/project.xcworkspace"))
        let got = try? XCWorkspace(path: path)
        XCTAssertNotNil(got)
    }

    func test_initFailsIfThePathIsWrong() {
        do {
            _ = try XCWorkspace(path: AbsolutePath("/test"))
            XCTAssertTrue(false, "Expected to throw an error but it didn't")
        } catch {}
    }

    func test_init_returnsAWorkspaceWithTheCorrectReference() {
        XCTAssertEqual(XCWorkspace().data.children.count, 1)
        XCTAssertEqual(XCWorkspace().data.children.first, .file(.init(location: .self(""))))
    }
}
