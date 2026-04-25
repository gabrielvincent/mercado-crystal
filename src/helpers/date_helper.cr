module DateHelper
  extend self

  SAO_PAULO = Time::Location.load("America/Sao_Paulo")

  PT_MONTHS = [
    "Janeiro", "Fevereiro", "Março", "Abril",
    "Maio", "Junho", "Julho", "Agosto",
    "Setembro", "Outubro", "Novembro", "Dezembro",
  ]

  # Formats a time as "17 de Março, 14h:05m" in the São Paulo timezone.
  def format_br(time : Time) : String
    local = time.in(SAO_PAULO)
    "#{local.day} de #{PT_MONTHS[local.month - 1]}, #{local.to_s("%Hh:%Mm")}"
  end
end
