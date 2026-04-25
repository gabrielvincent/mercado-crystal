module CurrencyHelper
  extend self

  # Parses a Brazilian-formatted currency string ("1.234,56") into cents (123456).
  # Returns nil if the string can't be parsed as a number.
  def parse_cents(input : Float64) : Int32?
    (input * 100).round.to_i32
  rescue OverflowError
    nil
  end

  # Formats cents as "R$1234,56".
  def format(cents : Int32) : String
    whole = cents // 100
    decimal = (cents % 100).abs
    "R$#{whole},#{decimal.to_s.rjust(2, '0')}"
  end
end
