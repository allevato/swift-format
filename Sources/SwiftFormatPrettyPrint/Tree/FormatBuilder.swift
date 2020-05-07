import SwiftSyntax

///
public struct FormatBuilder {
  /// Represents children of a format node being built.
  private enum Children {
    /// The node has no children.
    case none

    /// The node has one child.
    case single(FormatNode)

    /// The node has more than one child.
    case multiple([FormatNode])
  }

  /// The context through which pending format nodes for the file being
  /// formatted can be reached.
  private let state: FormatBuildingState

  /// The children that have been built so far.
  private var children = Children.none

  ///
  public static func build(
    into node: FormatNode,
    state: FormatBuildingState,
    content: (inout FormatBuilder) -> FormatNode.Behavior
  ) {
    var contentBuilder = FormatBuilder(state: state)
    node.behavior = content(&contentBuilder)
  }

  public static func build(
    into node: FormatNode,
    state: FormatBuildingState,
    content: (inout FormatBuilder) -> Void
  ) {
    var contentBuilder = FormatBuilder(state: state)
    content(&contentBuilder)

    let newNode = contentBuilder.resolvedAsOne()
    if let newBehavior = newNode.behavior {
      node.mergeBehavior(newBehavior)
    } else {
      node.behavior = .concat([newNode])
    }
  }

  /// Creates a new builder with the given context.
  private init(state: FormatBuildingState) {
    self.state = state
  }

  /// Adds the given node to the builder.
  private mutating func add(_ newChild: FormatNode) {
    switch children {
    case .none:
      children = .single(newChild)
    case .single(let firstChild):
      children = .multiple([firstChild, newChild])
    case .multiple(let firstChildren):
      children = .multiple(firstChildren + [newChild])
    }
  }

  /// Builds a new node using the given content function and then adds it to the
  /// builder's children.
  private mutating func add(
    state: FormatBuildingState,
    content: (inout FormatBuilder) -> FormatNode.Behavior
  ) {
    let node = FormatNode()
    FormatBuilder.build(into: node, state: state, content: content)
    add(node)
  }

  /// Returns the nodes in the builder as a single node.
  ///
  /// If this builder contains multiple children, they are wrapped in a new node
  /// with a `concat` behavior. If this builder has no children, this function
  /// traps.
  private func resolvedAsOne() -> FormatNode {
    switch children {
    case .none:
      fatalError("Could not resolve an empty builder as one FormatNode.")
    case .single(let child):
      return child
    case .multiple(let children):
      return FormatNode(.concat(children))
    }
  }

  /// Returns the nodes in the builder.
  private func resolvedAsArray() -> [FormatNode] {
    switch children {
    case .none:
      return []
    case .single(let child):
      return [child]
    case .multiple(let children):
      return children
    }
  }

  /// Adds a node with `group` behavior to the builder whose content is
  /// generated with the given function.
  public mutating func group(_ content: (inout FormatBuilder) -> Void) {
    add(state: state) {
      content(&$0)
      return .group($0.resolvedAsOne())
    }
  }

  /// Adds a node with `fill` behavior to the builder whose content is generated
  /// with the given function.
  public mutating func fill(_ content: (inout FormatBuilder) -> Void) {
    add(state: state) {
      content(&$0)
      return .fill($0.resolvedAsArray())
    }
  }

  /// Adds a node with `indent` behavior to the builder whose content is
  /// generated with the given function.
  public mutating func indent(_ content: (inout FormatBuilder) -> Void) {
    add(state: state) {
      content(&$0)
      return .indent($0.resolvedAsOne())
    }
  }

  /// Adds a node with `ifBreak` behavior to the builder that has content
  /// generated with the given function if the containing group breaks, or no
  /// content if it does not break.
  public mutating func ifBreak(_ breakContent: (inout FormatBuilder) -> Void) {
    add(state: state) {
      var breakBuilder = $0
      breakContent(&breakBuilder)
      let breakNode = breakBuilder.resolvedAsOne()
      return .ifBreak(breakNode, noBreak: nil)
    }
  }

  /// Adds a node with `ifBreak` behavior to the builder that has content
  /// generated with the `breakContent` function if the containing group breaks,
  /// or has content generated with the `noBreakContent` function if it does not
  /// break.
  public mutating func ifBreak(
    _ breakContent: ((inout FormatBuilder) -> Void)?,
    noBreak noBreakContent: ((inout FormatBuilder) -> Void)?
  ) {
    add(state: state) {
      let breakNode: FormatNode?
      let noBreakNode: FormatNode?

      if let breakContent = breakContent {
        var breakBuilder = $0
        breakContent(&breakBuilder)
        breakNode = breakBuilder.resolvedAsOne()
      } else {
        breakNode = nil
      }

      if let noBreakContent = noBreakContent {
        var noBreakBuilder = $0
        noBreakContent(&noBreakBuilder)
        noBreakNode = noBreakBuilder.resolvedAsOne()
      } else {
        noBreakNode = nil
      }

      return .ifBreak(breakNode, noBreak: noBreakNode)
    }
  }

  /// Adds a node with `text` behavior to the builder whose content is the given
  /// text string.
  public mutating func text(_ text: String) {
    add(FormatNode(.text(text)))
  }

  /// Adds a node with `line` behavior to the builder that has the given line
  /// style.
  public mutating func `break`(_ style: LineStyle) {
    add(FormatNode(.break(style)))
  }

  /// Adds a node with `space` behavior to the builder that has the given count.
  public mutating func space(_ count: Int) {
    add(FormatNode(.space(count)))
  }

  /// Adds a node with `lineSuffix` behavior to the builder whose content is
  /// generated with the given function.
  public mutating func lineSuffix(_ content: (inout FormatBuilder) -> Void) {
    add(state: state) {
      content(&$0)
      return .lineSuffix($0.resolvedAsOne())
    }
  }

  ///
  public mutating func join<Items: Collection> (
    _ items: Items,
    _ content: (inout FormatBuilder, Items.Element) -> Void,
    separator: (inout FormatBuilder) -> Void
  ) {
    guard let first = items.first else { return }

    content(&self, first)
    for item in items.dropFirst() {
      separator(&self)
      content(&self, item)
    }
  }

  /// Returns a `FormatNode` that represents a placeholder for a child node that
  /// has yet to be visited, but whose behavior—once formatted—should be
  /// inserted in its place in the format tree.
  ///
  /// - Parameter node: The syntax node for which a placeholder should be
  ///   registered and returned.
  /// - Returns: A placeholder `FormatNode` that must have its behavior assigned
  ///   during a subsequent visitation.
  public mutating func format<Node: SyntaxProtocol>(_ node: Node) {
    #if DEBUG
      let pending = FormatNode(debugIdentifier: "\(type(of: node))")
    #else
      let pending = FormatNode()
    #endif
    state.setPendingNode(pending, forID: node.id)
    add(pending)
  }

  /// Returns a `FormatNode` that represents a placeholder for a child node that
  /// has yet to be visited, but whose behavior—once formatted—should be
  /// inserted in its place in the format tree.
  ///
  /// - Parameter node: The syntax node for which a placeholder should be
  ///   registered and returned.
  /// - Returns: A placeholder `FormatNode` that must have its behavior assigned
  ///   during a subsequent visitation.
  public mutating func format(_ node: SyntaxProtocol) {
    #if DEBUG
      let pending = FormatNode(debugIdentifier: "\(type(of: node))")
    #else
      let pending = FormatNode()
    #endif
    state.setPendingNode(pending, forID: node.id)
    add(pending)
  }

  /// Returns a `FormatNode` that represents a placeholder for a child node that
  /// has yet to be visited, but whose behavior—once formatted—should be
  /// inserted in its place in the format tree.
  ///
  /// - Parameter node: The syntax node for which a placeholder should be
  ///   registered and returned.
  /// - Returns: A placeholder `FormatNode` that must have its behavior assigned
  ///   during a subsequent visitation.
  public mutating func format(_ node: Syntax) {
    // Cast the type-erased node back to its actual type so that the debug
    // identifier is properly computed.
    format(node.asProtocol(SyntaxProtocol.self))
  }

  ///
  public mutating func formatIfPresent<Node: SyntaxProtocol>(_ node: Node?) {
    guard let node = node else { return }
    format(node)
  }

  ///
  public mutating func format<Nodes: Sequence>(_ nodes: Nodes)
  where Nodes.Element: SyntaxProtocol {
    nodes.forEach { format($0) }
  }

  ///
  public mutating func skip<Node: SyntaxProtocol>(_ node: Node?) {
    guard let node = node else { return }
    state.skipNode(withID: node.id)
  }
}
