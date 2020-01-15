import SwiftSyntax
import XCTest

@testable import SwiftFormatRules

public class NoBlockCommentsTests: DiagnosingTestCase {
  public func testReplacesBlockCommentsAtEndOfLine() {
    XCTAssertFormatting(
      NoBlockComments.self,
      input:
        """
        var a = 0  /*end of line*/
        var b = 0/*end of line*/
        """,
      expected:
        """
        var a = 0  // end of line
        var b = 0// end of line
        """)
    XCTAssertDiagnosed(.avoidBlockComment)
    XCTAssertDiagnosed(.avoidBlockComment)
  }

  public func testKeepsBlockCommentsBeforeEndOfLine() {
    XCTAssertFormatting(
      NoBlockComments.self,
      input:
        """
        /*ff*/let a = /*ff*/10  /*ff*/ + 10
        """,
      expected:
        """
        /*ff*/let a = /*ff*/10  /*ff*/ + 10
        """)
    XCTAssertDiagnosed(.avoidBlockCommentBetweenCode)
    XCTAssertDiagnosed(.avoidBlockCommentBetweenCode)
    XCTAssertDiagnosed(.avoidBlockCommentBetweenCode)
  }

  public func testMultipleCommentsInSameTrivia() {
    XCTAssertFormatting(
      NoBlockComments.self,
      input:
        """
        /* foo */

        /* bar */

        /* baz */ var a: Int
        """,
      expected:
        """
        // foo

        // bar

        /* baz */ var a: Int
        """)
    XCTAssertDiagnosed(.avoidBlockComment)
    XCTAssertDiagnosed(.avoidBlockComment)
    XCTAssertDiagnosed(.avoidBlockCommentBetweenCode)
  }

  public func testRemovesOnlyFirstAndLastNewlineFromBlockComment() {
    XCTAssertFormatting(
      NoBlockComments.self,
      input:
        """
        /* This will be one line */
        var a: Int

        /*
        This will be one line
        */
        var a: Int

        /*

        I'll have a blank comment line above me */
        var a: Int

        /*

        I'll have a blank comment line above me
        */
        var a: Int

        /* I'll have a blank comment line below me

        */
        var a: Int

        /*
        I'll have a blank comment line below me

        */
        var a: Int

        /*

        I'll have blank comment lines on both sides

        */
        var a: Int
        """,
      expected:
        """
        // This will be one line
        var a: Int

        // This will be one line
        var a: Int

        //
        // I'll have a blank comment line above me
        var a: Int

        //
        // I'll have a blank comment line above me
        var a: Int

        // I'll have a blank comment line below me
        //
        var a: Int

        // I'll have a blank comment line below me
        //
        var a: Int

        //
        // I'll have blank comment lines on both sides
        //
        var a: Int
        """)
  }

  public func testReplacesCommentOnEOFToken() {
    XCTAssertFormatting(
      NoBlockComments.self,
      input:
        """
        var a: Int
        /* foo */
        """,
      expected:
        """
        var a: Int
        // foo
        """)
    XCTAssertDiagnosed(.avoidBlockComment)
  }

  public func testInputOnlyContainsComments() {
    XCTAssertFormatting(
      NoBlockComments.self,
      input:
        """
        /* foo */
        /* bar */ /* bar */
        /* baz */
        """,
      expected:
        """
        // foo
        /* bar */ // bar
        // baz
        """)
    XCTAssertDiagnosed(.avoidBlockComment)
    XCTAssertDiagnosed(.avoidBlockCommentBetweenCode)
    XCTAssertDiagnosed(.avoidBlockComment)
    XCTAssertDiagnosed(.avoidBlockComment)
  }

  public func testNestedCommentSpacingIsCorrect() {
    XCTAssertFormatting(
      NoBlockComments.self,
      input:
        """
        struct Foo {
          struct Bar {
            /*
            foo
              bar
            baz
            */
            var a: Int
          }
        }
        """,
      expected:
        """
        struct Foo {
          struct Bar {
            // foo
            //   bar
            // baz
            var a: Int
          }
        }
        """)

  }
}
