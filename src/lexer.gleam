import gleam/int
import gleam/io
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

pub type Chars =
  List(String)

/// Given a filepath as input, this funcion lexes the contetnts of that file.
pub fn lex(filepath: String) -> ProgramResult {
  case simplifile.read(filepath) {
    Ok(source) -> source |> string.trim |> string.to_graphemes |> do_lex([])
    Error(_) -> Error("FileError: Error opening file: " <> filepath)
  }
}

/// Given a string as input, this function lexes that string.
pub fn lex_raw(source: String) -> ProgramResult {
  source |> string.trim |> string.to_graphemes |> do_lex([])
}

fn do_lex(characters: Chars, acc: Program) -> ProgramResult {
  case characters {
    [] -> Ok(acc |> list.reverse)
    ["+", ..rest] ->
      do_lex(rest, [token.Token(token.Plus, None, None, None), ..acc])
    ["-", ..rest] ->
      do_lex(rest, [token.Token(token.Minus, None, None, None), ..acc])
    ["*", ..rest] ->
      do_lex(rest, [token.Token(token.Star, None, None, None), ..acc])
    [".", ..rest] ->
      do_lex(rest, [token.Token(token.Dot, None, None, None), ..acc])
    ["/", ..rest] ->
      do_lex(rest, [token.Token(token.Slash, None, None, None), ..acc])
    ["<", ..rest] ->
      do_lex(rest, [token.Token(token.Less, None, None, None), ..acc])
    [">", ..rest] ->
      do_lex(rest, [token.Token(token.Greater, None, None, None), ..acc])
    [":", " ", ..rest] -> {
      case lex_word_def(rest) {
        Error(e) -> Error(e)
        Ok(#(token, rest)) -> do_lex(rest, [token, ..acc])
      }
    }
    [c, ..rest] ->
      case is_digit(c) {
        True -> {
          let #(rest, val) = read_number(characters)
          do_lex(rest, [token.Token(token.Number, Some(val), None, None), ..acc])
        }
        False ->
          case is_whitespace(c) {
            True -> do_lex(rest, acc)
            False ->
              case is_alpha(c) {
                True -> {
                  let #(r, id) = lex_word(characters)
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
fn read_number(characters: Chars) -> #(Chars, Int) {
  do_read_number(characters, [])
}

/// returns: rest, number literal
fn do_read_number(characters: Chars, acc: Chars) -> #(Chars, Int) {
  case characters {
    [] -> #(
      [],
      acc
        |> list.reverse
        |> string.join(with: "")
        |> int.parse
        |> result.unwrap(0),
    )
    [first, ..rest] ->
      case is_digit(first) {
        True -> do_read_number(rest, [first, ..acc])
        False -> #(
          rest,
          acc
            |> list.reverse
            |> string.join(with: "")
            |> int.parse
            |> result.unwrap(0),
        )
      }
  }
}

/// returns: Ok(Token.WordDef, rest) or Error(SyntaxError text)
/// example word: `: X 42 27 + . ;`
fn lex_word_def(characters: Chars) -> Result(#(Token, Chars), String) {
  let #(characters, ident) = characters |> do_read_word([])
  result.try(do_read_program(characters, []), fn(res) {
    let #(prog, rest) = res
    result.try(do_lex(prog, []), fn(prog) {
      Ok(#(token.Token(token.WordDef, None, Some(prog), Some(ident)), rest))
    })
  })
}

/// returns: rest, identifier
fn lex_word(characters: Chars) -> #(Chars, String) {
  do_read_word(characters, [])
}

/// returns: rest, identifier
fn do_read_word(characters: Chars, acc: Chars) -> #(Chars, String) {
  case characters {
    [] -> #([], acc |> list.reverse |> string.join(with: ""))
    [first, ..rest] ->
      case is_alpha(first) {
        True -> do_read_word(rest, [first, ..acc])
        False -> #(rest, acc |> list.reverse |> string.join(with: ""))
      }
  }
}

/// returns: Ok(body, rest) or Error(SyntaxError text)
fn do_read_program(
  characters: Chars,
  acc: Chars,
) -> Result(#(Chars, Chars), String) {
  case characters {
    [] -> Error("SyntaxError: Unterminated word definition.")
    [";", ..rest] -> Ok(#(acc |> list.reverse, rest))
    [first, ..rest] -> do_read_program(rest, [first, ..acc])
  }
}
