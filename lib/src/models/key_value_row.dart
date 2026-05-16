import 'dart:typed_data';

import 'package:posty/src/models/posty_enums.dart';

class KeyValueRow {
  const KeyValueRow({
    this.key = '',
    this.value = '',
    this.enabled = true,
    this.formValueType = FormValueType.text,
    this.filePath,
    this.fileName,
    this.fileBytes,
  });

  final String key;
  final String value;
  final bool enabled;
  /// Used for [BodyType.form] rows only.
  final FormValueType formValueType;
  final String? filePath;
  final String? fileName;
  /// In-memory file payload (e.g. web picker); not persisted in [toJson].
  final Uint8List? fileBytes;

  bool get hasFile =>
      formValueType == FormValueType.file &&
      ((filePath != null && filePath!.isNotEmpty) ||
          (fileBytes != null && fileBytes!.isNotEmpty));

  KeyValueRow copyWith({
    String? key,
    String? value,
    bool? enabled,
    FormValueType? formValueType,
    String? filePath,
    String? fileName,
    Uint8List? fileBytes,
    bool clearFile = false,
  }) {
    return KeyValueRow(
      key: key ?? this.key,
      value: value ?? this.value,
      enabled: enabled ?? this.enabled,
      formValueType: formValueType ?? this.formValueType,
      filePath: clearFile ? null : (filePath ?? this.filePath),
      fileName: clearFile ? null : (fileName ?? this.fileName),
      fileBytes: clearFile ? null : (fileBytes ?? this.fileBytes),
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'value': value,
        'enabled': enabled,
        'formValueType': formValueType.name,
        if (filePath != null) 'filePath': filePath,
        if (fileName != null) 'fileName': fileName,
      };

  factory KeyValueRow.fromJson(Map<String, dynamic> json) {
    final typeName = json['formValueType'] as String?;
    final formValueType = typeName == null
        ? FormValueType.text
        : FormValueType.values.firstWhere(
            (e) => e.name == typeName,
            orElse: () => FormValueType.text,
          );
    return KeyValueRow(
      key: json['key'] as String? ?? '',
      value: json['value'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      formValueType: formValueType,
      filePath: json['filePath'] as String?,
      fileName: json['fileName'] as String?,
    );
  }
}
