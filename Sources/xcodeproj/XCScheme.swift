import AEXML
import Basic
import Foundation

// swiftlint:disable:next type_body_length
public final class XCScheme {
    public static let defaultDebugger = "Xcode.DebuggerFoundation.Debugger.LLDB"
    public static let defaultLauncher = "Xcode.DebuggerFoundation.Launcher.LLDB"

    // MARK: - ExecutionAction

    public final class ExecutionAction: Equatable {
        public var title: String
        public var scriptText: String
        public var environmentBuildable: BuildableReference?

        public init(scriptText: String, title: String = "Run Script", environmentBuildable: BuildableReference? = nil) {
            self.scriptText = scriptText
            self.title = title
            self.environmentBuildable = environmentBuildable
        }

        init(element: AEXMLElement) throws {
            scriptText = element["ActionContent"].attributes["scriptText"] ?? ""
            title = element["ActionContent"].attributes["title"] ?? "Run Script"
            environmentBuildable = try? BuildableReference(element: element["ActionContent"]["EnvironmentBuildable"]["BuildableReference"])
        }

        private static let ActionType = "Xcode.IDEStandardExecutionActionsCore.ExecutionActionType.ShellScriptAction"

        fileprivate func xmlElement() -> AEXMLElement {
            let element = AEXMLElement(name: "ExecutionAction",
                                       value: nil,
                                       attributes: ["ActionType": ExecutionAction.ActionType])
            let content = AEXMLElement(name: "ActionContent",
                                       value: nil,
                                       attributes: [
                                           "title": title,
                                           "scriptText": scriptText,
            ])
            element.addChild(content)
            if let environmentBuildable = environmentBuildable {
                let environment = content.addChild(name: "EnvironmentBuildable")
                environment.addChild(environmentBuildable.xmlElement())
            }
            return element
        }

        public static func == (lhs: ExecutionAction, rhs: ExecutionAction) -> Bool {
            return lhs.title == rhs.title &&
                lhs.scriptText == rhs.scriptText &&
                lhs.environmentBuildable == rhs.environmentBuildable
        }
    }

    // MARK: - SerialAction

    public class SerialAction: Equatable {
        public var preActions: [ExecutionAction]
        public var postActions: [ExecutionAction]

        init(_ preActions: [ExecutionAction], _ postActions: [ExecutionAction]) {
            self.preActions = preActions
            self.postActions = postActions
        }

        init(element: AEXMLElement) throws {
            preActions = try element["PreActions"]["ExecutionAction"].all?.map(ExecutionAction.init) ?? []
            postActions = try element["PostActions"]["ExecutionAction"].all?.map(ExecutionAction.init) ?? []
        }

        fileprivate func writeXML(parent element: AEXMLElement) {
            if !preActions.isEmpty {
                let preActions = element.addChild(name: "PreActions")
                self.preActions.forEach { preAction in
                    preActions.addChild(preAction.xmlElement())
                }
            }
            if !postActions.isEmpty {
                let postActions = element.addChild(name: "PostActions")
                self.postActions.forEach { postAction in
                    postActions.addChild(postAction.xmlElement())
                }
            }
        }

        public static func == (lhs: SerialAction, rhs: SerialAction) -> Bool {
            return lhs.preActions == rhs.preActions &&
                lhs.postActions == rhs.postActions
        }
    }

    // MARK: - BuildAction

    public final class BuildAction: SerialAction, Equatable {
        public final class Entry: Equatable {
            public enum BuildFor {
                case running, testing, profiling, archiving, analyzing
                public static var `default`: [BuildFor] = [.running, .testing, .archiving, .analyzing]
                public static var indexing: [BuildFor] = [.testing, .analyzing, .archiving]
                public static var testOnly: [BuildFor] = [.testing, .analyzing]
            }

            public var buildableReference: BuildableReference
            public var buildFor: [BuildFor]

            public init(buildableReference: BuildableReference,
                        buildFor: [BuildFor]) {
                self.buildableReference = buildableReference
                self.buildFor = buildFor
            }

            init(element: AEXMLElement) throws {
                var buildFor: [BuildFor] = []
                if (element.attributes["buildForTesting"].map { $0 == "YES" }) ?? true {
                    buildFor.append(.testing)
                }
                if (element.attributes["buildForRunning"].map { $0 == "YES" }) ?? true {
                    buildFor.append(.running)
                }
                if (element.attributes["buildForProfiling"].map { $0 == "YES" }) ?? true {
                    buildFor.append(.profiling)
                }
                if (element.attributes["buildForArchiving"].map { $0 == "YES" }) ?? true {
                    buildFor.append(.archiving)
                }
                if (element.attributes["buildForAnalyzing"].map { $0 == "YES" }) ?? true {
                    buildFor.append(.analyzing)
                }
                self.buildFor = buildFor
                buildableReference = try BuildableReference(element: element["BuildableReference"])
            }

            fileprivate func xmlElement() -> AEXMLElement {
                var attributes: [String: String] = [:]
                attributes["buildForTesting"] = buildFor.contains(.testing) ? "YES" : "NO"
                attributes["buildForRunning"] = buildFor.contains(.running) ? "YES" : "NO"
                attributes["buildForProfiling"] = buildFor.contains(.profiling) ? "YES" : "NO"
                attributes["buildForArchiving"] = buildFor.contains(.archiving) ? "YES" : "NO"
                attributes["buildForAnalyzing"] = buildFor.contains(.analyzing) ? "YES" : "NO"
                let element = AEXMLElement(name: "BuildActionEntry",
                                           value: nil,
                                           attributes: attributes)
                element.addChild(buildableReference.xmlElement())
                return element
            }

            public static func == (lhs: Entry, rhs: Entry) -> Bool {
                return lhs.buildableReference == rhs.buildableReference &&
                    lhs.buildFor == rhs.buildFor
            }
        }

        public var buildActionEntries: [Entry]
        public var parallelizeBuild: Bool
        public var buildImplicitDependencies: Bool

        public init(buildActionEntries: [Entry] = [],
                    preActions: [ExecutionAction] = [],
                    postActions: [ExecutionAction] = [],
                    parallelizeBuild: Bool = false,
                    buildImplicitDependencies: Bool = false) {
            self.buildActionEntries = buildActionEntries
            self.parallelizeBuild = parallelizeBuild
            self.buildImplicitDependencies = buildImplicitDependencies
            super.init(preActions, postActions)
        }

        override init(element: AEXMLElement) throws {
            parallelizeBuild = element.attributes["parallelizeBuildables"].map { $0 == "YES" } ?? true
            buildImplicitDependencies = element.attributes["buildImplicitDependencies"].map { $0 == "YES" } ?? true
            buildActionEntries = try element["BuildActionEntries"]["BuildActionEntry"]
                .all?
                .map(Entry.init) ?? []
            try super.init(element: element)
        }

        fileprivate func xmlElement() -> AEXMLElement {
            let element = AEXMLElement(name: "BuildAction",
                                       value: nil,
                                       attributes: [
                                           "parallelizeBuildables": parallelizeBuild.xmlString,
                                           "buildImplicitDependencies": buildImplicitDependencies.xmlString,
            ])
            super.writeXML(parent: element)
            let entries = element.addChild(name: "BuildActionEntries")
            buildActionEntries.forEach { entry in
                entries.addChild(entry.xmlElement())
            }
            return element
        }

        public static func == (lhs: BuildAction, rhs: BuildAction) -> Bool {
            return lhs.buildActionEntries == rhs.buildActionEntries &&
                lhs.parallelizeBuild == rhs.parallelizeBuild &&
                lhs.buildImplicitDependencies == rhs.buildImplicitDependencies &&
                lhs.preActions == rhs.preActions &&
                lhs.postActions == rhs.postActions
        }

        public func add(buildActionEntry: Entry) -> BuildAction {
            var buildActionEntries = self.buildActionEntries
            buildActionEntries.append(buildActionEntry)
            return BuildAction(buildActionEntries: buildActionEntries,
                               parallelizeBuild: parallelizeBuild)
        }
    }

    public final class AdditionalOption {
        public var key: String
        public var value: String
        public var isEnabled: Bool

        public init(key: String, value: String, isEnabled: Bool) {
            self.key = key
            self.value = value
            self.isEnabled = isEnabled
        }

        init(element: AEXMLElement) throws {
            key = element.attributes["key"]!
            value = element.attributes["value"]!
            isEnabled = element.attributes["isEnabled"] == "YES"
        }

        fileprivate func xmlElement() -> AEXMLElement {
            return AEXMLElement(name: "AdditionalOption",
                                value: nil,
                                attributes: [
                                    "key": key,
                                    "value": value,
                                    "isEnabled": isEnabled.xmlString,
            ])
        }
    }

    public final class LaunchAction: SerialAction {
        private static let defaultBuildConfiguration = "Debug"
        public static let defaultDebugServiceExtension = "internal"
        private static let defaultLaunchStyle = Style.auto

        public enum Style: String {
            case auto = "0"
            case wait = "1"
        }

        public var buildableProductRunnable: BuildableProductRunnable?
        public var macroExpansion: BuildableReference?
        public var selectedDebuggerIdentifier: String
        public var selectedLauncherIdentifier: String
        public var buildConfiguration: String
        public var launchStyle: Style
        public var useCustomWorkingDirectory: Bool
        public var ignoresPersistentStateOnLaunch: Bool
        public var debugDocumentVersioning: Bool
        public var debugServiceExtension: String
        public var allowLocationSimulation: Bool
        public var locationScenarioReference: LocationScenarioReference?
        public var enableAddressSanitizer: Bool
        public var enableASanStackUseAfterReturn: Bool
        public var enableThreadSanitizer: Bool
        public var stopOnEveryThreadSanitizerIssue: Bool
        public var enableUBSanitizer: Bool
        public var stopOnEveryUBSanitizerIssue: Bool
        public var disableMainThreadChecker: Bool
        public var stopOnEveryMainThreadCheckerIssue: Bool
        public var additionalOptions: [AdditionalOption]
        public var commandlineArguments: CommandLineArguments?
        public var environmentVariables: [EnvironmentVariable]?
        public var language: String?
        public var region: String?

        public init(buildableProductRunnable: BuildableProductRunnable?,
                    buildConfiguration: String,
                    preActions: [ExecutionAction] = [],
                    postActions: [ExecutionAction] = [],
                    macroExpansion: BuildableReference? = nil,
                    selectedDebuggerIdentifier: String = XCScheme.defaultDebugger,
                    selectedLauncherIdentifier: String = XCScheme.defaultLauncher,
                    launchStyle: Style = .auto,
                    useCustomWorkingDirectory: Bool = false,
                    ignoresPersistentStateOnLaunch: Bool = false,
                    debugDocumentVersioning: Bool = true,
                    debugServiceExtension: String = LaunchAction.defaultDebugServiceExtension,
                    allowLocationSimulation: Bool = true,
                    locationScenarioReference: LocationScenarioReference? = nil,
                    enableAddressSanitizer: Bool = false,
                    enableASanStackUseAfterReturn: Bool = false,
                    enableThreadSanitizer: Bool = false,
                    stopOnEveryThreadSanitizerIssue: Bool = false,
                    enableUBSanitizer: Bool = false,
                    stopOnEveryUBSanitizerIssue: Bool = false,
                    disableMainThreadChecker: Bool = false,
                    stopOnEveryMainThreadCheckerIssue: Bool = false,
                    additionalOptions: [AdditionalOption] = [],
                    commandlineArguments: CommandLineArguments? = nil,
                    environmentVariables: [EnvironmentVariable]? = nil,
                    language: String? = nil,
                    region: String? = nil) {
            self.buildableProductRunnable = buildableProductRunnable
            self.macroExpansion = macroExpansion
            self.buildConfiguration = buildConfiguration
            self.launchStyle = launchStyle
            self.selectedDebuggerIdentifier = selectedDebuggerIdentifier
            self.selectedLauncherIdentifier = selectedLauncherIdentifier
            self.useCustomWorkingDirectory = useCustomWorkingDirectory
            self.ignoresPersistentStateOnLaunch = ignoresPersistentStateOnLaunch
            self.debugDocumentVersioning = debugDocumentVersioning
            self.debugServiceExtension = debugServiceExtension
            self.allowLocationSimulation = allowLocationSimulation
            self.locationScenarioReference = locationScenarioReference
            self.enableAddressSanitizer = enableAddressSanitizer
            self.enableASanStackUseAfterReturn = enableASanStackUseAfterReturn
            self.enableThreadSanitizer = enableThreadSanitizer
            self.stopOnEveryThreadSanitizerIssue = stopOnEveryThreadSanitizerIssue
            self.enableUBSanitizer = enableUBSanitizer
            self.stopOnEveryUBSanitizerIssue = stopOnEveryUBSanitizerIssue
            self.disableMainThreadChecker = disableMainThreadChecker
            self.stopOnEveryMainThreadCheckerIssue = stopOnEveryMainThreadCheckerIssue
            self.additionalOptions = additionalOptions
            self.commandlineArguments = commandlineArguments
            self.environmentVariables = environmentVariables
            self.language = language
            self.region = region
            super.init(preActions, postActions)
        }

        override init(element: AEXMLElement) throws {
            buildConfiguration = element.attributes["buildConfiguration"] ?? LaunchAction.defaultBuildConfiguration
            selectedDebuggerIdentifier = element.attributes["selectedDebuggerIdentifier"] ?? XCScheme.defaultDebugger
            selectedLauncherIdentifier = element.attributes["selectedLauncherIdentifier"] ?? XCScheme.defaultLauncher
            launchStyle = element.attributes["launchStyle"].flatMap { Style(rawValue: $0) } ?? .auto
            useCustomWorkingDirectory = element.attributes["useCustomWorkingDirectory"] == "YES"
            ignoresPersistentStateOnLaunch = element.attributes["ignoresPersistentStateOnLaunch"] == "YES"
            debugDocumentVersioning = element.attributes["debugDocumentVersioning"].map { $0 == "YES" } ?? true
            debugServiceExtension = element.attributes["debugServiceExtension"] ?? LaunchAction.defaultDebugServiceExtension
            allowLocationSimulation = element.attributes["allowLocationSimulation"].map { $0 == "YES" } ?? true

            let buildableProductRunnableElement = element["BuildableProductRunnable"]
            if buildableProductRunnableElement.error == nil {
                buildableProductRunnable = try BuildableProductRunnable(element: buildableProductRunnableElement)
            }
            let buildableReferenceElement = element["MacroExpansion"]["BuildableReference"]
            if buildableReferenceElement.error == nil {
                macroExpansion = try BuildableReference(element: buildableReferenceElement)
            }

            if element["LocationScenarioReference"].all?.first != nil {
                locationScenarioReference = try LocationScenarioReference(element: element["LocationScenarioReference"])
            } else {
                locationScenarioReference = nil
            }

            enableAddressSanitizer = element.attributes["enableAddressSanitizer"] == "YES"
            enableASanStackUseAfterReturn = element.attributes["enableASanStackUseAfterReturn"] == "YES"
            enableThreadSanitizer = element.attributes["enableThreadSanitizer"] == "YES"
            stopOnEveryThreadSanitizerIssue = element.attributes["stopOnEveryThreadSanitizerIssue"] == "YES"
            enableUBSanitizer = element.attributes["enableUBSanitizer"] == "YES"
            stopOnEveryUBSanitizerIssue = element.attributes["stopOnEveryUBSanitizerIssue"] == "YES"
            disableMainThreadChecker = element.attributes["disableMainThreadChecker"] == "YES"
            stopOnEveryMainThreadCheckerIssue = element.attributes["stopOnEveryMainThreadCheckerIssue"] == "YES"

            additionalOptions = try element["AdditionalOptions"]["AdditionalOption"]
                .all?
                .map(AdditionalOption.init) ?? []

            let commandlineOptions = element["CommandLineArguments"]
            if commandlineOptions.error == nil {
                commandlineArguments = try CommandLineArguments(element: commandlineOptions)
            }

            let environmentVariables = element["EnvironmentVariables"]
            if environmentVariables.error == nil {
                self.environmentVariables = try EnvironmentVariable.parseVariables(from: environmentVariables)
            }

            language = element.attributes["language"]
            region = element.attributes["region"]
            try super.init(element: element)
        }

        private var xmlAttributes: [String: String] {
            var attributes = [
                "buildConfiguration": buildConfiguration,
                "selectedDebuggerIdentifier": selectedDebuggerIdentifier,
                "selectedLauncherIdentifier": selectedLauncherIdentifier,
                "launchStyle": launchStyle.rawValue,
                "useCustomWorkingDirectory": useCustomWorkingDirectory.xmlString,
                "ignoresPersistentStateOnLaunch": ignoresPersistentStateOnLaunch.xmlString,
                "debugDocumentVersioning": debugDocumentVersioning.xmlString,
                "debugServiceExtension": debugServiceExtension,
                "allowLocationSimulation": allowLocationSimulation.xmlString,
            ]

            if enableAddressSanitizer {
                attributes["enableAddressSanitizer"] = enableAddressSanitizer.xmlString
            }
            if enableASanStackUseAfterReturn {
                attributes["enableASanStackUseAfterReturn"] = enableASanStackUseAfterReturn.xmlString
            }
            if enableThreadSanitizer {
                attributes["enableThreadSanitizer"] = enableThreadSanitizer.xmlString
            }
            if stopOnEveryThreadSanitizerIssue {
                attributes["stopOnEveryThreadSanitizerIssue"] = stopOnEveryThreadSanitizerIssue.xmlString
            }
            if enableUBSanitizer {
                attributes["enableUBSanitizer"] = enableUBSanitizer.xmlString
            }
            if stopOnEveryUBSanitizerIssue {
                attributes["stopOnEveryUBSanitizerIssue"] = stopOnEveryUBSanitizerIssue.xmlString
            }
            if disableMainThreadChecker {
                attributes["disableMainThreadChecker"] = disableMainThreadChecker.xmlString
            }
            if stopOnEveryMainThreadCheckerIssue {
                attributes["stopOnEveryMainThreadCheckerIssue"] = stopOnEveryMainThreadCheckerIssue.xmlString
            }

            return attributes
        }

        fileprivate func xmlElement() -> AEXMLElement {
            let element = AEXMLElement(name: "LaunchAction",
                                       value: nil,
                                       attributes: xmlAttributes)
            super.writeXML(parent: element)
            if let buildableProductRunnable = buildableProductRunnable {
                element.addChild(buildableProductRunnable.xmlElement())
            }

            if let locationScenarioReference = locationScenarioReference {
                element.addChild(locationScenarioReference.xmlElement())
            }

            if let macroExpansion = macroExpansion {
                let macro = element.addChild(name: "MacroExpansion")
                macro.addChild(macroExpansion.xmlElement())
            }

            if let commandlineArguments = commandlineArguments {
                element.addChild(commandlineArguments.xmlElement())
            }

            if let environmentVariables = environmentVariables {
                element.addChild(EnvironmentVariable.xmlElement(from: environmentVariables))
            }

            if let language = language {
                element.attributes["language"] = language
            }

            if let region = region {
                element.attributes["region"] = region
            }

            let additionalOptionsElement = element.addChild(AEXMLElement(name: "AdditionalOptions"))
            additionalOptions.forEach { additionalOption in
                additionalOptionsElement.addChild(additionalOption.xmlElement())
            }
            return element
        }
    }

    public final class ProfileAction: SerialAction {
        private static let defaultBuildConfiguration = "Release"

        public var buildableProductRunnable: BuildableProductRunnable?
        public var buildConfiguration: String
        public var shouldUseLaunchSchemeArgsEnv: Bool
        public var savedToolIdentifier: String
        public var ignoresPersistentStateOnLaunch: Bool
        public var useCustomWorkingDirectory: Bool
        public var debugDocumentVersioning: Bool
        public var commandlineArguments: CommandLineArguments?
        public var environmentVariables: [EnvironmentVariable]?
        public var macroExpansion: BuildableReference?
        public var enableTestabilityWhenProfilingTests: Bool

        public init(buildableProductRunnable: BuildableProductRunnable?,
                    buildConfiguration: String,
                    preActions: [ExecutionAction] = [],
                    postActions: [ExecutionAction] = [],
                    macroExpansion: BuildableReference? = nil,
                    shouldUseLaunchSchemeArgsEnv: Bool = true,
                    savedToolIdentifier: String = "",
                    ignoresPersistentStateOnLaunch: Bool = false,
                    useCustomWorkingDirectory: Bool = false,
                    debugDocumentVersioning: Bool = true,
                    commandlineArguments: CommandLineArguments? = nil,
                    environmentVariables: [EnvironmentVariable]? = nil,
                    enableTestabilityWhenProfilingTests: Bool = true) {
            self.buildableProductRunnable = buildableProductRunnable
            self.buildConfiguration = buildConfiguration
            self.macroExpansion = macroExpansion
            self.shouldUseLaunchSchemeArgsEnv = shouldUseLaunchSchemeArgsEnv
            self.savedToolIdentifier = savedToolIdentifier
            self.useCustomWorkingDirectory = useCustomWorkingDirectory
            self.debugDocumentVersioning = debugDocumentVersioning
            self.commandlineArguments = commandlineArguments
            self.environmentVariables = environmentVariables
            self.ignoresPersistentStateOnLaunch = ignoresPersistentStateOnLaunch
            self.enableTestabilityWhenProfilingTests = enableTestabilityWhenProfilingTests
            super.init(preActions, postActions)
        }

        override init(element: AEXMLElement) throws {
            buildConfiguration = element.attributes["buildConfiguration"] ?? ProfileAction.defaultBuildConfiguration
            shouldUseLaunchSchemeArgsEnv = element.attributes["shouldUseLaunchSchemeArgsEnv"].map { $0 == "YES" } ?? true
            savedToolIdentifier = element.attributes["savedToolIdentifier"] ?? ""
            useCustomWorkingDirectory = element.attributes["useCustomWorkingDirectory"] == "YES"
            debugDocumentVersioning = element.attributes["debugDocumentVersioning"].map { $0 == "YES" } ?? true
            ignoresPersistentStateOnLaunch = element.attributes["ignoresPersistentStateOnLaunch"].map { $0 == "YES" } ?? false

            let buildableProductRunnableElement = element["BuildableProductRunnable"]
            if buildableProductRunnableElement.error == nil {
                buildableProductRunnable = try BuildableProductRunnable(element: buildableProductRunnableElement)
            }
            let buildableReferenceElement = element["MacroExpansion"]["BuildableReference"]
            if buildableReferenceElement.error == nil {
                macroExpansion = try BuildableReference(element: buildableReferenceElement)
            }
            let commandlineOptions = element["CommandLineArguments"]
            if commandlineOptions.error == nil {
                commandlineArguments = try CommandLineArguments(element: commandlineOptions)
            }
            let environmentVariables = element["EnvironmentVariables"]
            if environmentVariables.error == nil {
                self.environmentVariables = try EnvironmentVariable.parseVariables(from: environmentVariables)
            }
            enableTestabilityWhenProfilingTests = element.attributes["enableTestabilityWhenProfilingTests"].map { $0 != "No" } ?? true
            try super.init(element: element)
        }

        fileprivate func xmlElement() -> AEXMLElement {
            let element = AEXMLElement(name: "ProfileAction",
                                       value: nil,
                                       attributes: [
                                           "buildConfiguration": buildConfiguration,
                                           "shouldUseLaunchSchemeArgsEnv": shouldUseLaunchSchemeArgsEnv.xmlString,
                                           "savedToolIdentifier": savedToolIdentifier,
                                           "useCustomWorkingDirectory": useCustomWorkingDirectory.xmlString,
                                           "debugDocumentVersioning": debugDocumentVersioning.xmlString,
            ])
            super.writeXML(parent: element)
            if ignoresPersistentStateOnLaunch {
                element.attributes["ignoresPersistentStateOnLaunch"] = ignoresPersistentStateOnLaunch.xmlString
            }
            if !enableTestabilityWhenProfilingTests {
                element.attributes["enableTestabilityWhenProfilingTests"] = "No"
            }
            if let buildableProductRunnable = buildableProductRunnable {
                element.addChild(buildableProductRunnable.xmlElement())
            }
            if let commandlineArguments = commandlineArguments {
                element.addChild(commandlineArguments.xmlElement())
            }
            if let environmentVariables = environmentVariables {
                element.addChild(EnvironmentVariable.xmlElement(from: environmentVariables))
            }

            if let macroExpansion = macroExpansion {
                let macro = element.addChild(name: "MacroExpansion")
                macro.addChild(macroExpansion.xmlElement())
            }

            return element
        }
    }

    public final class TestAction: SerialAction {
        private static let defaultBuildConfiguration = "Debug"

        public var testables: [TestableReference]
        public var buildConfiguration: String
        public var selectedDebuggerIdentifier: String
        public var selectedLauncherIdentifier: String
        public var shouldUseLaunchSchemeArgsEnv: Bool
        public var codeCoverageEnabled: Bool
        public var enableAddressSanitizer: Bool
        public var enableASanStackUseAfterReturn: Bool
        public var enableThreadSanitizer: Bool
        public var enableUBSanitizer: Bool
        public var disableMainThreadChecker: Bool
        public var macroExpansion: BuildableReference?
        public var additionalOptions: [AdditionalOption]
        public var commandlineArguments: CommandLineArguments?
        public var environmentVariables: [EnvironmentVariable]?
        public var language: String?
        public var region: String?

        public enum AttachmentLifetime: String {
            case keepAlways, keepNever
        }

        public var systemAttachmentLifetime: AttachmentLifetime?
        public var userAttachmentLifetime: AttachmentLifetime?

        public init(buildConfiguration: String,
                    macroExpansion: BuildableReference?,
                    testables: [TestableReference] = [],
                    preActions: [ExecutionAction] = [],
                    postActions: [ExecutionAction] = [],
                    selectedDebuggerIdentifier: String = XCScheme.defaultDebugger,
                    selectedLauncherIdentifier: String = XCScheme.defaultLauncher,
                    shouldUseLaunchSchemeArgsEnv: Bool = true,
                    codeCoverageEnabled: Bool = false,
                    enableAddressSanitizer: Bool = false,
                    enableASanStackUseAfterReturn: Bool = false,
                    enableThreadSanitizer: Bool = false,
                    enableUBSanitizer: Bool = false,
                    disableMainThreadChecker: Bool = false,
                    additionalOptions: [AdditionalOption] = [],
                    commandlineArguments: CommandLineArguments? = nil,
                    environmentVariables: [EnvironmentVariable]? = nil,
                    language: String? = nil,
                    region: String? = nil,
                    systemAttachmentLifetime: AttachmentLifetime? = nil,
                    userAttachmentLifetime: AttachmentLifetime? = nil) {
            self.buildConfiguration = buildConfiguration
            self.macroExpansion = macroExpansion
            self.testables = testables
            self.selectedDebuggerIdentifier = selectedDebuggerIdentifier
            self.selectedLauncherIdentifier = selectedLauncherIdentifier
            self.shouldUseLaunchSchemeArgsEnv = shouldUseLaunchSchemeArgsEnv
            self.codeCoverageEnabled = codeCoverageEnabled
            self.enableAddressSanitizer = enableAddressSanitizer
            self.enableASanStackUseAfterReturn = enableASanStackUseAfterReturn
            self.enableThreadSanitizer = enableThreadSanitizer
            self.enableUBSanitizer = enableUBSanitizer
            self.disableMainThreadChecker = disableMainThreadChecker
            self.additionalOptions = additionalOptions
            self.commandlineArguments = commandlineArguments
            self.environmentVariables = environmentVariables
            self.language = language
            self.region = region
            self.systemAttachmentLifetime = systemAttachmentLifetime
            self.userAttachmentLifetime = userAttachmentLifetime
            super.init(preActions, postActions)
        }

        override init(element: AEXMLElement) throws {
            buildConfiguration = element.attributes["buildConfiguration"] ?? TestAction.defaultBuildConfiguration
            selectedDebuggerIdentifier = element.attributes["selectedDebuggerIdentifier"] ?? XCScheme.defaultDebugger
            selectedLauncherIdentifier = element.attributes["selectedLauncherIdentifier"] ?? XCScheme.defaultLauncher
            shouldUseLaunchSchemeArgsEnv = element.attributes["shouldUseLaunchSchemeArgsEnv"].map { $0 == "YES" } ?? true
            codeCoverageEnabled = element.attributes["codeCoverageEnabled"] == "YES"
            enableAddressSanitizer = element.attributes["enableAddressSanitizer"] == "YES"
            enableASanStackUseAfterReturn = element.attributes["enableASanStackUseAfterReturn"] == "YES"
            enableThreadSanitizer = element.attributes["enableThreadSanitizer"] == "YES"
            enableUBSanitizer = element.attributes["enableUBSanitizer"] == "YES"
            disableMainThreadChecker = element.attributes["disableMainThreadChecker"] == "YES"
            testables = try element["Testables"]["TestableReference"]
                .all?
                .map(TestableReference.init) ?? []

            let buildableReferenceElement = element["MacroExpansion"]["BuildableReference"]
            if buildableReferenceElement.error == nil {
                macroExpansion = try BuildableReference(element: buildableReferenceElement)
            }

            additionalOptions = try element["AdditionalOptions"]["AdditionalOption"]
                .all?
                .map(AdditionalOption.init) ?? []

            let commandlineOptions = element["CommandLineArguments"]
            if commandlineOptions.error == nil {
                commandlineArguments = try CommandLineArguments(element: commandlineOptions)
            }

            let environmentVariables = element["EnvironmentVariables"]
            if environmentVariables.error == nil {
                self.environmentVariables = try EnvironmentVariable.parseVariables(from: environmentVariables)
            }

            language = element.attributes["language"]
            region = element.attributes["region"]

            systemAttachmentLifetime = element.attributes["systemAttachmentLifetime"]
                .flatMap(AttachmentLifetime.init(rawValue:))
            userAttachmentLifetime = element.attributes["userAttachmentLifetime"]
                .flatMap(AttachmentLifetime.init(rawValue:))
            try super.init(element: element)
        }

        fileprivate func xmlElement() -> AEXMLElement {
            var attributes: [String: String] = [:]
            attributes["buildConfiguration"] = buildConfiguration
            attributes["selectedDebuggerIdentifier"] = selectedDebuggerIdentifier
            attributes["selectedLauncherIdentifier"] = selectedLauncherIdentifier
            if let language = language {
                attributes["language"] = language
            }
            attributes["region"] = region
            attributes["shouldUseLaunchSchemeArgsEnv"] = shouldUseLaunchSchemeArgsEnv.xmlString
            if codeCoverageEnabled {
                attributes["codeCoverageEnabled"] = codeCoverageEnabled.xmlString
            }
            if enableAddressSanitizer {
                attributes["enableAddressSanitizer"] = enableAddressSanitizer.xmlString
            }
            if enableASanStackUseAfterReturn {
                attributes["enableASanStackUseAfterReturn"] = enableASanStackUseAfterReturn.xmlString
            }
            if enableThreadSanitizer {
                attributes["enableThreadSanitizer"] = enableThreadSanitizer.xmlString
            }
            if enableUBSanitizer {
                attributes["enableUBSanitizer"] = enableUBSanitizer.xmlString
            }
            if disableMainThreadChecker {
                attributes["disableMainThreadChecker"] = disableMainThreadChecker.xmlString
            }
            attributes["systemAttachmentLifetime"] = systemAttachmentLifetime?.rawValue
            if case .keepAlways? = userAttachmentLifetime {
                attributes["userAttachmentLifetime"] = userAttachmentLifetime?.rawValue
            }

            let element = AEXMLElement(name: "TestAction", value: nil, attributes: attributes)
            super.writeXML(parent: element)
            let testablesElement = element.addChild(name: "Testables")
            testables.forEach { testable in
                testablesElement.addChild(testable.xmlElement())
            }
            if let macroExpansion = macroExpansion {
                let macro = element.addChild(name: "MacroExpansion")
                macro.addChild(macroExpansion.xmlElement())
            }

            if let commandlineArguments = commandlineArguments {
                element.addChild(commandlineArguments.xmlElement())
            }

            if let environmentVariables = environmentVariables {
                element.addChild(EnvironmentVariable.xmlElement(from: environmentVariables))
            }

            let additionalOptionsElement = element.addChild(AEXMLElement(name: "AdditionalOptions"))
            additionalOptions.forEach { additionalOption in
                additionalOptionsElement.addChild(additionalOption.xmlElement())
            }
            return element
        }
    }

    public final class AnalyzeAction {
        // Xcode disables PreActions and PostActions for Analyze actions, so this Action
        // does not exetend SerialAction.
        private static let defaultBuildConfiguration = "Debug"

        public var buildConfiguration: String
        public init(buildConfiguration: String) {
            self.buildConfiguration = buildConfiguration
        }

        init(element: AEXMLElement) throws {
            buildConfiguration = element.attributes["buildConfiguration"] ?? AnalyzeAction.defaultBuildConfiguration
        }

        fileprivate func xmlElement() -> AEXMLElement {
            var attributes: [String: String] = [:]
            attributes["buildConfiguration"] = buildConfiguration
            return AEXMLElement(name: "AnalyzeAction", value: nil, attributes: attributes)
        }
    }

    public final class ArchiveAction: SerialAction {
        private static let defaultBuildConfiguration = "Release"

        public var buildConfiguration: String
        public var revealArchiveInOrganizer: Bool
        public var customArchiveName: String?
        public init(buildConfiguration: String,
                    revealArchiveInOrganizer: Bool,
                    customArchiveName: String? = nil,
                    preActions: [ExecutionAction] = [],
                    postActions: [ExecutionAction] = []) {
            self.buildConfiguration = buildConfiguration
            self.revealArchiveInOrganizer = revealArchiveInOrganizer
            self.customArchiveName = customArchiveName
            super.init(preActions, postActions)
        }

        override init(element: AEXMLElement) throws {
            buildConfiguration = element.attributes["buildConfiguration"] ?? ArchiveAction.defaultBuildConfiguration
            revealArchiveInOrganizer = element.attributes["revealArchiveInOrganizer"].map { $0 == "YES" } ?? true
            customArchiveName = element.attributes["customArchiveName"]
            try super.init(element: element)
        }

        fileprivate func xmlElement() -> AEXMLElement {
            var attributes: [String: String] = [:]
            attributes["buildConfiguration"] = buildConfiguration
            attributes["customArchiveName"] = customArchiveName
            attributes["revealArchiveInOrganizer"] = revealArchiveInOrganizer.xmlString
            let element = AEXMLElement(name: "ArchiveAction", value: nil, attributes: attributes)
            super.writeXML(parent: element)
            return element
        }
    }

    // MARK: - Properties

    public var buildAction: BuildAction?
    public var testAction: TestAction?
    public var launchAction: LaunchAction?
    public var profileAction: ProfileAction?
    public var analyzeAction: AnalyzeAction?
    public var archiveAction: ArchiveAction?
    public var lastUpgradeVersion: String?
    public var version: String?
    public var name: String

    // MARK: - Init

    /// Initializes the scheme reading the content from the disk.
    ///
    /// - Parameters:
    ///   - path: scheme path.
    public init(path: AbsolutePath) throws {
        if !path.exists {
            throw XCSchemeError.notFound(path: path)
        }
        name = path.lastComponentWithoutExtension
        let document = try AEXMLDocument(xml: try path.read())
        let scheme = document["Scheme"]
        lastUpgradeVersion = scheme.attributes["LastUpgradeVersion"]
        version = scheme.attributes["version"]
        buildAction = try BuildAction(element: scheme["BuildAction"])
        testAction = try TestAction(element: scheme["TestAction"])
        launchAction = try LaunchAction(element: scheme["LaunchAction"])
        analyzeAction = try AnalyzeAction(element: scheme["AnalyzeAction"])
        archiveAction = try ArchiveAction(element: scheme["ArchiveAction"])
        profileAction = try ProfileAction(element: scheme["ProfileAction"])
    }

    public init(name: String,
                lastUpgradeVersion: String?,
                version: String?,
                buildAction: BuildAction? = nil,
                testAction: TestAction? = nil,
                launchAction: LaunchAction? = nil,
                profileAction: ProfileAction? = nil,
                analyzeAction: AnalyzeAction? = nil,
                archiveAction: ArchiveAction? = nil) {
        self.name = name
        self.lastUpgradeVersion = lastUpgradeVersion
        self.version = version
        self.buildAction = buildAction
        self.testAction = testAction
        self.launchAction = launchAction
        self.profileAction = profileAction
        self.analyzeAction = analyzeAction
        self.archiveAction = archiveAction
    }
}

// MARK: - XCScheme Extension (Writable)

extension XCScheme: Writable {
    public func write(path: AbsolutePath, override: Bool) throws {
        let document = AEXMLDocument()
        var schemeAttributes: [String: String] = [:]
        schemeAttributes["LastUpgradeVersion"] = lastUpgradeVersion
        schemeAttributes["version"] = version
        let scheme = document.addChild(name: "Scheme", value: nil, attributes: schemeAttributes)
        if let buildAction = buildAction {
            scheme.addChild(buildAction.xmlElement())
        }
        if let testAction = testAction {
            scheme.addChild(testAction.xmlElement())
        }
        if let launchAction = launchAction {
            scheme.addChild(launchAction.xmlElement())
        }
        if let profileAction = profileAction {
            scheme.addChild(profileAction.xmlElement())
        }
        if let analyzeAction = analyzeAction {
            scheme.addChild(analyzeAction.xmlElement())
        }
        if let archiveAction = archiveAction {
            scheme.addChild(archiveAction.xmlElement())
        }

        if override && path.exists {
            try path.delete()
        }
        try path.write(document.xmlXcodeFormat)
    }
}

// MARK: - XCScheme Errors.

/// XCScheme Errors.
///
/// - notFound: returned when the .xcscheme cannot be found.
/// - missing: returned when there's a property missing in the .xcscheme.
public enum XCSchemeError: Error, CustomStringConvertible {
    case notFound(path: AbsolutePath)
    case missing(property: String)

    public var description: String {
        switch self {
        case let .notFound(path):
            return ".xcscheme couldn't be found at path \(path.asString)"
        case let .missing(property):
            return "Property \(property) missing"
        }
    }
}
