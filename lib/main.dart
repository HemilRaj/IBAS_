import 'package:flutter/material.dart';
import 'registrations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'View_attendance.dart';
import 'Take_attendance.dart';

void main() async{

  runApp(const MyApp());
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}

class Home extends StatelessWidget {
  const Home({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IBAS'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/maxresdefault.jpg"), //image
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5), // Translucent black color
                        borderRadius: BorderRadius.circular(20), // Rounded corners
                      ),
                      child:  ExpansionTile(
                        title: Text(
                          'Attendance',
                          style: TextStyle(
                            color: Colors.white, // Font color
                            fontSize: 30, // Font size
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        children: [
                          CustomCard('Take attendance',  TakeAttendancePage()),
                          CustomCard('View attendance',ViewAttendancePage()), // Use ViewAttendancePage
                          CustomCard('Register a student', FaceRegistrationPage(title: 'Face Registration')),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomCard extends StatelessWidget {
  final String _label;
  final Widget _viewPage;
  final bool featureCompleted;

  const CustomCard(this._label, this._viewPage, {Key? key, this.featureCompleted = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        tileColor: Colors.blue, // Set blue color for all buttons
        title: Text(
          _label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onTap: () {
          if (!featureCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('This feature has not been implemented yet'),
            ));
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => _viewPage),
            );
          }
        },
      ),
    );
  }
}

class FaceRegistrationWidget extends StatelessWidget {
  final String title;

  const FaceRegistrationWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text(
          'This is the $title page.',
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
