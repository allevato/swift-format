//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

// This file is automatically generated with generate-pipeline. Do Not Edit!

import SwiftFormatCore
import SwiftFormatRules
import SwiftSyntax

extension LintPipeline {

  func visit(_ node: ArrayExprSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(MultiLineTrailingCommas.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: AsExprSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(NeverForceUnwrap.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: AssociatedtypeDeclSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(BeginDocumentationCommentWithOneLineSummary.visit, in: context, for: node)
    visitIfEnabled(NoLeadingUnderscores.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(AllPublicDeclarationsHaveDocumentation.visit, in: context, for: node)
    visitIfEnabled(BeginDocumentationCommentWithOneLineSummary.visit, in: context, for: node)
    visitIfEnabled(DontRepeatTypeInStaticProperties.visit, in: context, for: node)
    visitIfEnabled(NoLeadingUnderscores.visit, in: context, for: node)
    visitIfEnabled(UseTripleSlashForDocumentationComments.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(OneVariableDeclarationPerLine.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: CodeBlockItemListSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(DoNotUseSemicolons.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(AmbiguousTrailingClosureOverload.visit, in: context, for: node)
    visitIfEnabled(OneVariableDeclarationPerLine.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: ConditionElementSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(NoParensAroundConditions.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: DeinitializerDeclSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(AllPublicDeclarationsHaveDocumentation.visit, in: context, for: node)
    visitIfEnabled(BeginDocumentationCommentWithOneLineSummary.visit, in: context, for: node)
    visitIfEnabled(UseTripleSlashForDocumentationComments.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: DictionaryExprSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(MultiLineTrailingCommas.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: EnumCaseElementSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(AlwaysUseLowerCamelCase.visit, in: context, for: node)
    visitIfEnabled(NoLeadingUnderscores.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(BeginDocumentationCommentWithOneLineSummary.visit, in: context, for: node)
    visitIfEnabled(DontRepeatTypeInStaticProperties.visit, in: context, for: node)
    visitIfEnabled(FullyIndirectEnum.visit, in: context, for: node)
    visitIfEnabled(NoLeadingUnderscores.visit, in: context, for: node)
    visitIfEnabled(OneCasePerLine.visit, in: context, for: node)
    visitIfEnabled(UseTripleSlashForDocumentationComments.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(DontRepeatTypeInStaticProperties.visit, in: context, for: node)
    visitIfEnabled(NoAccessLevelOnExtensionDeclaration.visit, in: context, for: node)
    visitIfEnabled(UseTripleSlashForDocumentationComments.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: ForcedValueExprSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(NeverForceUnwrap.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(NoEmptyTrailingClosureParentheses.visit, in: context, for: node)
    visitIfEnabled(OnlyOneTrailingClosureArgument.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(AllPublicDeclarationsHaveDocumentation.visit, in: context, for: node)
    visitIfEnabled(AlwaysUseLowerCamelCase.visit, in: context, for: node)
    visitIfEnabled(BeginDocumentationCommentWithOneLineSummary.visit, in: context, for: node)
    visitIfEnabled(NoLeadingUnderscores.visit, in: context, for: node)
    visitIfEnabled(UseTripleSlashForDocumentationComments.visit, in: context, for: node)
    visitIfEnabled(ValidateDocumentationComments.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: FunctionParameterSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(NoLeadingUnderscores.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: FunctionSignatureSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(NoVoidReturnOnFunctionSignature.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: FunctionTypeSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(ReturnVoidInsteadOfEmptyTuple.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: GenericParameterSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(NoLeadingUnderscores.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: IdentifierPatternSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(IdentifiersMustBeASCII.visit, in: context, for: node)
    visitIfEnabled(NoLeadingUnderscores.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: IfStmtSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(NoParensAroundConditions.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(AllPublicDeclarationsHaveDocumentation.visit, in: context, for: node)
    visitIfEnabled(BeginDocumentationCommentWithOneLineSummary.visit, in: context, for: node)
    visitIfEnabled(UseTripleSlashForDocumentationComments.visit, in: context, for: node)
    visitIfEnabled(ValidateDocumentationComments.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: IntegerLiteralExprSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(GroupNumericLiterals.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: MemberDeclBlockSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(AmbiguousTrailingClosureOverload.visit, in: context, for: node)
    visitIfEnabled(BlankLineBetweenMembers.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: MemberDeclListSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(DoNotUseSemicolons.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: PatternBindingSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(UseSingleLinePropertyGetter.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: PrecedenceGroupDeclSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(NoLeadingUnderscores.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(AllPublicDeclarationsHaveDocumentation.visit, in: context, for: node)
    visitIfEnabled(BeginDocumentationCommentWithOneLineSummary.visit, in: context, for: node)
    visitIfEnabled(DontRepeatTypeInStaticProperties.visit, in: context, for: node)
    visitIfEnabled(NoLeadingUnderscores.visit, in: context, for: node)
    visitIfEnabled(UseTripleSlashForDocumentationComments.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: RepeatWhileStmtSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(NoParensAroundConditions.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: SimpleTypeIdentifierSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(UseShorthandTypeNames.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(AmbiguousTrailingClosureOverload.visit, in: context, for: node)
    visitIfEnabled(NeverForceUnwrap.visit, in: context, for: node)
    visitIfEnabled(NeverUseForceTry.visit, in: context, for: node)
    visitIfEnabled(NeverUseImplicitlyUnwrappedOptionals.visit, in: context, for: node)
    visitIfEnabled(OneVariableDeclarationPerLine.visit, in: context, for: node)
    visitIfEnabled(OrderedImports.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: SpecializeExprSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(UseShorthandTypeNames.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(AllPublicDeclarationsHaveDocumentation.visit, in: context, for: node)
    visitIfEnabled(BeginDocumentationCommentWithOneLineSummary.visit, in: context, for: node)
    visitIfEnabled(DontRepeatTypeInStaticProperties.visit, in: context, for: node)
    visitIfEnabled(NoLeadingUnderscores.visit, in: context, for: node)
    visitIfEnabled(UseEnumForNamespacing.visit, in: context, for: node)
    visitIfEnabled(UseSynthesizedInitializer.visit, in: context, for: node)
    visitIfEnabled(UseTripleSlashForDocumentationComments.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(AllPublicDeclarationsHaveDocumentation.visit, in: context, for: node)
    visitIfEnabled(BeginDocumentationCommentWithOneLineSummary.visit, in: context, for: node)
    visitIfEnabled(UseTripleSlashForDocumentationComments.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: SwitchCaseLabelSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(NoLabelsInCasePatterns.visit, in: context, for: node)
    visitIfEnabled(UseLetInEveryBoundCaseVariable.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: SwitchStmtSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(CaseIndentLevelEqualsSwitch.visit, in: context, for: node)
    visitIfEnabled(NoCasesWithOnlyFallthrough.visit, in: context, for: node)
    visitIfEnabled(NoParensAroundConditions.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: TokenSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(NoBlockComments.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: TryExprSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(NeverUseForceTry.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: TypealiasDeclSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(AllPublicDeclarationsHaveDocumentation.visit, in: context, for: node)
    visitIfEnabled(BeginDocumentationCommentWithOneLineSummary.visit, in: context, for: node)
    visitIfEnabled(NoLeadingUnderscores.visit, in: context, for: node)
    visitIfEnabled(UseTripleSlashForDocumentationComments.visit, in: context, for: node)
    return .visitChildren
  }

  func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    visitIfEnabled(AllPublicDeclarationsHaveDocumentation.visit, in: context, for: node)
    visitIfEnabled(AlwaysUseLowerCamelCase.visit, in: context, for: node)
    visitIfEnabled(BeginDocumentationCommentWithOneLineSummary.visit, in: context, for: node)
    visitIfEnabled(NeverUseImplicitlyUnwrappedOptionals.visit, in: context, for: node)
    visitIfEnabled(UseTripleSlashForDocumentationComments.visit, in: context, for: node)
    return .visitChildren
  }
}

extension FormatPipeline {

  func visit(_ node: Syntax) -> Syntax {
    var node = node
    node = BlankLineBetweenMembers(context: context).visit(node)
    node = DoNotUseSemicolons(context: context).visit(node)
    node = FullyIndirectEnum(context: context).visit(node)
    node = GroupNumericLiterals(context: context).visit(node)
    node = MultiLineTrailingCommas(context: context).visit(node)
    node = NoAccessLevelOnExtensionDeclaration(context: context).visit(node)
    node = NoBlockComments(context: context).visit(node)
    node = NoCasesWithOnlyFallthrough(context: context).visit(node)
    node = NoEmptyTrailingClosureParentheses(context: context).visit(node)
    node = NoLabelsInCasePatterns(context: context).visit(node)
    node = NoParensAroundConditions(context: context).visit(node)
    node = NoVoidReturnOnFunctionSignature(context: context).visit(node)
    node = OneCasePerLine(context: context).visit(node)
    node = OneVariableDeclarationPerLine(context: context).visit(node)
    node = OrderedImports(context: context).visit(node)
    node = ReturnVoidInsteadOfEmptyTuple(context: context).visit(node)
    node = UseEnumForNamespacing(context: context).visit(node)
    node = UseShorthandTypeNames(context: context).visit(node)
    node = UseSingleLinePropertyGetter(context: context).visit(node)
    node = UseTripleSlashForDocumentationComments(context: context).visit(node)
    return node
  }
}
