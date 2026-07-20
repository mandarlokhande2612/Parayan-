import 'app_strings.dart';
import 'views.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:convert';

void main() {
  runApp(const ParayanApp());
}

class ParayanConfig {
  int totalMembers;
  int baseChapterForSerialOne;

  ParayanConfig({
    required this.totalMembers,
    this.baseChapterForSerialOne = 1,
  });
}

enum UserRole { user, admin }

class ParayanApp extends StatelessWidget {
  const ParayanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parayan Chapter Reader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.orange, useMaterial3: true),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

// ----------------------------------------------------
// 1. LOGIN SCREEN
// ----------------------------------------------------
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Parayan Reader', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 40),
            const TextField(decoration: InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone))),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'OTP', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)), obscureText: true),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.orange),
              onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
              child: const Text('Login', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 2. HOME SCREEN WITH CSV IMPORT FEATURE
// ----------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ParayanConfig appConfig;
  List<Map<String, dynamic>> members = [];
  List<String> memberNames = []; 
  List<String> memberStatuses = []; 
  String _currentLang = 'mr';     
  UserRole _currentRole = UserRole.user; 

  @override
  void initState() {
    super.initState();
    appConfig = ParayanConfig(totalMembers: 33, baseChapterForSerialOne: 1);
    
    // Default Marathi sample names
    final List<String> initialNames = [
      "मंदार", "राहुल", "तृप्ती", "अमित", "स्नेहा", "अनिकेत", "पूजा", "सचिन", "प्रिया", "रोहित"
    ];
    memberNames = List.generate(
      appConfig.totalMembers, 
      (i) => i < initialNames.length ? initialNames[i] : "वाचक ${i + 1}"
    );

    memberStatuses = List.generate(appConfig.totalMembers, (i) => (i % 6 == 0) ? "Completed" : "Pending");

    _calculateCascadingAssignments();
  }

  void _calculateCascadingAssignments() {
    members = List.generate(appConfig.totalMembers, (index) {
      int serialNo = index + 1;
      int rawChapterIndex = (appConfig.baseChapterForSerialOne - 1) + index;
      int calculatedChapter = (rawChapterIndex % appConfig.totalMembers) + 1;
      
      String chapterDisplay = "अध्याय $calculatedChapter";
      if (calculatedChapter == 33) {
        chapterDisplay = "अध्याय ३३ + सारांश";
      }

      String pdfUrl = "assets/assets/chapters/chapter_$calculatedChapter.pdf";

      return {
        "id": serialNo,
        "name": memberNames[index],
        "chapterNumber": calculatedChapter,
        "chapterDisplay": chapterDisplay,
        "pdfUrl": pdfUrl,
        "status": memberStatuses[index]
      };
    });
  }

  // ----------------------------------------------------
  // CSV FILE IMPORT FUNCTION (UTF-8 SUPPORTED)
  // ----------------------------------------------------
  void _importNamesFromCSV() {
    html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = '.csv,.txt';
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        final reader = html.FileReader();

        reader.readAsText(file, 'UTF-8');
        reader.onLoadEnd.listen((e) {
          String content = reader.result as String;
          // Split by newline and remove empty spaces
          List<String> parsedNames = content
              .split(RegExp(r'\r\n|\r|\n'))
              .map((e) => e.replaceAll(',', '').trim())
              .where((e) => e.isNotEmpty)
              .toList();

          if (parsedNames.isNotEmpty) {
            setState(() {
              for (int i = 0; i < appConfig.totalMembers; i++) {
                if (i < parsedNames.length) {
                  memberNames[i] = parsedNames[i];
                }
              }
              _calculateCascadingAssignments();
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _currentLang == 'mr' 
                      ? '${parsedNames.length} मराठी नावे यशस्वीरित्या अपडेट झाली!' 
                      : '${parsedNames.length} Marathi names imported successfully!',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        });
      }
    });
  }

  void _resetAllToPending() {
    setState(() {
      for (int i = 0; i < memberStatuses.length; i++) {
        memberStatuses[i] = "Pending";
      }
      _calculateCascadingAssignments();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_currentLang == 'mr' ? 'सर्व अध्याय स्थिती Pending वर रिसेट केली गेली!' : 'All chapter statuses reset to Pending!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showAnchorConfigurationDialog() {
    final anchorController = TextEditingController(text: appConfig.baseChapterForSerialOne.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_currentLang == 'mr' ? 'Serial 1 साठी अध्याय निवडा' : 'Set Anchor Rule (Serial 1)'),
          content: Column(
            mainAxisSize: MyAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentLang == 'mr' 
                  ? 'Serial 1 साठी जो अध्याय निवडाल, त्यानुसार उर्वरित ३३ सदस्यांचे अध्याय आपोआप बदलतील.' 
                  : 'Enter chapter for Serial 1. Rest will automatically adjust in cascading order.',
                style: const TextStyle(fontSize: 13, color: Colors.grey)
              ),
              const SizedBox(height: 12),
              TextField(
                controller: anchorController,
                decoration: InputDecoration(
                  labelText: _currentLang == 'mr' ? 'Serial 1 चा अध्याय नंबर' : 'Chapter for Serial No 1', 
                  border: const OutlineInputBorder()
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(_currentLang == 'mr' ? 'रद्द करा' : 'Cancel')),
            ElevatedButton(
              onPressed: () {
                int inputChapter = int.tryParse(anchorController.text) ?? 1;
                if (inputChapter > 0 && inputChapter <= appConfig.totalMembers) {
                  setState(() {
                    appConfig.baseChapterForSerialOne = inputChapter;
                    _calculateCascadingAssignments();
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(_currentLang == 'mr' ? 'बदल लागू करा' : 'Apply Changes'),
            ),
          ],
        );
      },
    );
  }

  void _showEditNameDialog(int index) {
    final nameController = TextEditingController(text: memberNames[index]);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${_currentLang == 'mr' ? 'नाव बदला' : 'Edit Name'} (Serial ${index + 1})'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: _currentLang == 'mr' ? 'नवीन नाव' : 'New Member Name',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(_currentLang == 'mr' ? 'रद्द करा' : 'Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  setState(() {
                    memberNames[index] = nameController.text.trim();
                    _calculateCascadingAssignments();
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(_currentLang == 'mr' ? 'सेव्ह करा' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  void _sendReminder(String name, String chapter) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_currentLang == 'mr' 
            ? '$name यांना $chapter पूर्ण करण्यासाठी रिमाइंडर पाठवला!' 
            : 'Reminder sent to $name for $chapter!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _viewChapterDocument(String title, String assetPath) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Reading View: $title'),
          content: Container(
            height: 200,
            width: double.maxFinite,
            color: Colors.grey.shade50,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.picture_as_pdf, color: Colors.red, size: 64),
                const SizedBox(height: 12),
                Text('File Path: $assetPath', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => html.window.open(assetPath, '_blank'),
                  icon: const Icon(Icons.open_in_new, color: Colors.white),
                  label: const Text('Open & Read PDF', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        );
      },
    );
  }

  Widget _buildTopHeaderInfo() {
    final DateTime now = DateTime.now();
    final List<String> weekDaysMr = ['सोमवार', 'मंगळवार', 'बुधवार', 'गुरुवार', 'शुक्रवार', 'शनिवार', 'रविवार'];
    final List<String> weekDaysEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final List<String> monthsMr = ['जानेवारी', 'फेब्रुवारी', 'मार्च', 'एप्रिल', 'मे', 'जून', 'जुलै', 'ऑगस्ट', 'सप्टेंबर', 'ऑक्टोबर', 'नोव्हेंबर', 'डिसेंबर'];
    final List<String> monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    String dayName = _currentLang == 'mr' ? weekDaysMr[now.weekday - 1] : weekDaysEn[now.weekday - 1];
    String monthName = _currentLang == 'mr' ? monthsMr[now.month - 1] : monthsEn[now.month - 1];
    String formattedDate = "$dayName, ${now.day} $monthName ${now.year}";

    var ch33Member = members.firstWhere(
      (m) => m['chapterNumber'] == 33, 
      orElse: () => {"name": "N/A", "chapterDisplay": "अध्याय ३३ + सारांश"}
    );

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today, size: 18, color: Colors.deepOrange),
              const SizedBox(width: 8),
              Text(
                formattedDate,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepOrange),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            border: Border.all(color: Colors.amber.shade800, width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentLang == 'mr' ? '🌟 अध्याय ३३ व सारांश वाचक:' : '🌟 Reading Chapter 33 + Summary:',
                      style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${ch33Member['name']}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ],
                ),
              ),
              Chip(
                label: const Text('Chapter 33 + Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                backgroundColor: Colors.amber.shade300,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressTrackerCard() {
    int completedCount = members.where((m) => m['status'] == 'Completed').length;
    int pendingCount = members.length - completedCount;
    double progressRatio = completedCount / members.length;

    return Card(
      elevation: 3,
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _currentLang == 'mr' ? '📊 वाचन प्रगती (Progress)' : '📊 Reading Progress',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                ),
                Text(
                  '${(progressRatio * 100).toInt()}%',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progressRatio,
              backgroundColor: Colors.orange.shade100,
              color: Colors.deepOrange,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Chip(
                  avatar: const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  label: Text(_currentLang == 'mr' ? 'पूर्ण: $completedCount' : 'Completed: $completedCount', style: const TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.green.shade50,
                ),
                Chip(
                  avatar: const Icon(Icons.hourglass_top, color: Colors.red, size: 18),
                  label: Text(_currentLang == 'mr' ? 'उरलेले: $pendingCount' : 'Remaining: $pendingCount', style: const TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.red.shade50,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentRole == UserRole.user 
              ? (_currentLang == 'mr' ? 'पारायण वाचक' : 'Parayan Reader')
              : (_currentLang == 'mr' ? 'प्रशासक पॅनेल' : 'Admin Panel'),
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _currentLang = _currentLang == 'mr' ? 'en' : 'mr'),
            icon: const Icon(Icons.language, color: Colors.white),
            label: Text(_currentLang == 'mr' ? 'English' : 'मराठी', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0, left: 4.0),
            child: SegmentedButton<UserRole>(
              segments: [
                ButtonSegment(value: UserRole.user, label: Text(_currentLang == 'mr' ? 'वाचक' : 'User')),
                ButtonSegment(value: UserRole.admin, label: Text(_currentLang == 'mr' ? 'प्रशासक' : 'Admin')),
              ],
              selected: {_currentRole},
              onSelectionChanged: (newSelection) => setState(() => _currentRole = newSelection.first),
            ),
          ),
        ],
      ),
      body: _currentRole == UserRole.user ? _buildUserView() : _buildAdminView(),
    );
  }

  // USER VIEW
  Widget _buildUserView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopHeaderInfo(),
          const SizedBox(height: 16),
          
          _buildProgressTrackerCard(),
          const SizedBox(height: 16),

          Text(
            _currentLang == 'mr' ? 'सक्रिय वाचन असाइनमेंट्स' : 'Active Reading Assignments', 
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 8),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final isPending = member['status'] == 'Pending';

              return Card(
                elevation: isPending ? 3 : 1,
                color: isPending ? Colors.red.shade50 : Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isPending ? Colors.red.shade100 : Colors.green.shade100,
                    child: Text('${member['id']}', style: TextStyle(color: isPending ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(member['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text(member['chapterDisplay'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chrome_reader_mode, color: Colors.deepOrange),
                        onPressed: () => _viewChapterDocument(member['chapterDisplay'], member['pdfUrl']),
                        tooltip: 'Read Chapter',
                      ),
                      if (isPending)
                        IconButton(
                          icon: const Icon(Icons.notifications_active, color: Colors.orange),
                          onPressed: () => _sendReminder(member['name'], member['chapterDisplay']),
                          tooltip: 'Send Reminder',
                        ),
                      Chip(
                        label: Text(
                          member['status'], 
                          style: TextStyle(fontWeight: FontWeight.bold, color: isPending ? Colors.red.shade900 : Colors.green.shade900)
                        ),
                        backgroundColor: isPending ? Colors.red.shade100 : Colors.green.shade100,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ADMIN VIEW WITH IMPORT CSV BUTTON
  Widget _buildAdminView() {
    int lastChapterNum = ((appConfig.baseChapterForSerialOne + 31) % 33) + 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopHeaderInfo(),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _currentLang == 'mr' ? 'प्रशासक डॅशबोर्ड' : 'Admin Dashboard', 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)
              ),
              Wrap(
                spacing: 8,
                children: [
                  // 1. IMPORT CSV BUTTON
                  ElevatedButton.icon(
                    onPressed: _importNamesFromCSV,
                    icon: const Icon(Icons.upload_file, color: Colors.white, size: 18),
                    label: Text(
                      _currentLang == 'mr' ? 'नावे अपलोड (CSV)' : 'Import CSV',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  ),
                  // 2. RESET ALL BUTTON
                  ElevatedButton.icon(
                    onPressed: _resetAllToPending,
                    icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                    label: Text(
                      _currentLang == 'mr' ? 'सर्व रिसेट करा' : 'Reset All',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildProgressTrackerCard(),
          const SizedBox(height: 16),

          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Serial 1 Assigned to: Chapter ${appConfig.baseChapterForSerialOne}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        Text('Cascading Rule: Serial 1 -> Ch ${appConfig.baseChapterForSerialOne}, Serial 33 -> Ch $lastChapterNum', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAnchorConfigurationDialog,
                    icon: const Icon(Icons.tune),
                    label: Text(_currentLang == 'mr' ? 'अध्याय बदला' : 'Set Serial 1'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade100),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            _currentLang == 'mr' ? 'सदस्य नावे व स्टेटस व्यवस्थापन' : 'Manage Member Names & Status',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final isPending = member['status'] == 'Pending';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: Text('${member['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  title: Row(
                    children: [
                      Text(member['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                        onPressed: () => _showEditNameDialog(index),
                        tooltip: 'Edit Name',
                      ),
                    ],
                  ),
                  subtitle: Text(member['chapterDisplay'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPending)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                          onPressed: () => _sendReminder(member['name'], member['chapterDisplay']),
                          icon: const Icon(Icons.notifications, size: 16),
                          label: Text(_currentLang == 'mr' ? 'रिमाइंडर' : 'Remind'),
                        ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: member['status'],
                        style: TextStyle(fontWeight: FontWeight.bold, color: member['status'] == 'Pending' ? Colors.red : Colors.green),
                        items: ['Pending', 'Completed'].map((String val) {
                          return DropdownMenuItem<String>(value: val, child: Text(val, style: const TextStyle(fontWeight: FontWeight.bold)));
                        }).toList(),
                        onChanged: (newVal) {
                          if (newVal != null) {
                            setState(() {
                              memberStatuses[index] = newVal;
                              _calculateCascadingAssignments();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}