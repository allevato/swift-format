import SwiftSyntax

/// Rewrites a syntax tree by folding any sequence expressions contained in it.
class SequenceExprFoldingRewriter: SyntaxRewriter {
  private let operatorContext: OperatorContext

  init(operatorContext: OperatorContext) {
    self.operatorContext = operatorContext
  }

  override func visit(_ node: SequenceExprSyntax) -> ExprSyntax {
    let rewrittenBySuper = super.visit(node)
    if let sequence = rewrittenBySuper.as(SequenceExprSyntax.self) {
      return sequence.folded(context: operatorContext)
    } else {
      return rewrittenBySuper
    }
  }
}
