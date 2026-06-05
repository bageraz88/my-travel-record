import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:printing/printing.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'main_record_tile.dart';
import 'splash_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  await Hive.openBox('records');
  await Hive.openBox<Uint8List>('images');
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Travel Record',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _themeMode,
      home: SplashScreen(
        themeMode: _themeMode,
        onThemeModeChanged: _setThemeMode,
      ),
    );
  }
}

class TravelRecordPage extends StatefulWidget {
  const TravelRecordPage({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<TravelRecordPage> createState() => _TravelRecordPageState();
}

class _TravelRecordPageState extends State<TravelRecordPage> {
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  String _distanceType = 'Departure';
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImage;
  DateTime? _time;
  String? _existingImageId;

  bool _isSaving = false;
  List<TravelRecord> _records = [];
  TravelRecord? _editingRecord;

  final Box _recordsBox = Hive.box('records');
  final Box<Uint8List> _imagesBox = Hive.box<Uint8List>('images');

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    try {
      final List<dynamic> jsonList = _recordsBox.get('list', defaultValue: []) as List<dynamic>;
      _safeSetState(() {
        _records = jsonList
            .map((dynamic item) => TravelRecord.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        _records.sort((a, b) => a.time.compareTo(b.time));
      });
    } catch (e) {
      debugPrint('Error loading records: $e');
    }
  }

  Future<void> _saveRecordsToBox() async {
    await _recordsBox.put('list', _records.map((r) => r.toJson()).toList());
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _time ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted || pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_time ?? now),
    );
    if (!mounted || pickedTime == null) return;

    _safeSetState(() {
      _time = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    final XFile? picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    final CroppedFile? cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.indigo,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Image',
          aspectRatioLockEnabled: true,
        ),
        WebUiSettings(
          context: context,
          presentStyle: WebPresentStyle.page,
          size: const CropperSize(width: 520, height: 520),
        ),
      ],
    );

    if (cropped != null) {
      _safeSetState(() {
        _selectedImage = XFile(cropped.path);
      });
    }
  }

  Future<void> _saveRecord() async {
    if (_time == null) {
      _showSnack('Please select a time.');
      return;
    }
    if (_placeController.text.trim().isEmpty) {
      _showSnack('Please enter a place.');
      return;
    }

    _safeSetState(() => _isSaving = true);

    try {
      String? imageId = _existingImageId;

      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        imageId = 'img_${DateTime.now().millisecondsSinceEpoch}';
        await _imagesBox.put(imageId, bytes);

        // Delete old image if updating
        if (_existingImageId != null) {
          await _imagesBox.delete(_existingImageId);
        }
      }

      if (_editingRecord != null) {
        final index = _records.indexWhere((r) => r.id == _editingRecord!.id);
        if (index != -1) {
          _records[index] = TravelRecord(
            id: _editingRecord!.id,
            time: _time!,
            place: _placeController.text.trim(),
            distanceType: _distanceType,
            distanceValue: _distanceController.text.trim(),
            imageId: imageId,
            createdAt: _editingRecord!.createdAt,
          );
        }
      } else {
        _records.add(
          TravelRecord(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            time: _time!,
            place: _placeController.text.trim(),
            distanceType: _distanceType,
            distanceValue: _distanceController.text.trim(),
            imageId: imageId,
            createdAt: DateTime.now(),
          ),
        );
      }

      _records.sort((a, b) => a.time.compareTo(b.time));
      await _saveRecordsToBox();
      _showSnack(_editingRecord != null ? 'Record updated.' : 'Record saved.');
      _resetForm();
    } catch (e) {
      _showSnack('Error saving record: $e');
    } finally {
      _safeSetState(() => _isSaving = false);
    }
  }

  void _resetForm() {
    _safeSetState(() {
      _time = null;
      _distanceController.clear();
      _placeController.clear();
      _selectedImage = null;
      _existingImageId = null;
      _editingRecord = null;
    });
  }

  void _editRecord(TravelRecord record) {
    _safeSetState(() {
      _editingRecord = record;
      _time = record.time;
      _placeController.text = record.place;
      _distanceController.text = record.distanceValue;
      _distanceType = record.distanceType;
      _existingImageId = record.imageId;
      _selectedImage = null;
    });
  }

  Future<void> _deleteRecord(TravelRecord record) async {
    final confirmed = await _showConfirmDialog(
      'Delete record',
      'Are you sure you want to delete this travel record?',
    );
    if (confirmed != true) return;

    try {
      if (record.imageId != null) {
        await _imagesBox.delete(record.imageId);
      }
      _records.removeWhere((r) => r.id == record.id);
      await _saveRecordsToBox();
      if (_editingRecord?.id == record.id) _resetForm();
      _safeSetState(() {});
      _showSnack('Record deleted.');
    } catch (e) {
      _showSnack('Error deleting record: $e');
    }
  }

  Future<void> _deleteAllRecords() async {
    final confirmed = await _showConfirmDialog(
      'Delete all records',
      'This will remove all saved travel records and their images. Continue?',
    );
    if (confirmed != true) return;

    try {
      await _imagesBox.clear();
      _records.clear();
      await _saveRecordsToBox();
      _resetForm();
      _showSnack('All records deleted.');
    } catch (e) {
      _showSnack('Error: $e');
    }
  }

  Future<void> _exportCsv() async {
    if (_records.isEmpty) {
      _showSnack('No records to export.');
      return;
    }

    final csv = 'Time,Place,Type,Distance,Created At\n${_records.map((r) => r.toCsvRow()).join('\n')}';
    final bytes = utf8.encode(csv);

    final now = DateTime.now();
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

    await Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename: 'travel_records_$timestamp.csv',
    );
  }

  Future<void> _exportPdf() async {
    if (_records.isEmpty) {
      _showSnack('No records to export.');
      return;
    }

    final pdf = pw.Document();
    
    // Convert px to pdf points (72 dpi). 500px is approximately 375 points.
    const double imageSize = 375; 

    for (final record in _records) {
      Uint8List? imageBytes;
      if (record.imageId != null) {
        imageBytes = _imagesBox.get(record.imageId);
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(level: 0, child: pw.Text('Travel Record: ${record.place}')),
                pw.SizedBox(height: 10),
                pw.Text('Time: ${_formatDateTime(record.time)}'),
                pw.Text('Type: ${record.distanceType}'),
                pw.Text('Distance: ${record.distanceValue}'),
                pw.SizedBox(height: 20),
                if (imageBytes != null)
                  pw.Center(
                    child: pw.Container(
                      width: imageSize,
                      height: imageSize,
                      child: pw.Image(pw.MemoryImage(imageBytes), fit: pw.BoxFit.cover),
                    ),
                  )
                else
                  pw.Text('No image attached'),
                pw.Spacer(),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('Created at: ${_formatDateTime(record.createdAt)}', 
                    style: const pw.TextStyle(fontSize: 10)),
                ),
              ],
            );
          },
        ),
      );
    }

    if (_records.isEmpty) {
      pdf.addPage(pw.Page(build: (ctx) => pw.Center(child: pw.Text('No records found'))));
    }

    final now = DateTime.now();
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'travel_records_$timestamp.pdf');
  }

  Future<void> _shareImage(String imageId) async {
    try {
      final Uint8List? bytes = _imagesBox.get(imageId);
      if (bytes == null) {
        _showSnack('Image not found.');
        return;
      }

      await Share.shareXFiles(
        [XFile.fromData(bytes, name: 'travel_image.jpg', mimeType: 'image/jpeg')],
        subject: 'Travel Memory',
      );
    } catch (e) {
      _showSnack('Error sharing image: $e');
    }
  }

  void _viewImage(String imageId) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<Uint8List?>(
              future: Future.value(_imagesBox.get(imageId)),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.7,
                      maxWidth: MediaQuery.of(context).size.width * 0.9,
                    ),
                    child: InteractiveViewer(
                      child: Image.memory(snapshot.data!),
                    ),
                  );
                }
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => _shareImage(imageId),
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutApp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About App'),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<String>(
            future: rootBundle.loadString('assets/README.md'),
            builder: (ctx, snapshot) {
              if (snapshot.hasData) {
                return Markdown(data: snapshot.data!);
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Travel Record'),
        actions: [
          PopupMenuButton<int>(
            onSelected: (val) {
              if (val == 1) _deleteAllRecords();
              if (val == 2) _exportCsv();
              if (val == 3) _exportPdf();
              if (val == 4) _showAboutApp();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 1, child: Text('Delete All')),
              const PopupMenuItem(value: 2, child: Text('Export CSV')),
              const PopupMenuItem(value: 3, child: Text('Export PDF')),
              const PopupMenuItem(value: 4, child: Text('About App')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInputForm(),
            const SizedBox(height: 20),
            if (_records.isEmpty)
              const Center(child: Text('No records found.'))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _records.length,
                itemBuilder: (ctx, i) => TravelRecordTile(
                  record: _records[i],
                  onEdit: () => _editRecord(_records[i]),
                  onDelete: () => _deleteRecord(_records[i]),
                  onOpenImage: () => _viewImage(_records[i].imageId!),
                  onShareImage: () => _shareImage(_records[i].imageId!),
                  formatDateTime: _formatDateTime,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              title: Text(_time == null ? 'Select Date & Time' : _formatDateTime(_time!)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDateTime,
            ),
            TextField(controller: _placeController, decoration: const InputDecoration(labelText: 'Place')),
            Row(
              children: [
                DropdownButton<String>(
                  value: _distanceType,
                  onChanged: (v) => _safeSetState(() => _distanceType = v!),
                  items: ['Departure', 'Arrival'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _distanceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Distance'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(onPressed: () => _pickImageFromSource(ImageSource.gallery), icon: const Icon(Icons.image)),
                IconButton(onPressed: () => _pickImageFromSource(ImageSource.camera), icon: const Icon(Icons.camera_alt)),
              ],
            ),
            if (_selectedImage != null || _existingImageId != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Image attached'),
              ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveRecord,
              child: Text(_editingRecord != null ? 'Update Record' : 'Save Record'),
            ),
            if (_editingRecord != null) TextButton(onPressed: _resetForm, child: const Text('Cancel')),
          ],
        ),
      ),
    );
  }
}

class TravelRecord {
  final String id;
  final DateTime time;
  final String place;
  final String distanceType;
  final String distanceValue;
  final String? imageId;
  final DateTime createdAt;

  TravelRecord({
    required this.id,
    required this.time,
    required this.place,
    required this.distanceType,
    required this.distanceValue,
    this.imageId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time.toIso8601String(),
        'place': place,
        'distanceType': distanceType,
        'distanceValue': distanceValue,
        'imageId': imageId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TravelRecord.fromJson(Map<String, dynamic> json) => TravelRecord(
        id: json['id'],
        time: DateTime.parse(json['time']),
        place: json['place'],
        distanceType: json['distanceType'],
        distanceValue: json['distanceValue'],
        imageId: json['imageId'],
        createdAt: DateTime.parse(json['createdAt']),
      );

  String toCsvRow() => [
        time.toIso8601String(),
        place,
        distanceType,
        distanceValue,
        createdAt.toIso8601String(),
      ].join(',');
}
