import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewAttendancePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Attendance'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('attendance').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          List<QueryDocumentSnapshot> documents = snapshot.data!.docs;
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  const DataColumn(label: Text('Subject')),
                  const DataColumn(label: Text('Name')),
                  const DataColumn(label: Text('Roll No')),
                  const DataColumn(label: Text('Date')),
                  const DataColumn(label: Text('Attendance')),
                ],
                rows: documents.map((doc) {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  return DataRow(cells: [
                    DataCell(Text(data['subject'])),
                    DataCell(Text(data['name'])),
                    DataCell(Text(data['rollNo'])),
                    DataCell(Text(data['date'].toDate().toString())), // Convert Timestamp to string
                    DataCell(Text(data['attendance'])),
                  ]);
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
