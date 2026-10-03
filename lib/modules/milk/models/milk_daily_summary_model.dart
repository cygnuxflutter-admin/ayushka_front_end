/// Model for Daily Milk Balance Sheet & Summary
/// Endpoint: GET /api/v1/milk/daily-summary?gaushalaId={id}&date={YYYY-MM-DD}
class MilkDailySummaryModel {
  final String date;
  final String gaushalaId;
  final MilkProductionSummary production;
  final MilkDistributionSummary distribution;
  final MilkDisposalSummary disposal;
  final MilkStockBalanceSummary stockBalance;

  const MilkDailySummaryModel({
    this.date = '',
    this.gaushalaId = '',
    this.production = const MilkProductionSummary(),
    this.distribution = const MilkDistributionSummary(),
    this.disposal = const MilkDisposalSummary(),
    this.stockBalance = const MilkStockBalanceSummary(),
  });

  factory MilkDailySummaryModel.fromJson(Map<String, dynamic> json) {
    return MilkDailySummaryModel(
      date: json['date']?.toString() ?? '',
      gaushalaId: json['gaushalaId']?.toString() ?? '',
      production: json['production'] is Map<String, dynamic>
          ? MilkProductionSummary.fromJson(json['production'] as Map<String, dynamic>)
          : json['production'] is Map
              ? MilkProductionSummary.fromJson(Map<String, dynamic>.from(json['production'] as Map))
              : const MilkProductionSummary(),
      distribution: json['distribution'] is Map<String, dynamic>
          ? MilkDistributionSummary.fromJson(json['distribution'] as Map<String, dynamic>)
          : json['distribution'] is Map
              ? MilkDistributionSummary.fromJson(Map<String, dynamic>.from(json['distribution'] as Map))
              : const MilkDistributionSummary(),
      disposal: json['disposal'] is Map<String, dynamic>
          ? MilkDisposalSummary.fromJson(json['disposal'] as Map<String, dynamic>)
          : json['disposal'] is Map
              ? MilkDisposalSummary.fromJson(Map<String, dynamic>.from(json['disposal'] as Map))
              : const MilkDisposalSummary(),
      stockBalance: json['stockBalance'] is Map<String, dynamic>
          ? MilkStockBalanceSummary.fromJson(json['stockBalance'] as Map<String, dynamic>)
          : json['stockBalance'] is Map
              ? MilkStockBalanceSummary.fromJson(Map<String, dynamic>.from(json['stockBalance'] as Map))
              : const MilkStockBalanceSummary(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'gaushalaId': gaushalaId,
      'production': production.toJson(),
      'distribution': distribution.toJson(),
      'disposal': disposal.toJson(),
      'stockBalance': stockBalance.toJson(),
    };
  }

  MilkDailySummaryModel copyWith({
    String? date,
    String? gaushalaId,
    MilkProductionSummary? production,
    MilkDistributionSummary? distribution,
    MilkDisposalSummary? disposal,
    MilkStockBalanceSummary? stockBalance,
  }) {
    return MilkDailySummaryModel(
      date: date ?? this.date,
      gaushalaId: gaushalaId ?? this.gaushalaId,
      production: production ?? this.production,
      distribution: distribution ?? this.distribution,
      disposal: disposal ?? this.disposal,
      stockBalance: stockBalance ?? this.stockBalance,
    );
  }
}

class MilkProductionSummary {
  final double morningProduced;
  final double eveningProduced;
  final double totalProduced;
  final int morningCowsCount;
  final int eveningCowsCount;

  const MilkProductionSummary({
    this.morningProduced = 0.0,
    this.eveningProduced = 0.0,
    this.totalProduced = 0.0,
    this.morningCowsCount = 0,
    this.eveningCowsCount = 0,
  });

  int get totalCowsCount => morningCowsCount + eveningCowsCount;

  factory MilkProductionSummary.fromJson(Map<String, dynamic> json) {
    return MilkProductionSummary(
      morningProduced: _toDouble(json['morningProduced']),
      eveningProduced: _toDouble(json['eveningProduced']),
      totalProduced: _toDouble(json['totalProduced']),
      morningCowsCount: _toInt(json['morningCowsCount']),
      eveningCowsCount: _toInt(json['eveningCowsCount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'morningProduced': morningProduced,
      'eveningProduced': eveningProduced,
      'totalProduced': totalProduced,
      'morningCowsCount': morningCowsCount,
      'eveningCowsCount': eveningCowsCount,
    };
  }
}

class MilkDistributionSummary {
  final double morningDistributed;
  final double eveningDistributed;
  final double allDistributed;
  final double totalDistributed;
  final double totalRevenue;

  const MilkDistributionSummary({
    this.morningDistributed = 0.0,
    this.eveningDistributed = 0.0,
    this.allDistributed = 0.0,
    this.totalDistributed = 0.0,
    this.totalRevenue = 0.0,
  });

  factory MilkDistributionSummary.fromJson(Map<String, dynamic> json) {
    return MilkDistributionSummary(
      morningDistributed: _toDouble(json['morningDistributed']),
      eveningDistributed: _toDouble(json['eveningDistributed']),
      allDistributed: _toDouble(json['allDistributed']),
      totalDistributed: _toDouble(json['totalDistributed']),
      totalRevenue: _toDouble(json['totalRevenue']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'morningDistributed': morningDistributed,
      'eveningDistributed': eveningDistributed,
      'allDistributed': allDistributed,
      'totalDistributed': totalDistributed,
      'totalRevenue': totalRevenue,
    };
  }
}

class MilkDisposalSummary {
  final double totalDisposed;

  const MilkDisposalSummary({
    this.totalDisposed = 0.0,
  });

  factory MilkDisposalSummary.fromJson(Map<String, dynamic> json) {
    return MilkDisposalSummary(
      totalDisposed: _toDouble(json['totalDisposed']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalDisposed': totalDisposed,
    };
  }
}

class MilkStockBalanceSummary {
  final double morningAvailable;
  final double eveningAvailable;
  final double remainingFridgeMilk;

  const MilkStockBalanceSummary({
    this.morningAvailable = 0.0,
    this.eveningAvailable = 0.0,
    this.remainingFridgeMilk = 0.0,
  });

  factory MilkStockBalanceSummary.fromJson(Map<String, dynamic> json) {
    return MilkStockBalanceSummary(
      morningAvailable: _toDouble(json['morningAvailable']),
      eveningAvailable: _toDouble(json['eveningAvailable']),
      remainingFridgeMilk: _toDouble(json['remainingFridgeMilk']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'morningAvailable': morningAvailable,
      'eveningAvailable': eveningAvailable,
      'remainingFridgeMilk': remainingFridgeMilk,
    };
  }
}

double _toDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString()) ?? 0.0;
}

int _toInt(dynamic val) {
  if (val == null) return 0;
  if (val is num) return val.toInt();
  return int.tryParse(val.toString()) ?? 0;
}
