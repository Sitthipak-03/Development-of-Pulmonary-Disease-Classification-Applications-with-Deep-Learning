import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('โรคของปอด'),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('lung disease').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator()); // Loading indicator
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}')); // Error message
          }

          final data = snapshot.data?.docs ?? []; // Get documents

          if (data.isEmpty) {
            return Center(child: Text('No data available'));
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final doc = data[index];
              final nameTh = doc['Name_th'] ?? 'Unknown';
              final nameEd = doc['Name_ed'] ?? 'Unknown';
              final img = doc['img'] ?? ''; // Image URL or path

              return GestureDetector(
                onTap: () {
                  // Navigate to a new page with full details of the disease
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DiseaseDetailPage(doc: doc),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(8.0),
                    title: Text(
                      '$nameTh ($nameEd)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    leading: img.isNotEmpty
                        ? Image.network(
                      img,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                        : Icon(Icons.image, size: 50), // Default image if no URL
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class DiseaseDetailPage extends StatelessWidget {
  final DocumentSnapshot doc;

  DiseaseDetailPage({required this.doc});

  @override
  Widget build(BuildContext context) {
    final nameTh = doc['Name_th'] ?? 'Unknown';
    final nameEd = doc['Name_ed'] ?? 'Unknown';
    final symptom = doc['symptom'] ?? 'No symptom data';
    final maintain = doc['Maintain'] ?? 'No maintenance data';
    final img = doc['img'] ?? ''; // Image URL or path

    return Scaffold(
      appBar: AppBar(
        title: Text('$nameTh Details'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView( // Wrap the body in SingleChildScrollView
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            img.isNotEmpty
                ? Image.network(img)
                : Container(height: 200, color: Colors.grey[200]), // Display image
            SizedBox(height: 16),
            Text(
              '$nameTh ($nameEd)',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('อาการ : $symptom', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('วิธีดูแลรักษา : $maintain', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
