import SwiftFormat
import SwiftSyntax
import _SwiftFormatTestSupport

final class _NewTokenStreamCreatorTests: PrettyPrintTestCase {
  func testX() {
    assertPrettyPrintEqual(
      input: """
        let x = 5
        let y: Int
        let z: Int = 10
        """,
      expected: """
        let x =
          5
        let y:
          Int
        let z:
          Int =
            10

        """,
      linelength: 7)

    assertPrettyPrintEqual(
      input: """
        let x = 5, y = 10
        let abcde = 5, fghij = 10
        """,
      expected: """
        let
          x = 5,
          y = 10
        let
          abcde =
            5,
          fghij =
            10

        """,
      linelength: 9)
  }

  func testA() {
    let input =
      """
      [ ]
      [
        // Comment
      ]
      [1, 2, 3,]
      [false, true, true, false]
      [11111111, 2222222, 33333333, 4444444]
      ["One", "Two", "Three", "Four"]
      ["One", "Two", "Three", "Four", "Five", "Six", "Seven"]
      ["One", "Two", "Three", "Four", "Five", "Six", "Seven",]
      [
        "One", "Two", "Three", "Four", "Five",
        "Six", "Seven", "Eight",
      ]
      [11111111, 2222222, 33333333, 444444]
      """

    let expected =
      """
      []
      [
        // Comment
      ]
      [1, 2, 3]
      [false, true, true, false]
      [
        11111111, 2222222, 33333333, 4444444,
      ]
      [
        "One", "Two", "Three", "Four",
      ]
      [
        "One", "Two", "Three", "Four", "Five",
        "Six", "Seven",
      ]
      [
        "One", "Two", "Three", "Four", "Five",
        "Six", "Seven",
      ]
      [
        "One", "Two", "Three", "Four", "Five",
        "Six", "Seven", "Eight",
      ]
      [
        11111111, 2222222, 33333333, 444444,
      ]

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testBasicArrays() {
    let input =
      """
      let a = [ ]
      let a = [
      ]
      let a = [
        // Comment
      ]
      let a = [1, 2, 3,]
      let a: [Bool] = [false, true, true, false]
      let a = [11111111, 2222222, 33333333, 4444444]
      let a: [String] = ["One", "Two", "Three", "Four"]
      let a: [String] = ["One", "Two", "Three", "Four", "Five", "Six", "Seven"]
      let a: [String] = ["One", "Two", "Three", "Four", "Five", "Six", "Seven",]
      let a: [String] = [
        "One", "Two", "Three", "Four", "Five",
        "Six", "Seven", "Eight",
      ]
      let a = [11111111, 2222222, 33333333, 444444]
      """

    let expected =
      """
      let a = []
      let a = []
      let a = [
        // Comment
      ]
      let a = [1, 2, 3]
      let a: [Bool] = [false, true, true, false]
      let a = [
        11111111, 2222222, 33333333, 4444444,
      ]
      let a: [String] = [
        "One", "Two", "Three", "Four",
      ]
      let a: [String] = [
        "One", "Two", "Three", "Four", "Five",
        "Six", "Seven",
      ]
      let a: [String] = [
        "One", "Two", "Three", "Four", "Five",
        "Six", "Seven",
      ]
      let a: [String] = [
        "One", "Two", "Three", "Four", "Five",
        "Six", "Seven", "Eight",
      ]

      """
      // Ideally, this array would be left on 1 line without a trailing comma. We don't know if the
      // comma is required when calculating the length of array elements, so the comma's length is
      // always added to last element and that 1 character causes the newlines inside of the array.
      + """
      let a = [
        11111111, 2222222, 33333333, 444444,
      ]

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }
}
