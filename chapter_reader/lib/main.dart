import 'app_strings.dart';
import 'views.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;

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
// 2. HOME SCREEN WITH ALL NEW ADVANCED FEATURES
// ----------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ParayanConfig appConfig;
  List<Map<String, dynamic>> members = [];
  List<String> memberNames = []; // Admin ने बदललेली नावे स्टोअर करण्यासाठी
  String _currentLang = 'mr';     // भाषा स्टेट: 'mr' (मराठी) / 'en' (English)
  UserRole _currentRole = UserRole.user; 

  @override
  void initState() {
    super.initState();
    appConfig = ParayanConfig(totalMembers: 33, baseChapterForSerialOne: 1);
    
    // डीफॉल्ट ३३ नावे तयार करणे
    final List<String> initialNames = ["Mandar", "Rahul", "Trupti", "Amit", "Sneha", "Aniket", "Pooja"];
    memberNames = List.generate(
      appConfig.totalMembers, 
      (i) => i < initialNames.length ? initialNames[i] : "Member ${i + 1}"
    );

    _calculateCascadingAssignments();
  }

  // 1. Cascading Math Logic (उदा. Serial 1 ला 11 दिल्यास ३३व्या सदस्याला १० मिळणे)
  void _calculateCascadingAssignments() {
    members = List.generate(appConfig.totalMembers, (index) {
      int serialNo = index + 1;
      int rawChapterIndex = (appConfig.baseChapterForSerialOne - 1) + index;
      int calculatedChapter = (rawChapterIndex % appConfig.totalMembers) + 1;
      
      String chapterDisplay = "Chapter $calculatedChapter";
      if (calculatedChapter == 33) {
        chapterDisplay = "Chapter 33 + Summary";
      }

      String pdfUrl = "assets/assets/chapters/chapter_$calculatedChapter.pdf";
      // काही डमी स्टेटस सेट करणे (चाचणीसाठी ५ सदस्य Completed दाखवणे)
      String status = (index % 6 == 0) ? "Completed" : "Pending";

      return {
        "id": serialNo,
        "name": memberNames[index],
        "chapterNumber": calculatedChapter,
        "chapterDisplay": chapterDisplay,
        "pdfUrl": pdfUrl,
        "status": status
      };
    });
  }

  // 2. Admin: Serial 1 Anchor अध्याय बदलणे
  void _showAnchorConfigurationDialog() {
    final anchorController = TextEditingController(text: appConfig.baseChapterForSerialOne.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_currentLang == 'mr' ? 'Serial 1 साठी अध्याय निवडा' : 'Set Anchor Rule (Serial 1)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
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
                    _calculateCascadingAssignments(); // सर्व अध्याय री-कॅल्क्युलेट करा
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

  // 3. Admin: सदस्याचे नाव बदलण्याचा डायलॉग (Edit Name)
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
                    _calculateCascadingAssignments(); // नाव अपडेट करा
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

  // 4. पेंडिंग वाचकांसाठी रिमाइंडर पाठवणे
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
          // भाषा बटण
          TextButton.icon(
            onPressed: () => setState(() => _currentLang = _currentLang == 'mr' ? 'en' : 'mr'),
            icon: const Icon(Icons.language, color: Colors.white),
            label: Text(_currentLang == 'mr' ? 'English' : 'मराठी', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),

          // रोल बटण (User / Admin)
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

  // ----------------------------------------------------
  // प्रगति ट्रॅकर कार्ड विजेट (Progress Tracker Card)
  // ----------------------------------------------------
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
                  label: Text(_currentLang == 'mr' ? 'पूर्ण: $completedCount' : 'Completed: $completedCount'),
                  backgroundColor: Colors.green.shade50,
                ),
                Chip(
                  avatar: const Icon(Icons.hourglass_top, color: Colors.red, size: 18),
                  label: Text(_currentLang == 'mr' ? 'उरलेले: $pendingCount' : 'Remaining: $pendingCount'),
                  backgroundColor: Colors.red.shade50,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // USER DASHBOARD VIEW
  // ----------------------------------------------------
  Widget _buildUserView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_currentLang == 'mr' ? 'सुस्वागतम, मंदार' : 'Welcome, Mandar', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          // ३. प्रगती कार्ड (Progress Tracker)
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
                // पेंडिंग वाचक असल्यास लाईट लाल हायलाइट करणे
                color: isPending ? Colors.red.shade50 : Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isPending ? Colors.red.shade100 : Colors.green.shade100,
                    child: Text('${member['id']}', style: TextStyle(color: isPending ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(member['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(member['chapterDisplay']),
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
                        label: Text(member['status']),
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

  // ----------------------------------------------------
  // ADMIN DASHBOARD VIEW
  // ----------------------------------------------------
  Widget _buildAdminView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentLang == 'mr' ? 'प्रशासक डॅशबोर्ड कॉन्फिगरेशन' : 'Admin Dashboard Controls', 
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)
          ),
          const SizedBox(height: 16),

          // प्रगती कार्ड
          _buildProgressTrackerCard(),
          const SizedBox(height: 16),

          // 2. SERIAL 1 ANCHOR CONTROL CARD
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
                        Text('Cascading Rule: Serial 1 $\\rightarrow$ Ch ${appConfig.baseChapterForSerialOne}, Serial 33 $\\rightarrow$ Ch ${((appConfig.baseChapterForSerialOne + 31) % 33) + 1}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
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

          // 1. MANAGE MEMBERS & EDIT NAMES LIST
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
                    child: Text('${member['id']}'),
                  ),
                  title: Row(
                    children: [
                      Text(member['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                        onPressed: () => _showEditNameDialog(index), // १. नाव बदलण्याचे बटण
                        tooltip: 'Edit Name',
                      ),
                    ],
                  ),
                  subtitle: Text(member['chapterDisplay']),
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
                        items: ['Pending', 'Completed'].map((String val) {
                          return DropdownMenuItem<String>(value: val, child: Text(val));
                        }).toList(),
                        onChanged: (newVal) {
                          if (newVal != null) {
                            setState(() {
                              members[index]['status'] = newVal;
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