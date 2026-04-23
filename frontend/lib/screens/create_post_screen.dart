import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../main.dart';

class CreatePostScreen extends StatefulWidget {
  final String userRole;
  const CreatePostScreen({super.key, required this.userRole});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String _loadingText = 'جاري الرفع...';
  String _selectedType = 'TEXT';
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  String? _selectedFileMime;

  static const String _cloudName = 'dlvxe1bjn';
  static const String _uploadPreset = 'learno_unsigned';

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedFileBytes = bytes;
        _selectedFileName = picked.name;
        _selectedFileMime = 'image/jpeg';
        _selectedType = 'IMAGE';
      });
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedFileBytes = bytes;
        _selectedFileName = picked.name;
        _selectedFileMime = 'video/mp4';
        _selectedType = 'VIDEO';
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt'],
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _selectedFileBytes = result.files.single.bytes;
        _selectedFileName = result.files.single.name;
        _selectedFileMime = 'application/octet-stream';
        _selectedType = 'DOCUMENT';
      });
    }
  }

  Future<String?> _uploadToCloudinary() async {
    if (_selectedFileBytes == null) return null;

    final isVideo = _selectedFileMime?.startsWith('video') == true;
    final isImage = _selectedFileMime?.startsWith('image') == true;
    final resourceType = isVideo ? 'video' : (isImage ? 'image' : 'raw');

    setState(() => _loadingText = isVideo ? 'جاري رفع الفيديو...' : (isImage ? 'جاري رفع الصورة...' : 'جاري رفع الملف...'));

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload',
    );

    final request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = _uploadPreset;
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      _selectedFileBytes!,
      filename: _selectedFileName ?? 'file',
      contentType: MediaType.parse(_selectedFileMime ?? 'image/jpeg'),
    ));

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final data = jsonDecode(body);

    if (response.statusCode == 200) {
      return data['secure_url'];
    } else {
      throw Exception(data['error']?['message'] ?? 'فشل رفع الملف على Cloudinary');
    }
  }

  Future<void> _submitPost() async {
    final text = _contentController.text.trim();
    if (text.isEmpty && _selectedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال محتوى أو اختيار ملف')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? mediaUrl;
      if (_selectedFileBytes != null) {
        mediaUrl = await _uploadToCloudinary();
      }

      setState(() => _loadingText = 'جاري النشر...');

      final token = await _apiService.getToken();

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/posts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'content': text.isEmpty ? '.' : text,
          'type': _selectedType,
          'title': '',
          if (mediaUrl != null) 'mediaUrl': mediaUrl,
        }),
      ).timeout(const Duration(seconds: 30));

      setState(() => _isLoading = false);

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم النشر بنجاح! ✅'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainNavigation()),
          );
        }
      } else {
        final data = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${data['message'] ?? data['error'] ?? 'فشل النشر'} - ${response.statusCode}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء منشور'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _isLoading
                ? Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _loadingText,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  )
                : ElevatedButton(
                    onPressed: _submitPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF678D88),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('نشر'),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark.withOpacity(0.5),
              border: Border(bottom: BorderSide(color: AppTheme.dividerColor, width: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.category_outlined, size: 20, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text('نوع المنشور:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedType,
                  dropdownColor: AppTheme.surfaceDark,
                  underline: const SizedBox(),
                  style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                  items: [
                    const DropdownMenuItem(value: 'TEXT', child: Text('نص')),
                    const DropdownMenuItem(value: 'IMAGE', child: Text('صورة')),
                    if (widget.userRole == 'TEACHER' || widget.userRole == 'PRINCIPAL') ...[
                      const DropdownMenuItem(value: 'STORY', child: Text('قصة')),
                      const DropdownMenuItem(value: 'VIDEO', child: Text('فيديو')),
                      const DropdownMenuItem(value: 'DOCUMENT', child: Text('ملف')),
                    ],
                  ],
                  onChanged: (val) => setState(() => _selectedType = val!),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'ماذا يدور في ذهنك؟',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 18),
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 18, color: Colors.white, height: 1.5),
              ),
            ),
          ),
            if (_selectedFileBytes != null) ...[
              const Divider(),
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade200,
                ),
                child: _selectedFileMime?.startsWith('image') == true
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(_selectedFileBytes!, fit: BoxFit.cover),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_selectedType == 'VIDEO' ? Icons.video_file : Icons.insert_drive_file, size: 50, color: Colors.grey),
                            Text(_selectedType == 'VIDEO' ? 'فيديو جاهز للرفع' : 'ملف جاهز للرفع', style: TextStyle(color: Colors.grey)),
                            if (_selectedFileName != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(_selectedFileName!, style: const TextStyle(color: Colors.blue, fontSize: 12), overflow: TextOverflow.ellipsis),
                              ),
                          ],
                        ),
                      ),
              ),
              TextButton.icon(
                onPressed: () => setState(() {
                  _selectedFileBytes = null;
                  _selectedFileName = null;
                  _selectedFileMime = null;
                  _selectedType = 'TEXT';
                }),
                icon: const Icon(Icons.close, color: Colors.red),
                label: const Text('إزالة', style: TextStyle(color: Colors.red)),
              ),
            ],
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAttachmentOption(Icons.image, 'صورة', Colors.green, _pickImage),
                if (widget.userRole == 'TEACHER' || widget.userRole == 'PRINCIPAL') ...[
                  _buildAttachmentOption(Icons.video_library, 'فيديو', Colors.red, _pickVideo),
                  _buildAttachmentOption(Icons.attach_file, 'ملف', Colors.blue, _pickFile),
                ],
              ],
            ),
          ],
        ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: color),
          onPressed: onTap,
        ),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}