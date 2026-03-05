class Validators {
  static String? requireString(Map<String, dynamic> data, String field) {
    final value = data[field];
    if (value == null || value is! String || value.trim().isEmpty) {
      return 'O campo "$field" é obrigatório e deve ser uma string não vazia.';
    }
    return null;
  }

  static String? requirePositiveNumber(Map<String, dynamic> data, String field) {
    final value = data[field];
    if (value == null) {
      return 'O campo "$field" é obrigatório.';
    }
    final number = value is num ? value : num.tryParse(value.toString());
    if (number == null || number <= 0) {
      return 'O campo "$field" deve ser um número positivo.';
    }
    return null;
  }

  static List<String> validate(
      Map<String, dynamic> data, Map<String, Function> rules) {
    final errors = <String>[];
    for (final entry in rules.entries) {
      final error = entry.value(data, entry.key) as String?;
      if (error != null) {
        errors.add(error);
      }
    }
    return errors;
  }
}
