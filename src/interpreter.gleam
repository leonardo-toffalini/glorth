import gleam/int
import gleam/io
import gleam/option
import lexer.{type Program}
import stack.{type Stack}
import token.{type Token}

pub type InterpResult =
  Result(Nil, String)

pub fn run(program: Program) -> Nil {
  let stack = stack.new()
  case interp(program, stack) {
    Ok(_) -> io.println("ok")
    Error(text) -> io.println(text)
  }
}

fn interp(program: Program, stack: Stack) -> InterpResult {
  case program {
    [] -> Ok(Nil)
    [first, ..rest] ->
      case first.token_type {
        token.Number -> number(first, rest, stack)
        token.Plus -> plus(rest, stack)
        token.Minus -> minus(rest, stack)
        token.Star -> star(rest, stack)
        token.Slash -> slash(rest, stack)
        token.Dot -> dot(rest, stack)
        // _ -> Error("Unrecognized token")
      }
  }
}

fn number(first: Token, rest: Program, stack: Stack) -> InterpResult {
  option.unwrap(first.literal, 0) |> stack.push(stack, _) |> interp(rest, _)
}

fn plus(program: Program, stack: Stack) -> InterpResult {
  case stack {
    [a, b, ..] -> stack.push(stack, a + b) |> interp(program, _)
    _ ->
      Error(
        "RuntimeError: Cannot do operation '+' because there are less than 2 numbers on the stack.",
      )
  }
}

fn minus(program: Program, stack: Stack) -> InterpResult {
  case stack {
    [a, b, ..] -> stack.push(stack, a - b) |> interp(program, _)
    _ ->
      Error(
        "RuntimeError: Cannot do operation '-' because there are less than 2 numbers on the stack.",
      )
  }
}

fn star(program: Program, stack: Stack) -> InterpResult {
  case stack {
    [a, b, ..] -> stack.push(stack, a * b) |> interp(program, _)
    _ ->
      Error(
        "RuntimeError: Cannot do operation '*' because there are less than 2 numbers on the stack.",
      )
  }
}

fn slash(program: Program, stack: Stack) -> InterpResult {
  case stack {
    [a, b, ..] -> stack.push(stack, a / b) |> interp(program, _)
    _ ->
      Error(
        "RuntimeError: Cannot do operation '/' because there are less than 2 numbers on the stack.",
      )
  }
}

fn dot(program: Program, stack: Stack) -> InterpResult {
  case stack.get(stack) {
    Error(Nil) ->
      Error(
        "RuntimeError: Cannot do operation '.' because the stack is empty and there is nothing to output.",
      )
    Ok(val) -> {
      val |> int.to_string |> io.println
      interp(program, stack)
    }
  }
}
