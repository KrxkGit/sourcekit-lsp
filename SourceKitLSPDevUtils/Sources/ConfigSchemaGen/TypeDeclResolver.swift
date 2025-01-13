//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

/// Resolves type declarations from Swift syntax nodes
class TypeDeclResolver {
  typealias TypeDecl = NamedDeclSyntax & DeclGroupSyntax & DeclSyntaxProtocol
  /// A representation of a qualified name of a type declaration
  ///
  /// `Outer.Inner` type declaration is represented as ["Outer", "Inner"]
  typealias QualifiedName = [String]
  private var typeDeclByQualifiedName: [QualifiedName: TypeDecl] = [:]

  enum Error: Swift.Error {
    case typeNotFound(QualifiedName)
  }

  private class TypeDeclCollector: SyntaxVisitor {
    let resolver: TypeDeclResolver
    var scope: [TypeDecl] = []
    var rootTypeDecls: [TypeDecl] = []

    init(resolver: TypeDeclResolver) {
      self.resolver = resolver
      super.init(viewMode: .all)
    }

    func visitNominalDecl(_ node: TypeDecl) -> SyntaxVisitorContinueKind {
      let name = node.name.text
      let qualifiedName = scope.map(\.name.text) + [name]
      resolver.typeDeclByQualifiedName[qualifiedName] = node
      scope.append(node)
      return .visitChildren
    }

    func visitPostNominalDecl() {
      let type = scope.removeLast()
      if scope.isEmpty {
        rootTypeDecls.append(type)
      }
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
      return visitNominalDecl(node)
    }
    override func visitPost(_ node: StructDeclSyntax) {
      visitPostNominalDecl()
    }
    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
      return visitNominalDecl(node)
    }
    override func visitPost(_ node: EnumDeclSyntax) {
      visitPostNominalDecl()
    }
  }

  /// Collects type declarations from a parsed Swift source file
  func collect(from schema: SourceFileSyntax) {
    let collector = TypeDeclCollector(resolver: self)
    collector.walk(schema)
  }

  /// Builds the type name scope for a given type usage
  private func buildScope(type: IdentifierTypeSyntax) -> QualifiedName {
    var innerToOuter: [String] = []
    var context: SyntaxProtocol = type
    while let parent = context.parent {
      if let parent = parent.asProtocol(NamedDeclSyntax.self), parent.isProtocol(DeclGroupSyntax.self) {
        innerToOuter.append(parent.name.text)
      }
      context = parent
    }
    return innerToOuter.reversed()
  }

  /// Looks up a qualified name of a type declaration by its unqualified type usage
  /// Returns the qualified name hierarchy of the type declaration
  /// If the type declaration is not found, returns the unqualified name
  private func tryQualify(type: IdentifierTypeSyntax) -> QualifiedName {
    let name = type.name.text
    let scope = buildScope(type: type)
    /// Search for the type declaration from the innermost scope to the outermost scope
    for i in (0...scope.count).reversed() {
      let qualifiedName = Array(scope[0..<i] + [name])
      if typeDeclByQualifiedName[qualifiedName] != nil {
        return qualifiedName
      }
    }
    return [name]
  }

  /// Looks up a type declaration by its unqualified type usage
  func lookupType(for type: IdentifierTypeSyntax) throws -> TypeDecl {
    let qualifiedName = tryQualify(type: type)
    guard let typeDecl = typeDeclByQualifiedName[qualifiedName] else {
      throw Error.typeNotFound(qualifiedName)
    }
    return typeDecl
  }

  /// Looks up a type declaration by its fully qualified name
  func lookupType(fullyQualified: QualifiedName) throws -> TypeDecl {
    guard let typeDecl = typeDeclByQualifiedName[fullyQualified] else {
      throw Error.typeNotFound(fullyQualified)
    }
    return typeDecl
  }
}
