//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation

///
/// * A blank line matches no files.
/// * A line starting with a `#` serves as a comment. If a pattern must begin with a literal `#`,
///   escape it by preceding it with a backslash (`\#`).
/// * Trailing spaces are ignored unless they are escaped with a backslash.
/// * An optional prefix `!` negates the pattern; any matching file ignored by a previous pattern
///   will become unignored again. It is not possible to unignore a file if a parent directory of
///   that file is ignored. If a pattern must begin with a literal `!`, escape it by preceding it
///   with a backslash (`\!`).
/// * The forward slash (`/`) is used as a directory separator. Separators may occur at the
///   beginning, middle, or end of the search pattern.
/// * If there is a separator at the beginning of middle (or both) of the pattern, then the pattern
///   is relative to the directory level of the particular `.swift-format-ignore` file itself.
///   Otherwise, the pattern may also match at any level below the `.swift-format-ignore` file.
/// * If there is a separator at the end of the pattern, then the pattern will only match
///   directories; otherwise, the pattern can match both files and directories.
/// * An asterisk (`*`) matches anything except a slash (`/`). The character `?` matches any *one*
///   character except `/`. The range notation -- e.g., `[a-zA-Z]` -- can be used to match one of
///   the characters in the range.
/// * Two consecutive asterisks (`**`) in patterns against full path names have special meaning:
///   * A leading `**` followed by a slash means match in all directories.
///   * A trailing `/**` matches everything inside, recursively.
///   * A slash followed by two consecutive asterisks then another slash matches zero or more
///     directories.
///   * Other consecutive asterisks are considered regular asterisks and will match according to
///     the previous rules.
@_spi(Internal)
public struct IgnoredPaths {
  ///
  private let root: URL

  ///
  private let patterns: [Pattern]

  ///
  ///
  /// - Parameters:
  ///   - root: The root URL used to resolve relative path patterns in the ignore file. If this is
  ///     a directory URL (i.e., a `URL` where `hasDirectoryPath == true`), then it is used as-is.
  ///     Otherwise, it is assumed to be the URL of the ignore file itself, and relative paths are
  ///     resolved with respect to the directory containing the file.
  ///   - contents: The text contents of the ignore file.
  public init(root: URL, contents: String) throws {
    if root.hasDirectoryPath {
      self.root = root
    } else {
      self.root = root.deletingLastPathComponent()
    }

    let lines = contents.split(separator: "\n")
    var patterns = [Pattern]()
    for line in lines {
      // Skip comment lines and blank lines.
      guard !line.hasPrefix("#") && !line.allSatisfy(\.isWhitespace) else {
        continue
      }
      patterns.append(try Pattern(line))
    }
    self.patterns = patterns
  }

  /// 
  public func shouldIgnore(_ url: URL) throws -> Bool {
    // By construction, `root` is a directory URL so it is guaranteed to be terminated by a slash.
    let rootPath = root.standardized.absoluteURL.path(percentEncoded: false)
    let path = url.standardized.absoluteURL.path(percentEncoded: false)
    guard path.hasPrefix(rootPath) else {
      return false
    }
    let relativePath = path.dropFirst(rootPath.count)
    for pattern in patterns.reversed() {
      if try pattern.matches(relativePath) {
        return !pattern.isNegated
      }
    }
    return false
  }
}

#if os(Windows)
  private let nonSeparatorPattern = "^[\\/]"
  private let separatorPattern = "[\\/]"
#else
  private let nonSeparatorPattern = "[^/]"
  private let separatorPattern = "/"
#endif

extension IgnoredPaths {
  @_spi(Internal)
  public struct Pattern {
    public let regexString: String
    public let regex: Regex<Substring>
    public let isAnchored: Bool
    public let isNegated: Bool
    public let onlyMatchesDirectories: Bool

    public init<S: StringProtocol>(_ string: S) throws {
      var string = string[...]
      let isNegated: Bool
      if string.hasPrefix("!") {
        isNegated = true
        string = string.dropFirst()
      } else {
        isNegated = false
      }

      var isAnchored = string.dropLast().contains("/")
      let onlyMatchesDirectories = string.hasSuffix("/")

      if string.first == "/" {
        string = string.dropFirst()
      }
      if string.hasPrefix("**") {
        string = string.dropFirst(2)
        isAnchored = false
      }
      if string.first == "/" {
        string = string.dropFirst()
      }
      if string.last == "/" {
        string = string.dropLast()
      }

      // Remove trailing spaces unless they're preceded by backslash.
      var spaceIndex = string.index(before: string.endIndex)
      while spaceIndex != string.startIndex && string[spaceIndex].isWhitespace {
        let previousIndex = string.index(before: spaceIndex)
        guard string[previousIndex] != "\\" else {
          break
        }
        spaceIndex = previousIndex
      }
      string = string[...spaceIndex]

      var regex = ""
      var index = string.startIndex
      while index != string.endIndex {
        let ch = string[index]
        index = string.index(after: index)

        switch ch {
        case "*":
          if index == string.endIndex || string[index] != "*" {
            // `*` (not followed by another `*`) matches zero or more non-directory separator
            // characters.
            regex.append("\(nonSeparatorPattern)*")
            break
          }
          index = string.index(after: index)
          if index == string.endIndex {
            // `**` at the end of the pattern matches anything beneath whatever has been matched
            // so far (files and directories, recursively).
            regex.append(".*")
          } else if string[index] == "/" {
            // `**/` matches (optionally) any sequence of characters (including directory
            // separators) followed by a directory separator.
            index = string.index(after: index)
            regex.append("(?:.*\(separatorPattern))?")
          } else {
            // Other occurrences of `**` act like `*`.
            regex.append("\(nonSeparatorPattern)*")
          }
        case "?":
          // `?` matches any single character other than a directory separator.
          regex.append(nonSeparatorPattern)
        case "/":
          // `/` matches any single directory separator.
          regex.append(separatorPattern)
        case "[":
          // `[` starts a character range.
          var innerIndex = index
          if innerIndex != string.endIndex && string[innerIndex] == "!" {
            innerIndex = string.index(after: innerIndex)
          }
          if innerIndex != string.endIndex && string[innerIndex] == "]" {
            innerIndex = string.index(after: innerIndex)
          }
          while innerIndex != string.endIndex && string[innerIndex] != "]" {
            innerIndex = string.index(after: innerIndex)
          }
          if innerIndex == string.endIndex {
            // If the string ended before the end of the range was found, treat it as a literal `[`.
            regex.append("\\[")
          } else {
            var rangeChars = string[index..<innerIndex]
            index = string.index(after: innerIndex)
            var rangeRegex = "["
            if let first = rangeChars.first, first == "!" {
              // `!` in `fnmatch`-style patterns is character class negation.
              rangeRegex.append("^")
              rangeChars = rangeChars.dropFirst()
            }
            var isFirst = true
            for rangeChar in rangeChars {
              switch rangeChar {
              case "^":
                // If the first character in the range is a `^`, escape it so that it's not treated
                // as character class negation in the regex.
                if isFirst {
                  rangeRegex.append("\\")
                }
                rangeRegex.append("^")
              case "\\":
                rangeRegex.append("\\\\")
              default:
                rangeRegex.append(rangeChar)
              }
              isFirst = false
            }
            rangeRegex.append("]")
            regex.append(rangeRegex)
          }
        case ".", "|", "+", "(", ")", "]", "{", "}", "^", "$":
          // Escape any characters that have special meaning in regexes.
          regex.append("\\")
          regex.append(ch)
        default:
          regex.append(ch)
        }
      }
      if isAnchored {
        regex.insert(contentsOf: "^", at: regex.startIndex)
      } else {
        regex.insert(contentsOf: "(?:^|\(separatorPattern))", at: regex.startIndex)
      }
      if !onlyMatchesDirectories {
        regex.append("$")
      } else if onlyMatchesDirectories && isNegated {
        regex.append("/$")
      } else {
        regex.append("(?:$|\\/)")
      }

      self.isAnchored = isAnchored
      self.isNegated = isNegated
      self.onlyMatchesDirectories = onlyMatchesDirectories
      self.regexString = regex
      self.regex = try Regex(regex)
    }

    public func matches(_ relativePath: Substring) throws -> Bool {
      print("\(isNegated ? "!" : " ") /\(regexString)/ -> \"\(relativePath)\" == \(try regex.firstMatch(in: relativePath) != nil)")
      return try regex.firstMatch(in: relativePath) != nil
    }
  }
}
