import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/glass_theme.dart';
import '../widgets/widgets.dart';
import '../utils/responsive.dart';

/// Widget for uploading Excel files to import customer data
class ExcelUploadWidget extends StatefulWidget {
  final VoidCallback? onUploadComplete;
  final String? title;

  const ExcelUploadWidget({
    super.key,
    this.onUploadComplete,
    this.title,
  });

  @override
  State<ExcelUploadWidget> createState() => _ExcelUploadWidgetState();
}

class _ExcelUploadWidgetState extends State<ExcelUploadWidget> {
  bool _isUploading = false;
  String? _uploadStatus;
  double? _uploadProgress;

  Future<void> _pickAndUploadExcel() async {
    try {
      // Pick Excel file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _isUploading = true;
          _uploadStatus = 'กำลังอัพโหลดไฟล์...';
          _uploadProgress = null;
        });

        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fullFileName = '${timestamp}_$fileName';
        
        // Upload to Firebase Storage in customers folder
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('customers')
            .child(fullFileName);

        final uploadTask = storageRef.putFile(file);
        
        // Listen to upload progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          setState(() {
            _uploadProgress = progress;
            _uploadStatus = 'กำลังอัพโหลด... ${(progress * 100).toInt()}%';
          });
        });

        await uploadTask;

        setState(() {
          _uploadStatus = 'อัพโหลดสำเร็จ! กำลังประมวลผลข้อมูล...';
          _uploadProgress = 1.0;
        });

        // Call Cloud Function to process the uploaded file
        try {
          final functionUrl = 'https://processcustomerexcel-hd55gpdsuq-as.a.run.app';
          
          final response = await http.post(
            Uri.parse(functionUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'fileName': fullFileName}),
          );

          if (response.statusCode == 200) {
            final responseData = json.decode(response.body);
            final processedCount = responseData['processed'] ?? 0;
            
            setState(() {
              _isUploading = false;
              _uploadStatus = 'นำเข้าข้อมูลลูกค้า $processedCount รายการเรียบร้อยแล้ว';
            });
          } else {
            throw Exception('Failed to process file: ${response.body}');
          }
        } catch (e) {
          setState(() {
            _isUploading = false;
            _uploadStatus = 'อัพโหลดสำเร็จ แต่เกิดข้อผิดพลาดในการประมวลผล: ${e.toString()}';
          });
        }

        if (widget.onUploadComplete != null) {
          widget.onUploadComplete!();
        }

        // Clear status after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _uploadStatus = null;
              _uploadProgress = null;
            });
          }
        });

      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadStatus = 'เกิดข้อผิดพลาด: ${e.toString()}';
      });

      // Clear error after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _uploadStatus = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: Responsive.padding(
        context,
        mobile: const EdgeInsets.all(20),
        tablet: const EdgeInsets.all(24),
        desktop: const EdgeInsets.all(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          if (widget.title != null)
            Padding(
              padding: EdgeInsets.only(
                bottom: Responsive.spacing(context, mobile: 16, tablet: 20, desktop: 24),
              ),
              child: Text(
                widget.title!,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, mobile: 18, tablet: 20, desktop: 22),
                  fontWeight: FontWeight.w700,
                  color: GlassTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Upload instructions
          Container(
            padding: Responsive.padding(
              context,
              mobile: const EdgeInsets.all(16),
              tablet: const EdgeInsets.all(20),
              desktop: const EdgeInsets.all(24),
            ),
            decoration: BoxDecoration(
              color: GlassTheme.glassBackground,
              borderRadius: BorderRadius.circular(
                Responsive.borderRadius(context, mobile: 12, tablet: 16, desktop: 20),
              ),
              border: Border.all(
                color: GlassTheme.glassBorder,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.upload_file_rounded,
                  size: Responsive.iconSize(context, mobile: 48, tablet: 56, desktop: 64),
                  color: GlassTheme.primary,
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16, desktop: 20)),
                Text(
                  'อัพโหลดไฟล์ Excel ข้อมูลลูกค้า',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, mobile: 16, tablet: 18, desktop: 20),
                    fontWeight: FontWeight.w600,
                    color: GlassTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 10, desktop: 12)),
                Text(
                  'ไฟล์ Excel ต้องมีคอลัมน์:\n• รหัสลูกค้า (ID)\n• ชื่อลูกค้า (Name)',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, mobile: 14, tablet: 16, desktop: 18),
                    color: GlassTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          SizedBox(height: Responsive.spacing(context, mobile: 20, tablet: 24, desktop: 28)),

          // Upload button
          if (!_isUploading)
            GlassButton(
              onPressed: _pickAndUploadExcel,
              text: 'เลือกไฟล์ Excel',
              icon: Icons.folder_open_rounded,
              color: GlassTheme.primary,
            )
          else
            Column(
              children: [
                // Progress indicator
                if (_uploadProgress != null)
                  Column(
                    children: [
                      LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: GlassTheme.glassBackground,
                        valueColor: AlwaysStoppedAnimation<Color>(GlassTheme.primary),
                      ),
                      SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 10, desktop: 12)),
                    ],
                  )
                else
                  Column(
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(GlassTheme.primary),
                      ),
                      SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20, desktop: 24)),
                    ],
                  ),
              ],
            ),

          // Status message
          if (_uploadStatus != null) ...[
            SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20, desktop: 24)),
            Container(
              padding: Responsive.padding(
                context,
                mobile: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                tablet: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                desktop: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              ),
              decoration: BoxDecoration(
                color: _uploadStatus!.contains('ข้อผิดพลาด')
                    ? GlassTheme.error.withValues(alpha: 0.1)
                    : GlassTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(
                  Responsive.borderRadius(context, mobile: 8, tablet: 10, desktop: 12),
                ),
                border: Border.all(
                  color: _uploadStatus!.contains('ข้อผิดพลาด')
                      ? GlassTheme.error
                      : GlassTheme.success,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _uploadStatus!.contains('ข้อผิดพลาด')
                        ? Icons.error_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    color: _uploadStatus!.contains('ข้อผิดพลาด')
                        ? GlassTheme.error
                        : GlassTheme.success,
                    size: Responsive.iconSize(context, mobile: 20, tablet: 22, desktop: 24),
                  ),
                  SizedBox(width: Responsive.spacing(context, mobile: 8, tablet: 10, desktop: 12)),
                  Flexible(
                    child: Text(
                      _uploadStatus!,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, mobile: 14, tablet: 16, desktop: 18),
                        color: _uploadStatus!.contains('ข้อผิดพลาด')
                            ? GlassTheme.error
                            : GlassTheme.success,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
