import 'package:advance_math/advance_math.dart';
import 'package:editfy_pdf/algorithms/helper_fun.dart';

class TruncatedSVD {
  final Matrix U; // m x k
  final Matrix S; // k x k diagonal
  final Matrix V; // n x k
  final int k;
  TruncatedSVD(this.U, this.S, this.V, this.k);
}

/// Compute truncated SVD with target k.
/// If svd returned only r < k factors, this pads with zeros to k.
/// Here `svdCompute` should be your library SVD call (returns an object with U,S,V).
TruncatedSVD computeTruncatedSVD(Matrix A, int k, {required dynamic Function(Matrix) svdCompute}) {
  final dynamic svd = svdCompute(A);
  final Matrix Ufull = svd.U();
  final Matrix Sfull = svd.S();
  final Matrix Vfull = svd.V();

  final r = Sfull.rowCount;
  final kEff = min(k, r);
  final Usub = Ufull.subMatrix(rowStart: 0, rowEnd: Ufull.rowCount - 1, colStart: 0, colEnd: kEff - 1);
  final SsubRows = List.generate(kEff, (i) {
    final row = List<dynamic>.filled(kEff, 0.0);
    for(int j = 0; j < kEff; j++){
      row[j] = (i == j) ? Sfull[i][i] : 0.0;
    }
    return row;
  });
  final Ssub = matrixFromDynamicRows(SsubRows);
  final Vsub = Vfull.subMatrix(rowStart: 0, rowEnd: Vfull.rowCount - 1, colStart: 0, colEnd: kEff - 1);

  if(kEff == k){
    return TruncatedSVD(Usub, Ssub, Vsub, k);
  }

  final pad = k - kEff;

  final Urows = <List<double>>[];
  for(int i = 0; i < Usub.rowCount; i++){
    final row = <double>[];
    for(int j = 0; j < Usub.columnCount; j++){
      row.add(toDoubleSafe(Usub[i][j]));
    }

    for(int p = 0; p < pad; p++){
      row.add(0.0);
    }

    Urows.add(row);
  }
  final Upadded = Matrix.fromList(Urows);

  final Vrows = <List<double>>[];
  for(int i = 0; i < Vsub.rowCount; i++){
    final row = <double>[];
    for(int j = 0; j < Vsub.columnCount; j++){
      row.add(toDoubleSafe(Vsub[i][j]));
    }

    for(int p = 0; p < pad; p++){
      row.add(0.0);
    }
    Vrows.add(row);
  }
  final Vpadded = Matrix.fromList(Vrows);

  final Srows = <List<double>>[];
  for(int i = 0; i < k; i++) {
    final row = List<double>.filled(k, 0.0);
    if(i < kEff){
      row[i] = toDoubleSafe(Ssub[i][i]);
    } else {
      row[i] = 0.0;
    }
    Srows.add(row);
  }
  final Spadded = Matrix.fromList(Srows);

  return TruncatedSVD(Upadded, Spadded, Vpadded, k);
}