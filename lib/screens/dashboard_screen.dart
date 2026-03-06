import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../widgets/data_card.dart';
import '../widgets/section_title.dart';

class DashboardScreen extends StatefulWidget {
  final double temperature;
  final double humidity;

  const DashboardScreen({
    super.key,
    required this.temperature,
    required this.humidity,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isDownloading = false;

  Future<void> _downloadCsv() async {
    setState(() => _isDownloading = true);
    try {
      if (!kIsWeb) {
        _showSnackBar("CSV download is only supported on web.");
        return;
      }
      final snapshot = await FirebaseDatabase.instance.ref('historical_data').get();
      if (!snapshot.exists) {
        _showSnackBar("No historical data to download.");
        return;
      }
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      List<String> csvRows = ['Timestamp,Temperature,Humidity'];
      data.forEach((key, value) {
        final record = Map<String, dynamic>.from(value as Map);
        final dt = DateTime.fromMillisecondsSinceEpoch(record['timestamp']);
        final formattedDate = dt.toIso8601String().substring(0, 19).replaceFirst('T', ' ');
        csvRows.add('$formattedDate,${record['temperature']},${record['humidity']}');
      });
      
      final csvString = csvRows.join('\n');
      final bytes = utf8.encode(csvString);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "smart_farm_report.csv")
        ..click();
      html.Url.revokeObjectUrl(url);

    } catch (e) {
      _showSnackBar("Error: $e");
    } finally {
      if(mounted) setState(() => _isDownloading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFD73A49),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Row(
          children: [
            Expanded(child: DataCard('Temperature', '${widget.temperature.toStringAsFixed(1)} °C', Icons.thermostat_rounded, const Color(0xFFFFA500))),
            const SizedBox(width: 16),
            Expanded(child: DataCard('Humidity', '${widget.humidity.toStringAsFixed(1)} %', Icons.water_drop_outlined, const Color(0xFF1E90FF))),
          ],
        ),
        const SizedBox(height: 24),
        const SectionTitle('Data Reports'),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _isDownloading ? null : _downloadCsv,
          icon: _isDownloading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.download_for_offline_outlined),
          label: Text(_isDownloading ? 'Downloading...' : 'Download Historical Data (CSV)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF238636),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}
