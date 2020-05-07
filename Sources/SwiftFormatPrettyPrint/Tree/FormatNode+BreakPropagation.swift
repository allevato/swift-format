extension FormatNode {
  ///
  public func propagateBreaks() {
    var visitor = BreakPropagatingVisitor()
    visitor.traverse(self, shouldVisitGroupAlternatives: true)
  }
}

///
private struct BreakPropagatingVisitor: FormatNodeVisitor {
  ///
  var groupStack: [FormatNode] = []

  ///
  var visitedNodes: Set<ObjectIdentifier> = []

  mutating func visit(_ node: FormatNode) -> Bool {
    switch node.behavior {
    case .breakParent:
      breakParentGroup()

    case .group:
      groupStack.append(node)
      let objectID = ObjectIdentifier(node)
      guard !visitedNodes.contains(objectID) else { return false }
      visitedNodes.insert(objectID)

    default:
      break
    }
    return true
  }

  mutating func visitPost(_ node: FormatNode) {
    switch node.behavior {
    case .group:
      let group = groupStack.removeLast()
      guard case .group(_, let shouldBreak, _) = group.behavior else {
        fatalError("Internal error: Group stack was inconsistent")
      }
      if shouldBreak {
        breakParentGroup()
      }

    default:
      break
    }
  }

  ///
  private func breakParentGroup() {
    guard let parentGroup = groupStack.last else { return }
    guard
      case .group(let content, _, let alternatives) =
        parentGroup.behavior
    else {
      fatalError("Internal error: Group stack was inconsistent")
    }

    // Don't propagate breaks through alternatives because the user is expected
    // to manually handle which groups break.
    guard alternatives.isEmpty else { return }

    parentGroup.behavior =
      .group(content, shouldBreak: true, alternatives: alternatives)
  }
}
