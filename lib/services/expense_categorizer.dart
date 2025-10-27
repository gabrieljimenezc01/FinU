import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ExpenseCategorizer {
  Interpreter? _interpreter;
  List<String> _labels = [];
  Map<String, dynamic> _tokenizer = {};

  /// Cargar el modelo y los recursos (tokenizer + labels)
  Future<void> loadModel() async {
    try {
      print('🔄 Cargando modelo y archivos...');

      // Cargar el modelo .tflite
      _interpreter = await Interpreter.fromAsset('assets/model/modelo_gastos.tflite');

      // Cargar el tokenizer JSON
      final tokenizerData = await rootBundle.loadString('assets/model/tokenizer.json');
      _tokenizer = jsonDecode(tokenizerData);

      // Cargar las etiquetas
      final labelsData = await rootBundle.loadString('assets/model/label_encoder.json');
      _labels = List<String>.from(jsonDecode(labelsData));

      print('✅ Modelo y recursos cargados correctamente');
    } catch (e) {
      print('❌ Error cargando modelo o archivos: $e');
      rethrow;
    }
  }

  /// Tokenización del texto (convierte palabras a IDs)
  List<double> _tokenize(String text) {
    Map<String, dynamic> wordIndex = {};

    // Verificar si existe config
    if (_tokenizer.containsKey('config')) {
      final config = _tokenizer['config'];

      if (config is Map && config.containsKey('word_index')) {
        final rawWordIndex = config['word_index'];

        // 🔍 Si 'word_index' está como String JSON → decodificarlo
        if (rawWordIndex is String) {
          try {
            wordIndex = Map<String, dynamic>.from(jsonDecode(rawWordIndex));
          } catch (e) {
            print('⚠️ Error al decodificar word_index: $e');
          }
        } else if (rawWordIndex is Map) {
          // Si ya es un mapa
          wordIndex = Map<String, dynamic>.from(rawWordIndex);
        }
      }
    } 
    // En caso de que esté directamente en la raíz
    else if (_tokenizer.containsKey('word_index')) {
      final rawWordIndex = _tokenizer['word_index'];
      if (rawWordIndex is String) {
        wordIndex = Map<String, dynamic>.from(jsonDecode(rawWordIndex));
      } else if (rawWordIndex is Map) {
        wordIndex = Map<String, dynamic>.from(rawWordIndex);
      }
    }

    // ✅ Convertir texto a minúsculas y separar por espacios
    final words = text.toLowerCase().split(RegExp(r'\s+'));

    // ✅ Mapear cada palabra a su índice
    final List<double> tokenIds = [];
    for (final word in words) {
      if (wordIndex.containsKey(word)) {
        tokenIds.add((wordIndex[word] as num).toDouble());
      } else {
        tokenIds.add(0.0); // palabra desconocida
      }
    }

    // ✅ Padding / truncado a longitud fija (10)
    const maxLen = 10;
    if (tokenIds.length > maxLen) {
      return tokenIds.sublist(0, maxLen);
    } else if (tokenIds.length < maxLen) {
      tokenIds.addAll(List.filled(maxLen - tokenIds.length, 0.0));
    }

    return tokenIds;
  }

  /// Realizar predicción de categoría
  Future<String> predictCategory(String description) async {
    if (_interpreter == null) {
      throw Exception('❗ Modelo no cargado. Llama a loadModel() primero.');
    }

    final input = [_tokenize(description)];
    final output = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);

    _interpreter!.run(input, output);

    // Buscar el índice con mayor probabilidad
    final probabilities = List<double>.from(output[0]);

    final maxProb = probabilities.reduce((a, b) => a > b ? a : b);
    final maxIndex = probabilities.indexOf(maxProb);

    final predictedCategory = _labels[maxIndex];
    print('🔍 Predicción: $predictedCategory (confianza: ${maxProb.toStringAsFixed(3)})');
    return predictedCategory;
  }

  /// Liberar recursos
  void close() {
    _interpreter?.close();
  }
}
