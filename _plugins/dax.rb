require "rouge"

# Rouge has no built-in DAX lexer. Keep the examples labeled in their own language.
module Rouge
  module Lexers
    class DAX < RegexLexer
      title "DAX"
      desc "Data Analysis Expressions"
      tag "dax"
      filenames "*.dax"

      state :root do
        rule %r/\s+/, Text::Whitespace
        rule %r{//[^\n]*|--[^\n]*}, Comment::Single
        rule %r{/\*.*?\*/}m, Comment::Multiline
        rule %r/"(?:[^"]|"")*"/, Str::Double
        rule %r/'(?:[^']|'')*'/, Name::Class
        rule %r/\[(?:[^\]]|\]\])*\]/, Name::Variable
        rule %r/\b(?:TRUE|FALSE|BLANK)\b/i, Keyword::Constant
        rule %r/\b(?:VAR|RETURN|IN|NOT)\b/i, Keyword
        rule %r/[A-Za-z_][A-Za-z_0-9]*(?=\s*\()/, Name::Function
        rule %r/\b\d+(?:\.\d+)?\b/, Num
        rule %r/:=|&&|\|\||<>|<=|>=|[=+\-*\/^&<>]/, Operator
        rule %r/[(),{}]/, Punctuation
        rule %r/[A-Za-z_][A-Za-z_0-9]*/, Name
        rule %r/./, Text
      end
    end
  end
end
