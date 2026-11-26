/// Nombre que se muestra para cada tipo de evento.
const eventTypeLabels = <String, String>{
  'orinal': 'Orinal',
  'comida': 'Comida',
  'agua': 'Agua',
  'paseo': 'Paseo',
  'juego': 'Tiempo de juego',
  'bano': 'Baño',
  'cepillado': 'Cepillado',
  'vacuna': 'Vacunación',
  'desparasitante': 'Antiparasitario',
  'medicina': 'Medicina',
  'visita': 'Visita al veterinario',
  'sintoma': 'Síntomas',
};

/// Tipos de la pestaña Diario.
const dailyTypes = <String>{
  'orinal',
  'comida',
  'agua',
  'paseo',
  'juego',
  'bano',
  'cepillado',
};

/// Tipos de la pestaña Salud.
const healthTypes = <String>{
  'vacuna',
  'desparasitante',
  'medicina',
  'visita',
  'sintoma',
};

/// Tipos que pueden tener una próxima fecha (y por tanto recordatorio).
const typesWithNextDate = <String>{
  'vacuna',
  'desparasitante',
  'medicina',
  'visita',
};
