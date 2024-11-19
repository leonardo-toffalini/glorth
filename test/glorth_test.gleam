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
  |> should.equal(Ok([
    token.Token(token.WordDef, None, Some([
      token.Token(token.Number, Some(42), None, None),
      token.Token(token.Number, Some(27), None, None),
      token.Token(token.Plus, None, None, None),
      token.Token(token.Dot, None, None, None),
    ]), Some("X"))
  ]))
}

pub fn interp_test() {
  let filepath = "examples/numbers.forth"
  let program = lexer.lex(filepath) |> result.unwrap([])
  interpreter.run(program)


  let filepath = "examples/word.forth"
  let program = lexer.lex(filepath) |> result.unwrap([])
  interpreter.run(program)
}
