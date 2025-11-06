# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HealthBuddy is an intelligent health management iOS app built with SwiftUI and Swift Package Manager (SPM). The project uses XcodeGen for project generation and follows a clean architecture pattern with strict layer separation.

The app integrates AI-powered health assistant with HealthKit data tracking. Core features:
- **AI Health Assistant**: LLM-based conversational health advice
- **HealthKit Integration**: Health data tracking and visualization
- **Account System**: User registration, login, and profile management

There is one app target: `HealthBuddy`.

## Current Module Structure

```
Packages/
├── Feature/                               # Feature Layer
│   └── FeatureAccount/                   # Example: Account feature
│       ├── FeatureAccountApi/            # API protocols
│       │   └── Sources/FeatureAccountApi/
│       │       └── FeatureAccountApi.swift
│       └── FeatureAccountImpl/           # Implementation
│           └── Sources/
│               ├── AccountModule.swift   # Module registration
│               ├── AccountBuilder.swift  # Builder implementation
│               └── Views...              # SwiftUI views
│
├── Domain/                               # Domain Layer
│   └── DomainAuth/                       # Example: Auth domain
│       └── Sources/DomainAuth/
│           ├── AuthDomainBootstrap.swift # Service registration
│           ├── AuthenticationService.swift
│           └── User.swift                # Domain models
│
└── Library/                              # Library Layer
    └── ServiceLoader/                    # Example: Service locator
        └── Sources/ServiceLoader/
            └── ServiceManager.swift

Note: Project has 3 features (Account/Chat/HealthKit),
      3 domains (Auth/Chat/Health), and 3 libraries (ServiceLoader/Networking/ThemeKit)
```

## Build and Project Generation

### Generate Xcode Project
After modifying any `Package.swift` files or adding new modules, regenerate the Xcode project:
```bash
scripts/generate_project.sh
```

### Build Script (IMPORTANT - Always Use After Code Changes)

**CRITICAL**: After writing or modifying code, you MUST build and install to verify your changes work correctly.

#### Quick Build and Install (Recommended)
```bash
# Build and install to running simulator (most common)
scripts/build.sh -i

# Build and install to connected device
scripts/build.sh -i -d device

# Release build and install to device
scripts/build.sh -r -i -d device
```

#### Build Only (No Install)
```bash
scripts/build.sh                    # Build for simulator
scripts/build.sh -d device          # Build for device
scripts/build.sh -r                 # Release build
scripts/build.sh -c                 # Clean build
```

#### Available Parameters
- `-h, --help`: Show help information
- `-c, --clean`: Clean before building
- `-r, --release`: Release mode (default: Debug)
- `-a, --archive`: Create archive and export .ipa
- `-i, --install`: Build and install to device/simulator
- `-d, --destination`: Target device: `simulator` (default) or `device`

The build script provides:
- **Auto device detection**: Automatically finds running simulator or connected device
- **Progress animation**: Shows building progress with spinner
- **Auto logging**: All build output saved to `build/xcodebuild_YYYYMMDD_HHMMSS.log`
- **Auto install**: Optionally installs and launches the app after building
- **Build time tracking**: Shows total build time
- Useful for CI/CD or pre-commit validation

**Best Practice**: Always run `scripts/build.sh -i` after making code changes to ensure:
1. Code compiles successfully
2. No runtime errors when launching
3. Changes work as expected on actual device/simulator

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
- App entry point (`AppMain/HealthBuddyApp.swift`)
- Composition root (`Composition/AppComposition.swift`) - registers all domain services and feature builders
- Root navigation (`AppMain/RootView.swift`) - handles splash, auth flow, and main TabView
- Main TabView with three tabs: AI Assistant, Health, Profile
- Only layer allowed to depend on Feature `impl` modules

**Feature** (`Packages/Feature/`)
- Each feature has two separate directories: `Feature[Name]Api` and `Feature[Name]Impl`
- **Important**: Directory names must match the package name exactly (e.g., `FeatureAccountApi`, not just `api`)
- `Feature[Name]Api` packages: Protocol definitions only (e.g., `FeatureAccountBuildable`)
- `Feature[Name]Impl` packages: Concrete implementations, ViewModels, Views, and business logic
- Features can only depend on other Feature `Api` modules (never `Impl`)
- Current features:
  - **FeatureAccount**: User registration, login, account landing page
  - **FeatureChat**: AI chat interface, conversation management
  - **FeatureHealthKit**: HealthKit authorization, dashboard, data visualization

**Domain** (`Packages/Domain/`)
- Core business logic and cross-feature domain services
- Examples:
  - `DomainHealth` - contains `AuthorizationService`, `HealthDataService`, and `HealthKitManager`
  - `DomainAuth` - contains `AuthenticationService` and `User` model
  - `DomainChat` - contains `ChatService` for AI conversations
- Bootstrap modules configure and register domain services into `ServiceManager`
- Integrates system frameworks directly (e.g., HealthKit in DomainHealth)

**Library** (`Packages/Library/`)
- Business-agnostic utilities and wrappers
- Examples:
  - `ServiceLoader`: Thread-safe service locator (`ServiceManager`)
  - `Networking`: HTTP client wrapper for API calls
  - `ThemeKit`: App-wide theming and styling

### Dependency Injection Pattern

The app uses a custom service locator pattern (`ServiceManager` from `LibraryServiceLoader`):

1. **Registration** happens in bootstrap modules during app launch:
   - `HealthDomainBootstrap.configure()` - registers health domain services
   - `AuthDomainBootstrap.configure()` - registers authentication services
   - `ChatDomainBootstrap.configure()` - registers chat services
   - `HealthKitModule.register()` - registers HealthKit feature builder
   - `AccountModule.register()` - registers account feature builder
   - `ChatModule.register()` - registers chat feature builder
   - All called from `AppComposition.bootstrap()` in `HealthBuddyApp.init()`

2. **Resolution** happens at view initialization or in constructors:
   ```swift
   let service = ServiceManager.shared.resolve(AuthenticationService.self)
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

## App Flow

1. **App Launch**: `HealthBuddyApp.init()` → `AppComposition.bootstrap()` registers all services
2. **Splash Screen**: Shows for 1.5 seconds while checking authentication
3. **Authentication Check**:
   - If authenticated → show MainTabView
   - If not authenticated → show AccountLandingView
4. **Main Interface**: TabView with three tabs:
   - AI Assistant (Chat Tab)
   - Health (HealthKit Tab)
   - Profile (ProfileView with user info and logout)
5. **Data Persistence**: Uses SwiftData with models defined in Domain layer

## HealthKit Integration

- Requires HealthKit entitlements (configured in `App/HealthBuddy.entitlements`)
- Usage descriptions defined in `project.yml`:
  - `NSHealthShareUsageDescription`
  - `NSHealthUpdateUsageDescription`
- Authorization flow handled by `FeatureHealthKit` → `DomainHealth` → HealthKit framework
- HealthKit framework is directly linked in `DomainHealth` module

## Important Patterns

### Feature Registration Pattern
Each feature `impl` module exports a registration function:
```swift
public enum FeatureModule {
    public static func register(in manager: ServiceManager = .shared) {
        // Register builder to ServiceManager
        manager.register(FeatureBuildable.self) { FeatureBuilder() }
    }
}
```

### Feature Builder Pattern
Features expose views via builder protocols:
```swift
public protocol FeatureAccountBuildable {
    func makeLoginView(onLoginSuccess: @escaping () -> Void) -> AnyView
    func makeRegisterView(onRegisterSuccess: @escaping () -> Void) -> AnyView
    func makeAccountLandingView(onSuccess: @escaping () -> Void) -> AnyView
}
```

### Bootstrap Pattern
Domain modules export a `configure()` function that registers services:
```swift
public enum DomainBootstrap {
    public static func configure(manager: ServiceManager = .shared) {
        // register domain services
        manager.register(SomeService.self) { SomeServiceImpl() }
    }
}
```

## File Naming Conventions

- Feature API protocols: `Feature[Name]Api.swift`, containing `Feature[Name]Buildable`
- Feature modules: `[Name]Module.swift` for registration
- Feature builders: `[Name]Builder.swift` for builder implementation
- Domain bootstraps: `[Domain]Bootstrap.swift`
- Service contracts: `ServiceContracts.swift` or descriptive service names
- Data models: `[Domain]DataModels.swift` or descriptive model names

## Adding a New Feature

### Step 1: Create the Feature Module
```bash
scripts/createModule.py -f YourFeature
```

This creates:
- `Packages/Feature/YourFeature/FeatureYourFeatureApi/` - API definitions
- `Packages/Feature/YourFeature/FeatureYourFeatureImpl/` - Implementation

### Step 2: Update Package.swift Files

In `FeatureYourFeatureApi/Package.swift`:
```swift
let package = Package(
    name: "FeatureYourFeatureApi",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "FeatureYourFeatureApi", targets: ["FeatureYourFeatureApi"]) ],
    targets: [
        .target(name: "FeatureYourFeatureApi", path: "Sources")
    ]
)
```

In `FeatureYourFeatureImpl/Package.swift`:
```swift
let package = Package(
    name: "FeatureYourFeatureImpl",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "FeatureYourFeatureImpl", targets: ["FeatureYourFeatureImpl"]) ],
    dependencies: [
        .package(name: "FeatureYourFeatureApi", path: "../FeatureYourFeatureApi"),
        .package(name: "LibraryServiceLoader", path: "../../../Library/ServiceLoader")
    ],
    targets: [
        .target(
            name: "FeatureYourFeatureImpl",
            dependencies: [
                .product(name: "FeatureYourFeatureApi", package: "FeatureYourFeatureApi"),
                .product(name: "LibraryServiceLoader", package: "LibraryServiceLoader")
            ],
            path: "Sources"
        )
    ]
)
```

### Step 3: Define API Protocol

In `FeatureYourFeatureApi/Sources/FeatureYourFeatureApi.swift`:
```swift
import SwiftUI

public protocol FeatureYourFeatureBuildable {
    func makeYourFeatureView() -> AnyView
}
```

### Step 4: Implement Builder

In `FeatureYourFeatureImpl/Sources/YourFeatureBuilder.swift`:
```swift
import SwiftUI
import FeatureYourFeatureApi

public struct YourFeatureBuilder: FeatureYourFeatureBuildable {
    public init() {}

    public func makeYourFeatureView() -> AnyView {
        AnyView(YourFeatureView())
    }
}
```

### Step 5: Create Module Registration

In `FeatureYourFeatureImpl/Sources/YourFeatureModule.swift`:
```swift
import LibraryServiceLoader
import FeatureYourFeatureApi

public enum YourFeatureModule {
    public static func register(in manager: ServiceManager = .shared) {
        manager.register(FeatureYourFeatureBuildable.self) { YourFeatureBuilder() }
    }
}
```

### Step 6: Update project.yml

Add your packages to `project.yml`:
```yaml
packages:
  # ... existing packages ...
  FeatureYourFeatureApi:
    path: Packages/Feature/YourFeature/FeatureYourFeatureApi
  FeatureYourFeatureImpl:
    path: Packages/Feature/YourFeature/FeatureYourFeatureImpl

targets:
  HealthBuddy:
    dependencies:
      # ... existing dependencies ...
      - package: FeatureYourFeatureApi
        product: FeatureYourFeatureApi
      - package: FeatureYourFeatureImpl
        product: FeatureYourFeatureImpl
```

### Step 7: Register in AppComposition

In `App/Sources/Composition/AppComposition.swift`:
```swift
import FeatureYourFeatureImpl  // Add import

enum AppComposition {
    @MainActor
    static func bootstrap() {
        // 1. Configure domain services
        HealthDomainBootstrap.configure()
        AuthDomainBootstrap.configure()
        ChatDomainBootstrap.configure()

        // 2. Register features
        HealthKitModule.register()
        AccountModule.register()
        ChatModule.register()
        YourFeatureModule.register()  // Add this line
    }
}
```

### Step 8: Regenerate and Build
```bash
scripts/generate_project.sh
scripts/build.sh
```

## Important Package Naming Rules

**Critical**: Package names, product names, and directory names must be consistent:

✅ **Correct:**
- Directory: `FeatureYourFeatureApi`
- Package name: `FeatureYourFeatureApi`
- Product name: `FeatureYourFeatureApi`
- Target name: `FeatureYourFeatureApi`

❌ **Wrong (causes build errors):**
- Directory: `api`
- Package name: `YourFeatureAPI`
- Product name: `FeatureYourFeatureApi`

**Import Statement Rules:**
- Domain modules: Use `DomainXxx` (e.g., `import DomainHealth`, `import DomainAuth`)
  - Exception: Health domain uses `HealthDomain` as source directory name but imports as `DomainHealth`
- Library modules: Use `LibraryXxx` (e.g., `import LibraryServiceLoader`, `import LibraryNetworking`)
- Feature modules: Use `FeatureXxxApi` or `FeatureXxxImpl`

## Adding a Domain Service

1. Create the service protocol and implementation in the Domain module
2. Add registration to `[Domain]Bootstrap.configure()`
3. Import and use via `ServiceManager.shared.resolve(YourService.self)`

## Modifying Package Dependencies

1. Edit the module's `Package.swift` file directly
2. Update `project.yml` if adding/removing packages from App target
3. Run `scripts/generate_project.sh` to apply changes
