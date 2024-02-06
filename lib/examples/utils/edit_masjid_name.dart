import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:masjid_app/examples/utils/show_alert_dialog.dart';
import 'package:toastification/toastification.dart';

class EditModal extends StatefulWidget {
  final String currentName;
  final String currentId;
  final Function(String) onNameUpdated;

  const EditModal(
      {super.key,
      required this.currentName,
      required this.onNameUpdated,
      required this.currentId});

  @override
  _EditModalState createState() => _EditModalState();
}

class _EditModalState extends State<EditModal> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
  }

  Future<void> updateFirestoreName(String masjidId, String newName) async {
    try {
      await FirebaseFirestore.instance
          .collection('masjids')
          .doc(masjidId)
          .update({
        'name': newName,
      });
      if (!context.mounted) return;
      showAlertDialog(
          context,
          title: "Tabriklaymiz!",
          "Siz masjid nomini muvaffaqiyatli o'zgartirdingiz...",
          toastType: ToastificationType.success,
          toastAlignment: Alignment.topCenter,
          margin: const EdgeInsets.only(top: 28.0));
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error updating name: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Image.asset(
            'assets/mosque.png',
            width: 200,
            height: 200,
            fit: BoxFit.fill,
          ),
          const SizedBox(
            height: 25,
          ),
          TextField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Masjid nomini o'zgartirish...",
            ),
            controller: _nameController,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  // Update the name in Firestore
                  await updateFirestoreName(
                      widget.currentId, _nameController.text);
                  // Update the local state
                  widget.onNameUpdated(_nameController.text);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
