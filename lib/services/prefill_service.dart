import 'dart:typed_data';
import 'dart:math';
import 'package:langchain_tiktoken/langchain_tiktoken.dart';

class PageAnalist{
  PageAnalist();

  Uint32List tokenize(String text, {String encodingType='cl100k_base'}){
    final engine = getEncoding(encodingType);

    return engine.encode(text);
  }

  String detokenize(Uint32List tokens, {String encodingType='cl100k_base'}){
    final engine = getEncoding(encodingType);

    return engine.decode(tokens);
  }

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

  Map<int, double> computeIDF(Map<int, int> df, int totalChunks) {
    final idf = <int, double>{};

    df.forEach((token, freq) {
      idf[token] = log(((totalChunks - freq + 0.5) / (freq + 0.5)) + 1.0);
    });

    return idf;
  }

  double avgChunkLength(List<Uint32List> chunks) {
    final total = chunks.fold<int>(0, (sum, p) => sum + p.length);
    return total / chunks.length;
  }

  double bm25Score({
    required int chunkIndex,
    required Uint32List query,
    required List<Uint32List> chunks,
    required List<Map<int, int>> tf,
    required Map<int, double> idf,
    required double avgdl,
    double k1 = 1.5,
    double b = 0.75,
  }) {
    double score = 0.0;

    final freq = tf[chunkIndex];
    final dl = chunks[chunkIndex].length;

    for (var token in query) {
      if (!freq.containsKey(token)) continue;

      final f = freq[token]!.toDouble();
      final idfTerm = idf[token] ?? 0.0;

      score += idfTerm *
          (f * (k1 + 1.0)) /
          (f + k1 * (1.0 - b + b * dl / avgdl));
    }

    return score;
  }

  List<(int chunkIndex, double score)> chunksScore(
    List<Uint32List> chunks,
    Uint32List query, {
    double k1 = 1.5,
    double b = 0.75,
  }) {
    final tfList = computeTF(chunks);
    final df = computeDF(chunks);
    final idf = computeIDF(df, chunks.length);
    final avgdl = avgChunkLength(chunks);

    final results = <(int, double)>[];

    for (var i = 0; i < chunks.length; i++) {
      final score = bm25Score(
        chunkIndex: i,
        query: query,
        chunks: chunks,
        tf: tfList,
        idf: idf,
        avgdl: avgdl,
        k1: k1,
        b: b,
      );
      results.add((i, score));
    }

    results.sort((a, b) => b.$2.compareTo(a.$2));
    return results;
  }
}