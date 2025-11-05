# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HealthBuddy is a modular iOS demo collection platform built with SwiftUI and Swift Package Manager (SPM). The project uses XcodeGen for project generation and follows a clean architecture pattern with strict layer separation.

The app serves as a showcase for various iOS features and functionalities. Currently includes:
- **HealthKit Demo**: Health data tracking and visualization

There is one app target: `HealthBuddy`, sharing the unified codebase.

## Current Module Structure

After simplification (October 2025), the project structure is:

```
Packages/
├── Domain/
│   └── Health/
│       ├── Package.swift
│       └── Sources/HealthDomain/
│           ├── HealthDomainBootstrap.swift    # Domain service registration
│           ├── HealthDataModels.swift         # SwiftData models
│           ├── HealthKitManager.swift         # HealthKit wrapper
│           └── ServiceContracts.swift         # Service protocols
│
├── Feature/
│   ├── DemoList/
│   │   ├── FeatureDemoListApi/               # API protocols
│   │   └── FeatureDemoListImpl/              # Demo list implementation
│   └── HealthKit/                            # Unified HealthKit feature
│       ├── FeatureHealthKitApi/
│       │   └── Sources/FeatureHealthKitApi/
│       │       └── FeatureHealthKitAPI.swift  # Builder protocol
│       └── FeatureHealthKitImpl/
│           └── Sources/FeatureHealthKitImpl/
│               ├── HealthKitModule.swift       # Module registration
│               ├── HealthKitBuilder.swift      # Builder implementation
│               ├── HealthKitDemoCoordinator.swift
│               ├── AuthorizationFeatureView.swift
│               ├── DashboardFeatureView.swift
│               ├── CareKitChartView.swift
│               └── CustomChartStyle.swift
│
└── Library/
    ├── ServiceLoader/
    │   └── Sources/ServiceLoader/
    │       └── ServiceManager.swift           # Service locator
    └── DemoRegistry/
        └── Sources/LibraryDemoregistry/
            ├── DemoRegistry.swift             # Demo registry
            ├── DemoItem.swift                 # Demo item model
            └── DemoCategory.swift             # Demo categories
```

### Key Changes from Previous Version
- **Merged**: `FeatureAuthorization` + `FeatureDashboard` → `FeatureHealthKit`
- **Merged**: `LibraryHealthKit` → `DomainHealth`
- **Unified**: HealthKit functionality now consolidated in single Feature module

## Build and Project Generation

### Generate Xcode Project
After modifying any `Package.swift` files or adding new modules, regenerate the Xcode project:
```bash
scripts/generate_project.sh
```

### Quick Build (Recommended)
Use the build script to quickly verify code changes:
```bash
scripts/build.sh                    # Quick build for iPhone 17 Pro
scripts/build.sh --clean            # Clean build
scripts/build.sh --verbose          # Detailed output
scripts/build.sh -d "iPhone 16 Pro" # Different simulator
```

The build script provides:
- Fast incremental builds
- Clear success/failure indicators
- Build time tracking
- Useful for CI/CD or pre-commit validation

### Build and Run in Xcode
Open `HealthBuddy.xcodeproj` in Xcode and build normally. The project requires:
- iOS 17.0+
- Xcode 15.0+
- XcodeGen installed (`brew install xcodegen`)

## Architecture

The codebase follows a strict **layered modular architecture** with dependency rules flowing downward:

```
App → Feature (impl) → Feature (api) → Domain → Library
```

### Layer Responsibilities

**App** (`App/Sources/`)
- App entry point (`HealthBuddyApp.swift`)
- Composition root (`AppComposition.swift`) - registers all feature implementations
- Root navigation (`RootView.swift`)
- Only layer allowed to depend on Feature `impl` modules

**Feature** (`Packages/Feature/`)
- Each feature has two separate directories: `Feature[Name]Api` and `Feature[Name]Impl`
- **Important**: Directory names must match the package name exactly (e.g., `FeatureAuthorizationApi`, not just `api`)
- `Feature[Name]Api` packages: Protocol definitions only (e.g., `FeatureAuthorizationBuildable`)
- `Feature[Name]Impl` packages: Concrete implementations, ViewModels, Views, and business logic
- Features can only depend on other Feature `Api` modules (never `Impl`)
- Current features:
  - **DemoList**: Main demo list UI with search and categorization
  - **HealthKit**: Comprehensive Health data tracking and visualization (includes authorization, dashboard, and demo coordinator)

**Domain** (`Packages/Domain/`)
- Core business logic and cross-feature domain services
- Example: `HealthDomain` - contains `AuthorizationService`, `HealthDataService`, and `HealthKitManager`
- Bootstrap modules configure and register domain services into `ServiceManager`
- Integrates HealthKit framework directly (no separate LibraryHealthKit module)

**Library** (`Packages/Library/`)
- Business-agnostic utilities and wrappers
- Examples:
  - `ServiceLoader`: Thread-safe service locator (`ServiceManager`)
  - `DemoRegistry`: Demo registration system with `DemoRegistry`, `DemoItem`, and `DemoCategory`

### Dependency Injection Pattern

The app uses a custom service locator pattern (`ServiceManager` from `LibraryServiceLoader`):

1. **Registration** happens in bootstrap modules during app launch:
   - `HealthDomainBootstrap.configure()` - registers domain services
   - `HealthKitModule.register()` - registers feature builder and demo
   - All called from `AppComposition.bootstrap()` in `HealthBuddyApp.init()`

2. **Resolution** happens at view initialization or in constructors:
   ```swift
   let service = ServiceManager.shared.resolve(AuthorizationService.self)
   ```

3. **Protocol-based contracts**: Features depend on protocols (from api modules), not concrete implementations

## Creating New Modules

Use the provided Python script to scaffold new modules:

```bash
# Create a Feature module (generates both api and impl)
scripts/createModule.py -f FeatureName

# Create a Domain module
scripts/createModule.py -d DomainName

# Create a Library module
scripts/createModule.py -l LibraryName
```

After creating modules:
1. The script generates Package.swift with proper structure
2. Update `project.yml` to add the new package and dependencies
3. Run `scripts/generate_project.sh` to regenerate the Xcode project

## Data Flow

1. **App Launch**: `HealthBuddyApp` → `AppComposition.bootstrap()` registers all services and demos
2. **Navigation**: `RootView` follows the route: `.splash` → `.demoList` → `.demo(demoId)`
3. **Demo Display**: Demos are built dynamically via `DemoRegistry.shared.getDemo(by:)?.buildView()`
4. **Feature Display**: Features expose views via builder protocols (e.g., `makeAuthorizationView()`)
5. **Data Persistence**: Uses SwiftData with models defined in Domain layer (`HealthSection`, `HealthRow`)

## HealthKit Integration

- Requires HealthKit entitlements (configured in `App/HealthBuddy.entitlements`)
- Usage descriptions defined in `project.yml`:
  - `NSHealthShareUsageDescription`
  - `NSHealthUpdateUsageDescription`
- Authorization flow handled by `FeatureHealthKit` → `DomainHealth` → HealthKit framework
- HealthKit framework is directly linked in `DomainHealth` module
- No separate LibraryHealthKit module (simplified architecture)

## Important Patterns

### Feature Registration Pattern
Each feature `impl` module exports a registration function:
```swift
public enum FeatureModule {
    public static func register(in manager: ServiceManager = .shared) {
        // 1. Register builder to ServiceManager
        manager.register(FeatureBuildable.self) { FeatureBuilder() }

        // 2. Register demo to DemoRegistry (for demo features)
        let demoItem = DemoItem(
            id: "demo-id",
            title: "Demo Title",
            description: "Demo description",
            category: .systemFrameworks,
            iconName: "heart.fill",
            buildView: { AnyView(DemoView()) }
        )
        DemoRegistry.shared.register(demoItem)
    }
}
```

### Feature Builder Pattern
Features expose views via builder protocols:
```swift
public protocol FeatureHealthKitBuildable {
    func makeAuthorizationView(onAuthorized: @escaping () -> Void) -> AnyView
    func makeDashboardView() -> AnyView
    func makeHealthKitDemoView() -> AnyView
}
```

### Bootstrap Pattern
Domain modules export a `configure()` function that registers services:
```swift
public enum DomainBootstrap {
    public static func configure(manager: ServiceManager = .shared) {
        // register services
    }
}
```

### Demo Registration Pattern
Demo features register themselves to both ServiceManager and DemoRegistry:
```swift
public enum HealthKitModule {
    public static func register(in manager: ServiceManager = .shared) {
        // 1. Register builder to ServiceManager
        manager.register(FeatureHealthKitBuildable.self) { HealthKitBuilder() }

        // 2. Register demo item to DemoRegistry
        let demoItem = DemoItem(
            id: "healthkit-demo",
            title: "HealthKit Demo",
            description: "Health data tracking and visualization",
            category: .systemFrameworks,
            iconName: "heart.fill",
            buildView: { AnyView(HealthKitDemoCoordinator()) }
        )
        DemoRegistry.shared.register(demoItem)
    }
}
```

## File Naming Conventions

- Feature API protocols: `Feature[Name]Api.swift`, containing `Feature[Name]Buildable`
- Feature modules: `Feature[Name]Module.swift` for registration
- Domain bootstraps: `[Domain]Bootstrap.swift`
- Service contracts: `ServiceContracts.swift` in Domain modules
- Data models: `[Domain]DataModels.swift` or descriptive names

## Common Tasks

### Adding a New Demo Feature

**Step 1: Create the Feature Module**
```bash
scripts/createModule.py -f YourDemo
```

This creates:
- `Packages/Feature/Yourdemo/FeatureYourdemoApi/` - API definitions
- `Packages/Feature/Yourdemo/FeatureYourdemoImpl/` - Implementation

**Step 2: Rename Directories (Important!)**
```bash
cd Packages/Feature/Yourdemo
mv api FeatureYourdemoApi
mv impl FeatureYourdemoImpl
```

**Step 3: Update Package.swift Files**

In `FeatureYourdemoApi/Package.swift`:
```swift
let package = Package(
    name: "FeatureYourdemoApi",  // Must match directory name!
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "FeatureYourdemoApi", targets: ["FeatureYourdemoApi"]) ],
    targets: [
        .target(name: "FeatureYourdemoApi", path: "Sources")
    ]
)
```

In `FeatureYourdemoImpl/Package.swift`:
```swift
let package = Package(
    name: "FeatureYourdemoImpl",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "FeatureYourdemoImpl", targets: ["FeatureYourdemoImpl"]) ],
    dependencies: [
        .package(name: "FeatureYourdemoApi", path: "../FeatureYourdemoApi"),
        .package(name: "LibraryServiceLoader", path: "../../../Library/ServiceLoader"),
        .package(name: "LibraryDemoRegistry", path: "../../../Library/DemoRegistry")
    ],
    targets: [
        .target(
            name: "FeatureYourdemoImpl",
            dependencies: [
                .product(name: "FeatureYourdemoApi", package: "FeatureYourdemoApi"),
                .product(name: "LibraryServiceLoader", package: "LibraryServiceLoader"),
                .product(name: "LibraryDemoRegistry", package: "LibraryDemoRegistry")
            ],
            path: "Sources"
        )
    ]
)
```

**Step 4: Implement Your Demo**

Create your view in `FeatureYourdemoImpl/Sources/`:
```swift
import SwiftUI

struct YourDemoView: View {
    var body: some View {
        Text("Your Demo Content")
    }
}
```

**Step 5: Create Module Registration**

In `FeatureYourdemoImpl/Sources/YourDemoModule.swift`:
```swift
import SwiftUI
import LibraryServiceLoader
import LibraryDemoRegistry
import FeatureYourdemoApi

public enum YourDemoModule {
    public static func register(in manager: ServiceManager = .shared) {
        // Register demo to DemoRegistry
        let demoItem = DemoItem(
            id: "your-demo",
            title: "Your Demo",
            description: "Description of your demo",
            category: .uiComponents,  // Choose appropriate category
            iconName: "star.fill",     // SF Symbol name
            buildView: { AnyView(YourDemoView()) }
        )
        DemoRegistry.shared.register(demoItem)
    }
}
```

**Step 6: Update project.yml**

Add your packages to `project.yml`:
```yaml
packages:
  # ... existing packages ...
  FeatureYourdemoApi:
    path: Packages/Feature/Yourdemo/FeatureYourdemoApi
  FeatureYourdemoImpl:
    path: Packages/Feature/Yourdemo/FeatureYourdemoImpl

targets:
  HealthBuddy:
    dependencies:
      # ... existing dependencies ...
      - package: FeatureYourdemoApi
        product: FeatureYourdemoApi
      - package: FeatureYourdemoImpl
        product: FeatureYourdemoImpl
```

**Step 7: Register in AppComposition**

In `App/Sources/Composition/AppComposition.swift`:
```swift
import FeatureYourdemoImpl  // Add import

enum AppComposition {
    @MainActor
    static func bootstrap() {
        // 1. Configure domain services
        HealthDomainBootstrap.configure()

        // 2. Register features
        DemoListFeatureModule.register()
        YourDemoModule.register()  // Add this line
    }
}
```

**Step 8: Regenerate and Build**
```bash
scripts/generate_project.sh
scripts/build.sh
```

### Important Package Naming Rules

**Critical**: Package names, product names, and directory names must be consistent:

✅ **Correct:**
- Directory: `FeatureYourdemoApi`
- Package name: `FeatureYourdemoApi`
- Product name: `FeatureYourdemoApi`
- Target name: `FeatureYourdemoApi`

❌ **Wrong (causes build errors):**
- Directory: `api`
- Package name: `YourdemoFeatureAPI`
- Product name: `FeatureYourdemoApi`

**Import Statement Rules:**
- Domain modules: Use `DomainXxx` (e.g., `import DomainHealth`, NOT `import HealthDomain`)
- Library modules: Use `LibraryXxx` (e.g., `import LibraryServiceLoader`, NOT `import ServiceLoader`)
- Feature modules: Use `FeatureXxxApi` or `FeatureXxxImpl`

### Adding a new Feature dependency
1. Add to Feature's `Package.swift` dependencies with correct package names
2. Import in Swift files: `import DomainXxx` or `import LibraryXxx`
3. Run `scripts/generate_project.sh`

### Modifying Package Dependencies
1. Edit the module's `Package.swift` file directly
2. Update `project.yml` if adding/removing packages from App target
3. Run `scripts/generate_project.sh` to apply changes

## Recent Refactoring (October 2025)

### Simplification Summary
The project underwent a major refactoring to simplify the module structure:

**Before (8 health-related packages):**
- FeatureAuthorization (API + Impl)
- FeatureDashboard (API + Impl)
- FeatureHealthKitDemo (API + Impl)
- LibraryHealthKit

**After (2 packages):**
- DomainHealth (includes HealthKitManager)
- FeatureHealthKit (unified API + Impl)

### Benefits
- ✅ Reduced dependencies between modules
- ✅ Simplified dependency graph
- ✅ Improved build times
- ✅ Better maintainability
- ✅ All features preserved and working

### Module Migration
- Authorization logic moved to `FeatureHealthKit/AuthorizationFeatureView.swift`
- Dashboard logic moved to `FeatureHealthKit/DashboardFeatureView.swift`
- HealthKitManager moved from `Library/HealthKit` to `Domain/Health`
- All features consolidated under unified `HealthKitModule`

### Build Verification
All changes have been verified with clean builds:
```bash
scripts/build.sh --clean  # ✅ Build succeeds
```

See commit `3cb9b42` for complete refactoring details.
