import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ExpenseCategorizer {
  // === SINGLETON ===
  static final ExpenseCategorizer _instance = ExpenseCategorizer._internal();
  factory ExpenseCategorizer() => _instance;
  ExpenseCategorizer._internal();

  Interpreter? _interpreter;
  List<String> _labels = [];
  Map<String, dynamic> _tokenizer = {};
  Map<String, dynamic> _wordIndex = {}; // ← CLAVE: Extraído una vez

  bool _initialized = false;

  /// ============================================================
  ///  CARGA DEL MODELO — Con manejo robusto del tokenizer
  /// ============================================================
  Future<void> loadModel({bool forceReload = false}) async {
    if (_initialized && !forceReload) {
      print("🔁 Modelo IA ya estaba inicializado, se reutiliza.");
      return;
    }

    // Si se fuerza recarga, cerrar intérprete anterior
    if (forceReload && _interpreter != null) {
      _interpreter!.close();
      _interpreter = null;
      _initialized = false;
      print("🔄 Forzando recarga del modelo...");
    }

    try {
      print('🔄 Cargando modelo IA...');

      // 1. Cargar intérprete
      _interpreter = await Interpreter.fromAsset(
        'assets/model/modelo_gastos.tflite',
        options: InterpreterOptions()..threads = 2,
      );
      print('✅ Intérprete cargado');

      // 2. Cargar tokenizer con manejo robusto
      final tokenizerData = await rootBundle.loadString('assets/model/tokenizer.json');
      _tokenizer = jsonDecode(tokenizerData);
      
      // Extraer word_index con todos los casos posibles
      _extractWordIndex();
      print('✅ Tokenizer cargado: ${_wordIndex.length} palabras');
      
      // Mostrar primeras 10 palabras del vocabulario
      int count = 0;
      print("📚 Muestra del vocabulario:");
      for (var entry in _wordIndex.entries) {
        if (count++ < 10) {
          print("  '${entry.key}' → ${entry.value}");
        }
      }

      // 3. Cargar labels
      final labelsData = await rootBundle.loadString('assets/model/label_encoder.json');
      _labels = List<String>.from(jsonDecode(labelsData));
      print('✅ Labels cargadas: $_labels');

      _initialized = true;
      print('✅ Modelo IA cargado correctamente.');
    } catch (e) {
      print('❌ Error cargando modelo IA: $e');
      rethrow;
    }
  }

  /// ============================================================
  /// Extrae word_index del tokenizer (maneja múltiples formatos)
  /// ============================================================
  void _extractWordIndex() {
    // Caso 1: Está en config.word_index
    if (_tokenizer.containsKey('config')) {
      final config = _tokenizer['config'];
      if (config is Map && config.containsKey('word_index')) {
        final rawWordIndex = config['word_index'];
        
        // Si es un String JSON, decodificarlo
        if (rawWordIndex is String) {
          try {
            _wordIndex = Map<String, dynamic>.from(jsonDecode(rawWordIndex));
            print("📖 word_index encontrado en config (String JSON)");
            return;
          } catch (e) {
            print('⚠️ Error decodificando word_index como String: $e');
          }
        } 
        // Si ya es un Map
        else if (rawWordIndex is Map) {
          _wordIndex = Map<String, dynamic>.from(rawWordIndex);
          print("📖 word_index encontrado en config (Map)");
          return;
        }
      }
    }

    // Caso 2: Está directamente en la raíz
    if (_tokenizer.containsKey('word_index')) {
      final rawWordIndex = _tokenizer['word_index'];
      
      if (rawWordIndex is String) {
        try {
          _wordIndex = Map<String, dynamic>.from(jsonDecode(rawWordIndex));
          print("📖 word_index encontrado en raíz (String JSON)");
          return;
        } catch (e) {
          print('⚠️ Error decodificando word_index: $e');
        }
      } else if (rawWordIndex is Map) {
        _wordIndex = Map<String, dynamic>.from(rawWordIndex);
        print("📖 word_index encontrado en raíz (Map)");
        return;
      }
    }

    // Caso 3: El tokenizer ES el word_index directamente
    if (_tokenizer.isNotEmpty && !_tokenizer.containsKey('config') && !_tokenizer.containsKey('word_index')) {
      _wordIndex = Map<String, dynamic>.from(_tokenizer);
      print("📖 Tokenizer es directamente el word_index");
      return;
    }

    print("⚠️ No se pudo extraer word_index del tokenizer");
  }

  /// ============================================================
  ///                 TOKENIZACIÓN DEL TEXTO
  /// ============================================================
  List<double> _tokenize(String text) {
    // Limpiar y separar texto
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-záéíóúñ0-9 ]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.trim().isNotEmpty)
        .toList();

    print("🔤 Palabras extraídas: $words");

    final tokens = <double>[];

    for (final word in words) {
      if (_wordIndex.containsKey(word)) {
        final tokenId = (_wordIndex[word] as num).toDouble();
        tokens.add(tokenId);
        print("  ✅ '$word' → $tokenId");
      } else {
        tokens.add(0.0);
        print("  ❌ '$word' → 0 (desconocida)");
      }
    }

    // Ajustar longitud a 10
    const maxLen = 10;
    if (tokens.length > maxLen) {
      return tokens.sublist(0, maxLen);
    } else if (tokens.length < maxLen) {
      tokens.addAll(List<double>.filled(maxLen - tokens.length, 0.0));
    }

    print("🎯 Tokens finales: $tokens");
    return tokens;
  }

  /// ============================================================
  ///                     PREDICCIÓN IA
  /// ============================================================
  Future<String> predictCategory(String description) async {
    if (!_initialized) {
      throw Exception("❗ Debes llamar loadModel() antes de predecir.");
    }

    if (_interpreter == null) {
      throw Exception("❌ Intérprete no disponible.");
    }

    final input = [_tokenize(description)];
    print("🎯 Input shape: ${input.length}x${input[0].length}");

    // Crear output con reshape
    final output = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);

    try {
      _interpreter!.run(input, output);

      // Obtener probabilidades
      final probs = List<double>.from(output[0]);

      // Mostrar TODAS las probabilidades
      print("📊 Probabilidades de todas las categorías:");
      for (int i = 0; i < _labels.length; i++) {
        print("  ${_labels[i]}: ${(probs[i] * 100).toStringAsFixed(1)}%");
      }

      // Encontrar la categoría con mayor probabilidad
      double maxProb = -1;
      int index = 0;

      for (int i = 0; i < probs.length; i++) {
        if (probs[i] > maxProb) {
          maxProb = probs[i];
          index = i;
        }
      }

      final category = _labels[index];

      print("🔍 IA: $category (conf: ${maxProb.toStringAsFixed(3)})");

      return category;
    } catch (e) {
      print("❌ Error ejecutando IA: $e");
      return "Desconocido";
    }
  }

  /// ============================================================
  /// Cerrar el intérprete (solo si se necesita reiniciar)
  /// ============================================================
  void close() {
    if (_interpreter != null) {
      _interpreter!.close();
      _interpreter = null;
      _initialized = false;
      print("🔒 Modelo cerrado");
    }
  }
}