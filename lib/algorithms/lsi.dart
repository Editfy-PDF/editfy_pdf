import 'dart:typed_data';
import 'package:advance_math/advance_math.dart';
import 'package:editfy_pdf/algorithms/helper_fun.dart';
import 'package:editfy_pdf/algorithms/rsvd.dart';

// --- Project documents & query consistently to k-dim space ---
// Document projection: each doc row in TF-IDF is 1 x nTokens
// To get doc vector in reduced space: doc' = doc * V_k * S_k^{-1}
Vector projectEmbed2Vec(List<double> docRow, TruncatedSVD tsvd) {
  final k = tsvd.k;
  final qMatrix = Matrix.fromList([docRow]);
  final V = tsvd.V;

  final invSrows = <List<double>>[];
  for (int i = 0; i < k; i++) {
    final row = List<double>.filled(k, 0.0);
    final diag = toDoubleSafe(tsvd.S[i][i]);
    row[i] = diag == 0.0 ? 0.0 : 1.0 / diag;
    invSrows.add(row);
  }

  final invS = Matrix.fromList(invSrows);
  final prod = (qMatrix * V * invS);
  final row = prod.row(0).first;

  return vectorFromDynamicList(row);
}

// Query projection: same as document
Vector projectQuery(
  Uint32List queryTokens,
  List<int> vocab,
  Map<int,int> tokenIndex,
  Map<int,double> idf,
  int k,
  TruncatedSVD tsvd
  ){
  final q = List<double>.filled(vocab.length, 0.0);
  for (final t in queryTokens) {
    final idx = tokenIndex[t];
    if (idx != null) q[idx] += 1.0;
  }

  for (int i = 0; i < q.length; i++) {
    final tf = q[i];
    q[i] = tf > 0 ? (1.0 + log(tf)) : 0.0;
    final token = vocab[i];
    final idfVal = idf[token] ?? 0.0;
    q[i] = q[i] * idfVal;
  }

  final (projQ, _) = randomProjection(Matrix.fromList([q]), k);

  return projectEmbed2Vec(
    projQ.row(0).first.map(toDoubleSafe).toList(),
    tsvd
  );
}

// Rank query against projectedDocs (list of Vector) and return sorted indices+score
List<Map<String, dynamic>> rankQuery(Vector qVec, List<Vector> projectedDocs, {int topK = 10}) {
  final results = <Map<String, dynamic>>[];
  for (int i = 0; i < projectedDocs.length; i++) {
    final score = cosineSim(qVec, projectedDocs[i]);
    results.add({'index': i, 'score': score});
  }
  results.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
  return results.take(topK).toList();
}
