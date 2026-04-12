import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../services/api_service.dart';
import '../main.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

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
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
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

  Future<String?> _uploadToCloudinary() async {
    if (_selectedFileBytes == null) return null;

    final isVideo = _selectedFileMime?.startsWith('video') == true;
    final resourceType = isVideo ? 'video' : 'image';

    setState(() => _loadingText = isVideo ? 'جاري رفع الفيديو...' : 'جاري رفع الصورة...');

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
        Uri.parse('https://learno-school-production-2b55.up.railway.app/api/posts'),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text('النوع: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedType,
                  items: const [
                    DropdownMenuItem(value: 'TEXT', child: Text('نص')),
                    DropdownMenuItem(value: 'IMAGE', child: Text('صورة')),
                    DropdownMenuItem(value: 'STORY', child: Text('قصة')),
                    DropdownMenuItem(value: 'VIDEO', child: Text('فيديو')),
                  ],
                  onChanged: (val) => setState(() => _selectedType = val!),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'ماذا تريد أن تشارك؟',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 16, color: Colors.white),
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
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.video_file, size: 50, color: Colors.grey),
                            Text('فيديو جاهز للرفع', style: TextStyle(color: Colors.grey)),
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
                _buildAttachmentOption(Icons.video_library, 'فيديو', Colors.red, _pickVideo),
              ],
            ),
          ],
        ),
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