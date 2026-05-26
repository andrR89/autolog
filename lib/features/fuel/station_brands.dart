/// Bandeiras de combustível brasileiras comuns (autocomplete).
const Set<String> brStationBrands = {
  'Shell',
  'Petrobras',
  'Ipiranga',
  'Ale',
  'BR Petrobras',
  'Raízen',
  'Atem',
  'TG',
  'Sim',
  'Total',
  'Esso',
  'Branca', // sem bandeira / posto independente
};

/// Normaliza pra match (trim + lowercase + sem acento).
String normalizeStation(String s) {
  final lower = s.trim().toLowerCase();
  const accents = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };
  final buf = StringBuffer();
  for (final ch in lower.split('')) {
    buf.write(accents[ch] ?? ch);
  }
  return buf.toString();
}
