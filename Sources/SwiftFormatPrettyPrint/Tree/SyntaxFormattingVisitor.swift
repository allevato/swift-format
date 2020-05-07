import SwiftSyntax

///
class SyntaxFormattingVisitor: SyntaxVisitor {
  ///
  private let state = FormatBuildingState()

  /// The root node of the format tree.
  let root = FormatNode()

  /// Creates a new format building visitor.
  override init() {}

  // MARK: - Attribute Nodes

  override func visit(_ node: TokenListSyntax) -> SyntaxVisitorContinueKind {
    // token-list -> token? token-list?
    format(node) {
    }
  }

  override func visit(_ node: NonEmptyTokenListSyntax)
    -> SyntaxVisitorContinueKind
  {
    // token-list -> token token-list?
    format(node) {
    }
  }

  override func visit(_ node: CustomAttributeSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
    // attribute -> '@' identifier '('?
    //              ( identifier
    //                | string-literal
    //                | integer-literal
    //                | availability-spec-list
    //                | specialize-attr-spec-list
    //                | implements-attr-arguments
    //                | named-attribute-string-argument
    //              )? ')'?
    format(node) {
    }
  }

  override func visit(_ node: AttributeListSyntax) -> SyntaxVisitorContinueKind
  {
    // attribute-list -> attribute attribute-list?
    format(node) {
    }
  }

  override func visit(_ node: SpecializeAttributeSpecListSyntax)
    -> SyntaxVisitorContinueKind
  {
    // specialize-attr-spec-list -> labeled-specialize-entry
    //                                  specialize-spec-attr-list?
    //                            | generic-where-clause
    //                                  specialize-spec-attr-list?
    format(node) {
    }
  }

  override func visit(_ node: LabeledSpecializeEntrySyntax)
    -> SyntaxVisitorContinueKind
  {
    // labeled-specialize-entry -> identifier ':' token ','?
    format(node) {
    }
  }

  override func visit(_ node: NamedAttributeStringArgumentSyntax)
    -> SyntaxVisitorContinueKind
  {
    // named-attribute-string-arg -> 'name': string-literal
    format(node) {
    }
  }

  override func visit(_ node: DeclNameSyntax) -> SyntaxVisitorContinueKind {
    format(node) {
    }
  }

  override func visit(_ node: ImplementsAttributeArgumentsSyntax)
    -> SyntaxVisitorContinueKind
  {
    // implements-attr-arguments -> simple-type-identifier ','
    //                              (identifier | operator) decl-name-arguments
    format(node) {
    }
  }

  override func visit(_ node: ObjCSelectorPieceSyntax)
    -> SyntaxVisitorContinueKind
  {
    // objc-selector-piece -> identifier? ':'?
    format(node) {
    }
  }

  override func visit(_ node: ObjCSelectorSyntax) -> SyntaxVisitorContinueKind {
    // objc-selector -> objc-selector-piece objc-selector?
    format(node) {
    }
  }

  // TODO: Differentiability attributes

  // MARK: - Availability Nodes

  override func visit(_ node: AvailabilitySpecListSyntax)
    -> SyntaxVisitorContinueKind
  {
    // availability-spec-list -> availability-entry availability-spec-list?
    format(node) {
    }
  }

  override func visit(_ node: AvailabilityArgumentSyntax)
    -> SyntaxVisitorContinueKind
  {
    // availability-entry -> '*' ','?
    //                     | identifier ','?
    //                     | availability-version-restriction ','?
    //                     | availability-versioned-argument ','?
    format(node) {
    }
  }

  override func visit(_ node: AvailabilityLabeledArgumentSyntax)
    -> SyntaxVisitorContinueKind
  {
    // availability-versioned-argument -> identifier ':' version-tuple
    format(node) {
    }
  }

  override func visit(_ node: AvailabilityVersionRestrictionSyntax)
    -> SyntaxVisitorContinueKind
  {
    // availability-version-restriction -> identifier version-tuple
    format(node) {
    }
  }

  override func visit(_ node: VersionTupleSyntax) -> SyntaxVisitorContinueKind {
    // version-tuple -> integer-literal
    //                | float-literal
    //                | float-literal '.' integer-literal
    format(node) {
    }
  }

  // MARK: - Common Nodes

  override func visit(_ node: CodeBlockItemSyntax) -> SyntaxVisitorContinueKind
  {
    // code-block-item = (decl | stmt | expr) ';'?
    format(node) {
      $0.group {
        $0.format(node.item)
        $0.formatIfPresent(node.semicolon)
      }
    }
  }

  override func visit(_ node: CodeBlockItemListSyntax)
    -> SyntaxVisitorContinueKind
  {
    // code-block-item-list -> code-block-item code-block-item-list?
    format(node) {
      $0.join(
        node,
        { $0.format($1) },
        separator: { $0.break(.hard) })
    }
  }

  override func visit(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
    // code-block -> '{' stmt-list '}'
    format(node) {
      $0.format(node.leftBrace)
      $0.indent {
        $0.break(.hard)
        $0.format(node.statements)
      }
      $0.break(.hard)
      $0.format(node.rightBrace)
    }
  }

  // MARK: - Declaration Nodes

  override func visit(_ node: TypeInitializerClauseSyntax)
    -> SyntaxVisitorContinueKind
  {
    // type-assignment -> '=' type
    format(node) {
    }
  }

  override func visit(_ node: TypealiasDeclSyntax) -> SyntaxVisitorContinueKind
  {
    // typealias-declaration -> attributes? access-level-modifier? 'typealias'
    //                            typealias-name generic-parameter-clause?
    //                            type-assignment
    // typealias-name -> identifier
    format(node) {
    }
  }

  override func visit(_ node: AssociatedtypeDeclSyntax)
    -> SyntaxVisitorContinueKind
  {
    // associatedtype-declaration -> attributes? access-level-modifier?
    //                                 'associatedtype' associatedtype-name
    //                                 inheritance-clause? type-assignment?
    //                                 generic-where-clause?
    // associatedtype-name -> identifier
    format(node) {
    }
  }

  override func visit(_ node: FunctionParameterListSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: ParameterClauseSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
      $0.format(node.leftParen)
      //$0.format(node.parameterList)
      $0.format(node.rightParen)
    }
  }

  override func visit(_ node: ReturnClauseSyntax) -> SyntaxVisitorContinueKind {
    // '->' type
    format(node) {
    }
  }

  override func visit(_ node: FunctionSignatureSyntax)
    -> SyntaxVisitorContinueKind
  {
    // function-signature ->
    //   '(' parameter-list? ')' (throws | rethrows)? '->'? type?
    format(node) {
      $0.format(node.input)
      if let throwsOrRethrowsKeyword = node.throwsOrRethrowsKeyword {
        $0.format(throwsOrRethrowsKeyword)
      }
      if let output = node.output {
        $0.format(output)
      }
    }
  }

  override func visit(_ node: IfConfigClauseSyntax) -> SyntaxVisitorContinueKind
  {
    // if-config-clause ->
    //    ('#if' | '#elseif' | '#else') expr? (stmt-list | switch-case-list)
    format(node) {
    }
  }

  override func visit(_ node: IfConfigClauseListSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: IfConfigDeclSyntax) -> SyntaxVisitorContinueKind {
    // if-config-decl -> '#if' expr stmt-list else-if-directive-clause-list
    //   else-clause? '#endif'
    format(node) {
    }
  }

  override func visit(_ node: PoundErrorDeclSyntax) -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: PoundWarningDeclSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: PoundSourceLocationSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: PoundSourceLocationArgsSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: InheritedTypeSyntax) -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: InheritedTypeListSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: TypeInheritanceClauseSyntax)
    -> SyntaxVisitorContinueKind
  {
    // type-inheritance-clause -> ':' type
    format(node) {
    }
  }

  override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    // class-declaration -> attributes? access-level-modifier?
    //                      'class' class-name
    //                      generic-parameter-clause?
    //                      type-inheritance-clause?
    //                      generic-where-clause?
    //                     '{' class-members '}'
    // class-name -> identifier
    format(node) {
    }
  }

  override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    // struct-declaration -> attributes? access-level-modifier?
    //                         'struct' struct-name
    //                         generic-parameter-clause?
    //                           type-inheritance-clause?
    //                         generic-where-clause?
    //                         '{' struct-members '}'
    // struct-name -> identifier
    format(node) {
    }
  }

  override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    format(node) {
    }
  }

  override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind
  {
    // extension-declaration -> attributes? access-level-modifier?
    //                            'extension' extended-type
    //                              type-inheritance-clause?
    //                            generic-where-clause?
    //                            '{' extension-members '}'
    // extension-name -> identifier
    format(node) {
    }
  }

  override func visit(_ node: MemberDeclBlockSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: MemberDeclListSyntax) -> SyntaxVisitorContinueKind
  {
    // member-decl-list = member-decl member-decl-list?
    format(node) {
    }
  }

  override func visit(_ node: MemberDeclListItemSyntax)
    -> SyntaxVisitorContinueKind
  {
    // member-decl = decl ';'?
    format(node) {
    }
  }

  override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
    // source-file = code-block-item-list eof
    format(node) {
      $0.format(node.statements)
      $0.format(node.eofToken)
    }
  }

  override func visit(_ node: InitializerClauseSyntax)
    -> SyntaxVisitorContinueKind
  {
    // initializer -> '=' expr
    format(node) {
      $0.format(node.equal)
      $0.break(.soft(size: 1))
      $0.group {
        $0.format(node.value)
      }
    }
  }

  override func visit(_ node: FunctionParameterSyntax)
    -> SyntaxVisitorContinueKind
  {
    // parameter ->
    // external-parameter-name? local-parameter-name ':'
    //   type '...'? '='? expression? ','?
    format(node) {
    }
  }

  override func visit(_ node: ModifierListSyntax) -> SyntaxVisitorContinueKind {
    // declaration-modifier -> access-level-modifier
    //                       | mutation-modifier
    //                       | 'class'
    //                       | 'convenience'
    //                       | 'dynamic'
    //                       | 'final'
    //                       | 'infix'
    //                       | 'lazy'
    //                       | 'optional'
    //                       | 'override'
    //                       | 'postfix'
    //                       | 'prefix'
    //                       | 'required'
    //                       | 'static'
    //                       | 'unowned'
    //                       | 'unowned(safe)'
    //                       | 'unowned(unsafe)'
    //                       | 'weak'
    // mutation-modifier -> 'mutating' | 'nonmutating'
    format(node) {
    }
  }

  override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    format(node) {
      $0.format(node.funcKeyword)
      $0.space(1)
      $0.format(node.identifier)
      $0.format(node.signature)

      if let body = node.body {
        $0.space(1)
        $0.format(body)
      }
    }
  }

  override func visit(_ node: InitializerDeclSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: DeinitializerDeclSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: SubscriptDeclSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: AccessLevelModifierSyntax)
    -> SyntaxVisitorContinueKind
  {
    // access-level-modifier -> 'private' | 'private' '(' 'set' ')'
    //                        | 'fileprivate' | 'fileprivate' '(' 'set' ')'
    //                        | 'internal' | 'internal' '(' 'set' ')'
    //                        | 'public' | 'public' '(' 'set' ')'
    //                        | 'open' | 'open' '(' 'set' ')'
    format(node) {
    }
  }

  override func visit(_ node: AccessPathComponentSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: AccessPathSyntax) -> SyntaxVisitorContinueKind {
    format(node) {
    }
  }

  override func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
    format(node) {
    }
  }

  override func visit(_ node: AccessorParameterSyntax)
    -> SyntaxVisitorContinueKind
  {
    // '(' value ')'
    format(node) {
    }
  }

  override func visit(_ node: AccessorDeclSyntax) -> SyntaxVisitorContinueKind {
    format(node) {
    }
  }

  override func visit(_ node: AccessorListSyntax) -> SyntaxVisitorContinueKind {
    format(node) {
    }
  }

  override func visit(_ node: AccessorBlockSyntax) -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: PatternBindingSyntax) -> SyntaxVisitorContinueKind
  {
    format(node) {
      $0.format(node.pattern)
      if let typeAnnotation = node.typeAnnotation {
        $0.formatIfPresent(typeAnnotation)
      }
      if let initializer = node.initializer {
        $0.space(1)
        $0.indent {
          $0.formatIfPresent(initializer)
        }
      }
      if let accessor = node.accessor {
        $0.break(.soft(size: 1))
        $0.formatIfPresent(accessor)
      }
    }
  }

  override func visit(_ node: PatternBindingListSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    format(node) {
      $0.format(node.letOrVarKeyword)

      if node.bindings.count == 1 {
        // If there is only a single binding, don't allow a break between the
        // `let/var` keyword and the identifier; there are better places to
        // break later on.
        $0.space(1)
        $0.format(node.bindings)
      } else {
        // If there is more than one binding, we break and indent after the
        // `let/var` so that each of the comma-delimited items will potentially
        // receive indentation. We also add a group around the individual
        // bindings to bind them together better. (This is done here, not in
        // `visit(_: PatternBindingSyntax)`, because we only want that behavior
        // when there are multiple bindings.)
        $0.break(.soft(size: 1))
        $0.indent {
          for binding in node.bindings {
            $0.group {
              $0.format(binding)
              if binding.trailingComma != nil {
                $0.break(.soft(size: 1))
              }
            }
          }
        }
      }
    }
  }

  override func visit(_ node: EnumCaseElementSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: EnumCaseElementListSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: EnumCaseDeclSyntax) -> SyntaxVisitorContinueKind {
    format(node) {
    }
  }

  override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    format(node) {
    }
  }

  override func visit(_ node: OperatorDeclSyntax) -> SyntaxVisitorContinueKind {
    // operator-decl -> attribute? modifiers? 'operator' operator
    format(node) {
    }
  }

  override func visit(_ node: IdentifierListSyntax) -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: OperatorPrecedenceAndTypesSyntax)
    -> SyntaxVisitorContinueKind
  {
    // infix-operator-group -> ':' identifier ','? identifier?
    format(node) {
    }
  }

  override func visit(_ node: PrecedenceGroupDeclSyntax)
    -> SyntaxVisitorContinueKind
  {
    // precedence-group-decl -> attributes? modifiers? 'precedencegroup'
    //                            identifier '{' precedence-group-attribute-list
    //                            '}'
    format(node) {
    }
  }

  override func visit(_ node: PrecedenceGroupAttributeListSyntax)
    -> SyntaxVisitorContinueKind
  {
    // precedence-group-attribute-list ->
    //     (precedence-group-relation | precedence-group-assignment |
    //      precedence-group-associativity )*
    format(node) {
    }
  }

  override func visit(_ node: PrecedenceGroupRelationSyntax)
    -> SyntaxVisitorContinueKind
  {
    // precedence-group-relation ->
    //     ('higherThan' | 'lowerThan') ':' precedence-group-name-list
    format(node) {
    }
  }

  override func visit(_ node: PrecedenceGroupNameListSyntax)
    -> SyntaxVisitorContinueKind
  {
    // precedence-group-name-list ->
    //    identifier (',' identifier)*
    format(node) {
    }
  }

  override func visit(_ node: PrecedenceGroupAssignmentSyntax)
    -> SyntaxVisitorContinueKind
  {
    // precedence-group-assignment ->
    //     'assignment' ':' ('true' | 'false')
    format(node) {
    }
  }

  override func visit(_ node: PrecedenceGroupAssociativitySyntax)
    -> SyntaxVisitorContinueKind
  {
    // precedence-group-associativity ->
    //     'associativity' ':' ('left' | 'right' | 'none')
    format(node) {
    }
  }

  // MARK: - Expression nodes

  override func visit(_ node: InOutExprSyntax) -> SyntaxVisitorContinueKind {
    // '&' expr
    format(node) {
    }
  }

  override func visit(_ node: PoundColumnExprSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: TupleExprElementListSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: ArrayElementListSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: DictionaryElementListSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: StringLiteralSegmentsSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: TryExprSyntax) -> SyntaxVisitorContinueKind {
    // 'try' ( '?' | '!' )? expr
    format(node) {
    }
  }

  override func visit(_ node: DeclNameArgumentSyntax)
    -> SyntaxVisitorContinueKind
  {
    // declname-arguments -> '(' declname-argument-list ')'
    // declname-argument-list -> declname-argument*
    // declname-argument -> identifier ':'
    format(node) {
    }
  }

  override func visit(_ node: DeclNameArgumentListSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: DeclNameArgumentsSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: IdentifierExprSyntax) -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: SuperRefExprSyntax) -> SyntaxVisitorContinueKind {
    format(node) {
    }
  }

  override func visit(_ node: NilLiteralExprSyntax) -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: DiscardAssignmentExprSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: AssignmentExprSyntax) -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: SequenceExprSyntax) -> SyntaxVisitorContinueKind {
    format(node) {
      let firstIndex = node.elements.startIndex
      switch node.elements.count {
      case 1:
        $0.format(node.elements[firstIndex])
      case 2:
        let secondIndex = node.elements.index(after: firstIndex)
        $0.format(node.elements[firstIndex])
        $0.break(.soft(size: 1))
        $0.format(node.elements[secondIndex])
      case 3:
        let secondIndex = node.elements.index(after: firstIndex)
        let thirdIndex = node.elements.index(after: secondIndex)
        $0.format(node.elements[firstIndex])
        $0.break(.soft(size: 1))
        $0.format(node.elements[secondIndex])
        $0.space(1)
        $0.format(node.elements[thirdIndex])
      default:
        fatalError()
      }
    }
  }

  override func visit(_ node: ExprListSyntax) -> SyntaxVisitorContinueKind {
    format(node) {
    }
  }

  override func visit(_ node: PoundLineExprSyntax) -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: PoundFileExprSyntax) -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: PoundFilePathExprSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: PoundFunctionExprSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: PoundDsohandleExprSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: SymbolicReferenceExprSyntax)
    -> SyntaxVisitorContinueKind
  {
    // symbolic-reference-expression -> identifier generic-argument-clause?
    format(node) {
    }
  }

  override func visit(_ node: PrefixOperatorExprSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: BinaryOperatorExprSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: ArrowExprSyntax) -> SyntaxVisitorContinueKind {
    // arrow-expr -> 'throws'? '->'
    format(node) {
    }
  }

  override func visit(_ node: FloatLiteralExprSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: TupleExprSyntax) -> SyntaxVisitorContinueKind {
    format(node) {
    }
  }

  override func visit(_ node: ArrayExprSyntax) -> SyntaxVisitorContinueKind {
    format(node) {
      $0.group {
        $0.format(node.leftSquare)
        $0.indent {
          $0.break(.soft(size: 0))
          $0.fill {
            $0.join(
              node.elements,
              { $0.format($1) },
              separator: { $0.break(.soft(size: 1)) })
          }
          $0.ifBreak { $0.text(",") }
        }
        $0.break(.soft(size: 0))
        $0.format(node.rightSquare)
      }
    }
  }

  override func visit(_ node: DictionaryExprSyntax) -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: TupleExprElementSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: ArrayElementSyntax) -> SyntaxVisitorContinueKind {
    // expression ','?
    format(node) {
      $0.format(node.expression)

      if let parent = node.parent?.as(ArrayElementListSyntax.self),
        node.indexInParent < parent.count - 1
      {
        $0.formatIfPresent(node.trailingComma)
      } else {
        $0.skip(node.trailingComma)
      }
    }
  }

  override func visit(_ node: DictionaryElementSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: IntegerLiteralExprSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: BooleanLiteralExprSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: TernaryExprSyntax) -> SyntaxVisitorContinueKind {
    // expr '?' expr ':' expr
    format(node) {
    }
  }

  override func visit(_ node: MemberAccessExprSyntax)
    -> SyntaxVisitorContinueKind
  {
    // ( expr )? '.' name
    format(node) {
    }
  }

  override func visit(_ node: IsExprSyntax) -> SyntaxVisitorContinueKind {
    format(node) {
    }
  }

  override func visit(_ node: AsExprSyntax) -> SyntaxVisitorContinueKind {
    format(node) {
      $0.format(node.asTok)
      $0.formatIfPresent(node.questionOrExclamationMark)
      $0.space(1)
      $0.format(node.typeName)
    }
  }

  override func visit(_ node: TypeExprSyntax) -> SyntaxVisitorContinueKind {
    format(node) {
    }
  }

  override func visit(_ node: ClosureCaptureItemSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: ClosureCaptureItemListSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: ClosureCaptureSignatureSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: ClosureParamSyntax) -> SyntaxVisitorContinueKind {
    format(node) {
    }
  }

  override func visit(_ node: ClosureParamListSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: ClosureSignatureSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
    format(node) {
    }
  }

  override func visit(_ node: UnresolvedPatternExprSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: FunctionCallExprSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: SubscriptExprSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: OptionalChainingExprSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: ForcedValueExprSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: PostfixUnaryExprSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: SpecializeExprSyntax) -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: StringSegmentSyntax) -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: ExpressionSegmentSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: StringLiteralExprSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: KeyPathExprSyntax) -> SyntaxVisitorContinueKind {
    format(node) {
    }
  }

  override func visit(_ node: KeyPathBaseExprSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: ObjcNamePieceSyntax) -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: ObjcNameSyntax) -> SyntaxVisitorContinueKind {
    format(node) {
    }
  }

  override func visit(_ node: ObjcKeyPathExprSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: ObjcSelectorExprSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: EditorPlaceholderExprSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: ObjectLiteralExprSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  // MARK: - Generic Nodes

  override func visit(_ node: GenericWhereClauseSyntax)
    -> SyntaxVisitorContinueKind
  {
    // generic-where-clause -> 'where' requirement-list
    format(node) {
    }
  }

  override func visit(_ node: GenericRequirementListSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: GenericRequirementSyntax)
    -> SyntaxVisitorContinueKind
  {
    // generic-requirement ->
    //     (same-type-requrement|conformance-requirement) ','?
    format(node) {
    }
  }

  override func visit(_ node: SameTypeRequirementSyntax)
    -> SyntaxVisitorContinueKind
  {
    // same-type-requirement -> type-identifier == type
    format(node) {
    }
  }

  override func visit(_ node: GenericParameterListSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: GenericParameterSyntax)
    -> SyntaxVisitorContinueKind
  {
    // generic-parameter -> type-name
    //                    | type-name : type-identifier
    //                    | type-name : protocol-composition-type
    format(node) {
    }
  }

  override func visit(_ node: GenericParameterClauseSyntax)
    -> SyntaxVisitorContinueKind
  {
    // generic-parameter-clause -> '<' generic-parameter-list '>'
    format(node) {
    }
  }

  override func visit(_ node: ConformanceRequirementSyntax)
    -> SyntaxVisitorContinueKind
  {
    // conformance-requirement -> type-identifier : type-identifier
    format(node) {
    }
  }

  // MARK: - Pattern Nodes

  override func visit(_ node: TypeAnnotationSyntax) -> SyntaxVisitorContinueKind
  {
    // type-annotation -> ':' type
    format(node) {
      $0.format(node.colon)
      $0.break(.soft(size: 1))
      $0.group {
        $0.format(node.type)
      }
    }
  }

  override func visit(_ node: EnumCasePatternSyntax)
    -> SyntaxVisitorContinueKind
  {
    // enum-case-pattern -> type-identifier? '.' identifier tuple-pattern?
    format(node) {
    }
  }

  override func visit(_ node: IsTypePatternSyntax) -> SyntaxVisitorContinueKind
  {
    // is-type-pattern -> 'is' type
    format(node) {
      $0.format(node.isKeyword)
      $0.space(1)
      $0.format(node.type)
    }
  }

  override func visit(_ node: OptionalPatternSyntax)
    -> SyntaxVisitorContinueKind
  {
    // optional-pattern -> pattern '?'
    format(node) {
    }
  }

  override func visit(_ node: IdentifierPatternSyntax)
    -> SyntaxVisitorContinueKind
  {
    // identifier-pattern -> identifier
    format(node) {
    }
  }

  override func visit(_ node: AsTypePatternSyntax) -> SyntaxVisitorContinueKind
  {
    // as-pattern -> pattern 'as' type
    format(node) {
      $0.format(node.pattern)
      $0.break(.soft(size: 1))
      $0.format(node.asKeyword)
      $0.space(1)
      $0.format(node.type)
    }
  }

  private func formatAsTuple<Elements: SyntaxProtocol>(
    builder: inout FormatBuilder,
    leftParen: TokenSyntax, elements: Elements, rightParen: TokenSyntax
  ) {
    builder.format(leftParen)
    builder.indent {
      // TODO: fill
      $0.break(.soft(size: 0))
      $0.format(elements)
    }
    builder.break(.soft(size: 0))
    builder.format(rightParen)
  }

  override func visit(_ node: TuplePatternSyntax) -> SyntaxVisitorContinueKind {
    // tuple-pattern -> '(' tuple-pattern-element-list ')'
    format(node) {
      formatAsTuple(
        builder: &$0,
        leftParen: node.leftParen,
        elements: node.elements,
        rightParen: node.rightParen
      )
    }
  }

  override func visit(_ node: WildcardPatternSyntax)
    -> SyntaxVisitorContinueKind
  {
    // wildcard-pattern -> '_' type-annotation?
    format(node) {
    }
  }

  override func visit(_ node: TuplePatternElementSyntax)
    -> SyntaxVisitorContinueKind
  {
    // tuple-pattern-element -> identifier? ':' pattern ','?
    format(node) {
      if let labelName = node.labelName, let labelColon = node.labelColon {
        $0.format(labelName)
        $0.format(labelColon)
        $0.break(.soft(size: 1))
      }
      $0.format(node.pattern)
      if let trailingComma = node.trailingComma {
        $0.format(trailingComma)
        $0.break(.soft(size: 1))
      }
    }
  }

  override func visit(_ node: ExpressionPatternSyntax)
    -> SyntaxVisitorContinueKind
  {
    // expr-pattern -> expr
    format(node) {
    }
  }

  override func visit(_ node: TuplePatternElementListSyntax)
    -> SyntaxVisitorContinueKind
  {
    // tuple-pattern-element-list -> tuple-pattern-element
    //   tuple-pattern-element-list?
    format(node) {
    }
  }

  override func visit(_ node: ValueBindingPatternSyntax)
    -> SyntaxVisitorContinueKind
  {
    // value-binding-pattern -> 'let' pattern
    //                        | 'var' pattern
    format(node) {
      $0.format(node.letOrVarKeyword)
      $0.break(.soft(size: 1))
      $0.format(node.valuePattern)
    }
  }

  // MARK: - Statement Nodes

  override func visit(_ node: ContinueStmtSyntax) -> SyntaxVisitorContinueKind {
    // continue-stmt -> 'continue' label? ';'?
    format(node) {
    }
  }

  override func visit(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
    // while-stmt -> label? ':'? 'while' condition-list code-block ';'?
    format(node) {
    }
  }

  override func visit(_ node: DeferStmtSyntax) -> SyntaxVisitorContinueKind {
    // defer-stmt -> 'defer' code-block ';'?
    format(node) {
    }
  }

  override func visit(_ node: ExpressionStmtSyntax) -> SyntaxVisitorContinueKind
  {
    // expr-stmt -> expression ';'?
    format(node) {
    }
  }

  override func visit(_ node: SwitchCaseListSyntax) -> SyntaxVisitorContinueKind
  {
    // switch-case-list -> switch-case switch-case-list?
    format(node) {
    }
  }

  override func visit(_ node: RepeatWhileStmtSyntax)
    -> SyntaxVisitorContinueKind
  {
    // repeat-while-stmt -> label? ':'? 'repeat' code-block 'while' expr ';'?
    format(node) {
    }
  }

  override func visit(_ node: GuardStmtSyntax) -> SyntaxVisitorContinueKind {
    // guard-stmt -> 'guard' condition-list 'else' code-block ';'?
    format(node) {
    }
  }

  override func visit(_ node: WhereClauseSyntax) -> SyntaxVisitorContinueKind {
    format(node) {
    }
  }

  override func visit(_ node: ForInStmtSyntax) -> SyntaxVisitorContinueKind {
    // for-in-stmt -> label? ':'? 'for' 'case'? pattern 'in' expr 'where'?
    //   expr code-block ';'?
    format(node) {
    }
  }

  override func visit(_ node: SwitchStmtSyntax) -> SyntaxVisitorContinueKind {
    // switch-stmt -> identifier? ':'? 'switch' expr '{'
    //   switch-case-list '}' ';'?
    format(node) {
    }
  }

  override func visit(_ node: CatchClauseListSyntax)
    -> SyntaxVisitorContinueKind
  {
    // catch-clause-list -> catch-clause catch-clause-list?
    format(node) {
    }
  }

  override func visit(_ node: DoStmtSyntax) -> SyntaxVisitorContinueKind {
    // do-stmt -> identifier? ':'? 'do' code-block catch-clause-list ';'?
    format(node) {
    }
  }

  override func visit(_ node: ReturnStmtSyntax) -> SyntaxVisitorContinueKind {
    // return-stmt -> 'return' expr? ';'?
    format(node) {
    }
  }

  override func visit(_ node: YieldStmtSyntax) -> SyntaxVisitorContinueKind {
    // yield-stmt -> 'yield' '('? expr-list? ')'?
    format(node) {
    }
  }

  override func visit(_ node: YieldListSyntax) -> SyntaxVisitorContinueKind {
    format(node) {
    }
  }

  override func visit(_ node: FallthroughStmtSyntax)
    -> SyntaxVisitorContinueKind
  {
    // fallthrough-stmt -> 'fallthrough' ';'?
    format(node) {
    }
  }

  override func visit(_ node: BreakStmtSyntax) -> SyntaxVisitorContinueKind {
    // break-stmt -> 'break' identifier? ';'?
    format(node) {
    }
  }

  override func visit(_ node: CaseItemListSyntax) -> SyntaxVisitorContinueKind {
    // case-item-list -> case-item case-item-list?
    format(node) {
    }
  }

  override func visit(_ node: ConditionElementSyntax)
    -> SyntaxVisitorContinueKind
  {
    // condition -> expression
    //            | availability-condition
    //            | case-condition
    //            | optional-binding-condition
    format(node) {
    }
  }

  override func visit(_ node: AvailabilityConditionSyntax)
    -> SyntaxVisitorContinueKind
  {
    // availability-condition -> '#available' '(' availability-spec ')'
    format(node) {
    }
  }

  override func visit(_ node: MatchingPatternConditionSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: OptionalBindingConditionSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: ConditionElementListSyntax)
    -> SyntaxVisitorContinueKind
  {
    // condition-list -> condition
    //                 | condition ','? condition-list
    format(node) {
    }
  }

  override func visit(_ node: DeclarationStmtSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: ThrowStmtSyntax) -> SyntaxVisitorContinueKind {
    // throw-stmt -> 'throw' expr ';'?
    format(node) {
    }
  }

  override func visit(_ node: IfStmtSyntax) -> SyntaxVisitorContinueKind {
    // if-stmt -> identifier? ':'? 'if' condition-list code-block
    //   else-clause ';'?
    format(node) {
    }
  }

  override func visit(_ node: ElseIfContinuationSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: ElseBlockSyntax) -> SyntaxVisitorContinueKind {
    // else-clause -> 'else' code-block
    format(node) {
    }
  }

  override func visit(_ node: SwitchCaseSyntax) -> SyntaxVisitorContinueKind {
    // switch-case -> unknown-attr? switch-case-label stmt-list
    //              | unknown-attr? switch-default-label stmt-list
    format(node) {
    }
  }

  override func visit(_ node: SwitchDefaultLabelSyntax)
    -> SyntaxVisitorContinueKind
  {
    // switch-default-label -> 'default' ':'
    format(node) {
    }
  }

  override func visit(_ node: CaseItemSyntax) -> SyntaxVisitorContinueKind {
    // case-item -> pattern where-clause? ','?
    format(node) {
    }
  }

  override func visit(_ node: SwitchCaseLabelSyntax)
    -> SyntaxVisitorContinueKind
  {
    // switch-case-label -> 'case' case-item-list ':'
    format(node) {
    }
  }

  override func visit(_ node: CatchClauseSyntax) -> SyntaxVisitorContinueKind {
    // catch-clause 'catch' case-item-list? code-block
    format(node) {
    }
  }

  override func visit(_ node: PoundAssertStmtSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  // MARK: - Type Nodes

  override func visit(_ node: SimpleTypeIdentifierSyntax)
    -> SyntaxVisitorContinueKind
  {
    // simple-type-identifier -> identifier generic-argument-clause?
    format(node) {
    }
  }

  override func visit(_ node: MemberTypeIdentifierSyntax)
    -> SyntaxVisitorContinueKind
  {
    // member-type-identifier -> type '.' identifier generic-argument-clause?
    format(node) {
    }
  }

  override func visit(_ node: ClassRestrictionTypeSyntax)
    -> SyntaxVisitorContinueKind
  {
    // class-restriction-type -> 'class'
    format(node) {
    }
  }

  override func visit(_ node: ArrayTypeSyntax) -> SyntaxVisitorContinueKind {
    // array-type -> '[' type ']'
    format(node) {
    }
  }

  override func visit(_ node: DictionaryTypeSyntax) -> SyntaxVisitorContinueKind
  {
    // dictionary-type -> '[' type ':' type ']'
    format(node) {
    }
  }

  override func visit(_ node: MetatypeTypeSyntax) -> SyntaxVisitorContinueKind {
    // metatype-type -> type '.' 'Type'
    //                | type '.' 'Protocol
    format(node) {
    }
  }

  override func visit(_ node: OptionalTypeSyntax) -> SyntaxVisitorContinueKind {
    // optional-type -> type '?'
    format(node) {
    }
  }

  override func visit(_ node: SomeTypeSyntax) -> SyntaxVisitorContinueKind {
    // some type -> some 'type'
    format(node) {
      $0.format(node.someSpecifier)
      $0.space(1)
      $0.format(node.baseType)
    }
  }

  override func visit(_ node: ImplicitlyUnwrappedOptionalTypeSyntax)
    -> SyntaxVisitorContinueKind
  {
    // implicitly-unwrapped-optional-type -> type '!'
    format(node) {
    }
  }

  override func visit(_ node: CompositionTypeElementSyntax)
    -> SyntaxVisitorContinueKind
  {
    // composition-type-element -> type '&'
    format(node) {
    }
  }

  override func visit(_ node: CompositionTypeElementListSyntax)
    -> SyntaxVisitorContinueKind
  {
    // composition-typeelement-list -> composition-type-element
    //   composition-type-element-list?
    format(node) {
    }
  }

  override func visit(_ node: CompositionTypeSyntax)
    -> SyntaxVisitorContinueKind
  {
    // composition-type -> composition-type-element-list
    format(node) {
    }
  }

  override func visit(_ node: TupleTypeElementSyntax)
    -> SyntaxVisitorContinueKind
  {
    // tuple-type-element -> identifier? ':'? type-annotation ','?
    format(node) {
    }
  }

  override func visit(_ node: TupleTypeElementListSyntax)
    -> SyntaxVisitorContinueKind
  {
    // tuple-type-element-list -> tuple-type-element tuple-type-element-list?
    format(node) {
    }
  }

  override func visit(_ node: TupleTypeSyntax) -> SyntaxVisitorContinueKind {
    // tuple-type -> '(' tuple-type-element-list ')'
    format(node) {
      formatAsTuple(
        builder: &$0,
        leftParen: node.leftParen,
        elements: node.elements,
        rightParen: node.rightParen
      )
    }
  }

  override func visit(_ node: FunctionTypeSyntax) -> SyntaxVisitorContinueKind {
    // throwing-specifier -> 'throws' | 'rethrows'
    // function-type -> attribute-list '(' function-type-argument-list ')'
    //   throwing-specifier? '->'? type?
    format(node) {
    }
  }

  override func visit(_ node: AttributedTypeSyntax) -> SyntaxVisitorContinueKind
  {
    // attributed-type -> type-specifier? attribute-list? type
    // type-specifiyer -> 'inout' | '__owned' | '__unowned'
    format(node) {
    }
  }

  override func visit(_ node: GenericArgumentListSyntax)
    -> SyntaxVisitorContinueKind
  {
    // generic-argument-list -> generic-argument generic-argument-list?
    format(node) {
    }
  }

  override func visit(_ node: GenericArgumentSyntax)
    -> SyntaxVisitorContinueKind
  {
    format(node) {
    }
  }

  override func visit(_ node: GenericArgumentClauseSyntax)
    -> SyntaxVisitorContinueKind
  {
    // generic-argument-clause -> '<' generic-argument-list '>'
    format(node) {
    }
  }

  // MARK: - Tokens

  override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
    format(token) {
      $0.text(token.text)
    }
  }
}

extension SyntaxFormattingVisitor {
  #if DEBUG
    /// A dummy format function that, in debug builds, acts as a placeholder for
    /// a future implementation.
    private func format<Node: SyntaxProtocol>(_ _: Node, _ _: () -> Void)
      -> SyntaxVisitorContinueKind
    {
      print("*** warning: visit(_ node: \(Node.self)) not yet implemented")
      return .visitChildren
    }
  #else
    /// A dummy format function that, in release builds, prevents empty
    /// placeholders from compiling if they were left in by mistake, and
    /// otherwise only compile successfully if they never return.
    private func format<Node: SyntaxProtocol>(_ _: Node, _ content: () -> Never)
      -> SyntaxVisitorContinueKind
    {
      content()
    }
  #endif

  /// Assigns formatting to the given syntax node.
  private func format<Node: SyntaxProtocol>(
    _ node: Node, content: (inout FormatBuilder) -> Void
  ) -> SyntaxVisitorContinueKind {
    guard !state.shouldSkipNode(withID: node.id) else { return .skipChildren }

    guard root.behavior != nil else {
      FormatBuilder.build(into: root, state: state, content: content)
      return .visitChildren
    }

    if let document = state.pendingNode(forID: node.id) {
      guard document.behavior == nil else {
        preconditionFailure(
          "Node \(type(of: node))"
            + "(\"\(node.description)\") was already formatted")
      }
      FormatBuilder.build(into: document, state: state, content: content)
      return .visitChildren
    }

    var current: SyntaxProtocol = node
    while let parent = current.parent {
      if let document = state.pendingNode(forID: parent.id) {
        FormatBuilder.build(into: document, state: state, content: content)
        return .visitChildren
      }
      current = parent
    }

    preconditionFailure("Made it to root without finding anything?")
  }
}

extension Diagnostic.Message {

  public static let moveEndOfLineComment = Diagnostic.Message(
    .warning, "move end-of-line comment that exceeds the line length")

  public static let addTrailingComma = Diagnostic.Message(
    .warning, "add trailing comma to the last element in multiline collection literal")

  public static let removeTrailingComma = Diagnostic.Message(
    .warning, "remove trailing comma from the last element in single line collection literal")
}
