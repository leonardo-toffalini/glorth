import gleam/option.{type Option}

pub type TokenType {
  Plus
  Minus
  Star
  Slash
  Dot
  Number
}

pub type Literal =
  Int

pub type Token {
  Token(token_type: TokenType, literal: Option(Literal))
}
