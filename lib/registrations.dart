import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Registered Users',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: registrationsCollection.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ListTile(
                    title: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListTile(
                    title: CircularProgressIndicator(),
                  );
                }

                List<QueryDocumentSnapshot> documents = snapshot.data!.docs;
                return Column(
                  children: documents.map((doc) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['name']),
                      subtitle: Text(data['rollNo']),
                      leading: FutureBuilder<String>(
                        future: _getUserImage(data['rollNo']),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          }
                          if (snapshot.hasError) {
                            return Icon(Icons.person);
                          }
                          if (snapshot.hasData) {
                            return Image.network(snapshot.data!);
                          }
                          return Icon(Icons.person);
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
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
      try {
        List<String> imagePaths = [];
        for (File? image in _images) {
          if (image != null) {
            String imageName = '${DateTime.now().millisecondsSinceEpoch}_${rollNo}_${_images.indexOf(image)}.jpg';
            String imagePath = 'KnownFaces/$rollNo/$imageName'; // Modified path

            // Upload image to Firebase Cloud Storage with content type
            await firebase_storage.FirebaseStorage.instance.ref(imagePath).putFile(
              image,
              firebase_storage.SettableMetadata(contentType: 'image/jpg'),
            );

            imagePaths.add(imagePath);
          }
        }

        Registration registration = Registration(
          name: name,
          email: email,
          rollNo: rollNo,
          imagePaths: imagePaths,
        );

        // Set document ID as rollNo
        await registrationsCollection.doc(rollNo).set(registration.toMap());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration submitted successfully.'),
            duration: Duration(seconds: 3),
          ),
        );

        nameController.clear();
        emailController.clear();
        rollNoController.clear();
        setState(() {
          _images = List.filled(4, null);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting registration.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All fields and images are required.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<String> _getUserImage(String rollNo) async {
    try {
      // Get the reference to the first image of the user from Firebase Cloud Storage
      String imagePath = 'KnownFaces/$rollNo/'; // Modified path
      firebase_storage.ListResult result = await firebase_storage.FirebaseStorage.instance.ref().child(imagePath).listAll();
      if (result.items.isNotEmpty) {
        String imageURL = await result.items.first.getDownloadURL();
        return imageURL;
      }
    } catch (e) {
      // Handle error
    }
    // If user has no images or there's an error, return a default person icon
    return 'https://www.pngitem.com/pimgs/m/150-1503945_transparent-user-png-default-user-image-png-png.png';
  }
}
