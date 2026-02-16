import '../models/ble_log_entry.dart';

class BleLogsService {
  static final BleLogsService _instance = BleLogsService._internal();
  factory BleLogsService() => _instance;
  BleLogsService._internal();

  final List<BleLogEntry> _logs = [];
  static const int maxLogs = 1000; // Keep only last 1000 entries

  void addLog(BleLogEntry entry) {
    _logs.add(entry);

    // Keep only the most recent entries
    if (_logs.length > maxLogs) {
      _logs.removeAt(0);
    }
  }

  List<BleLogEntry> getAllLogs() {
    return List.unmodifiable(_logs);
  }

  void clearLogs() {
    _logs.clear();
  }

  int get logCount => _logs.length;
}
