import SwiftOperators

@_spi(SyntaxTransformVisitor) import SwiftSyntax

func computeCommands(_ creator: NewTokenStreamCreator, node: Syntax) -> [Token] {
  creator.visit(node)
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

final class NewTokenStreamCreator {
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
  
}

extension NewTokenStreamCreator: SyntaxTransformVisitor {
  func visitAny(_ node: Syntax) {
    _ = visitChildren(node)
  }

  func visit(_ node: AccessorBlockSyntax) {
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

  func visit(_ node: AccessorDeclListSyntax) {
    if let last = node.last {
      for child in node.dropLast(1) {
        visit(child)

        let newlines: NewlineBehavior = child.body == nil ? .elective : .soft
        `break`(.same, size: 1, newlines: newlines)
      }
      visit(last)
    }
  }

  func visit(_ node: AccessorDeclSyntax) {
    visit(node.attributes)
    if let modifier = node.modifier {
      visit(modifier)
    }

    visit(node.accessorSpecifier)
    if let parameters = node.parameters {
      visit(parameters)
    }
    if let effectSpecifiers = node.effectSpecifiers {
      visit(effectSpecifiers)
    }
    if let body = node.body {
      visit(body)
    }
  }

  func visit(_ node: AccessorEffectSpecifiersSyntax) {
    arrangeEffectSpecifiers(node)
  }

  func visit(_ node: ActorDeclSyntax) {
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

  func visit(_ node: ArrayExprSyntax) {
    visit(node.leftSquare)
    `break`(.open, size: 0)
    group {
      visit(node.elements)
      `break`(.close, size: 0)
    }
    visit(node.rightSquare)
  }
  
  func visit(_ node: ArrayElementSyntax) {
    visit(node.expression)
    if let trailingComma = node.trailingComma {
      visit(trailingComma)
      `break`(.same)
    }
  }
  
  func visit(_ node: ArrayTypeSyntax) {
    visit(node.leftSquare)
    visit(Syntax(node.element))
    visit(node.rightSquare)
  }

  func visit(_ node: AttributeListSyntax) {
    guard !node.isEmpty else { return }

    group {
      for child in node {
        visit(child)
        `break`(.same)
      }
    }
    // TODO: suppressFinalBreak
    `break`(.same)
  }

  func visit(_ node: BreakStmtSyntax) {
    visit(node.breakKeyword)
    if let label = node.label {
      `break`()
      visit(label)
    }
  }

  func visit(_ node: ClassDeclSyntax) {
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

  func visit(_ node: CodeBlockItemSyntax) {
    let newlines: NewlineBehavior = /*
                                     item != node.last && shouldInsertNewline(basedOn: item.semicolon) ?*/ .soft /*: .elective*/
    let resetSize = node.semicolon != nil ? 1 : 0
    
    group {
      visit(node.item)
      if let semicolon = node.semicolon {
        visit(semicolon)
      }
    }
    `break`(.reset, size: resetSize, newlines: newlines)
  }

  func visit(_ node: CodeBlockSyntax) {
    arrangeBracesAndContents(of: node, contentsKeyPath: \.statements)
  }

  func visit(_ node: ContinueStmtSyntax) {
    visit(node.continueKeyword)
    if let label = node.label {
      `break`()
      visit(label)
    }
  }

  func visit(_ node: DeclModifierDetailSyntax) {
    visit(node.leftParen)
    visit(node.detail)
    visit(node.rightParen)
  }

  func visit(_ node: DeclModifierSyntax) {
    visit(node.name)
    if let detail = node.detail {
      visit(detail)
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

  func visit(_ node: DeferStmtSyntax) {
    visit(node.deferKeyword)
    visit(node.body)
  }

  func visit(_ node: DeinitializerDeclSyntax) {
    group {
      visit(node.attributes)
      visit(node.modifiers)
      visit(node.deinitKeyword)
      if let effectSpecifiers = node.effectSpecifiers {
        visit(effectSpecifiers)
      }
      if let body = node.body {
        visit(body)
      }
    }
  }

  func visit(_ node: DeinitializerEffectSpecifiersSyntax) {
    if let asyncSpecifier = node.asyncSpecifier {
      `break`()
      visit(asyncSpecifier)
    }
  }

  func visit(_ node: DictionaryTypeSyntax) {
    visit(node.leftSquare)
    visit(node.key)
    visit(node.colon)
    `break`()
    visit(node.value)
    visit(node.rightSquare)
  }

  func visit(_ node: DoStmtSyntax) {
    visit(node.doKeyword)
    visit(node.body)
    visit(node.catchClauses)
  }

  func visit(_ node: EnumDeclSyntax) {
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

  func visit(_ node: ExtensionDeclSyntax) {
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

  func visit(_ node: FallThroughStmtSyntax) {
    visit(node.fallthroughKeyword)
  }

  func visit(_ node: FunctionEffectSpecifiersSyntax) {
    arrangeEffectSpecifiers(node)
  }

  func visit(_ node: InitializerClauseSyntax) {
    space()
    visit(node.equal)
    `break`()
    visit(node.value)
  }

  func visit(_ node: LabeledStmtSyntax) {
    visit(node.label)
    visit(node.colon)
    space()
    visit(Syntax(node.statement))
  }

  func visit(_ node: MemberBlockItemSyntax) {
    let newlines: NewlineBehavior = /*
                                     item != node.last && shouldInsertNewline(basedOn: item.semicolon) ?*/ .soft /*: .elective*/
    let resetSize = node.semicolon != nil ? 1 : 0
    
    group {
      visit(Syntax(node.decl))
      if let semicolon = node.semicolon {
        visit(semicolon)
      }
    }
    `break`(.reset, size: resetSize, newlines: newlines)
  }

  func visit(_ node: PatternBindingSyntax) {
    group(if: environment.value(for: SingleBindingVarDecl.self)) {
      visit(node.pattern)

      // TODO: MissingTypeSyntax
      if let typeAnnotation = node.typeAnnotation {
        visit(typeAnnotation)

        if node.initializer == nil && node.trailingComma == nil {
          `break`(.close, size: 0)
        }
      }
      if let initializer = node.initializer {
        visit(initializer)

        if node.typeAnnotation != nil && node.trailingComma == nil {
          `break`(.close, size: 0)
        }
      }
      if let accessorBlock = node.accessorBlock {
        visit(accessorBlock)
      }
      if let trailingComma = node.trailingComma {
        visit(trailingComma)
        `break`(.same)

        if node.typeAnnotation != nil && node.initializer != nil {
          `break`(.close, size: 0)
        }
      }
    }
  }

  func visit(_ node: ProtocolDeclSyntax) {
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

  func visit(_ node: StructDeclSyntax) {
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

  func visit(_ node: ThrowStmtSyntax) {
    visit(node.throwKeyword)
    `break`()
    visit(Syntax(node.expression))
  }

  func visit(_ node: TypeAnnotationSyntax) {
    group {
      visit(node.colon)
      `break`(.open(kind: .continuation), newlines: .elective(ignoresDiscretionary: true))
      visit(node.type)
    }
  }

  func visit(_ node: TypeEffectSpecifiersSyntax) {
    arrangeEffectSpecifiers(node)
  }

  func visit(_ node: VariableDeclSyntax) {
    visit(node.attributes)
    visit(node.modifiers)
    visit(node.bindingSpecifier)

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
        visit(node.bindings)
      }

      if !isSingleBinding {
        `break`(.close, size: 0)
      }
    }
  }
  
  func visit(_ node: YieldStmtSyntax) {
    visit(node.yieldKeyword)
    space()
    visit(node.yieldedExpressions)
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

  func visit(_ node: TokenSyntax) {
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
  }
}

extension NewTokenStreamCreator {
  private func arrangeEffectSpecifiers<Node: EffectSpecifiersSyntax>(_ node: Node) {
    guard node.asyncSpecifier != nil || node.throwsSpecifier != nil else {
      return
    }

    `break`()
    if let asyncSpecifier = node.asyncSpecifier, let throwsSpecifier = node.throwsSpecifier {
      group {
        visit(asyncSpecifier)
        `break`()
        visit(throwsSpecifier)
      }
    } else if let asyncSpecifier = node.asyncSpecifier {
      visit(asyncSpecifier)
    } else if let throwsSpecifier = node.throwsSpecifier {
      visit(throwsSpecifier)
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
      visit(attributes)
      group {
        visit(modifiers)
        visit(typeKeyword)
        `break`()
        
        visit(Syntax(name))
      }
      if let genericParameterClause = genericParameterOrPrimaryAssociatedTypeClause {
        visit(genericParameterClause)
      }
      if let inheritanceClause = inheritanceClause {
        visit(inheritanceClause)
      }
      if let genericWhereClause = genericWhereClause {
        visit(genericWhereClause)
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

    visit(node.leftBrace)

    if !areBracesCompletelyEmpty(node, contentsKeyPath: contentsKeyPath) {
      `break`(.open, size: 1, newlines: openBraceNewlineBehavior)
      group {
        visit(Syntax(node[keyPath: contentsKeyPath]))
        `break`(.close, size: 1)
      }
    } else {
      `break`(.open, size: 0, newlines: openBraceNewlineBehavior)
      visit(Syntax(node[keyPath: contentsKeyPath]))
      `break`(.close, size: 0)
    }

    visit(node.rightBrace)
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
    visit(leftBrace)

    if !bracesAreCompletelyEmpty {
      `break`(.open, size: 1)
      group {
        visit(accessors)
        `break`(.close, size: 1)
      }
    } else {
      `break`(.open, size: 0)
      visit(accessors)
      `break`(.close, size: 0)
    }

    visit(rightBrace)
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
    commands.append(.break(kind, size: size, newlines: newlines))
  }

  private func group<Result>(
    _ style: GroupBreakStyle = .inconsistent,
    body: () -> Result
  ) -> Result {
    commands.append(.open(style))
    defer { commands.append(.close) }
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
    commands.append(.space(size: count, flexible: flexible))
  }
}
