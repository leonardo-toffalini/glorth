import gleeunit
import gleeunit/should
import lexer
import stack
import token
import gleam/option.{None}

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
  |> should.equal(Ok([token.Token(token.Plus, None)]))
}
