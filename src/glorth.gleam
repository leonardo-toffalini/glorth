import gleam/result
import interpreter
import lexer

pub fn main() {
  let filepath = "examples/word2.forth"
  let program = lexer.lex(filepath) |> result.unwrap([])
  interpreter.run(program)
}
