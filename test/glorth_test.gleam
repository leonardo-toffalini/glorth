import gleam/option.{None, Some}
import gleam/result
import gleeunit
import gleeunit/should
import interpreter
import lexer
import stack
import token

pub fn main() {
  gleeunit.main()
}

pub fn stack_test() {
  let s = stack.new()

  s |> should.equal([])
  stack.pop(s) |> should.equal([])
  stack.get(s) |> should.equal(Error(Nil))
  stack.push(s, 3) |> should.equal([3])
  s |> stack.push(3) |> stack.get |> should.equal(Ok(3))
}

pub fn lexer_test() {
  let filepath = "does_not_exists.forth"
  lexer.lex(filepath)
  |> should.equal(Error("FileError: Error opening file: does_not_exists.forth"))

  let filepath = "examples/add.forth"
  lexer.lex(filepath)
  |> should.equal(Ok([token.Token(token.Plus, None, None, None)]))

  let filepath = "examples/numbers.forth"
  lexer.lex(filepath)
  |> should.equal(
    Ok([
      token.Token(token.Number, Some(42), None, None),
      token.Token(token.Number, Some(27), None, None),
      token.Token(token.Plus, None, None, None),
      token.Token(token.Dot, None, None, None),
    ]),
  )

  let filepath = "examples/syntaxerror.forth"
  lexer.lex(filepath)
  |> should.equal(Error("SyntaxError: Unrecognized character: #"))

  let filepath = "examples/word.forth"
  lexer.lex(filepath)
  |> should.equal(
    Ok([
      token.Token(
        token.WordDef,
        None,
        Some([
          token.Token(token.Number, Some(42), None, None),
          token.Token(token.Number, Some(27), None, None),
          token.Token(token.Plus, None, None, None),
          token.Token(token.Dot, None, None, None),
        ]),
        Some("X"),
      ),
      token.Token(token.Word, None, None, Some("X")),
    ]),
  )
}

pub fn interp_test() {
  // number test
  let source = "1 2 3 4 5 6 7 8 9"
  use program <- result.try(lexer.lex_raw(source))
  use stack <- result.map(interpreter.run(program))
  stack |> should.equal([9, 8, 7, 6, 5, 4, 3, 2, 1])

  // plus test
  let source = "1 1 42 27 +"
  use program <- result.try(lexer.lex_raw(source))
  use stack <- result.map(interpreter.run(program))
  stack |> should.equal([69, 1, 1])

  // minus test
  let source = "2 2 42 27 -"
  use program <- result.try(lexer.lex_raw(source))
  use stack <- result.map(interpreter.run(program))
  stack |> should.equal([15, 2, 2])

  // multiply test
  let source = "3 3 42 27 *"
  use program <- result.try(lexer.lex_raw(source))
  use stack <- result.map(interpreter.run(program))
  stack |> should.equal([1134, 3, 3])

  // division test
  let source = "4 4 84 42 /"
  use program <- result.try(lexer.lex_raw(source))
  use stack <- result.map(interpreter.run(program))
  stack |> should.equal([2, 4, 4])

  // less test 1
  let source = "5 5 10 13 <"
  use program <- result.try(lexer.lex_raw(source))
  use stack <- result.map(interpreter.run(program))
  stack |> should.equal([1, 5, 5])

  // less test 2
  let source = "6 6 13 10 <"
  use program <- result.try(lexer.lex_raw(source))
  use stack <- result.map(interpreter.run(program))
  stack |> should.equal([0, 6, 6])

  // greater test 1
  let source = "7 7 10 13 >"
  use program <- result.try(lexer.lex_raw(source))
  use stack <- result.map(interpreter.run(program))
  stack |> should.equal([0, 7, 7])

  // greater test 2
  let source = "8 8 13 10 >"
  use program <- result.try(lexer.lex_raw(source))
  use stack <- result.map(interpreter.run(program))
  stack |> should.equal([1, 8, 8])

  // word test
  let source = "1 : X 42 27 + . ; 2 X 3"
  use program <- result.try(lexer.lex_raw(source))
  use stack <- result.map(interpreter.run(program))
  stack |> should.equal([3, 69, 2, 1])
}
