import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/option.{None, Some}
import gleam/result
import lexer.{type Program}
import stack.{type Stack}
import token.{type Token}

pub type InterpResult =
  Result(Stack, String)

pub type Words =
  Dict(String, Program)

pub fn run(program: Program) -> InterpResult {
  let stack = stack.new()
  let words = dict.new()
  interp(program, stack, words)
}

fn interp(program: Program, stack: Stack, words: Words) -> InterpResult {
  case program {
    [] -> Ok(stack)
    [first, ..rest] ->
      case first.token_type {
        token.Number -> number(first, rest, stack, words)
        token.Plus -> plus(rest, stack, words)
        token.Minus -> minus(rest, stack, words)
        token.Star -> star(rest, stack, words)
        token.Slash -> slash(rest, stack, words)
        token.Dot -> dot(rest, stack, words)
        token.WordDef -> word_def(first, rest, stack, words)
        token.Word -> word(first, rest, stack, words)
        _ -> Error("Unrecognized token")
      }
  }
}

fn number(
  first: Token,
  rest: Program,
  stack: Stack,
  words: Words,
) -> InterpResult {
  option.unwrap(first.literal, 0)
  |> stack.push(stack, _)
  |> interp(rest, _, words)
}

fn plus(program: Program, stack: Stack, words: Words) -> InterpResult {
  case stack {
    [a, b, ..rest] -> stack.push(rest, a + b) |> interp(program, _, words)
    _ ->
      Error(
        "RuntimeError: Cannot do operation '+' because there are less than 2 numbers on the stack.",
      )
  }
}

fn minus(program: Program, stack: Stack, words: Words) -> InterpResult {
  case stack {
    [a, b, ..rest] -> stack.push(rest, a - b) |> interp(program, _, words)
    _ ->
      Error(
        "RuntimeError: Cannot do operation '-' because there are less than 2 numbers on the stack.",
      )
  }
}

fn star(program: Program, stack: Stack, words: Words) -> InterpResult {
  case stack {
    [a, b, ..rest] -> stack.push(rest, a * b) |> interp(program, _, words)
    _ ->
      Error(
        "RuntimeError: Cannot do operation '*' because there are less than 2 numbers on the stack.",
      )
  }
}

fn slash(program: Program, stack: Stack, words: Words) -> InterpResult {
  case stack {
    [a, b, ..rest] -> stack.push(rest, a / b) |> interp(program, _, words)
    _ ->
      Error(
        "RuntimeError: Cannot do operation '/' because there are less than 2 numbers on the stack.",
      )
  }
}

fn dot(program: Program, stack: Stack, words: Words) -> InterpResult {
  case stack.get(stack) {
    Error(Nil) ->
      Error(
        "RuntimeError: Cannot do operation '.' because the stack is empty and there is nothing to output.",
      )
    Ok(val) -> {
      val |> int.to_string |> io.println
      interp(program, stack, words)
    }
  }
}

fn word_def(t: Token, rest: Program, stack: Stack, words: Words) -> InterpResult {
  case t.definition {
    None -> Error("RuntimeError: Empty definition for word.")
    Some(prog) -> {
      case t.ident {
        None -> Error("RuntimeError: Empty ident for word.")
        Some(id) -> {
          dict.insert(words, for: id, insert: prog)
          |> interp(rest, stack, _)
        }
      }
    }
  }
}

fn word(t: Token, rest: Program, stack: Stack, words: Words) -> InterpResult {
  case t.ident {
    None -> Error("RuntimeError: Empty ident for word.")
    Some(id) -> {
      case dict.get(words, id) {
        Error(Nil) -> Error("RuntimeError: Using undefined word.")
        Ok(p) -> {
          use stack <- result.try(interp(p, stack, words))
          interp(rest, stack, words)
        }
      }
    }
  }
}
