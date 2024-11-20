import gleam/option.{type Option}

pub type TokenType {
  // binary operators
  Plus
  Minus
  Star
  Slash
  Greater
  GreaterEqual
  Less
  LessEqual

  // unary operator
  Dot

  // other
  Number
  WordDef
  Word
}

pub type Literal =
  Int

type Program =
  List(Token)

pub type Token {
  Token(
    token_type: TokenType,
    literal: Option(Literal),
    definition: Option(Program),
    ident: Option(String),
  )
}
