import 'dart:math';

class PasswordGeneratorService {
  String generate({
    int length = 16,
    bool useLower = true,
    bool useUpper = true,
    bool useNumbers = true,
    bool useSymbols = true,
  }) {
    String chars = '';
    if (useLower) chars += _lower;
    if (useUpper) chars += _upper;
    if (useNumbers) chars += _numbers;
    if (useSymbols) chars += _symbols;

    if (chars.isEmpty) throw Exception('No character sets selected');

    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  // New method to generate a password with a specified length and character sets
  String generatePassword({
    int length = 16,
    bool useLower = true,
    bool useUpper = true,
    bool useNumbers = true,
    bool useSymbols = true,
  }) {
    return generate(
      length: length,
      useLower: useLower,
      useUpper: useUpper,
      useNumbers: useNumbers,
      useSymbols: useSymbols,
    );
  }
} 