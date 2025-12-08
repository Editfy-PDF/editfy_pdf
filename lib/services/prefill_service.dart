import 'dart:typed_data';
import 'package:advance_math/advance_math.dart';
import 'package:langchain_tiktoken/langchain_tiktoken.dart';

import 'package:editfy_pdf/algorithms/lsh.dart';
import 'package:editfy_pdf/algorithms/tf_idf.dart';
import 'package:editfy_pdf/algorithms/rsvd.dart';
import 'package:editfy_pdf/algorithms/helper_fun.dart';
import 'package:editfy_pdf/algorithms/lsi.dart';

class PageAnalist{
  PageAnalist();

  /// Converte o texto de entrada em uma lista de IDs de token (formato Uint32List).
  Uint32List tokenize(String text, {String encodingType='cl100k_base'}){
    final engine = getEncoding(encodingType);

    return engine.encode(text);
  }

  /// Converte a lista de IDs de token de volta para uma String.
  String detokenize(Uint32List tokens, {String encodingType='cl100k_base'}){
    final engine = getEncoding(encodingType);

    return engine.decode(tokens);
  }

  /// Calcula o BM25 Score de um único chunk em relação a uma query.
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

  /// Orquestra o cálculo completo do BM25 para
  /// todos os chunks contra a query e retorna os resultados ranqueados.
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

  List<(int chunkIndex, double similarity)> semanticSearchLSI(
  List<Uint32List> chunks,
  Uint32List queryTokens,
) {
  const int k1 = 64; // pré-projeção
  const int k2 = 32; // pós-projeção

  final df = computeDF(chunks);
  final idf = computeIDF(df, chunks.length);

  final vocab = buildVocab(idf);
  final tokenIndex = <int, int>{};
  for (int i = 0; i < vocab.length; i++) {
    tokenIndex[vocab[i]] = i;
  }

  final tfidf = buildTFIDFMatrix(chunks, vocab, idf, tokenIndex);

  final (projTfidf64, R) = randomProjection(tfidf, k1);

  final tsvd = computeTruncatedSVD(
    projTfidf64,
    k1,
    svdCompute: (A) => SVD(A),
  );

  final projectedDocs64 = <Vector>[];
  for (int i = 0; i < projTfidf64.rowCount; i++){
    final row = projTfidf64.row(i).first.map(toDoubleSafe).toList();
    final proj = projectEmbed2Vec(row, tsvd);
    projectedDocs64.add(proj);
  }

  final docsMatrix64 = Matrix.fromList(
    projectedDocs64.map((v) => v.toList()).toList(),
  );

  final (docsMatrix32, _) = randomProjection(docsMatrix64, k2);

  final projectedDocs32 = [
    for (int i = 0; i < docsMatrix32.rowCount; i++)
      Vector.fromList(docsMatrix32.row(i).first.toList())
  ];

  final q64 = projectQuery(queryTokens, vocab, tokenIndex, idf, k1, tsvd);

  final qMatrix64 = Matrix.fromList([q64.toList()]);
  final (qMatrix32, _) = randomProjection(qMatrix64, k2);
  final q32 = Vector.fromList(qMatrix32.row(0).first.toList());

  final ranked = rankQuery(q32, projectedDocs32, topK: chunks.length);

  return ranked
  .map< (int, double) >(
    (e) => (e['index'] as int, e['score'] as double),
  )
  .toList();
}

  List<(int chunkIndex, double similarity)> semanticSearchLSH(
    List<Uint32List> chunks,
    Uint32List queryTokens, {
    int bands = 16,
    int rowsPerBand = 4
  }) {
    final k = bands * rowsPerBand;
    final bm25Matrix = bm25(chunks);
    final (projected, R) = randomProjection(bm25Matrix, k);

    final lsh = LSHIndex(bands, rowsPerBand);

    for (int i = 0; i < projected.rowCount; i++) {
      final v = projected.row(i).asList
      .first
      .map((e) => (e).toDouble())
      .toList(growable: false);

      lsh.addVector(i, toDoubleVector(v));
    }

    final df = computeDF(chunks);
    final idf = computeIDF(df, chunks.length);

    final tokens = idf.keys.toList();
    final tokenIndex = {for (int i = 0; i < tokens.length; i++) tokens[i]: i};

    final queryRow = List<double>.filled(tokens.length, 0.0);

    for (final t in queryTokens) {
      if (tokenIndex.containsKey(t)) {
        queryRow[tokenIndex[t]!] = idf[t]!;
      }
    }

    final queryMatrix = Matrix.fromList([queryRow]);

    final queryProj = (queryMatrix * R)
    .row(0)
    .asList
    .first
    .map((e) => e.toDouble())
    .toList();

    final candidates = lsh.query(toDoubleVector(queryProj));

    final results = <(int, double)>[];

    for (final idx in candidates) {
      final doc = projected.row(idx).asList.first.map((e) => e.toDouble()).toList();
      final sim = cosine(toDoubleVector(doc), toDoubleVector(queryProj));
      results.add((idx, sim));
    }

    results.sort((a, b) => b.$2.compareTo(a.$2));

    return results;
  }
}