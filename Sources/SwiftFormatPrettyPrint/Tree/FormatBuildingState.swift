import SwiftSyntax

/// Holds contextual information about a file being formatted that is passed
/// across multiple builders as the format tree is created.
public class FormatBuildingState {
  /// Format nodes corresponding to syntax nodes.
  private var syntaxFormatNodes = [SyntaxIdentifier: FormatNode]()

  /// Nodes that should be skipped (as well as their children) when they are
  /// visited.
  private var skippedNodes = Set<SyntaxIdentifier>()

  /// Returns the pending format node that was registered for the syntax node
  /// with the given identifier.
  public func pendingNode(forID id: SyntaxIdentifier) -> FormatNode? {
    return syntaxFormatNodes[id]
  }

  /// Registers a pending format node for the syntax node with the given
  /// identifier.
  public func setPendingNode(
    _ formatNode: FormatNode,
    forID id: SyntaxIdentifier
  ) {
    syntaxFormatNodes[id] = formatNode
  }

  /// Marks a syntax node and its children to be skipped.
  public func skipNode(withID id: SyntaxIdentifier) {
    skippedNodes.insert(id)
  }

  /// Returns a value indicating whether the syntax node with the given
  /// identifier and its children should be skipped.
  public func shouldSkipNode(withID id: SyntaxIdentifier) -> Bool {
    return skippedNodes.contains(id)
  }
}
