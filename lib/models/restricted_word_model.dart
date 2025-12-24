/// Restricted Word Model - Represents a word that is restricted for a specific child
class RestrictedWord {
  final String id;
  final String childId;
  final String word;
  final DateTime createdAt;

  RestrictedWord({
    required this.id,
    required this.childId,
    required this.word,
    required this.createdAt,
  });

  /// Create RestrictedWord from JSON
  factory RestrictedWord.fromJson(Map<String, dynamic> json) {
    return RestrictedWord(
      id: json['id']?.toString() ?? '',
      childId: json['child']?.toString() ?? '',
      word: json['word'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Convert RestrictedWord to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'child': childId,
      'word': word,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Restricted Words List Model - Represents a list of restricted words for a child
class RestrictedWordsList {
  final String childId;
  final List<RestrictedWord> words;

  RestrictedWordsList({required this.childId, required this.words});

  /// Create RestrictedWordsList from JSON
  factory RestrictedWordsList.fromJson(Map<String, dynamic> json) {
    final wordsList =
        (json['words'] as List<dynamic>?)
            ?.map(
              (item) => RestrictedWord.fromJson(item as Map<String, dynamic>),
            )
            .toList() ??
        [];

    return RestrictedWordsList(
      childId: json['child_id']?.toString() ?? '',
      words: wordsList,
    );
  }

  /// Convert RestrictedWordsList to JSON
  Map<String, dynamic> toJson() {
    return {
      'child_id': childId,
      'words': words.map((word) => word.toJson()).toList(),
    };
  }
}
