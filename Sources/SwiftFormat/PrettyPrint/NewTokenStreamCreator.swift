import SwiftOperators

@_spi(SyntaxTransformVisitor) import SwiftSyntax

func computeCommands(_ creator: NewTokenStreamCreator, node: Syntax) -> [Token] {
  _ = creator.rewrite(node, detach: true)
  return creator.commands
}

protocol EnvironmentKey {
  associatedtype Value
  
  static var defaultValue: Value { get }
}

struct EnvironmentValues {
  struct Box {
    let key: any EnvironmentKey.Type
    let value: Any
  }

  private var stack: [Box] = []

  mutating func push<Key: EnvironmentKey>(_ value: Key.Value, for key: Key.Type) {
    stack.append(Box(key: key, value: value))
  }
  
  mutating func pop() {
    stack.removeLast()
  }
  
  func value<Key: EnvironmentKey>(for key: Key.Type) -> Key.Value {
    for box in stack.reversed() {
      if box.key == key {
        return box.value as! Key.Value
      }
    }
    return Key.defaultValue
  }
}

final class NewTokenStreamCreator: SyntaxRewriter {
  struct SingleBindingVarDecl: EnvironmentKey {
    static var defaultValue: Bool { false }
  }
  
  var commands: [Token] = []
  
  var environment: EnvironmentValues = EnvironmentValues()
  
  let configuration: Configuration
  
  let operatorTable: OperatorTable
  
  /// The index of the most recently appended break, or nil when no break has been appended.
  private var lastBreakIndex: Int? = nil
  
  /// Whether newlines can be merged into the most recent break, based on which tokens have been
  /// appended since that break.
  private var canMergeNewlinesIntoLastBreak = false
  
  init(configuration: Configuration, operatorTable: OperatorTable) {
    self.configuration = configuration
    self.operatorTable = operatorTable
  }

  private func format<Node: SyntaxProtocol>(
    _ node: Node, body: () -> Void
  ) -> Node {
    body()
    return node
  }
  
  private func format<Node: DeclSyntaxProtocol>(
    _ node: Node, body: () -> Void
  ) -> DeclSyntax {
    body()
    return DeclSyntax(node)
  }
  
  private func format<Node: ExprSyntaxProtocol>(
    _ node: Node, body: () -> Void
  ) -> ExprSyntax {
    body()
    return ExprSyntax(node)
  }
  
  private func format<Node: PatternSyntaxProtocol>(
    _ node: Node, body: () -> Void
  ) -> PatternSyntax {
    body()
    return PatternSyntax(node)
  }
  
  private func format<Node: StmtSyntaxProtocol>(
    _ node: Node, body: () -> Void
  ) -> StmtSyntax {
    body()
    return StmtSyntax(node)
  }
  
  private func format<Node: TypeSyntaxProtocol>(
    _ node: Node, body: () -> Void
  ) -> TypeSyntax {
    body()
    return TypeSyntax(node)
  }
  
  private func arrange<Node: SyntaxProtocol>(_ node: Node) {
    _ = rewrite(node, detach: true)
  }
  
  override func visit(_ node: AccessorBlockSyntax) -> AccessorBlockSyntax {
    format(node) {
      switch node.accessors {
      case .accessors(let accessors):
        arrangeBracesAndContents(
          leftBrace: node.leftBrace,
          accessors: accessors,
          rightBrace: node.rightBrace)
      case .getter:
        arrangeBracesAndContents(
          of: node,
          contentsKeyPath: \.getterCodeBlockItems)
      }
    }
  }
  
  override func visit(_ node: AccessorDeclListSyntax) -> AccessorDeclListSyntax {
    format(node) {
      if let last = node.last {
        for child in node.dropLast(1) {
          arrange(child)
          
          let newlines: NewlineBehavior = child.body == nil ? .elective : .soft
          `break`(.same, size: 1, newlines: newlines)
        }
        arrange(last)
      }
    }
  }
  
  override func visit(_ node: AccessorDeclSyntax) -> DeclSyntax {
    format(node) {
      arrange(node.attributes)
      if let modifier = node.modifier {
        arrange(modifier)
      }
      
      arrange(node.accessorSpecifier)
      if let parameters = node.parameters {
        arrange(parameters)
      }
      if let effectSpecifiers = node.effectSpecifiers {
        arrange(effectSpecifiers)
      }
      if let body = node.body {
        arrange(body)
      }
    }
  }
  
  override func visit(_ node: AccessorEffectSpecifiersSyntax) -> AccessorEffectSpecifiersSyntax {
    format(node) {
      arrangeEffectSpecifiers(node)
    }
  }
  
  override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
    format(node) {
      arrangeTypeDeclBlock(
        attributes: node.attributes,
        modifiers: node.modifiers,
        typeKeyword: node.actorKeyword,
        name: node.name,
        genericParameterOrPrimaryAssociatedTypeClause: node.genericParameterClause.map(Syntax.init),
        inheritanceClause: node.inheritanceClause,
        genericWhereClause: node.genericWhereClause,
        memberBlock: node.memberBlock)
    }
  }
  
  override func visit(_ node: ArrayExprSyntax) -> ExprSyntax {
    format(node) {
      arrange(node.leftSquare)
      `break`(.open, size: 0)
      group {
        arrange(node.elements)
        `break`(.close, size: 0)
      }
      arrange(node.rightSquare)
    }
  }
  
  override func visit(_ node: ArrayElementSyntax) -> ArrayElementSyntax{
    format(node) {
      arrange(node.expression)
      if let trailingComma = node.trailingComma {
        arrange(trailingComma)
        `break`(.same)
      }
    }
  }
  
  override func visit(_ node: ArrayTypeSyntax) -> TypeSyntax {
    format(node) {
      arrange(node.leftSquare)
      arrange(Syntax(node.element))
      arrange(node.rightSquare)
    }
  }

  private func forEach<Nodes: SyntaxCollection>(
    _ node: Nodes,
    execute: (Nodes.Element) -> Void,
    separator: () -> Void
  ) {
    if let first = node.first {
      execute(first)
      for child in node.dropFirst() {
        separator()
        execute(child)
      }
    }
  }

  override func visit(_ node: AttributeListSyntax) -> AttributeListSyntax {
    format(node) {
      guard !node.isEmpty else { return }
      
      group {
        forEach(node) { child in
          arrange(child)
        } separator: {
          `break`(.same)
        }
      }
      // TODO: suppressFinalBreak
      `break`(.same)
    }
  }
  
  override func visit(_ node: AvailabilityArgumentListSyntax) -> AvailabilityArgumentListSyntax {
    format(node) {
      forEach(node) { child in
        arrange(child)
      } separator: {
        `break`(.same, size: 1)
      }
    }
  }

  override func visit(_ node: AvailabilityLabeledArgumentSyntax) -> AvailabilityLabeledArgumentSyntax {
    format(node) {
      group {
        arrange(node.label)
        arrange(node.colon)
        `break`(.continue, newlines: .elective(ignoresDiscretionary: true))
        arrange(node.value)
      }
    }
  }

  override func visit(_ node: BreakStmtSyntax) -> StmtSyntax {
    format(node) {
      arrange(node.breakKeyword)
      if let label = node.label {
        `break`()
        arrange(label)
      }
    }
  }
  
  override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    format(node) {
      arrangeTypeDeclBlock(
        attributes: node.attributes,
        modifiers: node.modifiers,
        typeKeyword: node.classKeyword,
        name: node.name,
        genericParameterOrPrimaryAssociatedTypeClause: node.genericParameterClause.map(Syntax.init),
        inheritanceClause: node.inheritanceClause,
        genericWhereClause: node.genericWhereClause,
        memberBlock: node.memberBlock)
    }
  }
  
  override func visit(_ node: CodeBlockItemSyntax) -> CodeBlockItemSyntax {
    format(node) {
      let newlines: NewlineBehavior = /*
                                       item != node.last && shouldInsertNewline(basedOn: item.semicolon) ?*/ .soft /*: .elective*/
      let resetSize = node.semicolon != nil ? 1 : 0
      
      group {
        arrange(node.item)
        if let semicolon = node.semicolon {
          arrange(semicolon)
        }
      }
      `break`(.reset, size: resetSize, newlines: newlines)
    }
  }
  
  override func visit(_ node: CodeBlockSyntax) -> CodeBlockSyntax {
    format(node) {
      arrangeBracesAndContents(of: node, contentsKeyPath: \.statements)
    }
  }
  
  override func visit(_ node: ConformanceRequirementSyntax) -> ConformanceRequirementSyntax {
    format(node) {
      arrange(node.leftType)
      arrange(node.colon)
      `break`()
      arrange(node.rightType)
    }
  }

  override func visit(_ node: ContinueStmtSyntax) -> StmtSyntax {
    format(node) {
      arrange(node.continueKeyword)
      if let label = node.label {
        `break`()
        arrange(label)
      }
    }
  }
  
  override func visit(_ node: DeclModifierDetailSyntax) -> DeclModifierDetailSyntax {
    format(node) {
      arrange(node.leftParen)
      arrange(node.detail)
      arrange(node.rightParen)
    }
  }
  
  override func visit(_ node: DeclModifierSyntax) -> DeclModifierSyntax {
    format(node) {
      arrange(node.name)
      if let detail = node.detail {
        arrange(detail)
      }
      
      // Due to the way we currently use spaces after variable binding specifiers, we need this
      // special exception for `async let` statements to avoid breaking prematurely between the
      // `async` and `let` keywords.
      if node.name.tokenKind == .keyword(.async) {
        space()
      } else {
        `break`()
      }
    }
  }
  
  override func visit(_ node: DeferStmtSyntax) -> StmtSyntax {
    format(node) {
      arrange(node.deferKeyword)
      arrange(node.body)
    }
  }
  
  override func visit(_ node: DeinitializerDeclSyntax) -> DeclSyntax {
    format(node) {
      group {
        arrange(node.attributes)
        arrange(node.modifiers)
        arrange(node.deinitKeyword)
        if let effectSpecifiers = node.effectSpecifiers {
          arrange(effectSpecifiers)
        }
        if let body = node.body {
          arrange(body)
        }
      }
    }
  }
  
  override func visit(_ node: DeinitializerEffectSpecifiersSyntax) -> DeinitializerEffectSpecifiersSyntax {
    format(node) {
      if let asyncSpecifier = node.asyncSpecifier {
        `break`()
        arrange(asyncSpecifier)
      }
    }
  }
  
  override func visit(_ node: DictionaryTypeSyntax) -> TypeSyntax {
    format(node) {
      arrange(node.leftSquare)
      arrange(node.key)
      arrange(node.colon)
      `break`()
      arrange(node.value)
      arrange(node.rightSquare)
    }
  }
  
  override func visit(_ node: DoStmtSyntax) -> StmtSyntax {
    format(node) {
      arrange(node.doKeyword)
      arrange(node.body)
      arrange(node.catchClauses)
    }
  }
  
  override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
    format(node) {
      arrangeTypeDeclBlock(
        attributes: node.attributes,
        modifiers: node.modifiers,
        typeKeyword: node.enumKeyword,
        name: node.name,
        genericParameterOrPrimaryAssociatedTypeClause: node.genericParameterClause.map(Syntax.init),
        inheritanceClause: node.inheritanceClause,
        genericWhereClause: node.genericWhereClause,
        memberBlock: node.memberBlock)
    }
  }
  
  override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
    format(node) {
      arrangeTypeDeclBlock(
        attributes: node.attributes,
        modifiers: node.modifiers,
        typeKeyword: node.extensionKeyword,
        name: node.extendedType,
        genericParameterOrPrimaryAssociatedTypeClause: nil,
        inheritanceClause: node.inheritanceClause,
        genericWhereClause: node.genericWhereClause,
        memberBlock: node.memberBlock)
    }
  }
  
  override func visit(_ node: FallThroughStmtSyntax) -> StmtSyntax {
    format(node) {
      arrange(node.fallthroughKeyword)
    }
  }
  
  override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
    format(node) {
      arrange(node.calledExpression)
      if let leftParen = node.leftParen, let rightParen = node.rightParen {
        arrange(leftParen)
        
        if !node.arguments.isEmpty {
          `break`(.open, size: 0)
          group(argumentListConsistency(), if: shouldGroupAroundArgumentList(node.arguments)) {
            arrange(node.arguments)
            `break`(.close, size: 0)
          }
        }
        
        arrange(rightParen)
      }
      
      if node.trailingClosure != nil &&
          !isCompactSingleFunctionCallArgument(node.arguments) {
        `break`(.same, newlines: .elective(ignoresDiscretionary: true))
      }
      
      if let trailingClosure = node.trailingClosure {
        arrange(trailingClosure)
        arrange(node.additionalTrailingClosures)
      }
    }
  }
  
  override func visit(_ node: FunctionEffectSpecifiersSyntax) -> FunctionEffectSpecifiersSyntax {
    format(node) {
      arrangeEffectSpecifiers(node)
    }
  }
  
  override func visit(_ node: GenericParameterClauseSyntax) -> GenericParameterClauseSyntax {
    format(node) {
      arrange(node.leftAngle)
      `break`(.open, size: 0)
      group(argumentListConsistency()) {
        arrange(node.parameters)
        `break`(.close, size: 0)
      }
      arrange(node.rightAngle)
    }
  }

  override func visit(_ node: GenericParameterSyntax) -> GenericParameterSyntax {
    format(node) {
      group {
        if let eachKeyword = node.eachKeyword {
          arrange(eachKeyword)
        }
        arrange(node.name)
        if let colon = node.colon {
          arrange(colon)
          `break`()
        }
        if let inheritedType = node.inheritedType {
          arrange(inheritedType)
        }
        if let trailingComma = node.trailingComma {
          arrange(trailingComma)
        }
      }
      if node.trailingComma != nil {
        `break`(.same)
      }
    }
  }

  override func visit(_ node: GenericRequirementSyntax) -> GenericRequirementSyntax {
    format(node) {
      group {
        arrange(node.requirement)
        if let trailingComma = node.trailingComma {
          arrange(trailingComma)
        }
      }
      if node.trailingComma != nil {
        `break`(.same)
      }
    }
  }

  override func visit(_ node: GenericWhereClauseSyntax) -> GenericWhereClauseSyntax {
    format(node) {
      arrange(node.whereKeyword)
      `break`(.open)
      group(genericRequirementListConsistency()) {
        arrange(node.requirements)
      }
      `break`(.close, size: 0)
    }
  }

  override func visit(_ node: InitializerClauseSyntax) -> InitializerClauseSyntax {
    format(node) {
      space()
      arrange(node.equal)
      `break`()
      arrange(node.value)
    }
  }
  
  override func visit(_ node: InheritanceClauseSyntax) -> InheritanceClauseSyntax {
    format(node) {
      arrange(node.colon)

      // Normally, the open-break is placed before entering the group. In this case, it's intentionally
      // ordered differently so that the inheritance list can start on the current line and only
      // breaks if the first item in the list would overflow the column limit.
      group {
        `break`(.open)
        arrange(node.inheritedTypes)
        `break`(.close, size: 0)
      }
    }
  }

  override func visit(_ node: InheritedTypeSyntax) -> InheritedTypeSyntax {
    format(node) {
      arrange(node.type)
      if let trailingComma = node.trailingComma {
        arrange(trailingComma)
        `break`(.same)
      }
    }
  }

  override func visit(_ node: LabeledStmtSyntax) -> StmtSyntax {
    format(node) {
      arrange(node.label)
      arrange(node.colon)
      space()
      arrange(Syntax(node.statement))
    }
  }
  
  override func visit(_ node: MemberBlockItemSyntax) -> MemberBlockItemSyntax {
    format(node) {
      let newlines: NewlineBehavior = /*
                                       item != node.last && shouldInsertNewline(basedOn: item.semicolon) ?*/ .soft /*: .elective*/
      let resetSize = node.semicolon != nil ? 1 : 0
      
      group {
        arrange(Syntax(node.decl))
        if let semicolon = node.semicolon {
          arrange(semicolon)
        }
      }
      `break`(.reset, size: resetSize, newlines: newlines)
    }
  }
  
  override func visit(_ node: PatternBindingSyntax) -> PatternBindingSyntax {
    format(node) {
      group(if: environment.value(for: SingleBindingVarDecl.self)) {
        arrange(node.pattern)
        
        // TODO: MissingTypeSyntax
        if let typeAnnotation = node.typeAnnotation {
          arrange(typeAnnotation)
          
//          if node.initializer == nil && node.trailingComma == nil {
//            `break`(.close, size: 0)
//          }
        }
        if let initializer = node.initializer {
          arrange(initializer)
          
//          if node.typeAnnotation != nil && node.trailingComma == nil {
//            `break`(.close, size: 0)
//          }
        }
        if let accessorBlock = node.accessorBlock {
          arrange(accessorBlock)
        }
        if let trailingComma = node.trailingComma {
          arrange(trailingComma)
          `break`(.same)
          
//          if node.typeAnnotation != nil && node.initializer != nil {
//            `break`(.close, size: 0)
//          }
        }
      }
    }
  }
  
  override func visit(_ node: PlatformVersionItemListSyntax) -> PlatformVersionItemListSyntax {
    format(node) {
      forEach(node) { child in
        arrange(child)
      } separator: {
        `break`(.same)
      }
    }
  }

  override func visit(_ node: PlatformVersionSyntax) -> PlatformVersionSyntax {
    format(node) {
      group {
        arrange(node.platform)
        if let version = node.version {
          `break`(.continue)
          arrange(version)
        }
      }
    }
  }

  override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
    format(node) {
      arrangeTypeDeclBlock(
        attributes: node.attributes,
        modifiers: node.modifiers,
        typeKeyword: node.protocolKeyword,
        name: node.name,
        genericParameterOrPrimaryAssociatedTypeClause: node.primaryAssociatedTypeClause.map(Syntax.init),
        inheritanceClause: node.inheritanceClause,
        genericWhereClause: node.genericWhereClause,
        memberBlock: node.memberBlock)
    }
  }
  
  override func visit(_ node: SameTypeRequirementSyntax) -> SameTypeRequirementSyntax {
    format(node) {
      arrange(node.leftType)
      `break`()
      arrange(node.equal)
      space()
      arrange(node.rightType)
    }
  }

  override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    format(node) {
      arrangeTypeDeclBlock(
        attributes: node.attributes,
        modifiers: node.modifiers,
        typeKeyword: node.structKeyword,
        name: node.name,
        genericParameterOrPrimaryAssociatedTypeClause: node.genericParameterClause.map(Syntax.init),
        inheritanceClause: node.inheritanceClause,
        genericWhereClause: node.genericWhereClause,
        memberBlock: node.memberBlock)
    }
  }
  
  override func visit(_ node: ThrowStmtSyntax) -> StmtSyntax {
    format(node) {
      arrange(node.throwKeyword)
      `break`()
      arrange(Syntax(node.expression))
    }
  }
  
  override func visit(_ node: TypeAnnotationSyntax) -> TypeAnnotationSyntax {
    format(node) {
      group {
        arrange(node.colon)
//        `break`(.open(kind: .continuation), newlines: .elective(ignoresDiscretionary: true))
        arrange(node.type)
//        `break`(.close(mustBreak: false), size: 0)
      }
    }
  }
  
  override func visit(_ node: TypeEffectSpecifiersSyntax) -> TypeEffectSpecifiersSyntax {
    format(node) {
      arrangeEffectSpecifiers(node)
    }
  }
  
  override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
    format(node) {
      arrange(node.attributes)
      arrange(node.modifiers)
      arrange(node.bindingSpecifier)
      
      withEnvironment(node.bindings.count == 1, for: SingleBindingVarDecl.self) { isSingleBinding in
        if isSingleBinding {
          // If there is only a single binding, don't allow a break between the binding specifier
          // and the identifier; there are better places to break later on.
          space()
        } else {
          // If there is more than one binding, we permit an open-break after the binding specifier
          // so that each of the comma-delimited items will potentially receive indentation.
          `break`(.open)
        }
        
        group(if: !isSingleBinding) {
          arrange(node.bindings)
        }
        
        if !isSingleBinding {
          `break`(.close, size: 0)
        }
      }
    }
  }
  
  override func visit(_ node: YieldStmtSyntax) -> StmtSyntax {
    format(node) {
      arrange(node.yieldKeyword)
      space()
      arrange(node.yieldedExpressions)
    }
  }
  
  override func visit(_ node: TokenSyntax) -> TokenSyntax {
    processLeadingTrivia(of: node)
    enqueue(.syntax(node.text))
    
    for piece in node.trailingTrivia {
      switch piece {
      case .blockComment(let comment):
        enqueue(.comment(Comment(kind: .block, text: comment), wasEndOfLine: false))
      case .docBlockComment(let comment):
        enqueue(.comment(Comment(kind: .docBlock, text: comment), wasEndOfLine: false))

      case .lineComment(let comment):
        enqueue(.comment(Comment(kind: .line, text: comment), wasEndOfLine: true))
        `break`(.same, size: 0, newlines: .soft(count: 1, discretionary: false))
      case .docLineComment(let comment):
        enqueue(.comment(Comment(kind: .docLine, text: comment), wasEndOfLine: true))
        `break`(.same, size: 0, newlines: .soft(count: 1, discretionary: false))

      default:
        break
      }
    }
    
    return node
  }
}

extension NewTokenStreamCreator {
  private func processLeadingTrivia(of token: TokenSyntax) {
    var isStartOfFile = token.previousToken(viewMode: .sourceAccurate) == nil
    var requiresNextNewline = false

    for (index, piece) in token.leadingTrivia.enumerated() {
      switch piece {
      case .lineComment(let comment):
        if index > 0 || isStartOfFile {
          enqueue(.comment(Comment(kind: .line, text: comment), wasEndOfLine: false))
          appendNewlines(.soft)
          isStartOfFile = false
        }
        requiresNextNewline = true

      case .docLineComment(let comment):
        enqueue(.comment(Comment(kind: .docLine, text: comment), wasEndOfLine: false))
        appendNewlines(.soft)
        isStartOfFile = false
        requiresNextNewline = false

      case .blockComment(let comment):
        enqueue(.comment(Comment(kind: .block, text: comment), wasEndOfLine: false))
        appendNewlines(.soft)
        
      case .docBlockComment(let comment):
        enqueue(.comment(Comment(kind: .docBlock, text: comment), wasEndOfLine: false))
        appendNewlines(.soft)
        isStartOfFile = false
        requiresNextNewline = false

      case .newlines(let count), .carriageReturns(let count), .carriageReturnLineFeeds(let count):
        guard !isStartOfFile else { break }
        if requiresNextNewline
          || (configuration.respectsExistingLineBreaks /*
            && isDiscretionaryNewlineAllowed(before: token)*/)
        {
          appendNewlines(.soft(count: count, discretionary: true))
        } else {
          // Even if discretionary line breaks are not being respected, we still respect multiple
          // line breaks in order to keep blank separator lines that the user might want.
          // TODO: It would be nice to restrict this to only allow multiple lines between statements
          // and declarations; as currently implemented, multiple newlines will locally ignore the
          // configuration setting.
          if count > 1 {
            appendNewlines(.soft(count: count, discretionary: true))
          }
        }

      case .unexpectedText(let text):
        // Garbage text in leading trivia might be something meaningful that would be disruptive to
        // throw away when formatting the file, like a hashbang line or Unicode byte-order marker at
        // the beginning of a file, or source control conflict markers. Keep it as verbatim text so
        // that it is printed exactly as we got it.
        enqueue(.verbatim(Verbatim(text: text, indentingBehavior: .none)))

        // Unicode byte-order markers shouldn't allow leading newlines to otherwise appear in the
        // file, nor should they modify our detection of the beginning of the file.
        let isBOM = text == "\u{feff}"
        requiresNextNewline = !isBOM
        isStartOfFile = isStartOfFile && isBOM

      default:
        break
      }
    }
  }

  /// Appends the newlines to the token stream.
  ///
  /// The newlines will be inserted using one of the following approaches:
  /// - As a new break, whose kind is compatible with the most recent break.
  /// - Overwriting the newlines of the most recent break.
  /// - Appending to the newlines of the most recent break.
  private func appendNewlines(_ newlines: NewlineBehavior) {
    guard let lastBreakIndex = lastBreakIndex else {
      // When there haven't been any breaks yet, there can't be any indentation to maintain so a
      // same break is safe here.
      enqueue(.break(.same, size: 0, newlines: newlines))
      return
    }

    let lastBreak = commands[lastBreakIndex]
    guard case .break(let kind, let size, let existingNewlines) = lastBreak else {
      fatalError("Found non-break token at lastBreakIndex. TokenStreamCreator is invalid.")
    }

    guard !canMergeNewlinesIntoLastBreak else {
      commands[lastBreakIndex] = .break(kind, size: size, newlines: existingNewlines + newlines)
      return
    }

    // Otherwise, create and insert a new break whose `kind` is compatible with last break.
    let compatibleKind: BreakKind
    switch kind {
    case .open, .close, .reset, .same:
      compatibleKind = .same
    case .continue, .contextual:
      compatibleKind = kind
    }
    enqueue(.break(compatibleKind, size: 0, newlines: newlines))
  }
}

extension NewTokenStreamCreator {
  /// Returns the group consistency that should be used for argument lists based on the user's
  /// current configuration.
  private func argumentListConsistency() -> GroupBreakStyle {
    return configuration.lineBreakBeforeEachArgument ? .consistent : .inconsistent
  }

  /// Returns the group consistency that should be used for generic requirement lists based on
  /// the user's current configuration.
  private func genericRequirementListConsistency() -> GroupBreakStyle {
    return configuration.lineBreakBeforeEachGenericRequirement ? .consistent : .inconsistent
  }

  private func arrangeEffectSpecifiers<Node: EffectSpecifiersSyntax>(_ node: Node) {
    guard node.asyncSpecifier != nil || node.throwsSpecifier != nil else {
      return
    }

    `break`()
    if let asyncSpecifier = node.asyncSpecifier, let throwsSpecifier = node.throwsSpecifier {
      group {
        arrange(asyncSpecifier)
        `break`()
        arrange(throwsSpecifier)
      }
    } else if let asyncSpecifier = node.asyncSpecifier {
      arrange(asyncSpecifier)
    } else if let throwsSpecifier = node.throwsSpecifier {
      arrange(throwsSpecifier)
    }
  }

  /// Returns a value indicating whether or not the given braced syntax node is completely empty;
  /// that is, it contains neither child syntax nodes (aside from the braces) *nor* any comments.
  ///
  /// Checking for comments separately is vitally important, because a code block that appears to be
  /// "empty" because it doesn't contain any statements might still contain comments, and if those
  /// are line comments, we need to make sure to insert the same breaks that we would if there were
  /// other statements there to get the same layout.
  ///
  /// Note the slightly different generic constraints on this and the other overloads. All are
  /// required because protocols in Swift do not conform to themselves, so if the element type of
  /// the collection is *precisely* `Syntax`, the constraint `BodyContents.Element: Syntax` is not
  /// satisfied and we must constrain it by `BodyContents.Element == Syntax` instead.
  ///
  /// - Parameters:
  ///   - node: A node that conforms to `BracedSyntax`.
  ///   - contentsKeyPath: A keypath describing how to get from `node` to the contents of the node
  ///     (a `Collection` whose elements are of a type that conforms to `Syntax`).
  /// - Returns: True if the collection at the node's keypath is empty and there are no comments.
  private func areBracesCompletelyEmpty<Node: BracedSyntax, BodyContents: SyntaxCollection>(
    _ node: Node,
    contentsKeyPath: KeyPath<Node, BodyContents>
  ) -> Bool where BodyContents.Element: SyntaxProtocol {
    // If the collection is empty, then any comments that might be present in the block must be
    // leading trivia of the right brace.
    let commentPrecedesRightBrace = node.rightBrace.leadingTrivia.hasAnyComments
    // We can't use `count` here because it also includes missing children. Instead, we get an
    // iterator and check if it returns `nil` immediately.
    var contentsIterator = node[keyPath: contentsKeyPath].makeIterator()
    return contentsIterator.next() == nil && !commentPrecedesRightBrace
  }

  /// Applies formatting tokens to the tokens in the given type declaration node (i.e., a class,
  /// struct, enum, protocol, or extension).
  private func arrangeTypeDeclBlock(
    attributes: AttributeListSyntax,
    modifiers: DeclModifierListSyntax,
    typeKeyword: TokenSyntax,
    name: some SyntaxProtocol,
    genericParameterOrPrimaryAssociatedTypeClause: Syntax?,
    inheritanceClause: InheritanceClauseSyntax?,
    genericWhereClause: GenericWhereClauseSyntax?,
    memberBlock: MemberBlockSyntax
  ) {
    group {
      arrange(attributes)
      group {
        arrange(modifiers)
        arrange(typeKeyword)
        `break`()
        
        arrange(Syntax(name))
      }
      if let genericParameterClause = genericParameterOrPrimaryAssociatedTypeClause {
        arrange(genericParameterClause)
      }
      if let inheritanceClause = inheritanceClause {
        arrange(inheritanceClause)
      }
      if let genericWhereClause = genericWhereClause {
        `break`(.same)
        group {
          arrange(genericWhereClause)
        }
      }

      arrangeBracesAndContents(of: memberBlock, contentsKeyPath: \.members)
    }
  }

  /// Applies consistent formatting to the braces and contents of the given node.
  ///
  /// - Parameters:
  ///   - node: A node that conforms to `BracedSyntax`.
  ///   - contentsKeyPath: A keypath describing how to get from `node` to the contents of the node
  ///     (a `Collection` whose elements are of a type that conforms to `Syntax`).
  ///   - shouldResetBeforeLeftBrace: If true, a `reset` break will be inserted before the node's
  ///     left brace (the default behavior). Passing false will suppress this break, which is useful
  ///     if you have already placed a `reset` elsewhere (for example, in a `guard` statement, the
  ///     `reset` is inserted before the `else` keyword to force both it and the brace down to the
  ///     next line).
  ///   - openBraceNewlineBehavior: The newline behavior to apply to the break following the open
  ///     brace; defaults to `.elective`.
  private func arrangeBracesAndContents<Node: BracedSyntax, BodyContents: SyntaxCollection>(
    of node: Node?,
    contentsKeyPath: KeyPath<Node, BodyContents>?,
    shouldResetBeforeLeftBrace: Bool = true,
    openBraceNewlineBehavior: NewlineBehavior = .elective
  ) where BodyContents.Element: SyntaxProtocol {
    guard let node = node, let contentsKeyPath = contentsKeyPath else { return }

    if shouldResetBeforeLeftBrace {
      `break`(.reset, size: 1, newlines: .elective(ignoresDiscretionary: true))
    }

    arrange(node.leftBrace)

    if !areBracesCompletelyEmpty(node, contentsKeyPath: contentsKeyPath) {
      `break`(.open, size: 1, newlines: openBraceNewlineBehavior)
      group {
        arrange(Syntax(node[keyPath: contentsKeyPath]))
        `break`(.close, size: 1)
      }
    } else {
      `break`(.open, size: 0, newlines: openBraceNewlineBehavior)
      arrange(Syntax(node[keyPath: contentsKeyPath]))
      `break`(.close, size: 0)
    }

    arrange(node.rightBrace)
  }

  /// Applies consistent formatting to the braces and contents of the given node.
  ///
  /// - Parameter node: An `AccessorBlockSyntax` node.
  private func arrangeBracesAndContents(
    leftBrace: TokenSyntax,
    accessors: AccessorDeclListSyntax,
    rightBrace: TokenSyntax
  ) {
    // If the collection is empty, then any comments that might be present in the block must be
    // leading trivia of the right brace.
    let commentPrecedesRightBrace = rightBrace.leadingTrivia.hasAnyComments
    // We can't use `count` here because it also includes missing children. Instead, we get an
    // iterator and check if it returns `nil` immediately.
    var accessorsIterator = accessors.makeIterator()
    let areAccessorsEmpty = accessorsIterator.next() == nil
    let bracesAreCompletelyEmpty = areAccessorsEmpty && !commentPrecedesRightBrace

    `break`(.reset, size: 1)
    arrange(leftBrace)

    if !bracesAreCompletelyEmpty {
      `break`(.open, size: 1)
      group {
        arrange(accessors)
        `break`(.close, size: 1)
      }
    } else {
      `break`(.open, size: 0)
      arrange(accessors)
      `break`(.close, size: 0)
    }

    arrange(rightBrace)
  }

  /// Returns true if the argument list can be compacted, even if it spans multiple lines (where
  /// compact means that it can start immediately after the open parenthesis).
  ///
  /// This is true for any argument list that contains a single argument (labeled or unlabeled) that
  /// is an array, dictionary, or closure literal.
  func isCompactSingleFunctionCallArgument(_ argumentList: LabeledExprListSyntax) -> Bool {
    guard argumentList.count == 1 else { return false }

    let expression = argumentList.first!.expression
    return expression.is(ArrayExprSyntax.self) || expression.is(DictionaryExprSyntax.self)
      || expression.is(ClosureExprSyntax.self)
  }

  /// Returns true if open/close breaks should be inserted around the entire function call argument
  /// list.
  private func shouldGroupAroundArgumentList(_ arguments: LabeledExprListSyntax) -> Bool {
    let argumentCount = arguments.count

    // If there are no arguments, there's no reason to break.
    if argumentCount == 0 { return false }

    // If there is more than one argument, we must open/close break around the whole list.
    if argumentCount > 1 { return true }

    return !isCompactSingleFunctionCallArgument(arguments)
  }
}

extension NewTokenStreamCreator {
  func withEnvironment<Key: EnvironmentKey, Result>(
    _ value: Key.Value,
    for key: Key.Type,
    body: (Key.Value) -> Result
  ) -> Result {
    environment.push(value, for: key)
    defer { environment.pop() }
    return body(value)
  }
}

extension NewTokenStreamCreator {
  private func enqueue(_ command: Token) {
    if let last = commands.last {
      switch (last, command) {
      case (.comment(let c1, _), .comment(let c2, _))
      where c1.kind == .docLine && c2.kind == .docLine:
        var newComment = c1
        newComment.addText(c2.text)
        commands[commands.count - 1] = .comment(newComment, wasEndOfLine: false)
        return

      // If we see a pair of spaces where one or both are flexible, combine them into a new token
      // with the maximum of their counts.
      case (.space(let first, let firstFlexible), .space(let second, let secondFlexible))
      where firstFlexible || secondFlexible:
        commands[commands.count - 1] = .space(size: max(first, second), flexible: true)
        return

      default:
        break
      }
    }

    switch command {
    case .break:
      lastBreakIndex = commands.endIndex
      canMergeNewlinesIntoLastBreak = true
    case .open, .printerControl, .contextualBreakingStart:
      break
    default:
      canMergeNewlinesIntoLastBreak = false
    }
    commands.append(command)
  }

  private func `break`(
    _ kind: BreakKind = .continue,
    size: Int = 1,
    newlines: NewlineBehavior = .elective
  ) {
    enqueue(.break(kind, size: size, newlines: newlines))
  }

  private func group<Result>(
    _ style: GroupBreakStyle = .inconsistent,
    body: () -> Result
  ) -> Result {
    enqueue(.open(style))
    defer { enqueue(.close) }
    return body()
  }

  private func group<Result>(
    _ style: GroupBreakStyle = .inconsistent,
    if condition: @autoclosure () -> Bool,
    body: () -> Result
  ) -> Result {
    if condition() {
      return group(style, body: body)
    } else {
      return body()
    }
  }

  private func space(count: Int = 1, flexible: Bool = false) {
    enqueue(.space(size: count, flexible: flexible))
  }
}
