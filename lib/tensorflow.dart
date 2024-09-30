import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

class Tensorflow extends StatefulWidget {
  @override
  _TensorflowState createState() => _TensorflowState();
}

class _TensorflowState extends State<Tensorflow> {
  List? _outputs;
  File? _image;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loading = true;
    loadModel().then((_) {
      setState(() {
        _loading = false;
      });
    });
  }

  Future<void> loadModel() async {
    try {
      await Tflite.loadModel(
        model: "assets/model_unquant.tflite",
        labels: "assets/labels.txt",
        numThreads: 1,
      );
    } catch (e) {
      print("Failed to load the model: $e");
    }
  }

  Future<void> classifyImage(File image) async {
    try {
      var output = await Tflite.runModelOnImage(
        path: image.path,
        imageMean: 0.0,
        imageStd: 255.0,
        numResults: 2,
        threshold: 0.2,
        asynch: true,
      );
      setState(() {
        _loading = false;
        _outputs = output;
      });
    } catch (e) {
      print("Error classifying image: $e");
    }
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage == null) return;
    setState(() {
      _loading = true;
      _image = File(pickedImage.path);
    });
    classifyImage(_image!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Emotion Detection",
          style: GoogleFonts.poppins(
              color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    )
                  : _image == null
                      ? const SizedBox(height: 300, width: 300)
                      : Container(
                          margin: const EdgeInsets.all(20),
                          width: MediaQuery.of(context).size.width,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              _image == null
                                  ? Container()
                                  : Image.file(_image!),
                              const SizedBox(height: 20),
                              _outputs != null && _outputs!.isNotEmpty
                                  ? Text(
                                      _outputs![0]["label"],
                                      style: GoogleFonts.poppins(
                                          color: Colors.white, fontSize: 20),
                                    )
                                  : Center(
                                      child: Text(
                                      "No result",
                                      style: GoogleFonts.poppins(
                                          color: Colors.white),
                                    )),
                            ],
                          ),
                        ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.01,
              ),
              FloatingActionButton(
                tooltip: 'Pick Image',
                onPressed: pickImage,
                backgroundColor: Colors.white,
                child: const Icon(
                  Icons.add_a_photo,
                  size: 20,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
