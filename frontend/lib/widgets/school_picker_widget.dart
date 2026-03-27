import 'package:flutter/material.dart';
import '../school_data.dart';

class SchoolPickerWidget extends StatefulWidget {
  final Function(String school) onSelected;
  final String? initialValue;

  const SchoolPickerWidget({
    super.key,
    required this.onSelected,
    this.initialValue,
  });

  @override
  State<SchoolPickerWidget> createState() => _SchoolPickerWidgetState();
}

class _SchoolPickerWidgetState extends State<SchoolPickerWidget> {
  String? _selectedDirectorate;
  String? _selectedSchool;
  String _searchQuery = '';

  List<String> get _filteredSchools {
    if (_selectedDirectorate == null) return [];
    final schools = schoolsByDirectorate[_selectedDirectorate] ?? [];
    if (_searchQuery.isEmpty) return schools;
    return schools.where((s) => s.contains(_searchQuery)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // اختيار المديرية
        DropdownButtonFormField<String>(
          value: _selectedDirectorate,
          decoration: const InputDecoration(
            labelText: 'المديرية *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.account_balance),
          ),
          hint: const Text('اختر المديرية'),
          items: directorates.map((d) => DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (val) {
            setState(() {
              _selectedDirectorate = val;
              _selectedSchool = null;
              _searchQuery = '';
            });
          },
        ),
        const SizedBox(height: 12),

        // البحث عن المدرسة
        if (_selectedDirectorate != null) ...[
          TextField(
            decoration: const InputDecoration(
              labelText: 'ابحث عن مدرستك *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
              hintText: 'اكتب اسم المدرسة',
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          const SizedBox(height: 8),

          // قائمة المدارس
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _filteredSchools.isEmpty
                ? const Center(child: Text('لا توجد نتائج', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: _filteredSchools.length,
                    itemBuilder: (context, index) {
                      final school = _filteredSchools[index];
                      final isSelected = _selectedSchool == school;
                      return ListTile(
                        dense: true,
                        title: Text(school, style: const TextStyle(fontSize: 13)),
                        selected: isSelected,
                        selectedColor: Colors.white,
                        selectedTileColor: const Color(0xFF0A2342),
                        onTap: () {
                          setState(() => _selectedSchool = school);
                          widget.onSelected(school);
                        },
                        trailing: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                      );
                    },
                  ),
          ),

          if (_selectedSchool != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _selectedSchool!,
                      style: const TextStyle(color: Colors.green, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
