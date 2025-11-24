# ThriveBody Development Guide

## Project Overview

ThriveBody is an intelligent health management iOS app built with SwiftUI and Swift Package Manager (SPM). The app integrates AI-powered health assistant with HealthKit data tracking.

**Core Features**:
- AI Health Assistant: LLM-based conversational health advice
- HealthKit Integration: Health data tracking with HealthKit
- Account System: User registration, login, and profile management

**Requirements**:
- iOS 17.0+
- Xcode 15.0+
- XcodeGen (install via `brew install xcodegen`)

> ⚠️ **创建新模块或新增页面之前**：务必先阅读 [`modularization.md`](./modularization.md)。该文档汇总了分层边界、命名、脚本、路由注册等所有结构化约束。

## Architecture Overview

ThriveBody 遵循严格的分层架构：`App → Feature(Impl) → Feature(Api) → Domain → Library`。详细的分层职责、目录示例、脚本指引以及路由体系，请以 [`modularization.md`](./modularization.md) 为准；任何涉及模块拆分、路由扩展、页面新增的工作都应先阅读该文档。

- **App 层 (`App/Sources/`)**：入口、全局路由与依赖组装，只能依赖 Feature Impl，核心文件为 `AppMain/` 与 `Composition/`。
- **Feature 层 (`Packages/Feature/`)**：每个功能拆分为 `Api` + `Impl` 包，`Api` 暴露协议，`Impl` 实现 UI + 路由注册。
- **Domain 层 (`Packages/Domain/`)**：跨功能业务服务，通过 `[Name]DomainBootstrap.configure()` 将服务注入 `ServiceManager`。
- **Library 层 (`Packages/Library/`)**：业务无关工具，可被所有上层依赖。

需要示例目录结构、命名规范或拓展说明时，直接跳转到 `modularization.md` 查阅。

## Build, Test, and Development Commands

**CRITICAL - Always Build and Install After Code Changes**:
After writing or modifying ANY code, you MUST run `scripts/build.sh -i` to verify your changes compile and run correctly.

### Build Commands
- `scripts/build.sh -i` - **[REQUIRED AFTER CODE CHANGES]** Build and install to running simulator
- `scripts/build.sh -i -d device` - Build and install to connected iPhone
- `scripts/build.sh -r -i -d device` - Release build and install to device
- `scripts/build.sh -a` - Create archive and export .ipa for distribution
- `scripts/build.sh -c` - Clean build

Build script features:
- Auto-detects running simulator or connected device
- Shows progress animation during build
- All logs saved to `build/xcodebuild_YYYYMMDD_HHMMSS.log`
- Automatically installs and launches app with `-i` flag

### Other Commands
- `scripts/generate_project.sh` - Regenerates Xcode project via XcodeGen; run after adding modules or modifying `project.yml`
- `scripts/createModule.py -f [Name]` - Scaffolds a new Feature module (creates both Api and Impl packages)
- `scripts/createModule.py -d [Name]` - Scaffolds a new Domain module
- `scripts/createModule.py -l [Name]` - Scaffolds a new Library module

## Dependency Injection Pattern

The app uses a custom service locator pattern (`ServiceManager` from `LibraryServiceLoader`):

**1. Registration** (in bootstrap modules during app launch):
```swift
// Domain Bootstrap
public enum AuthDomainBootstrap {
    public static func configure(manager: ServiceManager = .shared) {
        manager.register(AuthenticationService.self) { AuthenticationServiceImpl() }
    }
}

// Feature Module Registration
public enum AccountModule {
    public static func register(
        in manager: ServiceManager = .shared,
        router: RouteRegistering
    ) {
        manager.register(FeatureAccountBuildable.self) { AccountBuilder() }

        registerRoutes(on: router)
    }
}
```

**2. App Composition** (`AppComposition.bootstrap(router:)`):
```swift
enum AppComposition {
    @MainActor
    static func bootstrap(router: RouteRegistering) {
        // 1. Configure domain services first
        HealthDomainBootstrap.configure()
        AuthDomainBootstrap.configure()
        ChatDomainBootstrap.configure()

        // 2. Register features (buildable + routes)
        AccountModule.register(router: router)
        ChatModule.register(router: router)
    }
}
```

**3. Resolution** (at view initialization):
```swift
let service = ServiceManager.shared.resolve(AuthenticationService.self)
```

## App Flow

1. Launch → `MainApp.init()` → `AppComposition.bootstrap(router:)`
2. Splash screen (1.5s) while checking authentication
3. If authenticated → MainTabView (AI Assistant, Agenda, Profile)
4. If not authenticated → AccountLandingView
5. Data persistence via SwiftData (models in Domain layer)

## Coding Conventions

**Package Naming** (Directory = Package = Product = Target):
- Feature: `Feature[Name]Api`, `Feature[Name]Impl`
- Domain: `Domain[Name]`
- Library: `Library[Name]`

**Import Rules**:
- Domain: `import DomainAuth`, `import DomainHealth`, `import DomainChat`
- Library: `import LibraryServiceLoader`, `import LibraryNetworking`
- Feature: `import FeatureAccountApi`, `import FeatureAccountImpl`

**File Naming**:
- Feature API: `Feature[Name]Api.swift` (contains `Feature[Name]Buildable` protocol)
- Feature Builder: `[Name]Builder.swift`
- Feature Module: `[Name]Module.swift`
- Domain Bootstrap: `[Name]DomainBootstrap.swift`

**Code Style**:
- Swift 5.9 conventions
- 4-space indentation
- Prefer `struct` + SwiftUI patterns
- Keep files focused and single-purpose

## Creating New Modules

### Quick Start

Use the scaffold script to generate module structure:

```bash
# Create a Feature module (generates both Api and Impl)
scripts/createModule.py -f YourFeature

# Create a Domain module
scripts/createModule.py -d YourDomain

# Create a Library module
scripts/createModule.py -l YourLibrary
```

### Step-by-Step: Adding a New Feature

**1. Create Module Structure**
```bash
scripts/createModule.py -f YourFeature
```

This creates:
- `Packages/Feature/YourFeature/FeatureYourFeatureApi/` - Protocol definitions
- `Packages/Feature/YourFeature/FeatureYourFeatureImpl/` - Implementation

**2. Define API Protocol** (`FeatureYourFeatureApi/Sources/FeatureYourFeatureApi.swift`):
```swift
import SwiftUI

public protocol FeatureYourFeatureBuildable {
    func makeYourFeatureView() -> AnyView
}
```

**3. Implement Builder** (`FeatureYourFeatureImpl/Sources/YourFeatureBuilder.swift`):
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

**4. Create Module Registration** (`FeatureYourFeatureImpl/Sources/YourFeatureModule.swift`):
```swift
import LibraryServiceLoader
import FeatureYourFeatureApi

public enum YourFeatureModule {
    public static func register(in manager: ServiceManager = .shared) {
        manager.register(FeatureYourFeatureBuildable.self) { YourFeatureBuilder() }
    }
}
```

**5. Update `project.yml`**:
```yaml
packages:
  FeatureYourFeatureApi:
    path: Packages/Feature/YourFeature/FeatureYourFeatureApi
  FeatureYourFeatureImpl:
    path: Packages/Feature/YourFeature/FeatureYourFeatureImpl

targets:
  ThriveBody:
    dependencies:
      - package: FeatureYourFeatureApi
        product: FeatureYourFeatureApi
      - package: FeatureYourFeatureImpl
        product: FeatureYourFeatureImpl
```

**6. Register in AppComposition** (`App/Sources/Composition/AppComposition.swift`):
```swift
import FeatureYourFeatureImpl  // Add import

enum AppComposition {
    @MainActor
    static func bootstrap(router: RouteRegistering) {
        // Domain services...
        HealthDomainBootstrap.configure()
        AuthDomainBootstrap.configure()
        ChatDomainBootstrap.configure()

        // Features...
        AccountModule.register(router: router)
        ChatModule.register(router: router)
        OnboardingModule.register()
        AgendaModule.register()
        YourFeatureModule.register(router: router)  // Add this
    }
}
```

**7. Regenerate and Build**:
```bash
scripts/generate_project.sh
scripts/build.sh -i
```

### Adding a Domain Service

1. Create service protocol and implementation in Domain module
2. Register in `[Domain]Bootstrap.configure()`:
   ```swift
   manager.register(YourService.self) { YourServiceImpl() }
   ```
3. Call bootstrap in `AppComposition.bootstrap(router:)`
4. Resolve where needed: `ServiceManager.shared.resolve(YourService.self)`

## Testing Guidelines

**Unit Tests**:
- Add `Tests/` targets to new packages
- Use XCTest with descriptive `test_<behavior>` names
- Mock domain services via dependency inversion

**Running Tests**:
```bash
# Run all project tests
xcodebuild test -project ThriveBody.xcodeproj -scheme ThriveBody

# Run package tests
swift test --package-path Packages/Feature/<Module>/Api
```

## HealthKit Integration

- **Entitlements**: Configured in `App/ThriveBody.entitlements`
- **Usage Descriptions**: Defined in `project.yml`:
  - `NSHealthShareUsageDescription`
  - `NSHealthUpdateUsageDescription`
- **Authorization Flow**: `Onboarding|Settings` → `DomainHealth` → HealthKit framework
- **Framework Linking**: HealthKit linked directly in `DomainHealth` module

## Common Pitfalls & Solutions

### 1. Package Name Mismatch
❌ **Wrong**: Directory `api`, Package `YourFeatureAPI`, Product `FeatureYourFeatureApi`
✅ **Correct**: All must match exactly: `FeatureYourFeatureApi`

### 2. Wrong Import Prefix
❌ **Wrong**: `import Health`, `import ServiceLoader`
✅ **Correct**: `import DomainHealth`, `import LibraryServiceLoader`

### 3. Reverse Dependencies
❌ **Wrong**: Domain depending on Feature
✅ **Correct**: Feature → Domain → Library (dependency flows downward)

### 4. Missing Project Regeneration
After modifying `Package.swift` or adding modules, always run:
```bash
scripts/generate_project.sh
```

### 5. Feature Impl Coupling
❌ **Wrong**: Feature depending on another Feature's `Impl` package
✅ **Correct**: Features depend only on other Feature `Api` modules

### 6. Forgetting to Build After Changes
Always verify your changes compile and run:
```bash
scripts/build.sh -i
```

## Git Workflow

**Commit Conventions**:
- Follow conventional commits: `type: summary`
- Examples: `feat: add chat feature`, `fix: resolve login bug`, `refactor: simplify module structure`
- Keep commits scoped to single changes

**Pull Request Checklist**:
- [ ] Summary of changes
- [ ] Screenshots for UI work
- [ ] Test results
- [ ] Migration notes for architectural changes
- [ ] All builds pass (`scripts/build.sh -i`)


## Quick Reference

**Create Module**:
```bash
scripts/createModule.py -f FeatureName    # Feature
scripts/createModule.py -d DomainName     # Domain
scripts/createModule.py -l LibraryName    # Library
```

**Build & Deploy**:
```bash
scripts/build.sh -i              # Build and install to simulator
scripts/build.sh -i -d device    # Build and install to device
scripts/generate_project.sh      # Regenerate Xcode project
```

**Import Patterns**:
```swift
import DomainAuth               // Domain modules
import LibraryServiceLoader     // Library modules
import FeatureAccountApi        // Feature API modules
```

**Service Registration**:
```swift
// Domain Bootstrap
AuthDomainBootstrap.configure()

// Feature Module
let router = RouteManager.shared
AccountModule.register(router: router)
```
