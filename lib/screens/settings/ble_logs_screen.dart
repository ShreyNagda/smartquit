import 'package:breathe_free/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../services/ble_logs_service.dart';
import '../../models/ble_log_entry.dart';

class BleLogsScreen extends StatefulWidget {
  const BleLogsScreen({super.key});

  @override
  State<BleLogsScreen> createState() => _BleLogsScreenState();
}

class _BleLogsScreenState extends State<BleLogsScreen> {
  final BleLogsService _logsService = BleLogsService();
  List<BleLogEntry> _logs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    setState(() {
      _logs = _logsService.getAllLogs();
    });
  }

  Future<void> _generatePdf() async {
    setState(() => _isLoading = true);

    try {
      final pdf = pw.Document();
      final dateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');

      // Split logs into chunks for pagination
      const rowsPerPage = 30;
      final totalPages = (_logs.length / rowsPerPage).ceil();

      for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
        final startIndex = pageIndex * rowsPerPage;
        final endIndex = (startIndex + rowsPerPage > _logs.length)
            ? _logs.length
            : startIndex + rowsPerPage;
        final pageLogs = _logs.sublist(startIndex, endIndex);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4.landscape,
            build: (context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Title
                  pw.Text(
                    'SmartQuit Band - BLE Data Logs',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Generated: ${dateFormatter.format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Page ${pageIndex + 1} of $totalPages',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 16),

                  // Data table
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey400),
                    columnWidths: {
                      0: const pw.FixedColumnWidth(80),
                      1: const pw.FixedColumnWidth(40),
                      2: const pw.FixedColumnWidth(40),
                      3: const pw.FixedColumnWidth(40),
                      4: const pw.FixedColumnWidth(40),
                      5: const pw.FixedColumnWidth(40),
                      6: const pw.FixedColumnWidth(40),
                      7: const pw.FixedColumnWidth(50),
                      8: const pw.FixedColumnWidth(50),
                    },
                    children: [
                      // Header row
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey300,
                        ),
                        children: [
                          _pdfCell('Timestamp', isHeader: true),
                          _pdfCell('AccX', isHeader: true),
                          _pdfCell('AccY', isHeader: true),
                          _pdfCell('AccZ', isHeader: true),
                          _pdfCell('GyroX', isHeader: true),
                          _pdfCell('GyroY', isHeader: true),
                          _pdfCell('GyroZ', isHeader: true),
                          _pdfCell('MQ9 PPM', isHeader: true),
                          _pdfCell('Prediction', isHeader: true),
                        ],
                      ),
                      // Data rows
                      ...pageLogs.map((log) {
                        return pw.TableRow(
                          children: [
                            _pdfCell(dateFormatter.format(log.timestamp)),
                            _pdfCell(log.accX.toStringAsFixed(2)),
                            _pdfCell(log.accY.toStringAsFixed(2)),
                            _pdfCell(log.accZ.toStringAsFixed(2)),
                            _pdfCell(log.gyroX.toStringAsFixed(2)),
                            _pdfCell(log.gyroY.toStringAsFixed(2)),
                            _pdfCell(log.gyroZ.toStringAsFixed(2)),
                            _pdfCell(log.mq9Ppm.toStringAsFixed(2)),
                            _pdfCell(log.prediction.toString()),
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      }

      // Save PDF to temporary directory and share
      try {
        final bytes = await pdf.save();
        final dir = await getTemporaryDirectory();
        final fileName = 'SmartQuit_BLE_Logs_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);

        // Share the PDF file
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'SmartQuit BLE Logs Export',
          subject: fileName,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error sharing PDF: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }catch(e){
      print('Error generating PDF: $e');
    }
  }

  pw.Widget _pdfCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 8 : 7,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  void _clearLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Logs'),
        content: const Text('Are you sure you want to clear all logs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _logsService.clearLogs();
              _loadLogs();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logs cleared')),
              );
            },
            child:
                const Text('Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('MMM dd, HH:mm:ss');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'BLE Logs',
          style:
              TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _logs.isEmpty ? null : _clearLogs,
            tooltip: 'Clear logs',
          ),
        ],
      ),
      body: _logs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bluetooth_disabled,
                    size: 64,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No logs available',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Connect to SmartQuit Band to start logging',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Summary header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.surface,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Entries: ${_logs.length}',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _generatePdf,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.picture_as_pdf, size: 18),
                        label:
                            Text(_isLoading ? 'Generating...' : 'Export PDF'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Data table
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 16,
                        headingRowColor: MaterialStateProperty.all(
                          AppColors.surface,
                        ),
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Time',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'AccX',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'AccY',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'AccZ',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'GyroX',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'GyroY',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'GyroZ',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'MQ9 PPM',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Prediction',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        rows: _logs.reversed.map((log) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  dateFormatter.format(log.timestamp),
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  log.accX.toStringAsFixed(2),
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  log.accY.toStringAsFixed(2),
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  log.accZ.toStringAsFixed(2),
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  log.gyroX.toStringAsFixed(2),
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  log.gyroY.toStringAsFixed(2),
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  log.gyroZ.toStringAsFixed(2),
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: log.mq9Ppm > 30
                                        ? AppColors.error.withOpacity(0.2)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    log.mq9Ppm.toStringAsFixed(2),
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 11,
                                      fontWeight: log.mq9Ppm > 30
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: log.mq9Ppm > 30
                                          ? AppColors.error
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: log.prediction == 1
                                        ? AppColors.error.withOpacity(0.2)
                                        : AppColors.success.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    log.prediction == 1 ? 'Smoking' : 'Normal',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: log.prediction == 1
                                          ? AppColors.error
                                          : AppColors.success,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
