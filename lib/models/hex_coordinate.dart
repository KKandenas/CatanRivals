/// Axial koordinat för hexagon-rutnätet i en spelares rike.
///
/// Vi använder axiella koordinater (q, r) istället för pixel-position,
/// eftersom det gör grannskaps- och avståndsberäkningar enkla och
/// gör rutnätet oberoende av hur det senare ritas ut på skärmen (zoom/pan).
class HexCoordinate {
  final int q;
  final int r;

  const HexCoordinate(this.q, this.r);

  /// De sex angränsande positionerna runt denna hexagon, medurs från öster.
  static const List<HexCoordinate> _directions = [
    HexCoordinate(1, 0),
    HexCoordinate(1, -1),
    HexCoordinate(0, -1),
    HexCoordinate(-1, 0),
    HexCoordinate(-1, 1),
    HexCoordinate(0, 1),
  ];

  List<HexCoordinate> get neighbors =>
      _directions.map((d) => HexCoordinate(q + d.q, r + d.r)).toList();

  /// Avstånd i antal hexagon-steg mellan två koordinater.
  int distanceTo(HexCoordinate other) {
    final dq = q - other.q;
    final dr = r - other.r;
    return (dq.abs() + dr.abs() + (dq + dr).abs()) ~/ 2;
  }

  HexCoordinate operator +(HexCoordinate other) =>
      HexCoordinate(q + other.q, r + other.r);

  Map<String, dynamic> toJson() => {'q': q, 'r': r};

  factory HexCoordinate.fromJson(Map<String, dynamic> json) =>
      HexCoordinate(json['q'] as int, json['r'] as int);

  @override
  bool operator ==(Object other) =>
      other is HexCoordinate && other.q == q && other.r == r;

  @override
  int get hashCode => Object.hash(q, r);

  @override
  String toString() => 'Hex($q, $r)';
}
