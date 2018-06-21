// swiftlint:disable all
import Basic
import Foundation

// MARK: - AbsolutePath extras.

let systemGlob = Darwin.glob

extension AbsolutePath {
    /// Returns the URL that points to the file path.
    var url: URL {
        return URL(fileURLWithPath: asString)
    }

    /// Returns true if a file exists at the given path.
    var exists: Bool {
        return FileManager.default.fileExists(atPath: asString)
    }

    /// Returns the last path component.
    var lastComponent: String {
        return components.last ?? ""
    }

    /// Returns last path component without the extension.
    var lastComponentWithoutExtension: String {
        return components.last?.split(separator: ".").first.map(String.init) ?? ""
    }

    /// Deletes the file at the given path.
    ///
    /// - Throws: an error if the deletion fails.
    func delete() throws {
        try FileManager.default.removeItem(atPath: asString)
    }

    /// Writes the string atomically into a file at the given path.
    ///
    /// - Parameter content: content to be written.
    /// - Throws: an error if the writing fails.
    func write(_ content: String) throws {
        try content.write(toFile: asString, atomically: true, encoding: .utf8)
    }

    /// Reads the content (string) at the given path.
    ///
    /// - Returns: file content.
    /// - Throws: an error if the content cannot be read.
    func read() throws -> String {
        return try String(contentsOf: URL(fileURLWithPath: asString))
    }

    /// Creates a directory
    ///
    /// - Throws: an errof if the directory cannot be created.
    func mkpath(withIntermediateDirectories: Bool = true) throws {
        try FileManager.default.createDirectory(atPath: asString, withIntermediateDirectories: withIntermediateDirectories, attributes: nil)
    }

    /// Copies a file to another path.
    ///
    /// - Parameter to: path the file/directory will be copied  to.
    func copy(_ to: AbsolutePath) throws {
        try FileManager.default.copyItem(atPath: asString,
                                         toPath: to.asString)
    }

    /// Finds files and directories using the given glob pattern.
    ///
    /// - Parameter pattern: glob pattern.
    /// - Returns: found directories and files.
    public func glob(_ pattern: String) -> [AbsolutePath] {
        var gt = glob_t()
        let cPattern = strdup(appending(RelativePath(pattern)).asString)
        defer {
            globfree(&gt)
            free(cPattern)
        }

        let flags = GLOB_TILDE | GLOB_BRACE | GLOB_MARK
        if systemGlob(cPattern, flags, nil, &gt) == 0 {
            let matchc = gt.gl_matchc
            return (0 ..< Int(matchc)).compactMap { index in
                if let path = String(validatingUTF8: gt.gl_pathv[index]!) {
                    return AbsolutePath(path)
                }
                return nil
            }
        }
        return []
    }
}

// swiftlint:enable all
