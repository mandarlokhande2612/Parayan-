import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:html' as html;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "[REDACTED_GCP_API_KEY_1]",
      authDomain: "parayan-app-d93ea.firebaseapp.com",
      databaseURL: "https://parayan-app-d93ea-default-rtdb.firebaseio.com",
      projectId: "parayan-app-d93ea",
      storageBucket: "parayan-app-d93ea.firebasestorage.app",
      messagingSenderId: "33806688499",
      appId: "1:33806688499:web:75417e567eb73fc36c5786",
    ),
  );
  runApp(const ParayanApp());
}

class ParayanApp extends StatelessWidget {
  const ParayanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'सदगुरू श्री लक्ष्मीकांत महाराज पारायण',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          primary: Colors.deepOrange.shade800,
          secondary: Colors.amber.shade800,
          surface: const Color(0xFFFFF8F0),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF5EA),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepOrange.shade900,
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),
      ),
      home: const ParayanHomeScreen(),
    );
  }
}

class Member {
  final String key;
  final int id;
  final String name;
  final String status;

  Member({
    required this.key,
    required this.id,
    required this.name,
    required this.status,
  });

  bool get isCompleted => status == 'Completed' || status == 'वाचून झाले';
}

class ParayanHomeScreen extends StatefulWidget {
  const ParayanHomeScreen({super.key});

  @override
  State<ParayanHomeScreen> createState() => _ParayanHomeScreenState();
}

class _ParayanHomeScreenState extends State<ParayanHomeScreen> {
  final DatabaseReference _membersRef = FirebaseDatabase.instance.ref('members');
  final DatabaseReference _settingsRef = FirebaseDatabase.instance.ref('settings');

  bool _isAdminMode = false;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  int _startChapter = 1;
  String _parayanDate = 'आजचा दिनांक सेट करा';
  String _pdfBaseUrl = '';

  int _calculateAssignedChapter(int memberId, int startChapter) {
    if (memberId <= 0) return 1;
    return ((memberId - 1 + (startChapter - 1)) % 33) + 1;
  }

  Future<Map<String, dynamic>> _fetchAppData() async {
    try {
      // Fetch Settings
      final settingsSnapshot = await _settingsRef.get();
      if (settingsSnapshot.exists && settingsSnapshot.value is Map) {
        final settingsMap = settingsSnapshot.value as Map;
        _startChapter = int.tryParse(settingsMap['startChapter']?.toString() ?? '1') ?? 1;
        _parayanDate = settingsMap['parayanDate']?.toString() ?? 'दिनांक उपलब्ध नाही';
        _pdfBaseUrl = settingsMap['pdfUrl']?.toString() ?? '';
      }

      // Fetch Members
      final membersSnapshot = await _membersRef.get();
      List<Member> memberList = [];

      if (membersSnapshot.exists && membersSnapshot.value != null) {
        final data = membersSnapshot.value;

        if (data is Map) {
          data.forEach((key, value) {
            if (value is Map) {
              memberList.add(
                Member(
                  key: key.toString(),
                  id: int.tryParse(value['id']?.toString() ?? '') ?? 0,
                  name: value['name']?.toString() ?? "अनामित",
                  status: value['status']?.toString() ?? "Pending",
                ),
              );
            }
          });
        } else if (data is List) {
          for (int i = 0; i < data.length; i++) {
            final value = data[i];
            if (value is Map) {
              memberList.add(
                Member(
                  key: '$i',
                  id: int.tryParse(value['id']?.toString() ?? '') ?? (i + 1),
                  name: value['name']?.toString() ?? "अनामित",
                  status: value['status']?.toString() ?? "Pending",
                ),
              );
            }
          }
        }
      }

      memberList.sort((a, b) => a.id.compareTo(b.id));

      Member? ch33Reader;
      for (var m in memberList) {
        if (_calculateAssignedChapter(m.id, _startChapter) == 33) {
          ch33Reader = m;
          break;
        }
      }

      return {
        'members': memberList,
        'startChapter': _startChapter,
        'parayanDate': _parayanDate,
        'ch33Reader': ch33Reader,
      };
    } catch (e) {
      debugPrint("Error fetching data: $e");
      return {'members': <Member>[], 'startChapter': 1, 'parayanDate': ''};
    }
  }

  // Opens PDF file in a new browser tab
  void _openPdfReader(int chapterNumber) {
    String targetUrl = _pdfBaseUrl.trim();

    if (targetUrl.isEmpty) {
      // Default to web asset folder if no custom URL is provided in admin settings
      targetUrl = 'assets/assets/pdf/chapter_$chapterNumber.pdf';
    } else {
      if (!targetUrl.startsWith('http://') &&
          !targetUrl.startsWith('https://') &&
          !targetUrl.startsWith('assets/')) {
        targetUrl = 'https://$targetUrl';
      }

      if (targetUrl.contains('#page=')) {
        // Single PDF file with page anchors
        targetUrl = targetUrl.replaceAll(RegExp(r'#page=\d+'), '#page=$chapterNumber');
      } else if (!targetUrl.endsWith('.pdf')) {
        // Folder or base URL
        if (!targetUrl.endsWith('/')) targetUrl += '/';
        targetUrl += 'chapter_$chapterNumber.pdf';
      }
    }

    html.window.open(targetUrl, '_blank');
  }

  Future<void> _toggleStatus(Member member) async {
    final newStatus = member.isCompleted ? 'Pending' : 'Completed';
    try {
      await _membersRef.child(member.key).update({'status': newStatus});
      setState(() {});
    } catch (e) {
      debugPrint("Status update error: $e");
    }
  }

  // Admin Actions
  Future<void> _updateDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      final formattedDate = "${picked.day}/${picked.month}/${picked.year}";
      await _settingsRef.update({'parayanDate': formattedDate});
      setState(() {
        _parayanDate = formattedDate;
      });
    }
  }

  Future<void> _updateStartChapter(int newStart) async {
    await _settingsRef.update({'startChapter': newStart});
    setState(() {
      _startChapter = newStart;
    });
  }

  Future<void> _updatePdfUrl(String newUrl) async {
    await _settingsRef.update({'pdfUrl': newUrl.trim()});
    setState(() {
      _pdfBaseUrl = newUrl.trim();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PDF Link अपडेट झाली.")),
      );
    }
  }

  Future<void> _resetAllStatuses(List<Member> members) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("सर्व स्टेटस रीसेट करायचे?"),
        content: const Text("सर्व सदस्यांचे स्टेटस 'प्रलंबित' केले जाईल."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("रद्द करा"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("होय, रीसेट करा", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      Map<String, dynamic> updates = {};
      for (var m in members) {
        updates['${m.key}/status'] = 'Pending';
      }
      await _membersRef.update(updates);
      setState(() {});
    }
  }

  void _uploadCSV() {
    html.FileUploadInputElement upload = html.FileUploadInputElement()..accept = '.csv';
    upload.click();
    upload.onChange.listen((e) {
      final files = upload.files;
      if (files == null || files.isEmpty) return;

      final reader = html.FileReader();
      reader.readAsText(files.first);
      reader.onLoadEnd.listen((e) async {
        final content = reader.result as String?;
        if (content == null) return;

        List<String> lines = content.split('\n');
        Map<String, dynamic> updates = {};

        int entryIndex = 1;
        for (int i = 0; i < lines.length; i++) {
          String name = lines[i].trim();
          if (name.contains(',')) {
            name = name.split(',').first.trim();
          }
          if (name.isNotEmpty) {
            updates['$entryIndex'] = {
              'id': entryIndex,
              'name': name,
              'status': 'Pending',
            };
            entryIndex++;
          }
        }

        if (updates.isNotEmpty) {
          await _membersRef.set(updates);
          setState(() {});
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "सदगुरू श्री लक्ष्मीकांत महाराज पारायण",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              avatar: Icon(
                _isAdminMode ? Icons.admin_panel_settings : Icons.person,
                color: _isAdminMode ? Colors.white : Colors.deepOrange,
                size: 18,
              ),
              label: Text(
                _isAdminMode ? "ॲडमिन" : "वाचक",
                style: TextStyle(
                  color: _isAdminMode ? Colors.white : Colors.deepOrange.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
              selected: _isAdminMode,
              selectedColor: Colors.red.shade800,
              backgroundColor: Colors.white,
              onSelected: (bool selected) {
                setState(() {
                  _isAdminMode = selected;
                });
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchAppData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
          }

          if (snapshot.hasError) {
            return Center(child: Text("त्रुटी आढळली: ${snapshot.error}"));
          }

          final rawMembers = snapshot.data?['members'];
          final members = rawMembers is List<Member>
              ? rawMembers
              : (rawMembers as List?)?.whereType<Member>().toList() ?? [];
          final currentStartChapter = (snapshot.data?['startChapter'] as int?) ?? 1;
          final dateStr = (snapshot.data?['parayanDate'] as String?) ?? '';
          final ch33Reader = snapshot.data?['ch33Reader'] as Member?;

          final completedCount = members.where((m) => m.isCompleted).length;
          final totalCount = members.length;
          final progressRatio = totalCount > 0 ? completedCount / totalCount : 0.0;

          final filteredMembers = members.where((m) {
            final matchesSearch = m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                m.id.toString().contains(_searchQuery);
            if (_selectedFilter == 'Completed') return matchesSearch && m.isCompleted;
            if (_selectedFilter == 'Pending') return matchesSearch && !m.isCompleted;
            return matchesSearch;
          }).toList();

          return Column(
            children: [
              // 1. DATE & PROGRESS BANNER
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade800, Colors.deepOrange.shade900],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, color: Colors.white, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              "दिनांक: $dateStr",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (_isAdminMode)
                          IconButton(
                            icon: const Icon(Icons.edit_calendar, color: Colors.white),
                            onPressed: _updateDate,
                            tooltip: "दिनांक बदला",
                          )
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "प्रगती: $completedCount / $totalCount वाचून झाले",
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        Text(
                          "सुरुवात: अध्याय $currentStartChapter",
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progressRatio,
                        minHeight: 8,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. CHAPTER 33 (अवतरणिका) SPECIAL READER CARD
              if (ch33Reader != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    border: Border.all(color: Colors.amber.shade700, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber.shade900),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "अध्याय ३३ (अवतरणिका) विशेष वाचक:",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown.shade800,
                              ),
                            ),
                            Text(
                              "${ch33Reader.name} (अनुक्रमांक ${ch33Reader.id})",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        onPressed: () => _openPdfReader(33),
                        icon: const Icon(Icons.picture_as_pdf, size: 16),
                        label: const Text("वाचा", style: TextStyle(fontSize: 12)),
                      )
                    ],
                  ),
                ),

              // 3. ADMIN CONTROL PANEL
              if (_isAdminMode)
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "ॲडमिन पॅनेल Control Panel:",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text("S.No 1 चा अध्याय: "),
                            DropdownButton<int>(
                              value: currentStartChapter,
                              items: List.generate(33, (i) => i + 1)
                                  .map((ch) => DropdownMenuItem(
                                        value: ch,
                                        child: Text("अध्याय $ch"),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) _updateStartChapter(val);
                              },
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: _uploadCSV,
                              icon: const Icon(Icons.upload_file, size: 16),
                              label: const Text("CSV"),
                            ),
                            const SizedBox(width: 6),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () => _resetAllStatuses(members),
                              icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                              label: const Text("रीसेट", style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: TextEditingController(text: _pdfBaseUrl),
                                decoration: const InputDecoration(
                                  hintText: "PDF / Drive Link टाका...",
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.all(8),
                                ),
                                onSubmitted: (val) => _updatePdfUrl(val),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) {
                                    final ctrl = TextEditingController(text: _pdfBaseUrl);
                                    return AlertDialog(
                                      title: const Text("PDF Link जोडा"),
                                      content: TextField(
                                        controller: ctrl,
                                        decoration: const InputDecoration(
                                          hintText: "https://... किंवा Drive URL",
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text("रद्द करा"),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            _updatePdfUrl(ctrl.text);
                                            Navigator.pop(ctx);
                                          },
                                          child: const Text("सेव्ह करा"),
                                        )
                                      ],
                                    );
                                  },
                                );
                              },
                              child: const Text("PDF Link"),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),

              // 4. SEARCH & FILTER SECTION
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: "सदस्य किंवा अनुक्रमांक शोधा...",
                        prefixIcon: const Icon(Icons.search, color: Colors.deepOrange),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFilterChip("सर्व ($totalCount)", 'All'),
                        const SizedBox(width: 8),
                        _buildFilterChip("बाकी (${totalCount - completedCount})", 'Pending'),
                        const SizedBox(width: 8),
                        _buildFilterChip("पूर्ण ($completedCount)", 'Completed'),
                      ],
                    ),
                  ],
                ),
              ),

              // 5. MEMBER LIST VIEW
              Expanded(
                child: filteredMembers.isEmpty
                    ? const Center(child: Text("सदस्य सापडले नाहीत."))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        itemCount: filteredMembers.length,
                        itemBuilder: (context, index) {
                          final member = filteredMembers[index];
                          final assignedChapter = _calculateAssignedChapter(
                            member.id,
                            currentStartChapter,
                          );

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: member.isCompleted
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                                child: Text(
                                  "${member.id}",
                                  style: TextStyle(
                                    color: member.isCompleted
                                        ? Colors.green.shade800
                                        : Colors.deepOrange.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                member.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "अध्याय $assignedChapter ${assignedChapter == 33 ? '(अवतरणिका)' : ''}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.brown.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.picture_as_pdf, color: Colors.deepOrange),
                                    tooltip: "वाचा (PDF)",
                                    onPressed: () => _openPdfReader(assignedChapter),
                                  ),
                                  InkWell(
                                    onTap: () => _toggleStatus(member),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: member.isCompleted
                                            ? Colors.green.shade50
                                            : Colors.red.shade50,
                                        border: Border.all(
                                          color: member.isCompleted
                                              ? Colors.green
                                              : Colors.red.shade300,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        member.isCompleted ? "वाचून झाले" : "प्रलंबित",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: member.isCompleted
                                              ? Colors.green.shade800
                                              : Colors.red.shade800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.deepOrange,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilter = value);
      },
    );
  }
}