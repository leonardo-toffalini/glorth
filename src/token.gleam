import gleam/option.{type Option}

pub type TokenType {
  Plus
  Minus
  Star
  Slash
  Dot
  Number
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
