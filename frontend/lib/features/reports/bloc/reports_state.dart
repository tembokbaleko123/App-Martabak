import 'package:equatable/equatable.dart';

abstract class ReportsState extends Equatable {
  const ReportsState();

  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {}

class ReportsLoading extends ReportsState {}

class ReportsLoaded extends ReportsState {
  final DailyReport report;

  const ReportsLoaded(this.report);

  @override
  List<Object?> get props => [report];
}

class ReportsError extends ReportsState {
  final String message;

  const ReportsError(this.message);

  @override
  List<Object?> get props => [message];
}

class DailyReport {
  final DateTime date;
  final int totalTransaksi;
  final int totalPemasukan;
  final int rataRata;
  final int lunas;
  final int pending;
  final int expired;
  final List<KasirPerformance> perKasir;
  final List<TopMenu> topMenus;

  DailyReport({
    required this.date,
    required this.totalTransaksi,
    required this.totalPemasukan,
    required this.rataRata,
    required this.lunas,
    required this.pending,
    required this.expired,
    required this.perKasir,
    required this.topMenus,
  });

  factory DailyReport.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>;
    final perKasirList = (json['per_kasir'] as List<dynamic>?)
            ?.map((e) => KasirPerformance.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final topMenusList = (json['top_menus'] as List<dynamic>?)
            ?.map((e) => TopMenu.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return DailyReport(
      date: DateTime.parse(json['date'] as String),
      totalTransaksi: summary['total_transaksi'] as int? ?? 0,
      totalPemasukan: summary['total_pemasukan'] as int? ?? 0,
      rataRata: summary['rata_rata'] as int? ?? 0,
      lunas: summary['lunas'] as int? ?? 0,
      pending: summary['pending'] as int? ?? 0,
      expired: summary['expired'] as int? ?? 0,
      perKasir: perKasirList,
      topMenus: topMenusList,
    );
  }
}

class KasirPerformance {
  final int kasirId;
  final String name;
  final int transaksi;
  final int total;

  KasirPerformance({
    required this.kasirId,
    required this.name,
    required this.transaksi,
    required this.total,
  });

  factory KasirPerformance.fromJson(Map<String, dynamic> json) {
    return KasirPerformance(
      kasirId: json['kasir_id'] as int,
      name: json['name'] as String,
      transaksi: json['transaksi'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
    );
  }
}

class TopMenu {
  final int menuId;
  final String name;
  final String emoji;
  final int qty;
  final int total;

  TopMenu({
    required this.menuId,
    required this.name,
    required this.emoji,
    required this.qty,
    required this.total,
  });

  factory TopMenu.fromJson(Map<String, dynamic> json) {
    return TopMenu(
      menuId: json['menu_id'] as int,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '🥞',
      qty: json['qty'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
    );
  }
}
