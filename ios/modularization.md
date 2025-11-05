# 模块化架构

技术选型：Swift Package Manager + XcodeGen

每个模块为本地 SwiftPM 包，工程由 XcodeGen 编排。


## 分层设计

按架构从下到上，分成：App、Feature、Domain、Library 几层

### Library

业务无关的基础库。
统一放在 Library 目录下

### Domain

核心业务领域模块，当前产品的核心领域知识、基础能力。
统一放在 Domain 目录下

### Feature

具体的业务功能模块，随需求变更频繁。Feature 进一步拆分成 api 和 impl 模块，Feature 模块之间只能依赖 api 模块，切通过 protocol 访问，只有 App 能够依赖 impl 模块。
统一放在 Feature 目录下


### App

包含 AppDelegate 等 App 的壳代码，以及组装编排 Feature


## 目录/分层示意

- App/
  - Resources/
  - Sources/                                      // 组合根：注册所有 impl  
- Packages/  
  - Feature/User/api/  
      - Package.swift  
      - Sources/FeatureUserApi                    // 只放协议
  - Feature/User/impl/  
      - Package.swift   
      - Sources/FeatureUserImpl                   // 具体实现、ViewModel、Repository、UI  
  - Feature/Dashboard/api/  
  - Feature/Dashboard/impl/  
  - Domain/Server/                                // 跨Feature的领域服务  
      - Package.swift
      - Sources/DomainServer
  - Library/ServiceLoader/                        // 业务无关的基础库
      - Package.swift
      - Sources/LibraryServiceLoader
  - Library/Network/  
  - Library/Design/  
  - Library/Health/
- project.yml                                     // XcodeGen：App target + 依赖 + 脚本
- scripts/                                        // 


# 使用说明

## 修改依赖
直接修改模块的 Package.swift 配置，并重新生成项目

```
scripts/generate_project.sh
```

## 创建模块

使用脚本 scripts/createModule.py

创建 Feature 模块
```
scripts/createModule.py -f User
```


创建 Domain 模块
```
scripts/createModule.py -d Model
```


创建 Library 模块
```
scripts/createModule.py -l Network
```
