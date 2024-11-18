import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
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
              let #(rest, val) = read_number(source)
              do_lex(rest, [token.Token(token.Number, Some(val)), ..acc])
            }
            False ->
              case is_whitespace(c) {
                True -> do_lex(rest, acc)
                False -> Error("SyntaxError: Unrecognized character: " <> c)
              }
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

fn is_whitespace(to_check: String) -> Bool {
  case to_check {
    " " -> True
    "\t" -> True
    _ -> False
  }
}

fn read_number(source: String) -> #(String, Int) {
  do_read_number(source, "")
}

fn do_read_number(source: String, acc: String) -> #(String, Int) {
  case string.pop_grapheme(source) {
    Error(Nil) -> #("", int.parse(acc) |> result.unwrap(0))
    Ok(#(first, rest)) ->
      case is_digit(first) {
        True -> do_read_number(rest, acc <> first)
        False -> #(rest, int.parse(acc) |> result.unwrap(0))
      }
  }
}
