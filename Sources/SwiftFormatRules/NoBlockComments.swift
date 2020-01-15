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

/// Block comments should be avoided in favor of line comments.
///
/// Lint: If a block comment appears, a lint error is raised.
///
/// Format: If a block comment appears on its own on a line, or if a block comment spans multiple
///         lines without appearing on the same line as code, it will be replaced with multiple
///         single-line comments.
///         If a block comment appears inline with code, it will be removed and hoisted to the line
///         above the code it appears on.
///
/// - SeeAlso: https://google.github.io/swift#non-documentation-comments
public final class NoBlockComments: SyntaxFormatRule {
  public override func visit(_ token: TokenSyntax) -> Syntax {
    var pieces = [TriviaPiece]()
    var didChangeTrivia = false

    // Replaces block comments with line comments, unless the comment is between tokens on the same
    // line.
    let leadingTrivia = token.leadingTrivia
    for pieceIndex in leadingTrivia.indices {
      let piece = leadingTrivia[pieceIndex]
      if case .blockComment(let text) = piece {
        if isEndOfLineTriviaPiece(
          at: pieceIndex,
          in: leadingTrivia,
          isEOF: token.tokenKind == .eof
        ) {
          diagnose(.avoidBlockComment, on: token)
          didChangeTrivia = true
          pieces.append(contentsOf: rewrittenTriviaPieces(forBlockComment: text))
        } else {
          diagnose(.avoidBlockCommentBetweenCode, on: token)
          pieces.append(piece)
        }
      } else {
        pieces.append(piece)
      }
    }

    return didChangeTrivia ? token.withLeadingTrivia(Trivia(pieces: pieces)) : token
  }

  /// Returns a value indicating whether the trivia piece at the given index in a trivia collection
  /// is at the end of the line that it occupies (excluding trailing whitespace).
  private func isEndOfLineTriviaPiece(
    at index: Trivia.Index,
    in trivia: Trivia,
    isEOF: Bool = false
  ) -> Bool {
    var index = trivia.index(after: index)
    while index != trivia.endIndex {
      switch trivia[index] {
      case .spaces, .tabs, .verticalTabs, .formfeeds:
        // Ignore non-newline whitespace.
        break
      case .newlines, .carriageReturns, .carriageReturnLineFeeds:
        // If we first encounter a newline or carriage return, the trivia piece was at the end of
        // a line.
        return true
      default:
        // If we encounter non-whitespace/non-newline trivia, the comment must be on the same line
        // as other text after it.
        return false
      }
      trivia.formIndex(after: &index)
    }

    // If we ran out of trivia but didn't encounter a newline or carriage return, then it's the end
    // of line only if the token is the end of the file.
    return isEOF
  }

  /// Receives the text of a Block comment and converts it to a Line Comment format text.
  private func rewrittenTriviaPieces(forBlockComment text: String) -> [TriviaPiece] {
    // Remove the comment delimiters and trim non-newline whitespace characters.
    var text = text.dropFirst(2).dropLast(2)

    // Remove only the first and last newline if they are present, to avoid extra line comment lines
    // when the user puts the comment delimiters (and nothing else) on their own lines.
    if text.first == "\n" {
      text = text.dropFirst(1)
    }
    if text.last == "\n" {
      text = text.dropLast(1)
    }

    let commentLines = text.split(separator: "\n", omittingEmptySubsequences: false)

    var pieces = [TriviaPiece]()
    for line in commentLines {
      if !pieces.isEmpty {
        pieces.append(.newlines(1))
      }
      let prefix = line.starts(with: " ") || line.count == 0 ? "//" : "// "
      let lineComment = (prefix + line).trimmingCharacters(in: .whitespaces)
      pieces.append(.lineComment(lineComment))
    }
    return pieces
  }
}

extension Diagnostic.Message {
  static let avoidBlockComment = Diagnostic.Message(
    .warning, "replace block comment with line comments")

  static let avoidBlockCommentBetweenCode = Diagnostic.Message(
    .warning, "remove block comment inline with code")
}
