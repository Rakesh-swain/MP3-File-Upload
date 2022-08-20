import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart';
import 'package:simple_progress_indicators/simple_progress_indicators.dart';
import 'package:flutter/foundation.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var file;
  String? name;
  UploadTask? task;
  PlatformFile? pfile;
  Future selectFile() async {
    final pickfile = await FilePicker.platform.pickFiles(
      allowMultiple: false,
    );
    if (pickfile == null) {
      return;
    }
    pfile = pickfile.files.single;

    setState(() {
      file = (kIsWeb) ? pfile!.bytes : File(pfile!.path!);
      name = pickfile.files.single.name;
    });
  }

  Future uploadFile() async {
    if (file == null) {
      return;
    }
    final fileName = basename(name!);
    task = (kIsWeb)
        ? FirebaseStorage.instance.ref('music/$fileName').putData(file!)
        : FirebaseStorage.instance.ref('music/$fileName').putFile(file);
    setState(() {});
    if (task == null) {
      return;
    }
    final snapshot = await task!.whenComplete(() => null);
    final url = await snapshot.ref.getDownloadURL();
    await FirebaseFirestore.instance
        .collection('songs')
        .doc()
        .set({"song_url": url});
  }

  @override
  Widget build(BuildContext context) {
    final fileName = file != null ? basename(name!) : 'No file selected';
    return Scaffold(
      appBar: AppBar(title: const Text("MP3 File Upload")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
                onPressed: selectFile,
                icon: const Icon(Icons.attach_file),
                label: const Text("Select File")),
            const SizedBox(
              height: 10,
            ),
            Text(
              fileName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(
              height: 50,
            ),
            ElevatedButton.icon(
                onPressed: uploadFile,
                icon: const Icon(Icons.upload_file),
                label: const Text("Upload File")),
            const SizedBox(
              height: 20,
            ),
            task != null ? uploadStatus(task!) : Container(),
          ],
        ),
      ),
    );
  }

  Widget uploadStatus(UploadTask task) {
    double progress = 0.0;
    return StreamBuilder(
        stream: task.snapshotEvents,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            final snap = snapshot.data;
            progress = ((snap.bytesTransferred.toDouble() /
                        snap.totalBytes.toDouble()) *
                    100)
                .roundToDouble();
            return AnimatedSwitcher(
              duration: const Duration(microseconds: 350),
              child: progress == 100.0
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_rounded,
                          color: Colors.green,
                        ),
                        const SizedBox(
                          width: 5.0,
                        ),
                        Text(
                          'Upload Complete',
                          style: GoogleFonts.poppins(
                            color: Colors.green,
                          ),
                        ),
                      ],
                    )
                  : ProgressBar(
                      value: progress / 100,
                      height: 7,
                      width: MediaQuery.of(context).size.width * 0.7,
                      gradient: const LinearGradient(colors: [
                        Colors.yellow,
                        Colors.orange,
                      ]),
                    ),
            );
          } else {
            return Container();
          }
        });
  }
}
