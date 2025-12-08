class LSHIndex {
  final int bands;
  final int rowsPerBand;

  final List<Map<int, List<int>>> buckets = [];

  LSHIndex(this.bands, this.rowsPerBand){
    for (int i = 0; i < bands; i++) {
      buckets.add({});
    }
  }

  int _hash(List<double> vec){
    int h = 0;
    for (var v in vec){
      h = (h * 31 + v.sign.toInt()) & 0x7fffffff;
    }
    return h;
  }

  void addVector(int index, List<double> vec){
    int pos = 0;

    for (int b = 0; b < bands; b++){
      final slice = vec.sublist(pos, pos + rowsPerBand);
      final h = _hash(slice);

      buckets[b].putIfAbsent(h, () => []).add(index);

      pos += rowsPerBand;
    }
  }

  Set<int> query(List<double> vec){
    int pos = 0;
    final candidates = <int>{};

    for (int b = 0; b < bands; b++){
      final slice = vec.sublist(pos, pos + rowsPerBand);
      final h = _hash(slice);

      if (buckets[b].containsKey(h)){
        candidates.addAll(buckets[b][h]!);
      }

      pos += rowsPerBand;
    }

    return candidates;
  }
}