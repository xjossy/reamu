/// Convert YamlMap to Map<String, dynamic> recursively
/// Handles nested maps and lists from yaml package
dynamic convertYamlToJson(dynamic data) {
  if (data is Map) {
    // Convert map recursively
    final result = <String, dynamic>{};
    for (final entry in data.entries) {
      result[entry.key.toString()] = convertYamlToJson(entry.value);
    }
    return result;
  } else if (data is List) {
    // Convert list recursively
    return data.map(convertYamlToJson).toList();
  } else {
    // Return primitive values as-is
    return data;
  }
}
