#!/usr/bin/env bash
# Scaffold one vertical feature slice the way the User feature is built (AGENTS.md §1).
#
#   tools/new-feature.sh Invoice
#   tools/new-feature.sh PurchaseOrder
#
# Creates (Name=Invoice, S=arcana-ios/Sources, T=arcana-iosTests):
#   S/ArcanaDomain/Model/Invoice.swift                          domain model (+ mocks)
#   S/ArcanaDomain/Service/InvoiceService.swift                 service protocol (what the ViewModel sees)
#   S/ArcanaDomain/Service/impl/InvoiceServiceImpl.swift        validation + analytics over the repository
#   S/ArcanaData/Repository/InvoiceRepository.swift             repository protocol
#   S/ArcanaData/Repository/impl/OfflineFirstInvoiceRepositoryImpl.swift   local (SwiftData) first, remote best-effort
#   S/ArcanaData/Local/InvoiceLocalDao.swift + impl/InvoiceLocalDaoImpl.swift   SwiftData DAO
#   S/ArcanaData/Local/Entities/InvoiceEntity.swift             @Model entity <-> domain mapping
#   S/ArcanaData/Remote/InvoiceRemoteDao.swift + impl/InvoiceRemoteDaoImpl.swift  URLSession GET/POST/DELETE
#   S/ArcanaPresentation/Screens/Invoice/InvoiceListViewModel.swift   Input / Output / Effect
#   S/ArcanaPresentation/Screens/Invoice/InvoiceListView.swift
#   T/Mocks/MockInvoice{Repository,Service,LocalDao,RemoteDao}.swift
#   T/Domain/InvoiceServiceImplTests.swift, T/Presentation/InvoiceListViewModelTests.swift,
#   T/OfflineFirstInvoiceRepositoryTests.swift                   (Swift Testing, like the User tests)
# and edits the anchors: ArcanaCore/DI/AppDependencies.swift (DependencyValues key, storage,
# wiring in setup(), SwiftData schema — the ONLY place that names the *Impl types),
# Screens/User/AppRoute.swift (route case + id/title/analyticsName) and
# Screens/User/NavGraph.swift (navigateTo<Name>List + view builder case).
#
# No pbxproj edit is needed: the app and test targets use Xcode 16 synchronized folders
# (PBXFileSystemSynchronizedRootGroup), so every file under arcana-ios/ and arcana-iosTests/
# is compiled automatically.
#
# Every anchor must match exactly once, or the script stops before writing anything.
set -euo pipefail

[ $# -eq 1 ] || { echo "usage: $0 <PascalCaseName>   e.g. $0 Invoice" >&2; exit 1; }
NAME="$1"
[[ "$NAME" =~ ^[A-Z][a-z0-9]+([A-Z][a-z0-9]+)*$ ]] || { echo "name must be PascalCase (Invoice, PurchaseOrder)" >&2; exit 1; }
case "$NAME" in User|Main|AppRoute|Analytics|PendingChange) echo "$NAME already exists in the template" >&2; exit 1 ;; esac
command -v perl >/dev/null || { echo "perl is required" >&2; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
# Product folders are renamed by new-app.sh: find the app folder by its Sources/ArcanaCore.
APPDIR="$(cd "$ROOT" && ls -d */Sources/ArcanaCore 2>/dev/null | head -1 | cut -d/ -f1)"
[ -n "$APPDIR" ] || { echo "new-feature: no */Sources/ArcanaCore found under $ROOT" >&2; exit 1; }
TESTDIR="${APPDIR}Tests"
[ -d "$TESTDIR" ] || { echo "new-feature: test folder $TESTDIR not found" >&2; exit 1; }
MODULE="$(printf '%s' "$APPDIR" | tr -c 'A-Za-z0-9\n' '_')"     # Swift module = target name, '-' → '_'
CAMEL="$(printf '%s' "$NAME" | perl -pe 's/^([A-Z])/lc($1)/e')"
PLURAL="${NAME}s"
SNAKE="$(printf '%s' "$NAME" | perl -pe 's/(?<!^)([A-Z])/_$1/g; $_=lc')"

S="$APPDIR/Sources"
DI="$S/ArcanaCore/DI/AppDependencies.swift"
ROUTE="$S/ArcanaPresentation/Screens/User/AppRoute.swift"
NAV="$S/ArcanaPresentation/Screens/User/NavGraph.swift"
SCREEN="$S/ArcanaPresentation/Screens/$NAME"

# ---------------------------------------------------------------- preflight (no writes yet)
for f in "$S/ArcanaDomain/Model/$NAME.swift" "$S/ArcanaDomain/Service/${NAME}Service.swift" "$SCREEN"; do
    [ ! -e "$f" ] || { echo "new-feature: $f already exists" >&2; exit 1; }
done
need() { # file anchor-regex → exactly one match or die
    local n; n="$(perl -0ne '$c=()=/'"$2"'/gm; print $c' "$1")"
    [ "$n" = 1 ] || { echo "new-feature: anchor /$2/ found $n times in $1 (need 1) — the template changed; update tools/new-feature.sh" >&2; exit 1; }
}
need "$DI" '^        set \{ self\[UserRepositoryKey\.self\] = newValue \}\n    \}\n\}\n'
need "$DI" '^    static var userRepository: UserRepository\?\n\}\n'
need "$DI" '^\/\/\/ Configure live dependencies for the app\n'
need "$DI" '^        \/\/ Register all live dependencies\n'
need "$DI" '^            PendingChangeEntity\.self\n        \]\)'
need "$ROUTE" '^    case userList\n'
need "$ROUTE" '^        case \.userList:\n            return "userList"\n'
need "$ROUTE" '^        case \.userList:\n            return "Users"\n'
need "$ROUTE" '^        case \.userList:\n            return "user_list_screen"\n'
need "$NAV" '^    func navigateToUserList\(\) \{\n        push\(\.userList\)\n    \}\n'
need "$NAV" '^        case \.userList:\n            UserListView\(viewModel: UserListViewModel\(navGraph: navGraph\)\)\n'

# ---------------------------------------------------------------- generate files
# Templates use XName / xName / XNames / x_name; render() substitutes them.
render() { perl -pe "s/XNames/${PLURAL}/g; s/XName/${NAME}/g; s/xName/${CAMEL}/g; s/x_name/${SNAKE}/g; s/XMODULE/${MODULE}/g" > "$1"; }
mkdir -p "$SCREEN" "$TESTDIR/Mocks" "$TESTDIR/Domain" "$TESTDIR/Presentation"

render "$S/ArcanaDomain/Model/$NAME.swift" <<'EOF'
import Foundation

/// Domain model. Plain value type: no SwiftData, no networking (those live in ArcanaData).
struct XName: Identifiable, Hashable, Codable {
    let id: String
    var title: String
    var createdAt: Date
    var updatedAt: Date

    init(id: String = UUID().uuidString, title: String, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension XName {
    static var mockXNames: [XName] {
        (1...3).map { XName(id: "\($0)", title: "XName \($0)") }
    }
}
EOF

render "$S/ArcanaDomain/Service/${NAME}Service.swift" <<'EOF'
import Foundation

/// Business operations for XName. ViewModels depend on this protocol only.
protocol XNameService {
    func getXNames() async throws -> [XName]
    func createXName(_ xName: XName) async throws -> XName
    func deleteXName(_ xName: XName) async throws
    func refreshXNames() async throws -> [XName]
}
EOF

render "$S/ArcanaDomain/Service/impl/${NAME}ServiceImpl.swift" <<'EOF'
import Foundation

/// Validation + analytics over XNameRepository. Bound only in ArcanaCore/DI/AppDependencies.swift.
final class XNameServiceImpl: XNameService {

    private let repository: XNameRepository
    private let analyticsTracker: AnalyticsTracker

    init(repository: XNameRepository, analyticsTracker: AnalyticsTracker) {
        self.repository = repository
        self.analyticsTracker = analyticsTracker
    }

    func getXNames() async throws -> [XName] {
        try await track("getXNames") { try await repository.getXNames() }
    }

    func createXName(_ xName: XName) async throws -> XName {
        let title = xName.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            throw AppError.validationError(.E2003_REQUIRED_FIELD, field: "title", message: "Title is required")
        }
        var valid = xName
        valid.title = title
        return try await track("createXName") { try await repository.createXName(valid) }
    }

    func deleteXName(_ xName: XName) async throws {
        try await track("deleteXName") { try await repository.deleteXName(xName) }
    }

    func refreshXNames() async throws -> [XName] {
        try await track("refreshXNames") { try await repository.refreshXNames() }
    }

    private func track<T>(_ operation: String, _ body: () async throws -> T) async throws -> T {
        analyticsTracker.trackEvent(.networkRequestStarted, params: ["operation": operation])
        do {
            let result = try await body()
            analyticsTracker.trackEvent(.networkRequestSuccess, params: ["operation": operation])
            return result
        } catch {
            let appError = AppError.from(error)
            analyticsTracker.trackAppError(appError, context: ["operation": operation])
            throw appError
        }
    }
}
EOF

render "$S/ArcanaData/Repository/${NAME}Repository.swift" <<'EOF'
import Foundation

/// Data access for XName (local SwiftData + remote API). Implemented in Repository/impl/.
protocol XNameRepository {
    func getXNames() async throws -> [XName]
    func createXName(_ xName: XName) async throws -> XName
    func deleteXName(_ xName: XName) async throws
    func refreshXNames() async throws -> [XName]
}
EOF

render "$S/ArcanaData/Repository/impl/OfflineFirst${NAME}RepositoryImpl.swift" <<'EOF'
import Foundation

/// Offline-first: reads come from SwiftData and fall back to / refresh from remote;
/// writes go to SwiftData first and are pushed to remote best-effort.
/// (The User repository additionally queues failed writes in PendingChangeEntity for later
/// sync — add that here when this feature needs guaranteed delivery.)
final class OfflineFirstXNameRepositoryImpl: XNameRepository {

    private let localDataSource: XNameLocalDao
    private let remoteDataSource: XNameRemoteDao
    private let analyticsTracker: AnalyticsTracker

    init(localDataSource: XNameLocalDao, remoteDataSource: XNameRemoteDao, analyticsTracker: AnalyticsTracker) {
        self.localDataSource = localDataSource
        self.remoteDataSource = remoteDataSource
        self.analyticsTracker = analyticsTracker
    }

    func getXNames() async throws -> [XName] {
        let local = try await localDataSource.getXNames()
        if !local.isEmpty { return local }
        do {
            return try await refreshXNames()
        } catch {
            analyticsTracker.trackError(error, context: ["operation": "getXNames", "fallback": "local"])
            return local
        }
    }

    func createXName(_ xName: XName) async throws -> XName {
        try await localDataSource.saveXName(xName)
        do {
            let saved = try await remoteDataSource.createXName(xName)
            try await localDataSource.saveXName(saved)
            return saved
        } catch {
            analyticsTracker.trackError(error, context: ["operation": "createXName", "offline": true])
            return xName
        }
    }

    func deleteXName(_ xName: XName) async throws {
        try await localDataSource.deleteXName(id: xName.id)
        do {
            try await remoteDataSource.deleteXName(id: xName.id)
        } catch {
            analyticsTracker.trackError(error, context: ["operation": "deleteXName", "offline": true])
        }
    }

    func refreshXNames() async throws -> [XName] {
        let remote = try await remoteDataSource.getXNames()
        try await localDataSource.saveXNames(remote)
        return remote
    }
}
EOF

render "$S/ArcanaData/Local/${NAME}LocalDao.swift" <<'EOF'
import Foundation

/// Local (SwiftData) data access for XName.
protocol XNameLocalDao {
    func getXNames() async throws -> [XName]
    func saveXName(_ xName: XName) async throws
    func saveXNames(_ xNames: [XName]) async throws
    func deleteXName(id: String) async throws
}
EOF

render "$S/ArcanaData/Local/Entities/${NAME}Entity.swift" <<'EOF'
import Foundation
import SwiftData

/// SwiftData model for XName. Registered in AppDependencies.createModelContainer().
@Model
final class XNameEntity {
    @Attribute(.unique) var id: String
    var title: String
    var createdAt: Date
    var updatedAt: Date

    init(id: String, title: String, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func toDomain() -> XName {
        XName(id: id, title: title, createdAt: createdAt, updatedAt: updatedAt)
    }

    static func from(_ xName: XName) -> XNameEntity {
        XNameEntity(id: xName.id, title: xName.title, createdAt: xName.createdAt, updatedAt: xName.updatedAt)
    }

    func update(from xName: XName) {
        title = xName.title
        updatedAt = xName.updatedAt
    }
}
EOF

render "$S/ArcanaData/Local/impl/${NAME}LocalDaoImpl.swift" <<'EOF'
import Foundation
import SwiftData

/// SwiftData implementation of XNameLocalDao.
final class XNameLocalDaoImpl: XNameLocalDao {

    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    private var context: ModelContext { modelContainer.mainContext }

    func getXNames() async throws -> [XName] {
        let descriptor = FetchDescriptor<XNameEntity>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func saveXName(_ xName: XName) async throws {
        try upsert(xName)
        try context.save()
    }

    func saveXNames(_ xNames: [XName]) async throws {
        for xName in xNames { try upsert(xName) }
        try context.save()
    }

    func deleteXName(id: String) async throws {
        let descriptor = FetchDescriptor<XNameEntity>(predicate: #Predicate { $0.id == id })
        for entity in try context.fetch(descriptor) { context.delete(entity) }
        try context.save()
    }

    private func upsert(_ xName: XName) throws {
        let id = xName.id
        let descriptor = FetchDescriptor<XNameEntity>(predicate: #Predicate { $0.id == id })
        if let entity = try context.fetch(descriptor).first {
            entity.update(from: xName)
        } else {
            context.insert(XNameEntity.from(xName))
        }
    }
}
EOF

render "$S/ArcanaData/Remote/${NAME}RemoteDao.swift" <<'EOF'
import Foundation

/// Remote data access for XName.
protocol XNameRemoteDao {
    func getXNames() async throws -> [XName]
    func createXName(_ xName: XName) async throws -> XName
    func deleteXName(id: String) async throws
}
EOF

render "$S/ArcanaData/Remote/impl/${NAME}RemoteDaoImpl.swift" <<'EOF'
import Foundation

/// REST implementation of XNameRemoteDao against AppConstants.API.baseURL + "/x_names".
/// Replace the path / DTO mapping with your backend's contract.
final class XNameRemoteDaoImpl: XNameRemoteDao {

    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder = {
        let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601; return d
    }()
    private let encoder: JSONEncoder = {
        let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601; return e
    }()

    init(baseURL: String = AppConstants.API.baseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func getXNames() async throws -> [XName] {
        let data = try await send(try request("GET", path: "/x_names"))
        return try decoder.decode([XName].self, from: data)
    }

    func createXName(_ xName: XName) async throws -> XName {
        var req = try request("POST", path: "/x_names")
        req.httpBody = try encoder.encode(xName)
        return try decoder.decode(XName.self, from: try await send(req))
    }

    func deleteXName(id: String) async throws {
        _ = try await send(try request("DELETE", path: "/x_names/\(id)"))
    }

    private func request(_ method: String, path: String) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else {
            throw AppError.unknownError(.E9000_UNKNOWN, message: "Invalid URL \(baseURL + path)", underlyingError: nil)
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return req
    }

    private func send(_ req: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw AppError.fromHTTPResponse(statusCode: status, data: data)
        }
        return data
    }
}
EOF

render "$SCREEN/${NAME}ListViewModel.swift" <<'EOF'
import Foundation
import Observation
import Dependencies

/// XName list ViewModel — Input / Output / Effect, like UserListViewModel.
@MainActor
@Observable
final class XNameListViewModel {

    // MARK: - Input
    enum Input {
        case loadInitial
        case refresh
        case create(title: String)
        case delete(XName)
    }

    // MARK: - Effect
    enum Effect {
        case showError(AppError)
        case showSuccess(String)
    }

    // MARK: - Output
    struct Output {
        var xNames: [XName] = []
        var isLoading: Bool = false
        var errorMessage: String?
    }

    private(set) var output = Output()

    // MARK: - Dependencies (injected via swift-dependencies)
    @ObservationIgnored
    @Dependency(\.xNameService) var xNameService

    @ObservationIgnored
    @Dependency(\.analyticsTracker) var analyticsTracker

    @ObservationIgnored
    private var navGraph: NavGraph?

    init(navGraph: NavGraph? = nil) {
        self.navGraph = navGraph
    }

    func input(_ action: Input) async -> Effect? {
        switch action {
        case .loadInitial:
            analyticsTracker.trackScreen("x_name_list_screen")
            return await load { try await self.xNameService.getXNames() }
        case .refresh:
            return await load { try await self.xNameService.refreshXNames() }
        case .create(let title):
            return await mutate("XName created") {
                let created = try await self.xNameService.createXName(XName(title: title))
                self.output.xNames.insert(created, at: 0)
            }
        case .delete(let xName):
            return await mutate("XName deleted") {
                try await self.xNameService.deleteXName(xName)
                self.output.xNames.removeAll { $0.id == xName.id }
            }
        }
    }

    private func load(_ fetch: () async throws -> [XName]) async -> Effect? {
        output.isLoading = true
        output.errorMessage = nil
        defer { output.isLoading = false }
        do {
            output.xNames = try await fetch()
            return nil
        } catch {
            return fail(error)
        }
    }

    private func mutate(_ success: String, _ body: () async throws -> Void) async -> Effect? {
        output.errorMessage = nil
        do {
            try await body()
            return .showSuccess(success)
        } catch {
            return fail(error)
        }
    }

    private func fail(_ error: Error) -> Effect {
        let appError = AppError.from(error)
        output.errorMessage = appError.message
        analyticsTracker.trackAppError(appError, context: ["screen": "x_name_list"])
        return .showError(appError)
    }
}
EOF

render "$SCREEN/${NAME}ListView.swift" <<'EOF'
import SwiftUI

/// Renders XNameListViewModel.output and sends Input; never calls a service directly.
struct XNameListView: View {
    @State var viewModel: XNameListViewModel
    @State private var newTitle = ""
    @State private var message: String?

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("New XName", text: $newTitle)
                        .accessibilityIdentifier("XNameTitleField")
                    Button("Add") {
                        let title = newTitle
                        Task { handle(await viewModel.input(.create(title: title))); newTitle = "" }
                    }
                    .accessibilityIdentifier("AddXNameButton")
                }
            }
            Section {
                ForEach(viewModel.output.xNames) { xName in
                    Text(xName.title)
                }
                .onDelete { offsets in
                    let items = offsets.map { viewModel.output.xNames[$0] }
                    Task { for item in items { handle(await viewModel.input(.delete(item))) } }
                }
            }
        }
        .overlay { if viewModel.output.isLoading { ProgressView() } }
        .refreshable { handle(await viewModel.input(.refresh)) }
        .task { handle(await viewModel.input(.loadInitial)) }
        .alert(message ?? "", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {}
        .navigationTitle("XNames")
    }

    private func handle(_ effect: XNameListViewModel.Effect?) {
        switch effect {
        case .showError(let error): message = error.message
        case .showSuccess(let text): message = text
        case nil: break
        }
    }
}
EOF

# ---------------------------------------------------------------- tests (mirror the User tests)
render "$TESTDIR/Mocks/Mock${NAME}Repository.swift" <<'EOF'
import Foundation
@testable import XMODULE

final class MockXNameRepository: XNameRepository {
    var xNames: [XName] = []
    var shouldThrowError: AppError?
    var getCallCount = 0
    var createCallCount = 0
    var deleteCallCount = 0

    func getXNames() async throws -> [XName] {
        getCallCount += 1
        if let error = shouldThrowError { throw error }
        return xNames
    }

    func createXName(_ xName: XName) async throws -> XName {
        createCallCount += 1
        if let error = shouldThrowError { throw error }
        xNames.append(xName)
        return xName
    }

    func deleteXName(_ xName: XName) async throws {
        deleteCallCount += 1
        if let error = shouldThrowError { throw error }
        xNames.removeAll { $0.id == xName.id }
    }

    func refreshXNames() async throws -> [XName] {
        try await getXNames()
    }
}
EOF

render "$TESTDIR/Mocks/Mock${NAME}Service.swift" <<'EOF'
import Foundation
@testable import XMODULE

final class MockXNameService: XNameService {
    var xNamesToReturn: [XName] = []
    var shouldThrowError: AppError?

    func getXNames() async throws -> [XName] {
        if let error = shouldThrowError { throw error }
        return xNamesToReturn
    }

    func createXName(_ xName: XName) async throws -> XName {
        if let error = shouldThrowError { throw error }
        return xName
    }

    func deleteXName(_ xName: XName) async throws {
        if let error = shouldThrowError { throw error }
    }

    func refreshXNames() async throws -> [XName] {
        try await getXNames()
    }
}
EOF

render "$TESTDIR/Mocks/Mock${NAME}LocalDao.swift" <<'EOF'
import Foundation
@testable import XMODULE

final class MockXNameLocalDao: XNameLocalDao {
    var stored: [XName] = []

    func getXNames() async throws -> [XName] { stored }

    func saveXName(_ xName: XName) async throws {
        stored.removeAll { $0.id == xName.id }
        stored.append(xName)
    }

    func saveXNames(_ xNames: [XName]) async throws {
        for xName in xNames { try await saveXName(xName) }
    }

    func deleteXName(id: String) async throws {
        stored.removeAll { $0.id == id }
    }
}
EOF

render "$TESTDIR/Mocks/Mock${NAME}RemoteDao.swift" <<'EOF'
import Foundation
@testable import XMODULE

final class MockXNameRemoteDao: XNameRemoteDao {
    var remote: [XName] = []
    var shouldThrowError: AppError?
    var deletedIds: [String] = []

    func getXNames() async throws -> [XName] {
        if let error = shouldThrowError { throw error }
        return remote
    }

    func createXName(_ xName: XName) async throws -> XName {
        if let error = shouldThrowError { throw error }
        remote.append(xName)
        return xName
    }

    func deleteXName(id: String) async throws {
        if let error = shouldThrowError { throw error }
        deletedIds.append(id)
    }
}
EOF

render "$TESTDIR/Domain/${NAME}ServiceImplTests.swift" <<'EOF'
import Testing
import Foundation
@testable import XMODULE

struct XNameServiceImplTests {

    func makeTestDependencies() -> (service: XNameServiceImpl, repository: MockXNameRepository, analytics: MockAnalyticsTracker) {
        let repository = MockXNameRepository()
        let analytics = MockAnalyticsTracker()
        return (XNameServiceImpl(repository: repository, analyticsTracker: analytics), repository, analytics)
    }

    @Test("getXNames returns items from repository and tracks analytics")
    func testGetXNames() async throws {
        let (service, repository, analytics) = makeTestDependencies()
        repository.xNames = XName.mockXNames

        let items = try await service.getXNames()

        #expect(items.count == 3)
        #expect(repository.getCallCount == 1)
        #expect(analytics.trackedEvents.map(\.event) == [.networkRequestStarted, .networkRequestSuccess])
    }

    @Test("createXName rejects an empty title without touching the repository")
    func testCreateValidation() async throws {
        let (service, repository, _) = makeTestDependencies()

        await #expect(throws: AppError.self) {
            _ = try await service.createXName(XName(title: "   "))
        }
        #expect(repository.createCallCount == 0)
    }

    @Test("repository errors are tracked and rethrown")
    func testErrorTracked() async throws {
        let (service, repository, analytics) = makeTestDependencies()
        repository.shouldThrowError = AppError.networkError(.E1000_NO_CONNECTION, message: "offline", isRetryable: true, underlyingError: nil)

        await #expect(throws: AppError.self) { _ = try await service.getXNames() }
        #expect(analytics.trackedAppErrors.count == 1)
    }
}
EOF

render "$TESTDIR/Presentation/${NAME}ListViewModelTests.swift" <<'EOF'
import Testing
import Foundation
import Dependencies
@testable import XMODULE

@MainActor
struct XNameListViewModelTests {

    private func makeViewModel(_ service: MockXNameService) -> XNameListViewModel {
        withDependencies {
            $0.xNameService = service
            $0.analyticsTracker = MockAnalyticsTracker()
        } operation: {
            XNameListViewModel()
        }
    }

    @Test("starts empty")
    func testInitialState() {
        let viewModel = makeViewModel(MockXNameService())
        #expect(viewModel.output.xNames.isEmpty)
        #expect(viewModel.output.isLoading == false)
    }

    @Test("loadInitial fills output")
    func testLoadInitial() async {
        let service = MockXNameService()
        service.xNamesToReturn = XName.mockXNames
        let viewModel = makeViewModel(service)

        let effect = await viewModel.input(.loadInitial)

        #expect(effect == nil)
        #expect(viewModel.output.xNames.count == 3)
    }

    @Test("a failing load returns showError and sets errorMessage")
    func testLoadError() async {
        let service = MockXNameService()
        service.shouldThrowError = AppError.networkError(.E1000_NO_CONNECTION, message: "offline", isRetryable: true, underlyingError: nil)
        let viewModel = makeViewModel(service)

        let effect = await viewModel.input(.loadInitial)

        guard case .showError = effect else { Issue.record("expected showError, got \(String(describing: effect))"); return }
        #expect(viewModel.output.errorMessage != nil)
    }

    @Test("create inserts, delete removes")
    func testCreateDelete() async {
        let viewModel = makeViewModel(MockXNameService())

        _ = await viewModel.input(.create(title: "First"))
        #expect(viewModel.output.xNames.map(\.title) == ["First"])

        _ = await viewModel.input(.delete(viewModel.output.xNames[0]))
        #expect(viewModel.output.xNames.isEmpty)
    }
}
EOF

render "$TESTDIR/OfflineFirst${NAME}RepositoryTests.swift" <<'EOF'
import Testing
import Foundation
@testable import XMODULE

struct OfflineFirstXNameRepositoryTests {

    func make() -> (OfflineFirstXNameRepositoryImpl, MockXNameLocalDao, MockXNameRemoteDao) {
        let local = MockXNameLocalDao()
        let remote = MockXNameRemoteDao()
        let repository = OfflineFirstXNameRepositoryImpl(localDataSource: local, remoteDataSource: remote, analyticsTracker: MockAnalyticsTracker())
        return (repository, local, remote)
    }

    @Test("empty local store is filled from remote")
    func testFetchFromRemote() async throws {
        let (repository, local, remote) = make()
        remote.remote = XName.mockXNames

        let items = try await repository.getXNames()

        #expect(items.count == 3)
        #expect(local.stored.count == 3)
    }

    @Test("offline: create is kept locally")
    func testCreateOffline() async throws {
        let (repository, local, remote) = make()
        remote.shouldThrowError = AppError.networkError(.E1000_NO_CONNECTION, message: "offline", isRetryable: true, underlyingError: nil)

        _ = try await repository.createXName(XName(title: "Offline"))

        #expect(local.stored.map(\.title) == ["Offline"])
    }

    @Test("offline: get falls back to local without throwing")
    func testGetOffline() async throws {
        let (repository, _, remote) = make()
        remote.shouldThrowError = AppError.networkError(.E1000_NO_CONNECTION, message: "offline", isRetryable: true, underlyingError: nil)

        let items = try await repository.getXNames()
        #expect(items.isEmpty)
    }
}
EOF

# ---------------------------------------------------------------- anchors
export NAME CAMEL PLURAL SNAKE
perl -0pi -e '
  s/^(        set \{ self\[UserRepositoryKey\.self\] = newValue \}\n    \}\n)(\}\n)/$1\n    var $ENV{CAMEL}Service: $ENV{NAME}Service {\n        get { self[$ENV{NAME}ServiceKey.self] }\n        set { self[$ENV{NAME}ServiceKey.self] = newValue }\n    }\n$2/m;
  s/^(    static var userRepository: UserRepository\?\n)(\}\n)/$1    static var $ENV{CAMEL}Service: $ENV{NAME}Service?\n$2/m;
  s/^(\/\/\/ Configure live dependencies for the app\n)/private enum $ENV{NAME}ServiceKey: DependencyKey {\n    static var liveValue: $ENV{NAME}Service {\n        guard let instance = DependencyStorage.$ENV{CAMEL}Service else {\n            fatalError("$ENV{NAME}Service not configured. Call AppDependencies.setup() in your App init.")\n        }\n        return instance\n    }\n}\n\n$1/m;
  s/^(        \/\/ Register all live dependencies\n)/        \/\/ $ENV{NAME} feature (tools\/new-feature.sh): local + remote DAO -> repository -> service\n        let $ENV{CAMEL}Repository = OfflineFirst$ENV{NAME}RepositoryImpl(\n            localDataSource: $ENV{NAME}LocalDaoImpl(modelContainer: modelContainer),\n            remoteDataSource: $ENV{NAME}RemoteDaoImpl(),\n            analyticsTracker: analyticsTracker\n        )\n        DependencyStorage.$ENV{CAMEL}Service = $ENV{NAME}ServiceImpl(\n            repository: $ENV{CAMEL}Repository,\n            analyticsTracker: analyticsTracker\n        )\n\n$1/m;
  s/^(            PendingChangeEntity\.self)(\n        \]\))/$1,\n            $ENV{NAME}Entity.self$2/m;
' "$DI"
perl -0pi -e '
  s/^(    case userList\n)/$1    case $ENV{CAMEL}List\n/m;
  s/^(        case \.userList:\n            return "userList"\n)/$1        case .$ENV{CAMEL}List:\n            return "$ENV{CAMEL}List"\n/m;
  s/^(        case \.userList:\n            return "Users"\n)/$1        case .$ENV{CAMEL}List:\n            return "$ENV{PLURAL}"\n/m;
  s/^(        case \.userList:\n            return "user_list_screen"\n)/$1        case .$ENV{CAMEL}List:\n            return "$ENV{SNAKE}_list_screen"\n/m;
' "$ROUTE"
perl -0pi -e '
  s/^(    func navigateToUserList\(\) \{\n        push\(\.userList\)\n    \}\n)/$1\n    \/\/\/ Navigate to $ENV{NAME} list\n    func navigateTo$ENV{NAME}List() {\n        push(.$ENV{CAMEL}List)\n    }\n/m;
  s/^(        case \.userList:\n            UserListView\(viewModel: UserListViewModel\(navGraph: navGraph\)\)\n)/$1\n        case .$ENV{CAMEL}List:\n            $ENV{NAME}ListView(viewModel: $ENV{NAME}ListViewModel(navGraph: navGraph))\n/m;
' "$NAV"

grep -q "${NAME}ServiceKey" "$DI" && grep -q "${NAME}Entity.self" "$DI" && grep -q "case .${CAMEL}List" "$ROUTE" && grep -q "navigateTo${NAME}List" "$NAV" \
    || { echo "new-feature: an anchor edit did not apply — inspect git diff" >&2; exit 1; }

echo "new-feature: ${NAME} slice created (module ${MODULE}). Entry point: navGraph.navigateTo${NAME}List()."
echo "next: build + test (AGENTS.md §5), then tools/arch-check.sh"
