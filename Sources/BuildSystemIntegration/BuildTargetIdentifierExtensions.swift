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

import Foundation
import LanguageServerProtocol
import SKLogging

#if compiler(>=6)
package import BuildServerProtocol
#else
import BuildServerProtocol
#endif

extension BuildTargetIdentifier {
  package static let dummy: BuildTargetIdentifier = BuildTargetIdentifier(uri: try! URI(string: "dummy://dummy"))
}

package enum BuildDestinationIdentifier {
  case host
  case target

  /// A string that can be used to identify the build triple in a `BuildTargetIdentifier`.
  ///
  /// `BuildSystemManager.canonicalBuildTargetIdentifier` picks the canonical target based on alphabetical
  /// ordering. We rely on the string "destination" being ordered before "tools" so that we prefer a
  /// `destination` (or "target") target over a `tools` (or "host") target.
  var id: String {
    switch self {
    case .host:
      return "tools"
    case .target:
      return "destination"
    }
  }
}

extension BuildTargetIdentifier {
  /// - Important: *For testing only*
  package init(target: String, destination: BuildDestinationIdentifier) throws {
    var components = URLComponents()
    components.scheme = "swiftpm"
    components.host = "target"
    components.queryItems = [
      URLQueryItem(name: "target", value: target),
      URLQueryItem(name: "destination", value: destination.id),
    ]

    struct FailedToConvertSwiftBuildTargetToUrlError: Swift.Error, CustomStringConvertible {
      var target: String
      var destination: String

      var description: String {
        return "Failed to generate URL for target: \(target), destination: \(destination)"
      }
    }

    guard let url = components.url else {
      throw FailedToConvertSwiftBuildTargetToUrlError(target: target, destination: destination.id)
    }

    self.init(uri: URI(url))
  }

  fileprivate static let forPackageManifest = BuildTargetIdentifier(uri: try! URI(string: "swiftpm://package-manifest"))

  fileprivate var targetProperties: (target: String, runDestination: String) {
    get throws {
      struct InvalidTargetIdentifierError: Swift.Error, CustomStringConvertible {
        var target: BuildTargetIdentifier

        var description: String {
          return "Invalid target identifier \(target)"
        }
      }
      guard let components = URLComponents(url: self.uri.arbitrarySchemeURL, resolvingAgainstBaseURL: false) else {
        throw InvalidTargetIdentifierError(target: self)
      }
      let target = components.queryItems?.last(where: { $0.name == "target" })?.value
      let runDestination = components.queryItems?.last(where: { $0.name == "destination" })?.value

      guard let target, let runDestination else {
        throw InvalidTargetIdentifierError(target: self)
      }

      return (target, runDestination)
    }
  }
}

#if compiler(>=6)
extension BuildTargetIdentifier: CustomLogStringConvertible {
  package var description: String {
    return uri.stringValue
  }

  package var redactedDescription: String {
    return uri.stringValue.hashForLogging
  }
}
#else
extension BuildTargetIdentifier: CustomLogStringConvertible {
  public var description: String {
    return uri.stringValue
  }

  public var redactedDescription: String {
    return uri.stringValue.hashForLogging
  }
}
#endif
