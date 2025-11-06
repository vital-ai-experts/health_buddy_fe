# Create Module Command

You are helping the user create a new module in the HealthBuddy iOS project.

## Parameter Parsing

Parse the user's input intelligently to determine module type and name. Users may provide arguments in various formats:
- `/create-module UserProfile` -> Feature (default), name: UserProfile
- `/create-module feature UserProfile` -> Feature, name: UserProfile
- `/create-module -f UserProfile` -> Feature, name: UserProfile
- `/create-module domain Analytics` -> Domain, name: Analytics
- `/create-module -d Notification` -> Domain, name: Notification
- `/create-module library Logger` -> Library, name: Logger
- `/create-module -l NetworkKit` -> Library, name: NetworkKit

### Keyword Detection Rules

**Module Type**:
- Keywords for `Feature`: `feature`, `f`, `-f`, `功能`, `特性`
- Keywords for `Domain`: `domain`, `d`, `-d`, `领域`, `域`
- Keywords for `Library`: `library`, `lib`, `l`, `-l`, `库`, `工具`
- Default: `Feature` (most commonly used)

**Module Name**:
- Any word that is NOT a type keyword is treated as the module name
- Must be in PascalCase (e.g., "UserProfile", "Analytics", "NetworkKit")
- If no name provided, ask the user for it (this is required)

## Execution Steps

1. **Parse arguments** to determine module type and name
2. **If name is missing**, ask: "Please provide the module name (in PascalCase, e.g., UserProfile):"
3. **Create the module** using createModule.py script:
   ```bash
   # Feature
   scripts/createModule.py -f [Name]

   # Domain
   scripts/createModule.py -d [Name]

   # Library
   scripts/createModule.py -l [Name]
   ```
4. **Guide the user** on next steps (but don't execute them automatically):
   - Update `project.yml` to add package(s) and dependencies
   - For Features: Define API protocol and implement builder
   - Register module in `AppComposition.swift`
   - Run `scripts/generate_project.sh`
   - Run `scripts/build.sh -i` to verify

## Examples

```bash
# User: /create-module UserProfile
# Type: Feature (default), Name: UserProfile
# Execute: scripts/createModule.py -f UserProfile

# User: /create-module feature Settings
# Type: Feature, Name: Settings
# Execute: scripts/createModule.py -f Settings

# User: /create-module -f Payment
# Type: Feature, Name: Payment
# Execute: scripts/createModule.py -f Payment

# User: /create-module domain Notification
# Type: Domain, Name: Notification
# Execute: scripts/createModule.py -d Notification

# User: /create-module -d Analytics
# Type: Domain, Name: Analytics
# Execute: scripts/createModule.py -d Analytics

# User: /create-module library Logger
# Type: Library, Name: Logger
# Execute: scripts/createModule.py -l Logger

# User: /create-module -l NetworkKit
# Type: Library, Name: NetworkKit
# Execute: scripts/createModule.py -l NetworkKit
```

## After Module Creation

Provide guidance on next steps:

### For Feature Modules
```
Module created! Next steps:

1. Update project.yml:
   Add to packages section:
   ```yaml
   Feature[Name]Api:
     path: Packages/Feature/[Name]/Feature[Name]Api
   Feature[Name]Impl:
     path: Packages/Feature/[Name]/Feature[Name]Impl
   ```

   Add to HealthBuddy target dependencies:
   - package: Feature[Name]Api
     product: Feature[Name]Api
   - package: Feature[Name]Impl
     product: Feature[Name]Impl

2. Define API protocol in Feature[Name]Api/Sources/Feature[Name]Api.swift
3. Implement builder in Feature[Name]Impl/Sources/[Name]Builder.swift
4. Create module registration in Feature[Name]Impl/Sources/[Name]Module.swift
5. Register in App/Sources/Composition/AppComposition.swift
6. Run: scripts/generate_project.sh
7. Run: scripts/build.sh -i
```

### For Domain Modules
```
Module created! Next steps:

1. Update project.yml:
   Add to packages section:
   ```yaml
   Domain[Name]:
     path: Packages/Domain/Domain[Name]
   ```

   Add to HealthBuddy target dependencies:
   - package: Domain[Name]
     product: Domain[Name]

2. Implement domain services in Domain[Name]/Sources
3. Create bootstrap in Domain[Name]/Sources/[Name]DomainBootstrap.swift
4. Register in App/Sources/Composition/AppComposition.swift
5. Run: scripts/generate_project.sh
6. Run: scripts/build.sh -i
```

### For Library Modules
```
Module created! Next steps:

1. Update project.yml:
   Add to packages section:
   ```yaml
   Library[Name]:
     path: Packages/Library/Library[Name]
   ```

   Add to HealthBuddy target dependencies:
   - package: Library[Name]
     product: Library[Name]

2. Implement utility code in Library[Name]/Sources
3. Run: scripts/generate_project.sh
4. Run: scripts/build.sh -i
```

## Important Notes

- Module names must be in PascalCase (e.g., "UserProfile", not "user-profile")
- Package names must match directory names exactly
- Features are automatically split into Api and Impl packages
- Follow the architecture patterns from AGENTS.md
- Always regenerate project and build after creating modules
- Do NOT ask for type if it can be inferred from keywords
- Do NOT ask for name if provided in the command
- Only ask when information is truly missing
