class GameGrid {
  List<List<bool>> board;
  List<String> rows;
  List<String> columns;
  int toggleCount;

  GameGrid({
    required this.board,
    required this.rows,
    required this.columns,
    required this.toggleCount,
  });

  factory GameGrid.init() {
    return GameGrid(
      board: List.generate(5, (_) => List<bool>.filled(5, false)),
      rows: ['A', 'B', 'C', 'D', 'E'],
      columns: ['1', '2', '3', '4', '5'],
      toggleCount: 0,
    );
  }
}
