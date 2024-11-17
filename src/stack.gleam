pub type Stack =
  List(Int)

pub fn new() -> Stack {
  []
}

pub fn pop(stack: Stack) -> Stack {
  case stack {
    [] -> []
    [_, ..rest] -> rest
  }
}

pub fn get(stack: Stack) -> Result(Int, Nil) {
  case stack {
    [] -> Error(Nil)
    [first, ..] -> Ok(first)
  }
}

pub fn push(stack: Stack, val: Int) -> Stack {
  [val, ..stack]
}
