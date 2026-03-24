class ReportSummary {
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final String currencyCode;

  ReportSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netProfit,
    required this.currencyCode,
  });

  bool get isProfitable => netProfit >= 0;
}
