@_spi(Internal) import SwiftFormat
import XCTest

final class IgnoredPathsTests: XCTestCase {
  let rootURL = URL(fileURLWithPath: "/Users/swiftformat", isDirectory: true)

  func testIgnoredPaths_filesOutsideRootAreIgnored() throws {
    let paths = try IgnoredPaths(
      root: rootURL,
      contents: """
        foo
        """
    )
    try assertIgnore(paths, "/Users/notswiftformat/foo", false)
    try assertIgnore(paths, "/Users/foo", false)
    try assertIgnore(paths, "/Users/swiftformatfoo", false)
  }

  func testIgnoredPaths_leadingDoubleAsterisk() throws {
    let paths = try IgnoredPaths(
      root: rootURL,
      contents: """
        **/foo
        """
    )
    try assertIgnore(paths, "/Users/swiftformat/foo", true)
    try assertIgnore(paths, "/Users/swiftformat/bar/foo", true)
    try assertIgnore(paths, "/Users/swiftformat/foo/bar", false)
  }

  func testIgnoredPaths_internalDoubleAsterisk() throws {
    let paths = try IgnoredPaths(
      root: rootURL,
      contents: """
        foo/**/bar
        """
    )
    try assertIgnore(paths, "/Users/swiftformat/foo/bar", true)
    try assertIgnore(paths, "/Users/swiftformat/foo/x/bar", true)
    try assertIgnore(paths, "/Users/swiftformat/foo/x/y/bar", true)
    try assertIgnore(paths, "/Users/swiftformat/foo/foo/bar", true)
    try assertIgnore(paths, "/Users/swiftformat/foo/bar/bar", true)
    try assertIgnore(paths, "/Users/swiftformat/foobar", false)
    try assertIgnore(paths, "/Users/swiftformat/foo/bbar", false)
    try assertIgnore(paths, "/Users/swiftformat/fooo/bar", false)
  }

  func testIgnoredPaths_trailingDoubleAsterisk() throws {
    let paths = try IgnoredPaths(
      root: rootURL,
      contents: """
        foo/**
        """
    )
    try assertIgnore(paths, "/Users/swiftformat/foo", false)
    try assertIgnore(paths, "/Users/swiftformat/bar/foo", false)
    try assertIgnore(paths, "/Users/swiftformat/foo/bar", true)
    try assertIgnore(paths, "/Users/swiftformat/foo/bar/baz", true)
  }

  func testIgnoredPaths_doesNotMatchPartialFilename() throws {
    let paths = try IgnoredPaths(
      root: rootURL,
      contents: """
        oo.swift
        """
    )
    try assertIgnore(paths, "/Users/swiftformat/oo.swift", true)
    try assertIgnore(paths, "/Users/swiftformat/foo.swift", false)
    try assertIgnore(paths, "/Users/swiftformat/oo.swifty", false)
    try assertIgnore(paths, "/Users/swiftformat/dir/oo.swift", true)
    try assertIgnore(paths, "/Users/swiftformat/dir/foo.swift", false)
    try assertIgnore(paths, "/Users/swiftformat/dir/oo.swifty", false)
  }

  func testIgnoredPaths_asteriskMatchesNonDirectories() throws {
    let paths = try IgnoredPaths(
      root: rootURL,
      contents: """
        *
        """
    )
    try assertIgnore(paths, "/Users/swiftformat/foo", true)
    try assertIgnore(paths, "/Users/swiftformat/foo/bar", true)
  }

  func testIgnoredPaths_asteriskMatchesPartialFilename() throws {
    let paths = try IgnoredPaths(
      root: rootURL,
      contents: """
        foo.*
        """
    )
    try assertIgnore(paths, "/Users/swiftformat/foo.swift", true)
    try assertIgnore(paths, "/Users/swiftformat/foo.bar", true)
    try assertIgnore(paths, "/Users/swiftformat/foo.", true)
    try assertIgnore(paths, "/Users/swiftformat/foo", false)
    try assertIgnore(paths, "/Users/swiftformat/foobar", false)
    try assertIgnore(paths, "/Users/swiftformat/dir/foo.swift", true)
    try assertIgnore(paths, "/Users/swiftformat/dir/foo.bar", true)
    try assertIgnore(paths, "/Users/swiftformat/dir/foo.", true)
    try assertIgnore(paths, "/Users/swiftformat/dir/foo", false)
    try assertIgnore(paths, "/Users/swiftformat/dir/foobar", false)
  }

  func testIgnoredPaths_doubleAsteriskWithoutSlashesIsLikeSingleAsterisk() throws {
    let paths = try IgnoredPaths(
      root: rootURL,
      contents: """
        foo**bar
        """
    )
    try assertIgnore(paths, "/Users/swiftformat/foobar", true)
    try assertIgnore(paths, "/Users/swiftformat/foobazbar", true)
    try assertIgnore(paths, "/Users/swiftformat/foo/bar", false)
    try assertIgnore(paths, "/Users/swiftformat/foo/baz/bar", false)
  }

  func testIgnoredPaths_questionMark() throws {
    let paths = try IgnoredPaths(
      root: rootURL,
      contents: """
        foo?.swift
        """
    )
    try assertIgnore(paths, "/Users/swiftformat/foo.swift", false)
    try assertIgnore(paths, "/Users/swiftformat/foof.swift", true)
    try assertIgnore(paths, "/Users/swiftformat/foo..swift", true)
    try assertIgnore(paths, "/Users/swiftformat/foo/.swift", false)
  }

  func testIgnoredPaths_anchoredPath() throws {
    let paths = try IgnoredPaths(
      root: rootURL,
      contents: """
        /foo
        """
    )
    try assertIgnore(paths, "/Users/swiftformat/foo", true)
    try assertIgnore(paths, "/Users/swiftformat/foo/bar", false)
    try assertIgnore(paths, "/Users/swiftformat/dir/foo", false)
    try assertIgnore(paths, "/Users/swiftformat/dir/foo/bar", false)
  }

  func testIgnoredPaths_trailingSpaces() throws {
    let paths = try IgnoredPaths(
      root: rootURL,
      contents: """
        ignore_these\u{0020}\u{0020}
        dont_ignore_this\\\u{0020}
        keep_only_one\\\u{0020}\u{0020}
        keep_last_two\u{0020}\\\u{0020}\u{0020}
        keep_all_three\\\u{0020}\\\u{0020}\\\u{0020}
        """
    )
    try assertIgnore(paths, "/Users/swiftformat/ignore_these", true)
    try assertIgnore(paths, "/Users/swiftformat/ignore_these  ", false)
    try assertIgnore(paths, "/Users/swiftformat/dont_ignore_this", false)
    try assertIgnore(paths, "/Users/swiftformat/dont_ignore_this ", true)
    try assertIgnore(paths, "/Users/swiftformat/keep_only_one", false)
    try assertIgnore(paths, "/Users/swiftformat/keep_only_one ", true)
    try assertIgnore(paths, "/Users/swiftformat/keep_only_one  ", false)
    try assertIgnore(paths, "/Users/swiftformat/keep_last_two", false)
    try assertIgnore(paths, "/Users/swiftformat/keep_last_two ", false)
    try assertIgnore(paths, "/Users/swiftformat/keep_last_two  ", true)
    try assertIgnore(paths, "/Users/swiftformat/keep_last_two   ", false)
    try assertIgnore(paths, "/Users/swiftformat/keep_all_three", false)
    try assertIgnore(paths, "/Users/swiftformat/keep_all_three ", false)
    try assertIgnore(paths, "/Users/swiftformat/keep_all_three  ", false)
    try assertIgnore(paths, "/Users/swiftformat/keep_all_three   ", true)
    try assertIgnore(paths, "/Users/swiftformat/keep_all_three    ", false)
  }

  func testIgnoredPaths_comments() throws {
    let paths = try IgnoredPaths(
      root: rootURL,
      contents: """
        foo
        #bar
        baz
        \\#quux
        """
    )
    try assertIgnore(paths, "/Users/swiftformat/bar", false)
    try assertIgnore(paths, "/Users/swiftformat/#bar", false)
    try assertIgnore(paths, "/Users/swiftformat/quux", false)
    try assertIgnore(paths, "/Users/swiftformat/#quux", true)
  }

  func testIgnoredPaths_ignoreDirectory() throws {
    let paths = try IgnoredPaths(
      root: rootURL,
      contents: """
        foo/
        """
    )
    try assertIgnore(paths, "/Users/swiftformat/foo", true)
    try assertIgnore(paths, "/Users/swiftformat/foo/bar", true)
    try assertIgnore(paths, "/Users/swiftformat/foo/bar/baz", true)
    try assertIgnore(paths, "/Users/swiftformat/foo.txt", false)
  }

  func testIgnoredPaths_ignoreFilesInDirectory() throws {
    let paths = try IgnoredPaths(
      root: rootURL,
      contents: """
        foo/*
        """
    )
    try assertIgnore(paths, "/Users/swiftformat/foo", false)
    try assertIgnore(paths, "/Users/swiftformat/foo/bar", true)
    try assertIgnore(paths, "/Users/swiftformat/foo/bar/baz", false)
    try assertIgnore(paths, "/Users/swiftformat/foo.txt", false)
  }

  func testIgnoredPaths_negation() throws {
    let paths = try IgnoredPaths(
      root: rootURL,
      contents: """
        *.ignore
        !do_not.ignore
        """
    )
    try assertIgnore(paths, "/Users/swiftformat/.ignore", true)
    try assertIgnore(paths, "/Users/swiftformat/foo.ignore", true)
    try assertIgnore(paths, "/Users/swiftformat/do_not.ignore", false)
    try assertIgnore(paths, "/Users/swiftformat/not_do_not.ignore", true)
    try assertIgnore(paths, "/Users/swiftformat/dir/.ignore", true)
    try assertIgnore(paths, "/Users/swiftformat/dir/foo.ignore", true)
    try assertIgnore(paths, "/Users/swiftformat/dir/do_not.ignore", false)
    try assertIgnore(paths, "/Users/swiftformat/dir/not_do_not.ignore", true)
  }

  func testIgnoredPaths_negationButOrderMatters() throws {
    let paths = try IgnoredPaths(
      root: rootURL,
      contents: """
        !do_not.ignore
        *.ignore
        """
    )
    try assertIgnore(paths, "/Users/swiftformat/.ignore", true)
    try assertIgnore(paths, "/Users/swiftformat/foo.ignore", true)
    try assertIgnore(paths, "/Users/swiftformat/do_not.ignore", true)
    try assertIgnore(paths, "/Users/swiftformat/not_do_not.ignore", true)
    try assertIgnore(paths, "/Users/swiftformat/dir/.ignore", true)
    try assertIgnore(paths, "/Users/swiftformat/dir/foo.ignore", true)
    try assertIgnore(paths, "/Users/swiftformat/dir/do_not.ignore", true)
    try assertIgnore(paths, "/Users/swiftformat/dir/not_do_not.ignore", true)
  }

  func testIgnoredPaths_leadingEscapedExclamationPoint() throws {
    let paths = try IgnoredPaths(
      root: rootURL,
      contents: """
        \\!do_not.ignore!
        """
    )
    try assertIgnore(paths, "/Users/swiftformat/do_not.ignore", false)
    try assertIgnore(paths, "/Users/swiftformat/!do_not.ignore!", true)
    try assertIgnore(paths, "/Users/swiftformat/dir/do_not.ignore", false)
    try assertIgnore(paths, "/Users/swiftformat/dir/!do_not.ignore!", true)
  }

  func testIgnoredPaths_characterClass() throws {
    let paths = try IgnoredPaths(
      root: rootURL,
      contents: """
        [ae].swift
        [f-i].swift
        [\\].swift
        """
    )
    try assertIgnore(paths, "/Users/swiftformat/a.swift", true)
    try assertIgnore(paths, "/Users/swiftformat/e.swift", true)
    try assertIgnore(paths, "/Users/swiftformat/d.swift", false)
    try assertIgnore(paths, "/Users/swiftformat/ae.swift", false)
    try assertIgnore(paths, "/Users/swiftformat/[ae].swift", false)
    try assertIgnore(paths, "/Users/swiftformat/f.swift", true)
    try assertIgnore(paths, "/Users/swiftformat/g.swift", true)
    try assertIgnore(paths, "/Users/swiftformat/h.swift", true)
    try assertIgnore(paths, "/Users/swiftformat/i.swift", true)
    try assertIgnore(paths, "/Users/swiftformat/[f-i].swift", false)
    try assertIgnore(paths, "/Users/swiftformat/\\.swift", true)
    try assertIgnore(paths, "/Users/swiftformat/[\\].swift", false)
  }

  func testIgnoredPaths_invertedCharacterClass() throws {
    let paths = try IgnoredPaths(
      root: rootURL,
      contents: """
        [!ae].swift
        """
    )
    try assertIgnore(paths, "/Users/swiftformat/a.swift", false)
    try assertIgnore(paths, "/Users/swiftformat/e.swift", false)
    try assertIgnore(paths, "/Users/swiftformat/d.swift", true)
    try assertIgnore(paths, "/Users/swiftformat/ae.swift", false)
    try assertIgnore(paths, "/Users/swiftformat/[ae].swift", false)
  }

  func testIgnoredPaths_characterClassWithInitialCaret() throws {
    let paths = try IgnoredPaths(
      root: rootURL,
      contents: """
        [^x].swift
        """
    )
    try assertIgnore(paths, "/Users/swiftformat/^.swift", true)
    try assertIgnore(paths, "/Users/swiftformat/x.swift", true)
    try assertIgnore(paths, "/Users/swiftformat/d.swift", false)
    try assertIgnore(paths, "/Users/swiftformat/^x.swift", false)
    try assertIgnore(paths, "/Users/swiftformat/[^x].swift", false)
  }

  func testIgnoredPaths_characterClassThatDecaysToRegularCharacters() throws {
    let paths = try IgnoredPaths(
      root: rootURL,
      contents: """
        [.o
        [!.a
        [!].swift
        """
    )
    try assertIgnore(paths, "/Users/swiftformat/[.o", true)
    try assertIgnore(paths, "/Users/swiftformat/[.a", false)
    try assertIgnore(paths, "/Users/swiftformat/[!.a", true)
    try assertIgnore(paths, "/Users/swiftformat/[!].swift", true)
    try assertIgnore(paths, "/Users/swiftformat/[.swift", false)
    try assertIgnore(paths, "/Users/swiftformat/!.swift", false)
    try assertIgnore(paths, "/Users/swiftformat/].swift", false)
  }

  func testIgnoredPaths_rootURLStripsBasenameIfFile() throws {
    let paths = try IgnoredPaths(
      root: URL(fileURLWithPath: "/Users/swiftformat/.swift-format-ignore", isDirectory: false),
      contents: """
        /foo
        """
    )
    try assertIgnore(paths, "/Users/swiftformat/foo", true)
    try assertIgnore(paths, "/Users/swiftformat/.swift-format-ignore", false)
    try assertIgnore(paths, "/Users/swiftformat/.swift-format-ignore/foo", false)
  }

  func assertIgnore(
    _ paths: IgnoredPaths,
    _ path: String,
    _ result: Bool,
    file: StaticString = #file,
    line: UInt = #line
  ) throws {
    XCTAssertEqual(try paths.shouldIgnore(URL(fileURLWithPath: path)), result, file: file, line: line)
  }
}
