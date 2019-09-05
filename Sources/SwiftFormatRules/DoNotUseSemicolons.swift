//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftFormatCore
import SwiftSyntax

/// Semicolons should not be present in Swift code.
///
/// Lint: If a semicolon appears anywhere, a lint error is raised.
///
/// Format: All semicolons will be replaced with line breaks.
///
/// - SeeAlso: https://google.github.io/swift#semicolons
public final class DoNotUseSemicolons: SyntaxFormatRule {

  /// Creates a new version of the given node which doesn't contain any semicolons. The node's
  /// items are recursively modified to remove semicolons, replacing with line breaks where needed.
  /// Items are checked recursively to support items that contain code blocks, which may have
  /// semicolons to be removed.
  /// - Parameters:
  ///   - node: A node that contains items which may have semicolons or nested code blocks.
  ///   - nodeCreator: A closure that creates a new node given an array of items.
  private func nodeByRemovingSemicolons<
    ItemType: Syntax & SemicolonSyntax & Equatable, NodeType: SyntaxCollection
  >(from node: NodeType, nodeCreator: ([ItemType]) -> NodeType) -> NodeType
  where NodeType.Element == ItemType {
    var newItems = Array(node)

    // Because newlines belong to the _first_ token on the new line, if we remove a semicolon, we
    // need to keep track of the fact that the next statement needs a new line.
    var previousHadSemicolon = false
    for (idx, item) in node.enumerated() {

      // Store the previous statement's semicolon-ness.
      defer { previousHadSemicolon = item.semicolon != nil }

      // Check for semicolons in statements inside of the item, because code blocks may be nested
      // inside of other code blocks.
      guard let visitedItem = visit(item) as? ItemType else {
        return node
      }

      // Check if we need to make any modifications (removing semicolon/adding newlines)
      guard visitedItem != item || item.semicolon != nil || previousHadSemicolon else {
        continue
      }

      var newItem = visitedItem

      // Check if the leading trivia for this statement needs a new line.
      if previousHadSemicolon, let firstToken = newItem.firstToken,
        !firstToken.leadingTrivia.containsNewlines
      {
        let leadingTrivia = .newlines(1) + firstToken.leadingTrivia
        newItem = replaceTrivia(
          on: newItem,
          token: firstToken,
          leadingTrivia: leadingTrivia
        ) as! ItemType
      }

      // If there's a semicolon, diagnose and remove it.
      if let semicolon = item.semicolon {
        // This discards any trailingTrivia from the semicolon. That trivia is at most some spaces,
        // and the pretty printer adds any necessary spaces so it's safe to discard.
        newItem = newItem.withSemicolon(nil)
        if idx < node.count - 1 {
          diagnose(.removeSemicolonAndMove, on: semicolon)
        } else {
          diagnose(.removeSemicolon, on: semicolon)
        }
      }
      newItems[idx] = newItem
    }
    return nodeCreator(newItems)
  }

  public override func visit(_ node: CodeBlockItemListSyntax) -> Syntax {
    return nodeByRemovingSemicolons(from: node, nodeCreator: SyntaxFactory.makeCodeBlockItemList)
  }

  public override func visit(_ node: MemberDeclListSyntax) -> Syntax {
    return nodeByRemovingSemicolons(from: node, nodeCreator: SyntaxFactory.makeMemberDeclList)
  }
}

extension Diagnostic.Message {
  static let removeSemicolon = Diagnostic.Message(.warning, "remove ';'")

  static let removeSemicolonAndMove = Diagnostic.Message(
    .warning, "remove ';' and move the next statement to a new line")
}
