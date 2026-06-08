typedef JsonMap = Map<String, dynamic>;

extension JsonReader on JsonMap {
  int readInt(String key) {
    final value = this[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    throw FormatException('Expected "$key" to be a number.');
  }

  String readString(String key) {
    final value = this[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    throw FormatException('Expected "$key" to be a non-empty string.');
  }

  JsonMap readObject(String key) {
    final value = this[key];
    if (value is JsonMap) {
      return value;
    }
    throw FormatException('Expected "$key" to be an object.');
  }
}
