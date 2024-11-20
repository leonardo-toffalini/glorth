import argv
import gleam/io
import gleam/result
import gleam/string
import interpreter
import lexer

pub fn main() {
  case argv.load().arguments {
    ["file", file] -> {
      io.println("filepath: " <> file)
      use program <- result.try(lexer.lex(string.trim(file)))
      case interpreter.run(program) {
        Ok(_) -> {
          io.println("ok")
          Ok(Nil)
        }
        Error(e) -> {
          io.println(e)
          Error(e)
        }
      }
    }
    _ -> {
      io.println("Usage: \n\t`gleam run file <filename>`")
      Error("Unexpected cli call.")
    }
  }
}
