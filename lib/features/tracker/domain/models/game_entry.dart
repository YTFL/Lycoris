import 'additional_expense.dart';
import 'game_status.dart';
import 'storefront.dart';

class GameEntry {
  final String id;
  final int igdbId;
  final String title;
  final String? coverUrl;
  final List<String> genres;
  final Storefront storefront;
  final GameStatus status;

  // Time tracking (Canonical normalized minutes)
  final int totalMinutesPlayed;

  // Financials
  final double basePrice;
  final String currency;
  final List<AdditionalExpense> additionalExpenses;

  // Personal score & Journal
  final double personalRating;
  final String notes;

  // Timestamps & Sync
  final DateTime addedAt;
  final DateTime? completedAt;
  final DateTime updatedAt;

  // Custom / Manual Entry Flags
  final bool isCustomEntry;
  final String? customCoverPath;

  GameEntry({
    required this.id,
    required this.igdbId,
    required this.title,
    this.coverUrl,
    required this.genres,
    required this.storefront,
    required this.status,
    this.totalMinutesPlayed = 0,
    this.basePrice = 0.0,
    this.currency = 'USD',
    List<AdditionalExpense>? additionalExpenses,
    this.personalRating = 0.0,
    this.notes = '',
    required this.addedAt,
    this.completedAt,
    required this.updatedAt,
    this.isCustomEntry = false,
    this.customCoverPath,
  }) : additionalExpenses = additionalExpenses ?? [];

  /// Total capital invested (Base price + all itemized DLC / expenses)
  double get totalSpent {
    final extras = additionalExpenses.fold<double>(0.0, (acc, item) => acc + item.amount);
    return basePrice + extras;
  }

  /// Exact cost per hour of entertainment, or null if unplayed/free
  double? get costPerHour {
    if (totalSpent <= 0.0 || totalMinutesPlayed <= 0) return null;
    final hours = totalMinutesPlayed / 60.0;
    return totalSpent / hours;
  }

  /// Total playtime represented in hours
  double get hoursPlayed => totalMinutesPlayed / 60.0;

  /// Helper factory to create composite ID
  static String generateId({
    required int igdbId,
    required Storefront storefront,
    String? customUuid,
  }) {
    if (igdbId > 0) {
      return 'igdb_${igdbId}_${storefront.name}';
    }
    return 'custom_${customUuid ?? DateTime.now().millisecondsSinceEpoch}_${storefront.name}';
  }

  GameEntry copyWith({
    String? id,
    int? igdbId,
    String? title,
    String? coverUrl,
    List<String>? genres,
    Storefront? storefront,
    GameStatus? status,
    int? totalMinutesPlayed,
    double? basePrice,
    String? currency,
    List<AdditionalExpense>? additionalExpenses,
    double? personalRating,
    String? notes,
    DateTime? addedAt,
    DateTime? completedAt,
    DateTime? updatedAt,
    bool? isCustomEntry,
    String? customCoverPath,
  }) {
    return GameEntry(
      id: id ?? this.id,
      igdbId: igdbId ?? this.igdbId,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      genres: genres ?? this.genres,
      storefront: storefront ?? this.storefront,
      status: status ?? this.status,
      totalMinutesPlayed: totalMinutesPlayed ?? this.totalMinutesPlayed,
      basePrice: basePrice ?? this.basePrice,
      currency: currency ?? this.currency,
      additionalExpenses: additionalExpenses ?? List.from(this.additionalExpenses),
      personalRating: personalRating ?? this.personalRating,
      notes: notes ?? this.notes,
      addedAt: addedAt ?? this.addedAt,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCustomEntry: isCustomEntry ?? this.isCustomEntry,
      customCoverPath: customCoverPath ?? this.customCoverPath,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'igdbId': igdbId,
    'title': title,
    'coverUrl': coverUrl,
    'genres': genres,
    'storefront': storefront.index,
    'status': status.index,
    'totalMinutesPlayed': totalMinutesPlayed,
    'basePrice': basePrice,
    'currency': currency,
    'additionalExpenses': additionalExpenses.map((e) => e.toJson()).toList(),
    'personalRating': personalRating,
    'notes': notes,
    'addedAt': addedAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isCustomEntry': isCustomEntry,
    'customCoverPath': customCoverPath,
  };

  factory GameEntry.fromJson(Map<String, dynamic> json) => GameEntry(
    id: json['id'] as String,
    igdbId: json['igdbId'] as int? ?? 0,
    title: json['title'] as String,
    coverUrl: json['coverUrl'] as String?,
    genres: (json['genres'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    storefront: Storefront.values[json['storefront'] as int? ?? 0],
    status: GameStatus.values[json['status'] as int? ?? 0],
    totalMinutesPlayed: json['totalMinutesPlayed'] as int? ?? 0,
    basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0.0,
    currency: json['currency'] as String? ?? 'USD',
    additionalExpenses: (json['additionalExpenses'] as List<dynamic>?)
        ?.map((e) => AdditionalExpense.fromJson(e as Map<String, dynamic>))
        .toList(),
    personalRating: (json['personalRating'] as num?)?.toDouble() ?? 0.0,
    notes: json['notes'] as String? ?? '',
    addedAt: DateTime.parse(json['addedAt'] as String),
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : DateTime.parse(json['addedAt'] as String),
    isCustomEntry: json['isCustomEntry'] as bool? ?? false,
    customCoverPath: json['customCoverPath'] as String?,
  );
}
