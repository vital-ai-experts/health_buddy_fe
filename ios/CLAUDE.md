# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **📖 Complete Development Guide**: For comprehensive project documentation, architecture details, and step-by-step instructions, see [AGENTS.md](./AGENTS.md).

## Quick Overview

ThriveBody is an intelligent health management iOS app built with SwiftUI and Swift Package Manager (SPM). The app follows a strict layered architecture with clean separation of concerns.

**Tech Stack**:
- iOS 17.0+, Xcode 15.0+
- SwiftUI + Swift Package Manager
- XcodeGen for project generation
- HealthKit integration

**Core Architecture**: `App → Feature(Impl) → Feature(Api) → Domain → Library`

## Most Common Tasks

### 1. After Writing/Modifying Code (CRITICAL)
Always build and verify your changes:
```bash
scripts/build.sh -i
```

### 2. Creating a New Module
```bash
# Feature (generates both Api and Impl)
scripts/createModule.py -f YourFeature

# Domain or Library
scripts/createModule.py -d YourDomain
scripts/createModule.py -l YourLibrary

# Then regenerate project
scripts/generate_project.sh
```

### 3. After Modifying Package.swift or project.yml
```bash
scripts/generate_project.sh
```

## Key Principles

**Package Naming Rule** (Critical):
- Directory name = Package name = Product name = Target name
- Example: All must be `FeatureAccountApi` (not `api` or `AccountAPI`)

**Import Conventions**:
```swift
import DomainAuth               // Domain modules
import LibraryServiceLoader     // Library modules
import FeatureAccountApi        // Feature modules
```

**Dependency Flow**:
- ✅ Features can depend on Feature APIs and Domains
- ✅ Domains can depend on Libraries
- ❌ Never depend upward (e.g., Domain → Feature)
- ❌ Never depend on Feature Impl from other features

**Service Registration Pattern**:
1. Domain services register in `[Domain]Bootstrap.configure()`
2. Feature builders register in `[Name]Module.register()`
3. All registered in `AppComposition.bootstrap()` during app launch
4. Resolve via `ServiceManager.shared.resolve(YourService.self)`

## Build Script Quick Reference

**CRITICAL - Always Build and Install After Code Changes**:

After writing or modifying ANY code, you MUST run `scripts/build.sh -i` to verify your changes compile and run correctly.

```bash
# Most common: Build and install to simulator
scripts/build.sh -i

# Build and install to device
scripts/build.sh -i -d device

# Clean build
scripts/build.sh -c

# Release build
scripts/build.sh -r -i -d device
```

**Features**:
- Auto-detects running simulator or connected device
- Progress animation and build time tracking
- Logs saved to `build/xcodebuild_YYYYMMDD_HHMMSS.log`
- `-i` flag automatically installs and launches app

## Current Project Structure

**Features** (3):
- `FeatureAccount`: User registration, login, account management
- `FeatureChat`: AI chat interface, conversation management
- `FeatureHealthKit`: HealthKit authorization, dashboard, data visualization

**Domains** (3):
- `DomainAuth`: Authentication service, user model
- `DomainChat`: AI chat service
- `DomainHealth`: Health data services, HealthKit manager

**Libraries** (3):
- `ServiceLoader`: Dependency injection container
- `Networking`: HTTP client wrapper
- `ThemeKit`: App theming and styling

## When You Need More Information

For detailed information on any of these topics, refer to [AGENTS.md](./AGENTS.md):
- Complete architecture overview and layer responsibilities
- Step-by-step guide for adding new features
- Dependency injection pattern details
- Testing guidelines
- HealthKit integration specifics
- Common pitfalls and solutions
- Git workflow and PR guidelines

## Claude Code Specific Notes

**Always Remember**:
1. ✅ Build after every code change: `scripts/build.sh -i`
2. ✅ Check [AGENTS.md](./AGENTS.md) for detailed instructions
3. ✅ Package names must match directory names exactly
4. ✅ Features depend only on Feature APIs, never Impl
5. ✅ Regenerate project after Package.swift changes: `scripts/generate_project.sh`
6. ✅ Check CI status with `.github/check_ci_status.sh` when you are running in a sandboxed environment (Codex, Claude Code web)