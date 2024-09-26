import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class Registration {
  final String name;
  final String email;
  final String rollNo;
  final List<String> imagePaths;

  Registration({
    required this.name,
    required this.email,
    required this.rollNo,
    required this.imagePaths,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'rollNo': rollNo,
      'imagePaths': imagePaths,
    };
  }

  factory Registration.fromMap(Map<String, dynamic> map) {
    return Registration(
      name: map['name'],
      email: map['email'],
      rollNo: map['rollNo'],
      imagePaths: List<String>.from(map['imagePaths']),
    );
  }
}

class FaceRegistrationWidget extends StatelessWidget {
  const FaceRegistrationWidget({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FaceRegistrationPage(title: title),
    );
  }
}

class FaceRegistrationPage extends StatefulWidget {
  const FaceRegistrationPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<FaceRegistrationPage> createState() => _FaceRegistrationPageState();
}

class _FaceRegistrationPageState extends State<FaceRegistrationPage> {
  final ImagePicker picker = ImagePicker();
  List<File?> _images = List.filled(4, null);
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController rollNoController = TextEditingController();
  CollectionReference registrationsCollection = FirebaseFirestore.instance.collection('registrations');

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp();
  }

  Future<void> _chooseImage(int index) async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _images[index] = File(image.path);
      });
    }
  }

  Future<void> _captureImage(int index) async {
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _images[index] = File(image.path);
      });
    }
  }

  Future<void> submitRegistration() async {
    String name = nameController.text;
    String email = emailController.text;
    String rollNo = rollNoController.text;

    if (_images.every((image) => image != null) && name.isNotEmpty && email.isNotEmpty && rollNo.isNotEmpty) {
      List<String> imagePaths = _images.map((image) => image!.path).toList();
      Registration registration = Registration(
        name: name,
        email: email,
        rollNo: rollNo,
        imagePaths: imagePaths,
      );

      try {
        await registrationsCollection.add(registration.toMap());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration submitted successfully.'),
            duration: Duration(seconds: 3),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting registration.'),
            duration: Duration(seconds: 3),
          ),
        );
      }

      nameController.clear();
      emailController.clear();
      rollNoController.clear();
      setState(() {
        _images = List.filled(4, null);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All fields and images are required.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    4,
                        (index) => GestureDetector(
                      onTap: () => _captureImage(index),
                      onLongPress: () => _chooseImage(index),
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: _images[index] != null
                            ? Image.file(_images[index]!)
                            : Container(
                          color: Colors.grey[300],
                          child: Icon(Icons.image, size: 50, color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: rollNoController,
                decoration: InputDecoration(
                  labelText: 'Roll Number',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: submitRegistration,
                child: Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


