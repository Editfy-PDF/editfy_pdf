import 'package:advance_math/advance_math.dart';

double gauss(Random rnd) {
  final u1 = rnd.nextDouble();
  final u2 = rnd.nextDouble();
  final r = sqrt(-2.0 * log(u1));
  return r * cos(2 * pi * u2);
}

double cosine(List<double> a, List<double> b) {
  double dot = 0, na = 0, nb = 0;
  for (int i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    na += a[i] * a[i];
    nb += b[i] * b[i];
  }

  final norma = sqrt(na);
  final normb = sqrt(nb);

  if (norma == 0 || normb == 0) return 0.0;

  return dot / (norma * normb);
}

double norm(Vector a) {
  double s = 0.0;
  for (int i = 0; i < a.length; i++) {
    final v = toDoubleSafe(a[i]);
    s += v * v;
  }
  return sqrt(s);
}

double cosineSim(Vector a, Vector b) {
  final denom = norm(a) * norm(b);
  if (denom == 0.0) return 0.0;
  return dotProduct(a, b) / denom;
}

/// Similaridade de Coseno e ranking
double dotProduct(Vector a, Vector b) {
  final n = a.length;
  double s = 0.0;
  for (int i = 0; i < n; i++) {
    s += toDoubleSafe(a[i]) * toDoubleSafe(b[i]);
  }
  return s;
}

/// Gera uma matriz de projeção aleatória que representa
/// a matriz real
(Matrix, Matrix) randomProjection(Matrix A, int k) {
  final n = A.columnCount;

  final rnd = Random();
  final scale = 1 / sqrt(k);

  final data = <List<double>>[];

  for (int i = 0; i < n; i++) {
    final row = List<double>.generate(
      k,
      (_) => gauss(rnd) * scale,
      growable: false,
    );
    data.add(row);
  }

  final R = Matrix.fromList(data);
  final result = (A * R);
  for(int i=0; i<result.rowCount; i++){
    for(int j=0; j<result.columnCount; j++){
      double temp = toDoubleSafe(result[i][j]);
      result[i][j] = temp;
    }
  }

  return (result, R);
}

/// Converte os valores de uma lista para double
List<double> toDoubleVector(List<dynamic> row) {
  return row.map<double>((e) {
    if (e is num) return e.toDouble();
    if (e is List && e.isNotEmpty && e.first is num){
      return (e.first as num).toDouble();
    }

    return 0.0;
  }).toList();
}

// Converte um número para double.
double toDoubleSafe(dynamic v) {
  if (v == null) return 0.0;
  if (v is double){
    if(v.isNaN || v.isInfinite) return 0.0;

    if (v > 1e6) v = 1e6;
    if (v < -1e6) v = -1e6;
    return v;
  }

  if (v is int){
    v = v.toDouble();
    if(v.isNaN || v.isInfinite) return 0.0;

    if (v > 1e6) v = 1e6;
    if (v < -1e6) v = -1e6;
    return v;
  }

  if (v is Complex){
    v = v.real.toDouble();
    if(v.isNaN || v.isInfinite) return 0.0;

    if (v > 1e6) v = 1e6;
    if (v < -1e6) v = -1e6;
    return v;
  }

  try {
    v = (v as num).toDouble();
    if(v.isNaN || v.isInfinite) return 0.0;

    if (v > 1e6) v = 1e6;
    if (v < -1e6) v = -1e6;
    return v;
  } catch (e) {
    return 0.0;
  }
}

// Converte uma List<List<dynamic>> em Matrix de doubles.
// Assumimos Matrix.fromList aceita List<List<double>>.
Matrix matrixFromDynamicRows(List<List<dynamic>> rows) {
  final converted = rows
      .map((r) => r.map((e) => toDoubleSafe(e)).toList())
      .toList();
  return Matrix.fromList(converted);
}

// Converte Vector/Row em Vector<double>
Vector vectorFromDynamicList(List<dynamic> row) {
  return Vector.fromList(row.map((e) => toDoubleSafe(e)).toList());
}