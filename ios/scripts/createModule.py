#!/usr/bin/env python3
import os
import sys
import argparse
import re

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))

def to_pascal_case(name: str) -> str:
    """保持原始大小写，只处理连字符分隔的情况"""
    parts = re.split(r"[-_\s]+", name.strip())
    if len(parts) == 1:
        # 单个部分直接返回，保持原始大小写
        return parts[0]
    else:
        # 多个部分拼接，保持每个部分的原始大小写
        return "".join(p for p in parts if p)

def write_file(path: str, content: str):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if os.path.exists(path):
        raise FileExistsError(f"文件已存在: {path}")
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

def create_feature(name: str):
    module = to_pascal_case(name)
    feature_name = f"Feature{module}"
    base = os.path.join(REPO_ROOT, 'Packages', 'Feature', module)

    # API
    api_pkg = os.path.join(base, f'{feature_name}Api')
    api_package_swift = f"""// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "{feature_name}Api",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "{feature_name}Api", targets: ["{feature_name}Api"]) ],
    targets: [
        .target(
            name: "{feature_name}Api",
            path: "Sources"
        )
    ]
)
"""
    api_src = os.path.join(api_pkg, 'Sources', f'{feature_name}Api', f'{feature_name}Api.swift')
    api_code = f"""import SwiftUI

public protocol {feature_name}Buildable {{
    func make{module}View() -> AnyView
}}
"""

    write_file(os.path.join(api_pkg, 'Package.swift'), api_package_swift)
    write_file(api_src, api_code)

    # Impl
    impl_pkg = os.path.join(base, f'{feature_name}Impl')
    impl_package_swift = f"""// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "{feature_name}Impl",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "{feature_name}Impl", targets: ["{feature_name}Impl"]) ],
    dependencies: [
        .package(name: "{feature_name}Api", path: "../{feature_name}Api"),
        .package(name: "LibraryServiceLoader", path: "../../../Library/ServiceLoader")
    ],
    targets: [
        .target(
            name: "{feature_name}Impl",
            dependencies: [
                .product(name: "{feature_name}Api", package: "{feature_name}Api"),
                .product(name: "LibraryServiceLoader", package: "LibraryServiceLoader")
            ],
            path: "Sources"
        )
    ]
)
"""
    impl_src_module = os.path.join(impl_pkg, 'Sources', f'{feature_name}Impl')
    impl_module_swift = f"""import SwiftUI
import LibraryServiceLoader
import {feature_name}Api

struct {module}FeatureView: View {{
    var body: some View {{
        Text("{module} Feature")
    }}
}}

public struct {module}FeatureBuilder: {feature_name}Buildable {{
    public init() {{}}
    public func make{module}View() -> AnyView {{ AnyView({module}FeatureView()) }}
}}

public enum {module}FeatureModule {{
    public static func register(in manager: ServiceManager = .shared) {{
        // Register builder to ServiceManager
        manager.register({feature_name}Buildable.self) {{ {module}FeatureBuilder() }}
    }}
}}
"""

    write_file(os.path.join(impl_pkg, 'Package.swift'), impl_package_swift)
    write_file(os.path.join(impl_src_module, f'{module}FeatureModule.swift'), impl_module_swift)

    print(f"[完成] Feature 模块创建: Feature/{module}/({feature_name}Api, {feature_name}Impl)")

def create_domain(name: str):
    module = to_pascal_case(name)
    domain_name = f"Domain{module}"
    base = os.path.join(REPO_ROOT, 'Packages', 'Domain', module)
    package_swift = f"""// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "{domain_name}",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "{domain_name}", targets: ["{domain_name}"]) ],
    targets: [
        .target(
            name: "{domain_name}",
            path: "Sources"
        )
    ]
)
"""
    src = os.path.join(base, 'Sources', f'{domain_name}', f'{module}DomainBootstrap.swift')
    code = f"""import LibraryServiceLoader

public enum {module}DomainBootstrap {{
    public static func configure(manager: ServiceManager = .shared) {{
        // Configure domain services here
    }}
}}
"""
    write_file(os.path.join(base, 'Package.swift'), package_swift)
    write_file(src, code)
    print(f"[完成] Domain 模块创建: Domain/{module}/({domain_name})")

def create_library(name: str):
    module = to_pascal_case(name)
    library_name = f"Library{module}"
    base = os.path.join(REPO_ROOT, 'Packages', 'Library', module)
    package_swift = f"""// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "{library_name}",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "{library_name}", targets: ["{library_name}"]) ],
    targets: [
        .target(
            name: "{library_name}",
            path: "Sources"
        )
    ]
)
"""
    src = os.path.join(base, 'Sources', f'{library_name}', f'{module}Manager.swift')
    code = f"""public enum {module}Manager {{
    public static func start() {{
        // Initialize {module} manager
    }}
}}
"""
    write_file(os.path.join(base, 'Package.swift'), package_swift)
    write_file(src, code)
    print(f"[完成] Library 模块创建: Library/{module}/({library_name})")

def main():
    parser = argparse.ArgumentParser(description='按模块化规范创建模块 (Feature/Domain/Library)')
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('-f', '--feature', help='创建 Feature 模块，如: User')
    group.add_argument('-d', '--domain', help='创建 Domain 模块，如: Health')
    group.add_argument('-l', '--library', help='创建 Library 模块，如: Network')

    args = parser.parse_args()

    try:
        if args.feature:
            create_feature(args.feature)
        elif args.domain:
            create_domain(args.domain)
        elif args.library:
            create_library(args.library)
    except FileExistsError as e:
        print(f"[跳过] {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()


