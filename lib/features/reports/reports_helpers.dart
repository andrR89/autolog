/// Nomes abreviados dos meses em PT-BR (3 letras, minúsculas, sem ponto).
///
/// Usados para evitar dependência de `initializeDateFormatting` na hora de
/// formatar labels de eixo, garantindo funcionamento em testes sem setup.
const _monthNames = [
  'jan', // 1
  'fev', // 2
  'mar', // 3
  'abr', // 4
  'mai', // 5
  'jun', // 6
  'jul', // 7
  'ago', // 8
  'set', // 9
  'out', // 10
  'nov', // 11
  'dez', // 12
];

/// Formata [month] como "mai/2026" — 3 letras minúsculas PT-BR + barra + ano.
///
/// Não depende de `initializeDateFormatting`; usa tabela estática de nomes
/// em PT-BR para funcionar sem setup de locale (inclusive em testes unitários).
String formatMonthLabel(DateTime month) {
  final abbr = _monthNames[month.month - 1];
  return '$abbr/${month.year}';
}
