///
public class FormatNode {
  /// Represents the content of the node and how it is laid out.
  public enum Behavior {
    /// A node containing text.
    case text(String)

    /// A node that concatenates an array of format nodes into a single node.
    case concat([FormatNode])

    /// Content that the printer should try to keep together on the same line,
    /// if possible.
    ///
    /// If the content does not fit, or if `shouldBreak` is true, then the
    /// printer will break the outermost group and try to fit the content again,
    /// repeating this until everything fits or there are no more groups to
    /// break.
    ///
    /// A group can provide alternative layouts that may be used if the main
    /// content doesn't fit. It is assumed that these are ordered from least
    /// expanded to most expanded.
    case group(
      FormatNode, shouldBreak: Bool = false, alternatives: [FormatNode] = [])

    /// A group that lays its contents out until a line is filled, breaking only
    /// when the next element will not fit.
    case fill([FormatNode])

    /// Specifies content that should be printed if the containing group wraps
    /// or if it does not.
    case ifBreak(FormatNode?, noBreak: FormatNode?)

    /// A node containing the specified number of spaces.
    ///
    /// Spaces are not printed at the end of a line.
    case space(Int)

    /// A location where a line break may be inserted if its containing group
    /// doesn't fit on the line.
    case `break`(LineStyle)

    /// Content that is deferred until the end of the current line is reached.
    case lineSuffix(FormatNode)

    /// Increases the indentation level of its contents.
    case indent(FormatNode)

    /// Forces all parent groups to break.
    case breakParent
  }

  /// A string identifier that will be printed in the debug description of the
  /// node.
  public let debugIdentifier: String?

  /// The behavior of the format node.
  public var behavior: Behavior?

  /// Creates a new node with the given debug identifier and unspecified
  /// behavior.
  public init(debugIdentifier: String? = nil) {
    self.debugIdentifier = debugIdentifier
    self.behavior = nil
  }

  /// Creates a new node with the given behavior and no debug identifier.
  ///
  /// The parent references of the nodes in the behavior, if any, will be
  /// updated to refer to the new node.
  public init(_ behavior: Behavior) {
    self.debugIdentifier = nil
    self.behavior = behavior
  }

  /// Updates the node's behavior by merging another behavior into it.
  ///
  /// Behaviors are merged as compactly as possible, to avoid growing the depth
  /// of the tree unnecessarily. The outcome depends on the behaviors being
  /// merged:
  ///
  /// *   If the receiver's behavior is unspecified, it is set to the specified
  ///     behavior.
  /// *   If both the receiver's behavior and the other behavior are `.concat`,
  ///     the receiver's behavior is set to `.concat` with the merged items of
  ///     the original behaviors.
  /// *   If the receiver's behavior is `.concat` and the other behavior is a
  ///     different kind, the receiver's behavior is set to `.concat` with an
  ///     array consisting of the those from the receiver's original `.concat`
  ///     followed by the other behavior.
  /// *   If the other behavior is `.concat` and the receiver's behavior is a
  ///     different kind, the receiver's behavior is set to `.concat` with an
  ///     array consisting of the receiver's behavior followed by those from the
  ///     other's `.concat`.
  /// *   Otherwise, if both behaviors are not `.concat`, then the receiver's
  ///     behavior becomes `.concat` with an array containing the receiver's
  ///     behavior and the other behavior.
  func mergeBehavior(_ other: Behavior) {
    switch (behavior, other) {
    case (nil, _):
      behavior = other
    case (.concat(let selfChildren), .concat(let otherChildren)):
      behavior = .concat(selfChildren + otherChildren)
    case (.concat(let selfChildren), _):
      behavior = .concat(selfChildren + [FormatNode(other)])
    case (let selfBehavior?, .concat(let otherChildren)):
      behavior = .concat([FormatNode(selfBehavior)] + otherChildren)
    case (let selfBehavior?, _):
      behavior = .concat([FormatNode(selfBehavior), FormatNode(other)])
    }
  }

  /// Prints a visual representation of the format tree that is useful for
  /// debugging.
  public func debugPrint() {
    debugPrint(branches: [])
  }

  private func debugPrint(branches: [Bool], prefix: String? = nil) {
    func printNodeDescription(_ description: String) {
      var output = description
      if let debugIdentifier = debugIdentifier {
        output += " <\(debugIdentifier)>"
      }
      print(output)
    }

    for branch in branches.dropLast() {
      print("  \(branch ? "\u{2502}" : " ")", terminator: "")
    }
    if let branch = branches.last {
      print("  \(branch ? "\u{251c}" : "\u{2514}")", terminator: "")
    }
    print("\u{2574} ", terminator: "")
    if let prefix = prefix {
      print("\(prefix): ", terminator: "")
    }

    switch behavior {
    case nil:
      printNodeDescription("<unspecified>")

    case .text(let text):
      printNodeDescription(#"text("\#(text)")"#)

    case .concat(let children):
      printNodeDescription("concat")
      for child in children.dropLast(1) {
        child.debugPrint(branches: branches + [true])
      }
      children.last?.debugPrint(branches: branches + [false])

    case .group(let content, let shouldBreak, let expandedStates):
      printNodeDescription("group(shouldBreak: \(shouldBreak))")
      content.debugPrint(branches: branches + [!expandedStates.isEmpty])

      for child in expandedStates.dropLast(1) {
        child.debugPrint(branches: branches + [true], prefix: "expandedState")
      }
      expandedStates.last?.debugPrint(
        branches: branches + [false], prefix: "expandedState")

    case .fill(let children):
      printNodeDescription("fill")
      for child in children.dropLast(1) {
        child.debugPrint(branches: branches + [true])
      }
      children.last?.debugPrint(branches: branches + [false])

    case .ifBreak(let maybeIfBreak, let maybeNoBreak):
      printNodeDescription("ifBreak")
      if let ifBreak = maybeIfBreak {
        ifBreak.debugPrint(
          branches: branches + [maybeNoBreak != nil], prefix: "ifBreak")
      }
      if let noBreak = maybeNoBreak {
        noBreak.debugPrint(branches: branches + [false], prefix: "noBreak")
      }

    case .space(let count):
      printNodeDescription("space(\(count))")

    case .break(let style):
      printNodeDescription("break(\(style))")

    case .lineSuffix(let content):
      printNodeDescription("lineSuffix")
      content.debugPrint(branches: branches + [false])

    case .indent(let content):
      printNodeDescription("indent")
      content.debugPrint(branches: branches + [false])

    case .breakParent:
      printNodeDescription("breakParent")
    }
  }
}

public enum LineStyle {
  case soft(size: Int)
  case hard
}
