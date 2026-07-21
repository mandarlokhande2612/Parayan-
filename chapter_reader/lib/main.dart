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

class ParayanApp extends StatefulWidget {
  const ParayanApp({super.key});

  @override
  State<ParayanApp> createState() => _ParayanAppState();
}

class _ParayanAppState extends State<ParayanApp> {
  bool _isLoggedIn = false;
  bool _isAdmin = false;

  void _login(bool isAdmin) {
    setState(() {
      _isLoggedIn = true;
      _isAdmin = isAdmin;
    });
  }

  void _logout() {
    setState(() {
      _isLoggedIn = false;
      _isAdmin = false;
    });
  }

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
      ),
      home: _isLoggedIn
          ? ParayanHomeScreen(isAdmin: _isAdmin, onLogout: _logout)
          : LoginScreen(onLoginSuccess: _login),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. LOGIN SCREEN
// ---------------------------------------------------------------------------
class LoginScreen extends StatefulWidget {
  final Function(bool isAdmin) onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  bool _obscurePin = true;

  void _handleLogin() {
    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();

    if (phone == "8830490396" && pin == "121212") {
      widget.onLoginSuccess(true);
      return;
    }

    if (phone == "9325534582" && pin == "123123") {
      widget.onLoginSuccess(false);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("चुकीचा मोबाईल नंबर किंवा PIN! पुन्हा प्रयत्न करा."),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.deepOrange.shade100,
                  child: const Icon(Icons.lock_person, size: 36, color: Colors.deepOrange),
                ),
                const SizedBox(height: 16),
                Text(
                  "सदगुरू श्री लक्ष्मीकांत महाराज पारायण",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "ॲपमध्ये प्रवेश करण्यासाठी मोबाईल नंबर व PIN टाका",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: "मोबाईल नंबर (Mobile No)",
                    prefixText: "+91 ",
                    prefixIcon: Icon(Icons.phone, color: Colors.deepOrange),
                    border: OutlineInputBorder(),
                    counterText: "",
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: _obscurePin,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: "६ अंकी PIN टाका",
                    prefixIcon: const Icon(Icons.password, color: Colors.deepOrange),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePin = !_obscurePin),
                    ),
                    border: const OutlineInputBorder(),
                    counterText: "",
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange.shade800,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _handleLogin,
                    child: const Text("प्रवेश करा (Login)", style: TextStyle(fontSize: 16)),
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

// ---------------------------------------------------------------------------
// 2. MAIN PARAYAN DASHBOARD (दर मंगळवारी ऑटो-रोटेशन सह)
// ---------------------------------------------------------------------------
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
  final bool isAdmin;
  final VoidCallback onLogout;

  const ParayanHomeScreen({
    super.key,
    required this.isAdmin,
    required this.onLogout,
  });

  @override
  State<ParayanHomeScreen> createState() => _ParayanHomeScreenState();
}

class _ParayanHomeScreenState extends State<ParayanHomeScreen> {
  final DatabaseReference _membersRef = FirebaseDatabase.instance.ref('members');
  final DatabaseReference _settingsRef = FirebaseDatabase.instance.ref('settings');

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
      final settingsSnapshot = await _settingsRef.get();
      if (settingsSnapshot.exists && settingsSnapshot.value is Map) {
        final settingsMap = settingsSnapshot.value as Map;
        _startChapter = int.tryParse(settingsMap['startChapter']?.toString() ?? '1') ?? 1;
        _parayanDate = settingsMap['parayanDate']?.toString() ?? '';
        _pdfBaseUrl = settingsMap['pdfUrl']?.toString() ?? '';
      }

      // ---------------------------------------------------------------------
      // 🔄 दर मंगळवारी ऑटो-रोटेशन लॉजिक (Automatic Rotation Every Tuesday)
      // ---------------------------------------------------------------------
      DateTime now = DateTime.now();
      // चालू आठवड्याचा मंगळवार शोधणे
      int daysSinceTuesday = (now.weekday - DateTime.tuesday + 7) % 7;
      DateTime currentTuesday = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysSinceTuesday));
      String currentTuesdayStr = "${currentTuesday.day}/${currentTuesday.month}/${currentTuesday.year}";

      if (_parayanDate.isNotEmpty && _parayanDate != 'आजचा दिनांक सेट करा') {
        try {
          List<String> dateParts = _parayanDate.split('/');
          if (dateParts.length == 3) {
            DateTime lastTuesday = DateTime(
              int.parse(dateParts[2]),
              int.parse(dateParts[1]),
              int.parse(dateParts[0]),
            );

            // जर नवीन मंगळवार आला असेल तर रोटेशन करा
            if (currentTuesday.isAfter(lastTuesday)) {
              int daysDiff = currentTuesday.difference(lastTuesday).inDays;
              int weeksPassed = (daysDiff / 7).floor();

              if (weeksPassed >= 1) {
                _startChapter = ((_startChapter - 1 + weeksPassed) % 33) + 1;
                _parayanDate = currentTuesdayStr;

                // फायरबेसमध्ये अपडेट सेव्ह करा
                await _settingsRef.update({
                  'startChapter': _startChapter,
                  'parayanDate': _parayanDate,
                });

                // सर्व सदस्यांचे स्टेटस 'वाचन बाकी' (Pending) करा
                final membersSnapshot = await _membersRef.get();
                if (membersSnapshot.exists && membersSnapshot.value != null) {
                  Map<String, dynamic> resetUpdates = {};
                  final data = membersSnapshot.value;

                  if (data is Map) {
                    data.forEach((k, v) => resetUpdates['$k/status'] = 'Pending');
                  } else if (data is List) {
                    for (int i = 0; i < data.length; i++) {
                      resetUpdates['$i/status'] = 'Pending';
                    }
                  }

                  if (resetUpdates.isNotEmpty) {
                    await _membersRef.update(resetUpdates);
                  }
                }
              }
            }
          }
        } catch (e) {
          debugPrint("Auto-rotation calculation error: $e");
        }
      } else {
        // जर पहिलीच वेळ असेल तर सध्याच्या मंगळवारची तारीख सेट करा
        _parayanDate = currentTuesdayStr;
        await _settingsRef.update({'parayanDate': _parayanDate});
      }

      // सदस्यांची यादी लोड करणे
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

  void _openPdfReader(int chapterNumber) {
    String customUrl = _pdfBaseUrl.trim();

    if (customUrl.isNotEmpty) {
      if (!customUrl.startsWith('http://') && !customUrl.startsWith('https://')) {
        customUrl = 'https://$customUrl';
      }
      if (customUrl.contains('#page=')) {
        customUrl = customUrl.replaceAll(RegExp(r'#page=\d+'), '#page=$chapterNumber');
      } else if (!customUrl.endsWith('.pdf')) {
        if (!customUrl.endsWith('/')) customUrl += '/';
        customUrl += 'chapter_$chapterNumber.pdf';
      }
      html.window.open(customUrl, '_blank');
      return;
    }

    final String relativePath = 'assets/assets/chapters/chapter_$chapterNumber.pdf';
    html.window.open(relativePath, '_blank');
  }

  void _editMemberName(Member member) {
    final nameController = TextEditingController(text: member.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("नाव दुरुस्त करा (अनुक्रमांक ${member.id})"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: "सदस्याचे नवीन नाव",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("रद्द करा"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                await _membersRef.child(member.key).update({'name': newName});
                if (mounted) Navigator.pop(ctx);
                setState(() {});
              }
            },
            child: const Text("सेव्ह करा", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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

  Future<void> _resetAllStatuses(List<Member> members) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("सर्व स्टेटस रीसेट करायचे?"),
        content: const Text("सर्व सदस्यांचे स्टेटस 'वाचन बाकी' केले जाईल."),
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
        toolbarHeight: 75,
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                image: const DecorationImage(
                  image: AssetImage('assets/images/maharaj.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                "सदगुरू श्री लक्ष्मीकांत महाराज पारायण",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                image: const DecorationImage(
                  image: AssetImage('assets/images/devi.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: "लॉगआउट करा",
            onPressed: widget.onLogout,
          )
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
            if (_selectedFilter == 'Completed') return m.isCompleted;
            if (_selectedFilter == 'Pending') return !m.isCompleted;
            return true;
          }).toList();

          return Column(
            children: [
              // BANNER
              Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade800, Colors.deepOrange.shade900],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              "दिनांक: $dateStr",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (widget.isAdmin)
                          IconButton(
                            icon: const Icon(Icons.edit_calendar, color: Colors.white, size: 20),
                            onPressed: _updateDate,
                            tooltip: "दिनांक बदला",
                          )
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "प्रगती: $completedCount / $totalCount वाचून झाले",
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        Text(
                          "सुरुवात: अध्याय $currentStartChapter",
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
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

              // CHAPTER 33 BANNER
              if (ch33Reader != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    border: Border.all(color: Colors.amber.shade700, width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber.shade900, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "अध्याय ३३ (अवतरणिका) विशेष वाचक:",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown.shade800,
                              ),
                            ),
                            Text(
                              "${ch33Reader.name} (अनुक्रमांक ${ch33Reader.id})",
                              style: TextStyle(
                                fontSize: 14,
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        ),
                        onPressed: () => _openPdfReader(33),
                        icon: const Icon(Icons.picture_as_pdf, size: 14),
                        label: const Text("वाचा", style: TextStyle(fontSize: 11)),
                      )
                    ],
                  ),
                ),

              // ADMIN PANEL
              if (widget.isAdmin)
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      children: [
                        const Text(
                          "S.No 1 अध्याय: ",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        DropdownButton<int>(
                          value: currentStartChapter,
                          isDense: true,
                          items: List.generate(33, (i) => i + 1)
                              .map((ch) => DropdownMenuItem(
                                    value: ch,
                                    child: Text("अध्याय $ch", style: const TextStyle(fontSize: 12)),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) _updateStartChapter(val);
                          },
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _uploadCSV,
                          icon: const Icon(Icons.upload_file, size: 14),
                          label: const Text("CSV", style: TextStyle(fontSize: 11)),
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => _resetAllStatuses(members),
                          icon: const Icon(Icons.refresh, size: 14, color: Colors.white),
                          label: const Text("रीसेट", style: TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                ),

              // FILTER CHIPS
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFilterChip("सर्व ($totalCount)", 'All'),
                    const SizedBox(width: 6),
                    _buildFilterChip("बाकी (${totalCount - completedCount})", 'Pending'),
                    const SizedBox(width: 6),
                    _buildFilterChip("पूर्ण ($completedCount)", 'Completed'),
                  ],
                ),
              ),

              // TABLE HEADER
              Container(
                color: Colors.deepOrange.shade800,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 45,
                      child: Text("अनु.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text("नाव", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text("अध्याय", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    SizedBox(
                      width: 50,
                      child: Text("वाचा", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    SizedBox(
                      width: 85,
                      child: Text("स्थिती", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),

              // MEMBERS LIST
              Expanded(
                child: filteredMembers.isEmpty
                    ? const Center(child: Text("सदस्य सापडले नाहीत."))
                    : ListView.separated(
                        padding: const EdgeInsets.all(8),
                        itemCount: filteredMembers.length,
                        separatorBuilder: (ctx, i) => const Divider(height: 1, thickness: 0.5),
                        itemBuilder: (context, index) {
                          final member = filteredMembers[index];
                          final assignedChapter = _calculateAssignedChapter(
                            member.id,
                            currentStartChapter,
                          );

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 45,
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: member.isCompleted
                                        ? Colors.green.shade100
                                        : Colors.orange.shade100,
                                    child: Text(
                                      "${member.id}",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: member.isCompleted
                                            ? Colors.green.shade900
                                            : Colors.deepOrange.shade900,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          member.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (widget.isAdmin)
                                        InkWell(
                                          onTap: () => _editMemberName(member),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 4.0),
                                            child: Icon(Icons.edit, size: 16, color: Colors.blue),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "अध्याय $assignedChapter",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.brown.shade900,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 50,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.picture_as_pdf, color: Colors.deepOrange, size: 22),
                                    tooltip: "अध्याय वाचा",
                                    onPressed: () => _openPdfReader(assignedChapter),
                                  ),
                                ),
                                SizedBox(
                                  width: 85,
                                  child: InkWell(
                                    onTap: () => _toggleStatus(member),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                      decoration: BoxDecoration(
                                        color: member.isCompleted
                                            ? Colors.green.shade50
                                            : Colors.red.shade50,
                                        border: Border.all(
                                          color: member.isCompleted
                                              ? Colors.green
                                              : Colors.red.shade300,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        member.isCompleted ? "वाचून झाले" : "वाचन बाकी",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: member.isCompleted
                                              ? Colors.green.shade800
                                              : Colors.red.shade800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilter = value);
      },
    );
  }
}