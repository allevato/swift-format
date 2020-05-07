import SwiftFormatCore
import SwiftSyntax

/// Rewriter that relocates comment trivia around nodes where comments are known to be better
/// formatted when placed before or after the node.
///
/// For example, comments after binary operators are relocated to be before the operator, which
/// results in fewer line breaks with the comment closer to the relevant tokens.
class CommentMovingRewriter: SyntaxRewriter {
  /// Map of tokens to alternate trivia to use as the token's leading trivia.
  var rewriteTokenTriviaMap: [TokenSyntax: Trivia] = [:]

  override func visit(_ node: SourceFileSyntax) -> Syntax {
    if shouldFormatterIgnore(file: node) {
      return Syntax(node)
    }
    return super.visit(node)
  }

  override func visit(_ node: CodeBlockItemSyntax) -> Syntax {
    if shouldFormatterIgnore(node: Syntax(node)) {
      return Syntax(node)
    }
    return super.visit(node)
  }

  override func visit(_ node: MemberDeclListItemSyntax) -> Syntax {
    if shouldFormatterIgnore(node: Syntax(node)) {
      return Syntax(node)
    }
    return super.visit(node)
  }

  override func visit(_ token: TokenSyntax) -> Syntax {
    if let rewrittenTrivia = rewriteTokenTriviaMap[token] {
      return Syntax(token.withLeadingTrivia(rewrittenTrivia))
    }
    return Syntax(token)
  }

  override func visit(_ node: SequenceExprSyntax) -> ExprSyntax {
    for element in node.elements {
      if let binaryOperatorExpr = element.as(BinaryOperatorExprSyntax.self),
        let followingToken = binaryOperatorExpr.operatorToken.nextToken,
        followingToken.leadingTrivia.hasLineComment
      {
        // Rewrite the trivia so that the comment is in the operator token's leading trivia.
        let (remainingTrivia, extractedTrivia) = extractLineCommentTrivia(from: followingToken)
        let combinedTrivia = binaryOperatorExpr.operatorToken.leadingTrivia + extractedTrivia
        rewriteTokenTriviaMap[binaryOperatorExpr.operatorToken] = combinedTrivia
        rewriteTokenTriviaMap[followingToken] = remainingTrivia
      }
    }
    return super.visit(node)
  }

  /// Extracts trivia containing and related to line comments from `token`'s leading trivia. Returns
  /// 2 trivia collections: the trivia that wasn't extracted and should remain in `token`'s leading
  /// trivia and the trivia that meets the criteria for extraction.
  /// - Parameter token: A token whose leading trivia should be split to extract line comments.
  private func extractLineCommentTrivia(from token: TokenSyntax) -> (
    remainingTrivia: Trivia, extractedTrivia: Trivia
  ) {
    var pendingPieces = [TriviaPiece]()
    var keepWithTokenPieces = [TriviaPiece]()
    var extractingPieces = [TriviaPiece]()

    // Line comments and adjacent newlines are extracted so they can be moved to a different token's
    // leading trivia, while all other kinds of tokens are left as-is.
    var lastPiece: TriviaPiece?
    for piece in token.leadingTrivia {
      defer { lastPiece = piece }
      switch piece {
      case .lineComment:
        extractingPieces.append(contentsOf: pendingPieces)
        pendingPieces.removeAll()
        extractingPieces.append(piece)
      case .blockComment, .docLineComment, .docBlockComment:
        keepWithTokenPieces.append(contentsOf: pendingPieces)
        pendingPieces.removeAll()
        keepWithTokenPieces.append(piece)
      case .newlines, .carriageReturns, .carriageReturnLineFeeds:
        if case .lineComment = lastPiece {
          extractingPieces.append(piece)
        } else {
          pendingPieces.append(piece)
        }
      default:
        pendingPieces.append(piece)
      }
    }
    keepWithTokenPieces.append(contentsOf: pendingPieces)
    return (Trivia(pieces: keepWithTokenPieces), Trivia(pieces: extractingPieces))
  }
}

/// Returns whether the given trivia includes a directive to ignore formatting for the next node.
///
/// - Parameters:
///   - trivia: Leading trivia for a node that the formatter supports ignoring.
///   - isWholeFile: Whether to search for a whole-file ignore directive or per node ignore.
/// - Returns: Whether the trivia contains the specified type of ignore directive.
func isFormatterIgnorePresent(inTrivia trivia: Trivia, isWholeFile: Bool) -> Bool {
  func isFormatterIgnore(in commentText: String, prefix: String, suffix: String) -> Bool {
    let trimmed =
      commentText.dropFirst(prefix.count)
        .dropLast(suffix.count)
        .trimmingCharacters(in: .whitespaces)
    let pattern = isWholeFile ? "swift-format-ignore-file" : "swift-format-ignore"
    return trimmed == pattern
  }

  for piece in trivia {
    switch piece {
    case .lineComment(let text):
      if isFormatterIgnore(in: text, prefix: "//", suffix: "") { return true }
      break
    case .blockComment(let text):
      if isFormatterIgnore(in: text, prefix: "/*", suffix: "*/") { return true }
      break
    default:
      break
    }
  }
  return false
}

/// Returns whether the formatter should ignore the given node by printing it without changing the
/// node's internal text representation (i.e. print all text inside of the node as it was in the
/// original source).
///
/// - Note: The caller is responsible for ensuring that the given node is a type of node that can
/// be safely ignored.
///
/// - Parameter node: A node that can be safely ignored.
func shouldFormatterIgnore(node: Syntax) -> Bool {
  // Regardless of the level of nesting, if the ignore directive is present on the first token
  // contained within the node then the entire node is eligible for ignoring.
  if let firstTrivia = node.firstToken?.leadingTrivia {
    return isFormatterIgnorePresent(inTrivia: firstTrivia, isWholeFile: false)
  }
  return false
}

/// Returns whether the formatter should ignore the given file by printing it without changing the
/// any if its nodes' internal text representation (i.e. print all text inside of the file as it was
/// in the original source).
///
/// - Parameter file: The root syntax node for a source file.
func shouldFormatterIgnore(file: SourceFileSyntax) -> Bool {
  if let firstTrivia = file.firstToken?.leadingTrivia {
    return isFormatterIgnorePresent(inTrivia: firstTrivia, isWholeFile: true)
  }
  return false
}
