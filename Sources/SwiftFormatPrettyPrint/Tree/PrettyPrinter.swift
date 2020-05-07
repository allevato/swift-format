import SwiftFormatConfiguration
import SwiftFormatCore
import SwiftSyntax

///
public final class PrettyPrinter {
  ///
  public let context: Context

  ///
  public let operatorContext: OperatorContext

  ///
  public let printTokenStream: Bool

  ///
  public let receiveOutput: (String) -> Void

  ///
  private var pendingSpaces = 0

  ///
  public init(
    context: Context,
    operatorContext: OperatorContext,
    printTokenStream: Bool,
    whitespaceOnly: Bool,
    receiveOutput: @escaping (String) -> Void
  ) {
    self.context = context
    self.operatorContext = operatorContext
    self.printTokenStream = printTokenStream
    self.receiveOutput = receiveOutput
  }

  ///
  public func print(_ syntax: Syntax) {
    let folded = SequenceExprFoldingRewriter(operatorContext: operatorContext)
      .visit(syntax)
    let commentsMoved = CommentMovingRewriter().visit(folded)

    let formatVisitor = SyntaxFormattingVisitor()
    formatVisitor.walk(commentsMoved)

    print(formatVisitor.root)
  }

  ///
  public func print(_ node: FormatNode) {
    node.propagateBreaks()

    var nextColumn = 0
    var shouldRemeasure = false

    var lineSuffix = PrinterStateStack()
    var commands = PrinterStateStack()
    commands.push(indent: Indentation(), mode: .break, node: node)

    while let command = commands.poppedState() {
      let indent = command.indent
      let mode = command.mode

      behaviorSwitch: switch command.behavior {
      case nil:
        preconditionFailure("A FormatNode did not have its behavior set.")

      case .text(let string):
        writeText(string)
        nextColumn += string.count

      case .concat(let parts):
        for part in parts.reversed() {
          commands.push(indent: indent, mode: mode, node: part)
        }

      case .indent(let contents):
        let newIndent = Indentation(value: indent.value + "  ")
        commands.push(indent: newIndent, mode: mode, node: contents)

      case .group(let contents, let shouldBreak, let alternatives):
        switch mode {
        case .flat:
          if !shouldRemeasure {
            commands.push(
              indent: indent,
              mode: shouldBreak ? .break : .flat,
              node: contents)
            break
          }
          else {
            fallthrough
          }
        case .break:
          shouldRemeasure = false

          let next = PrinterState(
            indent: indent, mode: .flat, behavior: contents.behavior)
          let spaceRemaining = context.configuration.lineLength - nextColumn

          if !shouldBreak
            && fits(next: next, width: spaceRemaining, restCommands: commands)
          {
            commands.push(next)
          } else {
            guard let mostExpandedAlternative = alternatives.last else {
              commands.push(indent: indent, mode: .break, node: contents)
              break
            }

            // If a group has expanded states, it is providing multiple
            // representations of itself that are ordered from most flattened
            // to most expanded. Find the first one that fits and use that.
            if shouldBreak {
              commands.push(
                indent: indent, mode: .break, node: mostExpandedAlternative)
              break
            }

            for alternative in alternatives {
              let printerState = PrinterState(
                indent: indent, mode: .flat, behavior: alternative.behavior)
              if fits(
                next: printerState,
                width: spaceRemaining,
                restCommands: commands)
              {
                commands.push(printerState)
                break behaviorSwitch
              }
            }

            // If none of the expansions fit when laid out flat, use the most
            // expanded state in break mode.
            commands.push(
              indent: indent, mode: .break, node: mostExpandedAlternative)
          }
        }

      case .fill(var parts):
        guard !parts.isEmpty else { break }

        let spaceRemaining = context.configuration.lineLength - nextColumn

        let content = parts[0]
        let contentFlatCmd =
          PrinterState(indent: indent, mode: .flat, behavior: content.behavior)
        let contentBreakCmd =
          PrinterState(indent: indent, mode: .break, behavior: content.behavior)
        let contentFits =
          fits(next: contentFlatCmd, width: spaceRemaining, mustBeFlat: true)

        if parts.count == 1 {
          if contentFits {
            commands.push(contentFlatCmd)
          } else {
            commands.push(contentBreakCmd)
          }
          break
        }

        let whitespace = parts[1]
        let whitespaceFlatCmd = PrinterState(
          indent: indent, mode: .flat, behavior: whitespace.behavior)
        let whitespaceBreakCmd = PrinterState(
          indent: indent, mode: .break, behavior: whitespace.behavior)

        if parts.count == 2 {
          if contentFits {
            commands.push(whitespaceFlatCmd)
            commands.push(contentFlatCmd)
          } else {
            commands.push(whitespaceBreakCmd)
            commands.push(contentBreakCmd)
          }
          break
        }

        parts.removeFirst(2)
        let remainingCmd =
          PrinterState(indent: indent, mode: mode, behavior: .fill(parts))

        let secondContent = parts[0]
        let firstAndSecondContentFlatCmd =
          PrinterState(
            indent: indent,
            mode: .flat,
            behavior: .concat([content, whitespace, secondContent]))
        let firstAndSecondContentFits = fits(
          next: firstAndSecondContentFlatCmd,
          width: spaceRemaining,
          mustBeFlat: true)

        if firstAndSecondContentFits {
          commands.push(remainingCmd)
          commands.push(whitespaceFlatCmd)
          commands.push(contentFlatCmd)
        } else if contentFits {
          commands.push(remainingCmd)
          commands.push(whitespaceBreakCmd)
          commands.push(contentFlatCmd)
        } else {
          commands.push(remainingCmd)
          commands.push(whitespaceBreakCmd)
          commands.push(contentBreakCmd)
        }

      case .ifBreak(let ifBreak, let noBreak):
        if mode == .break, let ifBreak = ifBreak {
          commands.push(indent: indent, mode: mode, node: ifBreak)
        } else if mode == .flat, let noBreak = noBreak {
          commands.push(indent: indent, mode: mode, node: noBreak)
        }

      case .space(let count):
        pendingSpaces += count

      case .break(let lineStyle):
        switch mode {
        case .flat:
          if case .soft(let size) = lineStyle {
            pendingSpaces += size
            nextColumn += size
            break
          } else {  // lineStyle == .hard
            shouldRemeasure = true
            fallthrough
          }

        case .break:
          if !lineSuffix.isEmpty {
            commands.push(command)
            lineSuffix.drain(into: &commands)
            break
          }
          // if doc.literal...
          // else...
          writeNewline()
          writeText(indent.value)
          nextColumn = indent.length
        }

      case .lineSuffix(let contents):
        lineSuffix.push(indent: indent, mode: mode, node: contents)

      case .breakParent:
        // Do nothing.
        break
      }
    }
  }

  ///
  private func writeText(_ text: String) {
    if pendingSpaces > 0 {
      receiveOutput(String(repeating: " ", count: pendingSpaces))
      pendingSpaces = 0
    }
    receiveOutput(text)
  }

  private func writeNewline() {
    pendingSpaces = 0
    receiveOutput("\n")
  }

  ///
  private func fits(
    next: PrinterState,
    width: Int,
    restCommands: PrinterStateStack = PrinterStateStack(),
    mustBeFlat: Bool = false
  ) -> Bool {
    var width = width

    var restCommands = restCommands

    var commands = PrinterStateStack()
    commands.push(next)

    while width >= 0 {
      if commands.isEmpty {
        guard let nextRestCommand = restCommands.poppedState() else {
          return true
        }
        commands.push(nextRestCommand)
        continue
      }

      guard let command = commands.poppedState() else {
        preconditionFailure("Should have had at least one command on the stack.")
      }

      let indent = command.indent
      let currentMode = command.mode

      switch command.behavior {
      case nil:
        preconditionFailure("A FormatNode did not have its behavior set.")

      case .text(let string):
        width -= string.count

      case .concat(let parts), .fill(let parts):
        parts.reversed().forEach {
          commands.push(indent: indent, mode: currentMode, node: $0)
        }

      case .indent(let contents):
        let newIndent = Indentation(value: indent.value + "  ")
        commands.push(indent: newIndent, mode: currentMode, node: contents)

      case .group(let contents, let shouldBreak, _):
        if mustBeFlat && shouldBreak {
          return false
        }

        commands.push(
          indent: indent,
          mode: shouldBreak ? .break : currentMode,
          node: contents)

      case .ifBreak(let ifBreak, let noBreak):
        if currentMode == .break, let ifBreak = ifBreak {
          commands.push(indent: indent, mode: currentMode, node: ifBreak)
        } else if currentMode == .flat, let noBreak = noBreak {
          commands.push(indent: indent, mode: currentMode, node: noBreak)
        }

      case .space(let count):
        width -= count

      case .break(let lineStyle):
        switch currentMode {
        case .flat:
          if case .soft(let size) = lineStyle {
            width -= size
            break
          }
          return true

        case .break:
          return true
        }

      case .lineSuffix:
        // Intentionally do nothing. Line suffixes always fit because they take
        // up no space, regardless of the physical length of their contents.
        break

      case .breakParent:
        // Do nothing.
        break
      }
    }

    return false
  }
}

///
struct PrinterState {
  ///
  enum Mode {
    ///
    case `break`

    ///
    case flat
  }

  ///
  var indent: Indentation

  ///
  var mode: Mode

  ///
  var behavior: FormatNode.Behavior?
}

///
struct PrinterStateStack {
  private var storage = [PrinterState]()

  @inline(__always)
  var isEmpty: Bool { storage.isEmpty }

  @inline(__always)
  mutating func push(
    indent: Indentation, mode: PrinterState.Mode, node: FormatNode
  ) {
    push(PrinterState(indent: indent, mode: mode, behavior: node.behavior))
  }

  @inline(__always)
  mutating func push(_ state: PrinterState) {
    storage.append(state)
  }

  @inline(__always)
  mutating func poppedState() -> PrinterState? {
    return storage.popLast()
  }

  mutating func drain(into sink: inout PrinterStateStack) {
    storage.reversed().forEach { sink.push($0) }
    storage.removeAll()
  }
}
