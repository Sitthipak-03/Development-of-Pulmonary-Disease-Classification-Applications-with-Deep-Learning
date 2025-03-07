import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchText = "";

  Future<String?> uploadImageToFirebase(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef = FirebaseStorage.instance.ref().child('uploads/$fileName.jpg');

      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  Future<void> saveImageToFirestore(File imageFile) async {
    String? imageUrl = await uploadImageToFirebase(imageFile);
    if (imageUrl != null) {
      await FirebaseFirestore.instance.collection('predictions').add({
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ประวัติการบันทึก'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchText = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                labelText: 'ค้นหา',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('predictions').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('ไม่มีประวัติการบันทึก'));
                }

                final documents = snapshot.data!.docs;
                final filteredDocs = documents.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nameUser = (data['Name_user'] ?? "").toString().toLowerCase();
                  return nameUser.contains(_searchText);
                }).toList();

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data = filteredDocs[index].data() as Map<String, dynamic>;
                    final diseases = data['diseases'] as List<dynamic>?;
                    final imageUrl = data['imageUrl'] ?? ''; // ใช้ key 'imageUrl' ที่ตรงกับที่บันทึก
                    final timestamp = data['timestamp'] as Timestamp?;
                    String displayTimestamp = timestamp != null ? timestamp.toDate().toString() : 'ไม่มีเวลา';

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                      child: ExpansionTile(
                        title: Text("${data['status']} ${data['prefix']} ${data['Name_user']} ${data['Lastname_User']}", style: TextStyle(fontSize: 16)),
                        subtitle: Text("วันที่: $displayTimestamp", style: TextStyle(fontSize: 14, color: Colors.grey)),
                        children: [
                          if (imageUrl.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.network(imageUrl, height: 200, fit: BoxFit.cover),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: diseases?.map((disease) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("ชื่อภาษาไทย: ${disease['Name_th'] ?? 'ไม่มีข้อมูล'}", style: TextStyle(fontSize: 16)),
                                    Text("ความแม่นยำ: ${disease['confidence'] ?? '0'}%", style: TextStyle(fontSize: 16)),
                                    SizedBox(height: 8),
                                  ],
                                );
                              }).toList() ?? [],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  await filteredDocs[index].reference.delete();
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
