import 'package:flutter/material.dart';
import 'package:mynotes/extensions/buildcontext/loc.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/utilities/dialogs/cannot_share_empty_note_dialog.dart';
import 'package:mynotes/utilities/generics/get_arguments.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/firebase_cloud_storage.dart';
import 'package:share_plus/share_plus.dart';
class CreateUpdateNoteView extends StatefulWidget {
  const CreateUpdateNoteView({super.key});

  @override
  State<CreateUpdateNoteView> createState() => _CreateUpdateNoteViewState();
}

class _CreateUpdateNoteViewState extends State<CreateUpdateNoteView> {
  CloudNote? _note;
  late final FirebaseCloudStorage _notesService;
  late final TextEditingController _textController;

  @override
  void initState(){
    _notesService = FirebaseCloudStorage();
    _textController = TextEditingController();
    super.initState();
  }

   Future<CloudNote> createOrGetExistingNote(BuildContext context) async {
    final widgetNote = context.getArgument<CloudNote>();
    if (widgetNote != null) {
      _note = widgetNote;
      _textController.text = widgetNote.text;
      return widgetNote;
    }
    final existingNote = _note;
    if (existingNote != null) {
      return existingNote;
    }
    final currentUser = AuthService.firebase().currentUser!;
    final userId = currentUser.id;
    final newNote = await _notesService.createNewNote(ownerUserId: userId);
    _note = newNote;
    _setupTextControllerListener(); 
    return newNote;
  }

  void _deleteNoteIfTextEmpty(){
    final note = _note;
    if (_textController.text.isEmpty && note != null) {
      _notesService.deleteNote(documentId: note.documentId);
    }
  }

  void _textControllerListener() async{
    final note = _note;
    if (note == null) {
      return;
    }
    final text = _textController.text;
    await _notesService.updateNote(documentId: note.documentId, text: text);
  }

  void _setupTextControllerListener(){
    _textController.removeListener(_textControllerListener);
    _textController.addListener(_textControllerListener);
  }

  void _saveNoteIfTextNotEmpty() async{
    final note = _note;
    final text = _textController.text;
    if (_textController.text.isNotEmpty && note != null ){
      await _notesService.updateNote(documentId: note.documentId, text: text);
    }
  }

  @override
  void dispose() {
    _deleteNoteIfTextEmpty();
    _saveNoteIfTextNotEmpty();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text(context.loc.note),
        backgroundColor: Color.fromARGB(239, 12, 12, 238),
        actions: [
          IconButton(onPressed: () async {
            final text = _textController.text;
            if(_note == null || text.isEmpty){
              await showCannotShareEmptyNoteDialog(context);
            } else{
              // ignore: deprecated_member_use
              Share.share(text);
            }
          }, icon: const Icon(Icons.share))
        ],
      ),
        body: FutureBuilder(
          future: createOrGetExistingNote(context), 
          builder: (context,snapshot){
            switch (snapshot.connectionState){
              case ConnectionState.done:
                return TextField(
                  controller: _textController,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  decoration:  InputDecoration(
                    hintText: context.loc.start_typing_your_note,
                  ),
                );
              default:
                return const CircularProgressIndicator();
            }
          })
      );
  }
}