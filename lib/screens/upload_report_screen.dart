import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

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

  // Initialize or create the local "reports" directory.
  Future<void> _initializeReportsDirectory() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    _reportsDirectory = Directory('${appDocDir.path}/reports');
    if (!(await _reportsDirectory.exists())) {
      await _reportsDirectory.create(recursive: true);
    }
    await _refreshReportList();
  }

  // Refresh the list of saved reports.
  Future<void> _refreshReportList() async {
    final reports = _reportsDirectory.listSync();
    setState(() {
      _reports = reports;
      _applyFiltering();
    });
  }

  // Apply search filter on the list of reports.
  void _applyFiltering() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredReports = _reports.where((file) {
        String fileName = file.path.split(Platform.pathSeparator).last;
        return fileName.toLowerCase().contains(query);
      }).toList();
    });
  }

  // Handle file selection, renaming, and storing locally.
  Future<void> _uploadReport() async {
    if (_reportNameController.text.trim().isEmpty) {
      _showCustomPopup(title: "Error", message: "Please enter a report name.");
      return;
    }
    setState(() => _isUploading = true);
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      String originalPath = result.files.single.path!;
      String extension = originalPath.substring(originalPath.lastIndexOf('.'));
      String newName = _reportNameController.text.trim() + extension;
      File newFile = File('${_reportsDirectory.path}/$newName');
      try {
        await File(originalPath).copy(newFile.path);
        _showCustomPopup(title: "Success", message: "Report uploaded successfully.");
        _reportNameController.clear();
        await _refreshReportList();
      } catch (e) {
        _showCustomPopup(title: "Error", message: "Failed to upload report.\n$e");
      }
    } else {
      // User canceled file selection.
      _showCustomPopup(title: "Cancelled", message: "No file selected.");
    }
    setState(() => _isUploading = false);
  }

  // Delete a report file after confirmation.
  Future<void> _deleteReport(FileSystemEntity file) async {
    String fileName = file.path.split(Platform.pathSeparator).last;
    try {
      await file.delete();
      await _refreshReportList();
      _showCustomPopup(title: "Deleted", message: "$fileName has been deleted.");
    } catch (e) {
      _showCustomPopup(title: "Error", message: "Failed to delete report:\n$e");
    }
  }

  // Custom animated pop-up dialog for notifications.
  Future<void> _showCustomPopup({required String title, required String message}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Popup",
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("OK"),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }

  // Build file list tile with thumbnail preview for images.
  Widget _buildFileTile(FileSystemEntity file) {
    String fileName = file.path.split(Platform.pathSeparator).last;
    bool isImage = fileName.toLowerCase().endsWith('.png') ||
        fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg') ||
        fileName.toLowerCase().endsWith('.gif');
    return ListTile(
      leading: isImage
          ? Image.file(
        File(file.path),
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      )
          : const Icon(Icons.insert_drive_file, size: 50),
      title: Text(fileName),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => _deleteReport(file),
      ),
      onTap: () {
        // Optionally, implement file preview functionality here.
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradient background consistent with the theme.
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Upload Form Card with refined UI.
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.white, Color(0xFFF2F8FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white70, width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _reportNameController,
                            decoration: InputDecoration(
                              labelText: "Enter the report name to upload.",
                              prefixIcon: const Icon(Icons.note),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _isUploading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                            onPressed: _uploadReport,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              minimumSize: const Size(double.infinity, 50),
                              textStyle: const TextStyle(fontSize: 18),
                            ),
                            child: const Text("Upload Report"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Search Bar for filtering reports.
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: "Search Reports",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // List of uploaded reports.
                _filteredReports.isEmpty
                    ? const Center(
                  child: Text(
                    "No reports found.",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                )
                    : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredReports.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.white70),
                  itemBuilder: (context, index) {
                    final file = _filteredReports[index];
                    return _buildFileTile(file);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
