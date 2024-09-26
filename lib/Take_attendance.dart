import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class TakeAttendancePage extends StatefulWidget {
  @override
  _TakeAttendancePageState createState() => _TakeAttendancePageState();
}

class _TakeAttendancePageState extends State<TakeAttendancePage> {
  late String subjectName;
  late List<String> imagePaths = [];

  void _onSubjectNameChanged(String value) {
    setState(() {
      subjectName = value;
    });
  }

  void _addImages(List<String> paths) {
    setState(() {
      imagePaths.addAll(paths);
    });
  }

  void _removeImage(int index) {
    setState(() {
      imagePaths.removeAt(index);
    });
  }

  Future<void> _uploadImages() async {
    // Check if subject name is entered and images are selected
    if (subjectName.isNotEmpty && imagePaths.isNotEmpty) {
      // Format the current date
      String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      try {
        for (int i = 0; i < imagePaths.length; i++) {
          String imageName = '$subjectName $formattedDate $i.jpg';
          // Read the file as bytes
          Uint8List bytes = await File(imagePaths[i]).readAsBytes();
          // Convert the List<int> to Uint8List
          // Upload the bytes to Firebase Storage with the new image name and IMAGE/JPEG format
          await firebase_storage.FirebaseStorage.instance.ref('Class/$imageName').putData(
            bytes,
            firebase_storage.SettableMetadata(contentType: 'image/jpeg'),
          );
        }
        // Clear the imagePaths list after successful upload
        setState(() {
          imagePaths.clear();
        });
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Images uploaded successfully.'),
            duration: Duration(seconds: 3),
          ),
        );
      } catch (error) {
        // Show error message if upload fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading images: $error'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      // Show error message if subject name is not entered or no images are selected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a subject name and select images.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Take Attendance'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                onChanged: _onSubjectNameChanged,
                decoration: InputDecoration(
                  labelText: 'Enter Subject Name',
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Upload Class Images',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                height: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: imagePaths.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Image.file(File(imagePaths[index])),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _removeImage(index),
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ImageUploadScreen(
                        onImagesUploaded: _addImages,
                      ),
                    ),
                  );
                },
                child: Text('Select Images'),
              ),
              ElevatedButton(
                onPressed: _uploadImages,
                child: Text('Upload Images'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Connect to the server
                  final socket = IO.io('http://172.28.115.113:5555', <String, dynamic>{
                    'transports': ['websocket'],
                  });

                  socket.onConnect((_) {
                    print('Connected');
                    // Send trigger message to the server
                    socket.emit('trigger', 'start recognition');
                  });

                  socket.on('message', (data) {
                    print('Received response: $data');
                    // Close the connection
                    socket.disconnect();
                  });

                  socket.onDisconnect((_) => print('Disconnected'));
                },
                child: Text('Mark Attendance'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ImageUploadScreen extends StatelessWidget {
  final Function(List<String>) onImagesUploaded;

  const ImageUploadScreen({Key? key, required this.onImagesUploaded}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Images'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                final picker = ImagePicker();
                final List<XFile>? images = await picker.pickMultiImage(
                  maxWidth: 1920,
                  maxHeight: 1200,
                  imageQuality: 90,
                );
                if (images != null) {
                  onImagesUploaded(images.map((image) => image.path).toList());
                  Navigator.pop(context);
                }
              },
              child: Text('Select Images from Gallery'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final picker = ImagePicker();
                List<String> capturedImages = [];
                while (true) {
                  final XFile? image = await picker.pickImage(source: ImageSource.camera);
                  if (image == null) break;
                  capturedImages.add(image.path);
                }
                if (capturedImages.isNotEmpty) {
                  onImagesUploaded(capturedImages);
                  Navigator.pop(context);
                }
              },
              child: Text('Capture Images from Camera'),
            ),
          ],
        ),
      ),
    );
  }
}


