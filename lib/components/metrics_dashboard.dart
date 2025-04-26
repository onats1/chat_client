import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chat_provider.dart';
import 'dart:async';

class MetricsDashboard extends StatefulWidget {
  const MetricsDashboard({Key? key}) : super(key: key);

  @override
  State<MetricsDashboard> createState() => _MetricsDashboardState();
}

class _MetricsDashboardState extends State<MetricsDashboard> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Refresh metrics every second
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final metricsService = chatProvider.metricsService;
        final currentProtocol = chatProvider.currentProtocol == ChatProtocol.grpc ? 'grpc' : 'websocket';
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance Metrics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildMetricRow(
                  'Average Latency',
                  '${metricsService.getAverageLatency(currentProtocol).toStringAsFixed(2)} ms',
                ),
                _buildMetricRow(
                  'Message Throughput',
                  '${metricsService.getMessageThroughput(currentProtocol).toStringAsFixed(2)} msg/s',
                ),
                _buildMetricRow(
                  'Average Message Size',
                  '${metricsService.getAverageMessageSize(currentProtocol).toStringAsFixed(2)} bytes',
                ),
                _buildMetricRow(
                  'Connection Time',
                  '${metricsService.getAverageConnectionTime(currentProtocol).toStringAsFixed(2)} ms',
                ),
                _buildMetricRow(
                  'Disconnections',
                  '${metricsService.disconnectionCount[currentProtocol] ?? 0}',
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        metricsService.clearMetrics();
                        setState(() {});
                      },
                      child: const Text('Reset Metrics'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
} 