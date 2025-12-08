import 'dart:typed_data';
import 'package:advance_math/advance_math.dart';

/// Calcula a Frequência de Termo (Term Frequency - TF) para cada chunk.
List<Map<int, int>> computeTF(List<Uint32List> chunks) {
  final tfList = <Map<int, int>>[];

  for (var chunkTokens in chunks) {
    final freq = <int, int>{};
    for (var token in chunkTokens) {
      freq[token] = (freq[token] ?? 0) + 1;
    }
    tfList.add(freq);
  }

  return tfList;
}

/// Calcula a Frequência de Documento (Document Frequency - DF) global.
Map<int, int> computeDF(List<Uint32List> chunks) {
  final df = <int, int>{};

  for (var chunkTokens in chunks) {
    final seen = <int>{};
    for (var token in chunkTokens) {
      if (seen.add(token)) {
        df[token] = (df[token] ?? 0) + 1;
      }
    }
  }

  return df;
}

/// Calcula a Frequência Inversa de Documento (Inverse Document Frequency - IDF)
/// para cada token, penalizando tokens comuns e valorizando tokens raros.
Map<int, double> computeIDF(Map<int, int> df, int totalChunks) {
  final idf = <int, double>{};

  df.forEach((token, freq) {
    final num = totalChunks - freq + 0.5;
    final den = freq + 0.5;
    
    idf[token] = log(1 + num / den);
  });

  return idf;
}

// Build vocabulary (list of tokens) and token->index map
List<int> buildVocab(Map<int, double> idf) {
  return idf.keys.toList();
}

// Build TF vector for a single chunk (raw counts) optionally normalized to TF or TF-IDF.
List<double> buildTFVector(Uint32List chunk, List<int> vocab, Map<int, int> tokenIndex) {
  final vec = List<double>.filled(vocab.length, 0.0);
  for (final t in chunk) {
    final idx = tokenIndex[t];
    if (idx != null) vec[idx] += 1.0;
  }

  for (int i = 0; i < vec.length; i++) {
    final tf = vec[i];
    vec[i] = tf > 0 ? (1.0 + log(tf)) : 0.0;
  }
  return vec;
}

// Build TF-IDF matrix: docs × terms => Matrix (m x n)
Matrix buildTFIDFMatrix(List<Uint32List> chunks, List<int> vocab, Map<int, double> idf, Map<int, int> tokenIndex) {
  final rows = <List<double>>[];
  for (final chunk in chunks) {
    final tf = buildTFVector(chunk, vocab, tokenIndex);

    for (int j = 0; j < tf.length; j++) {
      final token = vocab[j];
      final idfVal = idf[token] ?? 0.0;
      tf[j] = tf[j] * idfVal;
    }
    rows.add(tf);
  }

  return Matrix.fromList(rows);
}

/// Calcula o comprimento médio dos chunks (avgdl).
double avgChunkLength(List<Uint32List> chunks) {
  if (chunks.isEmpty) return 0;

  final total = chunks.fold<int>(0, (sum, p) => sum + p.length);
  return total / chunks.length;
}

Matrix bm25(
  List<Uint32List> chunks, {
  double k1 = 1.5,
  double b = 0.75,
}) {
  final tfList = computeTF(chunks);
  final df = computeDF(chunks);
  final idf = computeIDF(df, chunks.length);
  final avgdl = avgChunkLength(chunks);

  final tokens = idf.keys.toList();
  final tokenIndex = {
    for (int i = 0; i < tokens.length; i++) tokens[i]: i
  };

  final rows = <List<double>>[];

  for (int i = 0; i < chunks.length; i++) {
    final row = List<double>.filled(tokens.length, 0.0);

    final dl = chunks[i].length.toDouble();

    for (var token in tfList[i].keys) {
      if (!tokenIndex.containsKey(token)) continue;

      final col = tokenIndex[token]!;
      final f = tfList[i][token]!.toDouble();
      final idfVal = idf[token]!;

      row[col] = idfVal *
          (f * (k1 + 1)) /
          (f + k1 * (1 - b + b * dl / avgdl));
    }

    rows.add(row);
  }

  return Matrix.fromList(rows);
}