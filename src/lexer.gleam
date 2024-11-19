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
        "+" -> do_lex(rest, [token.Token(token.Plus, None, None, None), ..acc])
        "-" -> do_lex(rest, [token.Token(token.Minus, None, None, None), ..acc])
        "*" -> do_lex(rest, [token.Token(token.Star, None, None, None), ..acc])
        "." -> do_lex(rest, [token.Token(token.Dot, None, None, None), ..acc])
        "/" -> do_lex(rest, [token.Token(token.Slash, None, None, None), ..acc])
        ":" -> {
          case lex_word_def(rest) {
            Error(e) -> Error(e)
            Ok(#(token, rest)) -> do_lex(rest, [token, ..acc])
          }
        }
        c ->
          case is_digit(c) {
            True -> {
              let #(rest, val) = read_number(source)
              do_lex(rest, [
                token.Token(token.Number, Some(val), None, None),
                ..acc
              ])
            }
            False ->
              case is_whitespace(c) {
                True -> do_lex(rest, acc)
                False ->
                  case is_alpha(c) {
                    True -> {
                      let #(r, id) = lex_word(source)
                      do_lex(r, [
                        token.Token(token.Word, None, None, Some(id)),
                        ..acc
                      ])
                    }
                    False -> Error("SyntaxError: Unrecognized character: " <> c)
                  }
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

fn is_alpha(to_check: String) -> Bool {
  let assert [first, ..] = string.to_utf_codepoints(to_check)
  let n = first |> string.utf_codepoint_to_int
  case n >= 65, n <= 90, n >= 96, n <= 122 {
    True, True, _, _ -> True
    _, _, True, True -> True
    _, _, _, _ -> False
  }
}

/// returns: rest, number literal
fn read_number(source: String) -> #(String, Int) {
  do_read_number(source, "")
}

/// returns: rest, number literal
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

/// returns: Ok(Token.WordDef, rest) or Error(SyntaxError text)
/// example word: `: X 42 27 + . ;`
fn lex_word_def(source: String) -> Result(#(Token, String), String) {
  let #(source, ident) = source |> string.trim |> do_read_word("")
  let raw_program = do_read_program(source, "")
  case raw_program {
    Error(e) -> Error(e)
    Ok(#(prog, rest)) -> {
      case do_lex(prog, []) {
        Error(e) -> Error(e)
        Ok(prog) ->
          Ok(#(token.Token(token.WordDef, None, Some(prog), Some(ident)), rest))
      }
    }
  }
}

/// returns: rest, identifier
fn lex_word(source: String) -> #(String, String) {
  do_read_word(source, "")
}

/// returns: rest, identifier
fn do_read_word(source: String, acc: String) -> #(String, String) {
  case string.pop_grapheme(source) {
    Error(Nil) -> #("", acc)
    Ok(#(first, rest)) ->
      case is_alpha(first) {
        True -> do_read_word(rest, acc <> first)
        False -> #(rest, acc)
      }
  }
}

/// returns: Ok(raw_program, rest) or Error(SyntaxError text)
fn do_read_program(
  source: String,
  acc: String,
) -> Result(#(String, String), String) {
  case string.pop_grapheme(source) {
    Error(Nil) -> Error("SyntaxError: Unterminated word definition.")
    Ok(#(first, rest)) ->
      case first {
        ";" -> Ok(#(acc, rest))
        _ -> do_read_program(rest, acc <> first)
      }
  }
}
