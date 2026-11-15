// Clave de búsqueda: no modifica el nombre guardado ni los códigos escaneados.
String searchKey(String value) {
  const accents = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };
  var result = value.trim().toLowerCase();
  accents.forEach((accent, plain) => result = result.replaceAll(accent, plain));
  return result.replaceAll(RegExp(r'[\u0300-\u036f]'), '');
}

// Orden español: ñ después de n y antes de o; tildes no alteran el orden.
String spanishSortKey(String value) => searchKey(
  value.toLowerCase().replaceAll('ñ', 'n~').replaceAll('n\u0303', 'n~'),
);
