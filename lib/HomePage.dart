import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class ImageClassificationPage extends StatefulWidget {
  @override
  _ImageClassificationPageState createState() =>
      _ImageClassificationPageState();
}

class _ImageClassificationPageState extends State<ImageClassificationPage> {
  File? _image;
  String? _imageUrl; // ✅ ประกาศตัวแปรเก็บลิงก์ Cloudinary
  List? _predictions;
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isModelLoaded = false;
  bool _isSaved = false;
  final TextEditingController _prefixController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    String? result = await Tflite.loadModel(
      model: "assets/model_unquant.tflite",
      labels: "assets/labels.txt",
    );
    if (result != null) {
      setState(() {
        _isModelLoaded = true;
      });
    }
  }

  Future<void> _classifyImage(File image) async {
    var predictions = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 5,
      threshold: 0.0,
    );

    setState(() {
      _predictions = predictions;
      _isSaved = false;
    });
  }

  Future<String?> _uploadToCloudinary(File imageFile) async {
    try {
      final cloudName = "dfg2pl72f";
      final uploadPreset = "lung_app";

      final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

      var request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = json.decode(responseData);
        return jsonData['secure_url']; // ✅ ได้ URL จาก Cloudinary
      } else {
        print("❌ Upload Failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Error: $e");
      return null;
    }
  }

  Future<void> _savePredictionsToFirestore() async {
    if (_predictions != null &&
        _prefixController.text.isNotEmpty &&
        _nameController.text.isNotEmpty &&
        _lastnameController.text.isNotEmpty &&
        _imageUrl != null) {  // ✅ เช็คให้แน่ใจว่า _imageUrl มีค่า

      List<Map<String, dynamic>> diseases = _predictions!.map((prediction) {
        return {
          'Name_th': prediction['label'],
          'confidence': (prediction['confidence'] * 100).toStringAsFixed(2),
        };
      }).toList();

      await _firestore.collection('predictions').add({
        'prefix': _prefixController.text,
        'Name_user': _nameController.text,
        'Lastname_User': _lastnameController.text,
        'imageUrl': _imageUrl, // ✅ ใช้ URL จาก Cloudinary
        'diseases': diseases,
        'timestamp': FieldValue.serverTimestamp(),
        'status': '[x-ray]',
      });

      setState(() {
        _isSaved = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("กรุณากรอกข้อมูลให้ครบถ้วนก่อนบันทึก")),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      File image = File(pickedFile.path);

      setState(() {
        _image = image;
      });

      // ✅ ทำการจำแนกรูปภาพก่อนอัปโหลด
      await _classifyImage(image);

      // ✅ อัปโหลดไป Cloudinary
      String? imageUrl = await _uploadToCloudinary(image);
      if (imageUrl != null) {
        setState(() {
          _imageUrl = imageUrl;
        });
      }
    }
  }

  @override
  void dispose() {
    Tflite.close();
    _prefixController.dispose();
    _nameController.dispose();
    _lastnameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('X-ray'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_image != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.file(
                    _image!,
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                ),
              if (_predictions != null)
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _predictions!.length,
                  itemBuilder: (context, index) {
                    final prediction = _predictions![index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                      child: ListTile(
                        title: Text(
                          prediction['label'],
                          style: TextStyle(fontSize: 18),
                        ),
                        subtitle: Text(
                          "ความแม่นยำ: ${(prediction['confidence'] * 100).toStringAsFixed(2)}%",
                        ),
                      ),
                    );
                  },
                ),
              if (_predictions != null)
                Column(
                  children: [
                    _buildTextField(_prefixController, "คำนำหน้าชื่อ"),
                    _buildTextField(_nameController, "ชื่อ"),
                    _buildTextField(_lastnameController, "นามสกุล"),
                  ],
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildImageButton(Icons.camera, "กล้อง", ImageSource.camera),
                  SizedBox(width: 10),
                  _buildImageButton(Icons.photo, "แกลเลอรี", ImageSource.gallery),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _predictions != null && !_isSaved
                    ? _savePredictionsToFirestore
                    : null,
                child: Text(_isSaved ? "บันทึกสำเร็จแล้ว" : "บันทึกผลลัพธ์"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: _isSaved ? Colors.green : Colors.blueAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildImageButton(IconData icon, String label, ImageSource source) {
    return ElevatedButton.icon(
      onPressed: () => _pickImage(source),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
