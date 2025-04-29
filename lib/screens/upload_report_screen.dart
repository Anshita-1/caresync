import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';

/// Sorting criteria for report list
enum SortCriterion { nameAsc, dateAsc, dateDesc, sizeAsc, sizeDesc }

/// File type filter options
enum FilterType { all, images, pdf }

class UploadReportScreen extends StatefulWidget {
  const UploadReportScreen({Key? key}) : super(key: key);

  @override
  State<UploadReportScreen> createState() => _UploadReportScreenState();
}

class _UploadReportScreenState extends State<UploadReportScreen> {
  final TextEditingController _reportNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<FileSystemEntity> _reports = [];
  List<FileSystemEntity> _filteredReports = [];
  late Directory _reportsDirectory;
  bool _isUploading = false;
  SortCriterion _currentSort = SortCriterion.nameAsc;
  FilterType _currentFilter = FilterType.all;

  @override
  void initState() {
    super.initState();
    _initializeReportsDirectory();
    _searchController.addListener(_applyFiltering);
  }

  @override
  void dispose() {
    _reportNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeReportsDirectory() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    _reportsDirectory = Directory('${appDocDir.path}/reports');
    if (!await _reportsDirectory.exists()) {
      await _reportsDirectory.create(recursive: true);
    }
    await _refreshReportList();
  }

  Future<void> _refreshReportList() async {
    final files = _reportsDirectory.listSync();
    setState(() {
      _reports = files;
      _applyFiltering();
    });
  }

  void _applyFiltering() {
    String query = _searchController.text.toLowerCase();
    List<FileSystemEntity> temp = _reports.where((file) {
      String name = file.path.split(Platform.pathSeparator).last.toLowerCase();
      if (!name.contains(query)) return false;
      if (_currentFilter == FilterType.images) {
        return ['.png', '.jpg', '.jpeg', '.gif']
            .any((ext) => name.endsWith(ext));
      } else if (_currentFilter == FilterType.pdf) {
        return name.endsWith('.pdf');
      }
      return true;
    }).toList();

    temp.sort((a, b) {
      FileStat statA = a.statSync();
      FileStat statB = b.statSync();
      switch (_currentSort) {
        case SortCriterion.nameAsc:
          return a.path.compareTo(b.path);
        case SortCriterion.dateAsc:
          return statA.modified.compareTo(statB.modified);
        case SortCriterion.dateDesc:
          return statB.modified.compareTo(statA.modified);
        case SortCriterion.sizeAsc:
          return statA.size.compareTo(statB.size);
        case SortCriterion.sizeDesc:
          return statB.size.compareTo(statA.size);
      }
    });

    setState(() => _filteredReports = temp);
  }

  Future<void> _uploadReport() async {
    if (_reportNameController.text.trim().isEmpty) {
      _showPopup('Error', 'Please enter a report name.');
      return;
    }
    setState(() => _isUploading = true);
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      String orig = result.files.single.path!;
      String ext = orig.substring(orig.lastIndexOf('.'));
      String name = _reportNameController.text.trim() + ext;
      File dest = File('${_reportsDirectory.path}/$name');
      try {
        await File(orig).copy(dest.path);
        _showPopup('Success', 'Uploaded successfully.');
        _reportNameController.clear();
        await _refreshReportList();
      } catch (e) {
        _showPopup('Error', 'Upload failed: $e');
      }
    } else {
      _showPopup('Cancelled', 'No file selected.');
    }
    setState(() => _isUploading = false);
  }

  Future<void> _deleteReport(FileSystemEntity file) async {
    String name = file.path.split(Platform.pathSeparator).last;
    try {
      await file.delete();
      await _refreshReportList();
      _showPopup('Deleted', '$name removed.');
    } catch (e) {
      _showPopup('Error', 'Delete failed: $e');
    }
  }

  Future<void> _renameReport(FileSystemEntity file) async {
    String oldName = file.path.split(Platform.pathSeparator).last;
    String base = oldName.contains('.')
        ? oldName.substring(0, oldName.lastIndexOf('.'))
        : oldName;
    String ext = oldName.contains('.')
        ? oldName.substring(oldName.lastIndexOf('.'))
        : '';
    TextEditingController ctrl = TextEditingController(text: base);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              String newName = ctrl.text.trim() + ext;
              try {
                await File(file.path)
                    .rename('${_reportsDirectory.path}/$newName');
                Navigator.pop(context);
                await _refreshReportList();
              } catch (_) {
                Navigator.pop(context);
                _showPopup('Error', 'Rename failed.');
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showPopup(String title, String msg) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => Center(
        child: Material(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(20),
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(msg),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTile(FileSystemEntity file) {
    String name = file.path.split(Platform.pathSeparator).last;
    FileStat stat = file.statSync();
    String date = DateFormat('yyyy-MM-dd HH:mm').format(stat.modified);
    String size;
    if (stat.size < 1024) {
      size = '${stat.size} B';
    } else if (stat.size < 1024 * 1024) {
      size = '${(stat.size / 1024).toStringAsFixed(1)} KB';
    } else {
      size = '${(stat.size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    bool isImage = ['.png', '.jpg', '.jpeg', '.gif']
        .any((ext) => name.toLowerCase().endsWith(ext));

    return ListTile(
      leading: isImage
          ? Image.file(File(file.path), width: 50, height: 50, fit: BoxFit.cover)
          : const Icon(Icons.insert_drive_file, size: 50),
      title: Text(name),
      subtitle: Text('$date • $size'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () => _renameReport(file)),
          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteReport(file)),
        ],
      ),
      onTap: () => OpenFile.open(file.path),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _reportNameController,
                          decoration: const InputDecoration(
                            labelText: 'Report Name',
                            prefixIcon: Icon(Icons.note),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _isUploading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                          onPressed: _uploadReport,
                          child: const Text('Upload'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<FilterType>(
                      value: _currentFilter,
                      items: const [
                        DropdownMenuItem(value: FilterType.all, child: Text('All')),
                        DropdownMenuItem(value: FilterType.images, child: Text('Images')),
                        DropdownMenuItem(value: FilterType.pdf, child: Text('PDFs')),
                      ],
                      onChanged: (v) => setState(() {
                        _currentFilter = v!;
                        _applyFiltering();
                      }),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<SortCriterion>(
                      value: _currentSort,
                      items: const [
                        DropdownMenuItem(value: SortCriterion.nameAsc, child: Text('Name ↑')),
                        DropdownMenuItem(value: SortCriterion.dateAsc, child: Text('Date ↑')),
                        DropdownMenuItem(value: SortCriterion.dateDesc, child: Text('Date ↓')),
                        DropdownMenuItem(value: SortCriterion.sizeAsc, child: Text('Size ↑')),
                        DropdownMenuItem(value: SortCriterion.sizeDesc, child: Text('Size ↓')),
                      ],
                      onChanged: (v) => setState(() {
                        _currentSort = v!;
                        _applyFiltering();
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _filteredReports.isEmpty
                      ? const Center(child: Text('No reports found.', style: TextStyle(color: Colors.white)))
                      : ListView.separated(
                    itemCount: _filteredReports.length,
                    separatorBuilder: (_, __) => Divider(color: Colors.white54),
                    itemBuilder: (_, i) => _buildTile(_filteredReports[i]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
