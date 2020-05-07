///
public protocol FormatNodeVisitor {
  ///
  mutating func visit(_ node: FormatNode) -> Bool

  ///
  mutating func visitPost(_ node: FormatNode)
}

///
private enum FormatNodeVisitingState {
  ///
  case entering(FormatNode)

  ///
  case exiting(FormatNode)
}

extension FormatNodeVisitor {
  ///
  public mutating func traverse(
    _ root: FormatNode,
    shouldVisitGroupAlternatives: Bool = true
  ) {
    var stack: [FormatNodeVisitingState] = [.entering(root)]

    while let current = stack.popLast() {
      switch current {
      case .exiting(let node):
        visitPost(node)

      case .entering(let node):
        stack.append(.exiting(node))
        let visitChildren = visit(node)
        guard visitChildren else { break }

        switch node.behavior {
        case .concat(let children), .fill(let children):
          children.reversed().forEach { stack.append(.entering($0)) }

        case .group(let content, _, let alternatives):
          if shouldVisitGroupAlternatives {
            alternatives.reversed().forEach { stack.append(.entering($0)) }
          }
          stack.append(.entering(content))

        case .ifBreak(let ifBreak, let noBreak):
          if let noBreak = noBreak { stack.append(.entering(noBreak)) }
          if let ifBreak = ifBreak { stack.append(.entering(ifBreak)) }

        case .indent(let content), .lineSuffix(let content):
          stack.append(.entering(content))

        default:
          break
        }
      }
    }
  }
}
