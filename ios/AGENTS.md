# Repository Guidelines

## Project Structure & Module Organization

HealthBuddy follows a layered architecture: `App → Feature(Impl) → Feature(Api) → Domain → Library`.

**App Layer** (`App/Sources/`):
- `AppMain/`: Application entry point (`HealthBuddyApp.swift`), root navigation (`RootView.swift`), splash screen, main TabView
- `Composition/`: Dependency injection setup (`AppComposition.swift`) - registers all domain services and feature builders
- Only layer allowed to depend on Feature `Impl` modules

**Feature Layer** (`Packages/Feature/`):
- Each feature split into two packages: `Feature[Name]Api` (protocols) and `Feature[Name]Impl` (implementation)
- Current features:
  - `FeatureAccount`: User registration, login, account management
  - `FeatureChat`: AI chat interface and conversation management
  - `FeatureHealthKit`: HealthKit authorization, dashboard, data visualization
- Features depend only on other Feature `Api` modules, never `Impl`
- Register via `[Name]Module.register()` in `AppComposition.bootstrap()`

**Domain Layer** (`Packages/Domain/`):
- Core business logic and cross-feature services
- Current domains:
  - `DomainAuth`: Authentication service, user model
  - `DomainChat`: AI chat service
  - `DomainHealth`: Health data services, HealthKit manager
- Export `[Name]DomainBootstrap.configure()` to register services into `ServiceManager`

**Library Layer** (`Packages/Library/`):
- Business-agnostic utilities
- Current libraries:
  - `ServiceLoader`: Dependency injection container (`ServiceManager`)
  - `Networking`: HTTP client wrapper
  - `ThemeKit`: App theming and styling

## Build, Test, and Development Commands

- `scripts/generate_project.sh` - Regenerates Xcode project via XcodeGen; run after adding modules or modifying `project.yml`
- `scripts/build.sh [--clean|--verbose]` - Builds for simulator (default: iPhone 17 Pro)
- `scripts/createModule.py -f [Name]` - Scaffolds a new Feature module (creates both Api and Impl packages)
- `scripts/createModule.py -d [Name]` - Scaffolds a new Domain module
- `scripts/createModule.py -l [Name]` - Scaffolds a new Library module

## Coding Style & Naming Conventions

**Package Naming**:
- Feature: `Feature[Name]Api`, `Feature[Name]Impl`
- Domain: `Domain[Name]`
- Library: `Library[Name]`
- **Critical**: Directory name, Package name, Product name, and Target name must match exactly

**Import Rules**:
- Domain: `import DomainAuth`, `import DomainHealth`, `import DomainChat`
- Library: `import LibraryServiceLoader`, `import LibraryNetworking`
- Feature: `import FeatureAccountApi`, `import FeatureAccountImpl`

**File Naming**:
- Feature API: `Feature[Name]Api.swift` (contains `Feature[Name]Buildable` protocol)
- Feature Builder: `[Name]Builder.swift`
- Feature Module: `[Name]Module.swift`
- Domain Bootstrap: `[Name]DomainBootstrap.swift`

Use Swift 5.9 conventions, 4-space indentation, and prefer `struct` + SwiftUI patterns. Keep files focused and single-purpose.

## Architecture Patterns

**Service Locator Pattern** (via `ServiceManager`):
```swift
// Registration (in Bootstrap)
manager.register(AuthenticationService.self) { AuthenticationServiceImpl() }

// Resolution (in usage)
let service = ServiceManager.shared.resolve(AuthenticationService.self)
```

**Feature Builder Pattern**:
```swift
// Api package defines protocol
public protocol FeatureAccountBuildable {
    func makeLoginView(onLoginSuccess: @escaping () -> Void) -> AnyView
}

// Impl package implements builder
public struct AccountBuilder: FeatureAccountBuildable {
    public func makeLoginView(onLoginSuccess: @escaping () -> Void) -> AnyView {
        AnyView(LoginView(onLoginSuccess: onLoginSuccess))
    }
}
```

**Module Registration**:
```swift
// Feature Impl exports registration
public enum AccountModule {
    public static func register(in manager: ServiceManager = .shared) {
        manager.register(FeatureAccountBuildable.self) { AccountBuilder() }
    }
}

// Called in AppComposition.bootstrap()
HealthDomainBootstrap.configure()
AuthDomainBootstrap.configure()
ChatDomainBootstrap.configure()
HealthKitModule.register()
AccountModule.register()
ChatModule.register()
```

## App Flow

1. Launch → `HealthBuddyApp.init()` → `AppComposition.bootstrap()`
2. Splash screen (1.5s) while checking authentication
3. If authenticated → MainTabView (AI Assistant, Health, Profile)
4. If not authenticated → AccountLandingView
5. Data persistence via SwiftData (models in Domain layer)

## Adding New Features

1. **Create module**: `scripts/createModule.py -f YourFeature`
2. **Define API**: Create `FeatureYourFeatureBuildable` protocol in Api package
3. **Implement builder**: Create `YourFeatureBuilder` in Impl package
4. **Register module**: Export `YourFeatureModule.register()` in Impl package
5. **Update project.yml**: Add both Api and Impl packages
6. **Register in AppComposition**: Import Impl and call `.register()`
7. **Regenerate**: `scripts/generate_project.sh`
8. **Build**: `scripts/build.sh`

## Testing Guidelines

- Add `Tests/` targets to new packages
- Use XCTest with descriptive `test_<behavior>` names
- Mock domain services via dependency inversion
- Run project tests: `xcodebuild test -project HealthBuddy.xcodeproj -scheme HealthBuddy`
- Run package tests: `swift test --package-path Packages/Feature/<Module>/Api`

## Commit & Pull Request Guidelines

- Follow conventional commits: `type: summary` (e.g., `feat: add chat feature`, `refactor: simplify module structure`)
- Keep commits scoped to single changes
- PRs should include:
  - Summary of changes
  - Screenshots for UI work
  - Test results
  - Migration notes for architectural changes

## HealthKit Configuration

- Entitlements: `App/HealthBuddy.entitlements`
- Usage descriptions: Configured in `project.yml`
- Authorization flow: `FeatureHealthKit` → `DomainHealth` → HealthKit framework
- HealthKit linked directly in `DomainHealth` module

## Common Pitfalls

1. **Package name mismatch**: Ensure directory, package, product, and target names are identical
2. **Wrong import prefix**: Use `DomainXxx` for domains, `LibraryXxx` for libraries
3. **Reverse dependencies**: Never depend downward (e.g., Domain depending on Feature)
4. **Missing regeneration**: Always run `scripts/generate_project.sh` after Package.swift changes
5. **Feature Impl coupling**: Features should only depend on other Feature Api modules
