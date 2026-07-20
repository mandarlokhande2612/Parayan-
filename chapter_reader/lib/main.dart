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
// 2. ADVANCED HOME SCREEN (CASCADING CALCULATIONS + PDF)
// ----------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ParayanConfig appConfig;
  List<Map<String, dynamic>> members = [];
  String _currentLang = 'mr'; // Language state: 'mr' for Marathi, 'en' for English

  @override
  void initState() {
    super.initState();
    appConfig = ParayanConfig(totalMembers: 33, baseChapterForSerialOne: 1);
    _calculateCascadingAssignments();
  }

  void _calculateCascadingAssignments() {
    final List<String> primaryNames = ["Mandar", "Rahul", "Trupti", "Amit", "Sneha", "Aniket", "Pooja"];
    
    members = List.generate(appConfig.totalMembers, (index) {
      int serialNo = index + 1;
      int rawChapterIndex = (appConfig.baseChapterForSerialOne - 1) + index;
      int calculatedChapter = (rawChapterIndex % appConfig.totalMembers) + 1;
      
      String chapterDisplay = "Chapter $calculatedChapter";
      if (calculatedChapter == 33) {
        chapterDisplay = "Chapter 33 + Summary";
      }

      String name = index < primaryNames.length ? primaryNames[index] : "Member $serialNo";
      String pdfUrl = "assets/assets/chapters/chapter_$calculatedChapter.pdf";

      return {
        "id": serialNo,
        "name": name,
        "chapterNumber": calculatedChapter,
        "chapterDisplay": chapterDisplay,
        "pdfUrl": pdfUrl,
        "status": "Pending"
      };
    });
  }

  void _showAnchorConfigurationDialog() {
    final anchorController = TextEditingController(text: appConfig.baseChapterForSerialOne.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Anchor Rule (Serial No 1)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter the chapter number you wish to assign to Serial Number 1. All other numbers will automatically adjust in order.', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 12),
              TextField(
                controller: anchorController,
                decoration: const InputDecoration(labelText: 'Chapter for Serial No 1', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
              child: const Text('Apply Changes'),
            ),
          ],
        );
      },
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
                  onPressed: () {
                    html.window.open("$assetPath", '_blank');
                  },
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
        title: Text(_currentLang == 'mr' ? 'पारायण डॅशबोर्ड' : 'Parayan Dashboard'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          // Language Switch Button
          TextButton.icon(
            onPressed: () {
              setState(() {
                _currentLang = _currentLang == 'mr' ? 'en' : 'mr';
              });
            },
            icon: const Icon(Icons.language, color: Colors.white),
            label: Text(
              _currentLang == 'mr' ? 'English' : 'मराठी',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentLang == 'mr' ? 'सुस्वागतम, मंदार' : 'Welcome, Mandar', 
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // ADMIN CONTROL STRIP
            Text(
              _currentLang == 'mr' ? 'प्रशासक डॅशबोर्ड कॉन्फिगरेशन' : 'Admin Dashboard Configuration', 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Serial 1 Assigned to: Chapter ${appConfig.baseChapterForSerialOne}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        Text('System Strategy: Sequential Cascade (${appConfig.totalMembers} Members)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAnchorConfigurationDialog,
                      icon: const Icon(Icons.tune),
                      label: const Text('Set Serial 1'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade100),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // DYNAMIC TRACKER LIST 
            Text(
              _currentLang == 'mr' 
                  ? 'सक्रिय वाचन असाइनमेंट्स (${members.length})' 
                  : 'Active Reading Assignments (${members.length})', 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                final isSpecial = member['chapterDisplay'].contains('Summary');
                
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.shade100,
                      child: Text('${member['id']}'),
                    ),
                    title: Text(member['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      member['chapterDisplay'], 
                      style: TextStyle(
                        color: isSpecial ? Colors.deepOrange : Colors.black87, 
                        fontWeight: isSpecial ? FontWeight.bold : FontWeight.normal
                      )
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chrome_reader_mode, color: Colors.deepOrange),
                          onPressed: () => _viewChapterDocument(member['chapterDisplay'], member['pdfUrl']),
                          tooltip: 'Read Chapter Document File',
                        ),
                        const SizedBox(width: 4),
                        Chip(label: Text(member['status']), backgroundColor: Colors.amber.shade50),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}