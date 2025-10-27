import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../services/global_memory_service.dart';
import '../core/debug_config.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  final GlobalMemoryService _memoryService = GlobalMemoryService.instance;
  Map<String, dynamic> _progressData = {};
  bool _isLoading = true;
  String _selectedTab = '';
  List<String> _tabs = [];

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _memoryService.getRawData();
      
      setState(() {
        _progressData = data;
        _tabs = data.keys.toList();
        _selectedTab = _tabs.isNotEmpty ? _tabs.first : '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _progressData = {'error': e.toString()};
        _tabs = ['error'];
        _selectedTab = 'error';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!DebugConfig.debugMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('Debug Mode Disabled')),
        body: const Center(
          child: Text('Debug mode is disabled in this build'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Memory Service Debug'),
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProgressData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyToClipboard,
            tooltip: 'Copy JSON',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.grey[800],
      height: 50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _tabs.map((tab) {
            final isSelected = _selectedTab == tab;
            return GestureDetector(
              onTap: () => setState(() => _selectedTab = tab),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.orange : Colors.transparent,
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? Colors.orange : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  tab,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[300],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedTab.isEmpty || !_progressData.containsKey(_selectedTab)) {
      return const Center(
        child: Text('No data', style: TextStyle(color: Colors.white)),
      );
    }

    final tabData = _progressData[_selectedTab];
    if (tabData is Map<String, dynamic>) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: _JsonTreeViewer(data: tabData),
      );
    } else {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Text(
          tabData.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'monospace',
          ),
        ),
      );
    }
  }

  void _copyToClipboard() {
    if (_selectedTab.isEmpty) return;
    
    final tabData = _progressData[_selectedTab];
    final jsonString = tabData is Map
        ? const JsonEncoder.withIndent('  ').convert(tabData)
        : tabData.toString();
    
    Clipboard.setData(ClipboardData(text: jsonString));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$_selectedTab data copied to clipboard')),
    );
  }
}

/// Recursive JSON tree viewer widget
class _JsonTreeViewer extends StatefulWidget {
  final Map<String, dynamic> data;
  final int level;

  const _JsonTreeViewer({
    required this.data,
    this.level = 0,
  });

  @override
  State<_JsonTreeViewer> createState() => _JsonTreeViewerState();
}

class _JsonTreeViewerState extends State<_JsonTreeViewer> {
  late Map<String, bool> _expandedState;

  @override
  void initState() {
    super.initState();
    _expandedState = {};
    for (final key in widget.data.keys) {
      _expandedState[key] = widget.level < 2; // Auto-expand first 2 levels
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.data.entries.map((entry) {
        return _buildEntry(entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildEntry(String key, dynamic value) {
    final isExpanded = _expandedState[key] ?? false;
    final isMap = value is Map<String, dynamic>;
    final isList = value is List;
    final isExpandable = isMap || isList;

    if (!isExpandable) {
      return Padding(
        padding: EdgeInsets.only(left: widget.level * 16.0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: RichText(
            textAlign: TextAlign.left,
            text: TextSpan(
              children: [
                TextSpan(
                  text: key,
                  style: const TextStyle(
                    color: Colors.cyan,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(
                  text: ': ',
                  style: TextStyle(color: Colors.white, fontFamily: 'monospace'),
                ),
                TextSpan(
                  text: _formatValue(value),
                  style: TextStyle(
                    color: _getValueColor(value),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(left: widget.level * 16.0, top: 4),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: (value) {
            setState(() {
              _expandedState[key] = value;
            });
          },
          title: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: key,
                  style: const TextStyle(
                    color: Colors.cyan,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: isMap
                      ? ' (${value.length} items)'
                      : ' (${value.length} items)',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 8),
          children: [
            if (isMap)
              _JsonTreeViewer(
                data: value,
                level: widget.level + 1,
              )
            else
              ...value.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    left: (widget.level + 1) * 16.0,
                    top: 4,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: RichText(
                      textAlign: TextAlign.left,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '[$index]',
                            style: const TextStyle(
                              color: Colors.yellow,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(
                            text: ': ',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'monospace',
                            ),
                          ),
                          TextSpan(
                            text: _formatValue(item),
                            style: TextStyle(
                              color: _getValueColor(item),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) {
      return 'null';
    } else if (value is bool) {
      return value.toString();
    } else if (value is num) {
      return value.toString();
    } else if (value is String) {
      return '"$value"';
    } else if (value is List) {
      return '[List (${value.length})]';
    } else if (value is Map) {
      return '{Map (${value.length})}';
    }
    return value.toString();
  }

  Color _getValueColor(dynamic value) {
    if (value == null) {
      return Colors.grey;
    } else if (value is bool) {
      return Colors.orange;
    } else if (value is num) {
      return Colors.lightGreen;
    } else if (value is String) {
      return Colors.lightBlue;
    }
    return Colors.white;
  }
}
