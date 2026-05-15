class KeyValueRow {
  const KeyValueRow({
    this.key = '',
    this.value = '',
    this.enabled = true,
  });

  final String key;
  final String value;
  final bool enabled;

  KeyValueRow copyWith({
    String? key,
    String? value,
    bool? enabled,
  }) {
    return KeyValueRow(
      key: key ?? this.key,
      value: value ?? this.value,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'value': value,
        'enabled': enabled,
      };

  factory KeyValueRow.fromJson(Map<String, dynamic> json) {
    return KeyValueRow(
      key: json['key'] as String? ?? '',
      value: json['value'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}
