import gleam/list
import gleam/string
import gleam/int
import gleam/option.{Some, None}
import simplifile
import token.{type Token}

pub type Program =
  List(Token)

pub type ProgramResult =
  Result(Program, String)

pub fn lex(filepath: String) -> ProgramResult {
  case simplifile.read(filepath) {
    Ok(source) -> source |> string.trim |> do_lex([])
    Error(_) -> Error("FileError: Error opening file: " <> filepath)
  }
}

fn do_lex(source: String, acc: Program) -> ProgramResult {
  case string.pop_grapheme(source) {
    Error(Nil) -> Ok(list.reverse(acc))
    Ok(#(first, rest)) ->
      case first {
        "+" -> do_lex(rest, [token.Token(token.Plus, None), ..acc])
        "-" -> do_lex(rest, [token.Token(token.Minus, None), ..acc])
        "*" -> do_lex(rest, [token.Token(token.Star, None), ..acc])
        "." -> do_lex(rest, [token.Token(token.Dot, None), ..acc])
        "/" -> do_lex(rest, [token.Token(token.Slash, None), ..acc])
        c -> 
          case is_digit(c) {
            True -> {
              let val = read_number()
              do_lex(rest, [token.Token(token.Number, Some(val))])
            }
            False -> Error("SyntaxError: Unrecognized character: " <> c)
          }
      }
  }
}

fn is_digit(to_check: String) -> Bool {
  case int.base_parse(to_check, 10) {
    Error(Nil) -> False
    _ -> True
  }
}

fn read_number() {
  todo
}
