import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _tipoController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _precoController = TextEditingController();
  final TextEditingController _dataEntregaController = TextEditingController();

  final CollectionReference _bolos = FirebaseFirestore.instance.collection('bolos');

  File? _boloImage;
  final Color _primaryColor = Color(0xFF6f5ee0);

  Future<void> _pickBoloImage() async {
    final pickedImage = await ImagePicker().getImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _boloImage = File(pickedImage.path);
      });
    }
  }

  Future<String?> _uploadImageToFirebase(File? imageFile) async {
    if (imageFile == null) return null;
    final storageReference = FirebaseStorage.instance.ref().child('bolos/${DateTime.now().toIso8601String()}.png');
    await storageReference.putFile(imageFile);
    return await storageReference.getDownloadURL();
  }

  Future<void> _createOrUpdate([DocumentSnapshot? documentSnapshot]) async {
    String action = 'create';

    if (documentSnapshot != null) {
      action = 'update';
      _tipoController.text = documentSnapshot['tipo'];
      _descricaoController.text = documentSnapshot['descricao'];
      _precoController.text = documentSnapshot['preco'].toString();
      _dataEntregaController.text = documentSnapshot['dataEntrega'];
    }

    await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext ctx) {
          return Padding(
            padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _tipoController,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                ),
                TextField(
                  controller: _descricaoController,
                  decoration: const InputDecoration(labelText: 'Descricao'),
                ),
                TextField(
                  controller: _precoController,
                  decoration: const InputDecoration(
                    labelText: 'Preço',
                  ),
                ),
                TextField(
                  controller: _dataEntregaController,
                  decoration: const InputDecoration(labelText: 'DataEntrega'),
                ),
                const SizedBox(
                  height: 30,
                ),
                ElevatedButton(
                  child: const Text('Escolher Imagem do Bolo'),
                  style: ElevatedButton.styleFrom(
                    primary: Color(0xFF6f5ee0),
                  ),
                  onPressed: _pickBoloImage,
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  child: Text(action == 'create' ? 'Cadastrar' : 'Alterar'),
                  style: ElevatedButton.styleFrom(
                    primary: Color(0xFF6f5ee0),
                  ),
                  onPressed: () async {
                    final String? tipo = _tipoController.text;
                    final String? descricao = _descricaoController.text;
                    final String? preco = _precoController.text;
                    final String? dataEntrega = _dataEntregaController.text;
                    final imageUrl = await _uploadImageToFirebase(_boloImage);

                    if (tipo != null && descricao != null && preco != null && dataEntrega != null) {
                      if (action == 'create') {
                        await _bolos.add({
                          "tipo": tipo,
                          "descricao": descricao,
                          "preco": preco,
                          "dataEntrega": dataEntrega,
                          "imageUrl": imageUrl
                        });
                      }

                      if (action == 'update') {
                        await _bolos.doc(documentSnapshot!.id).update({
                          "tipo": tipo,
                          "descricao": descricao,
                          "preco": preco,
                          "dataEntrega": dataEntrega,
                          "imageUrl": imageUrl
                        });
                      }

                      _tipoController.text = '';
                      _descricaoController.text = '';
                      _precoController.text = '';
                      _dataEntregaController.text = '';
                      _boloImage = null;

                      Navigator.of(context).pop();
                    }
                  },
                )
              ],
            ),
          );
        });
  }

  Future<void> _deleteBolo(String boloId) async {
    await _bolos.doc(boloId).delete();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cookie excluído com sucesso'), backgroundColor: _primaryColor));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _primaryColor,
        title: const Text('Cookes.com'),
      ),
      body: StreamBuilder(
        stream: _bolos.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
             final DocumentSnapshot documentSnapshot = streamSnapshot.data!.docs[index];
            final data = documentSnapshot.data() as Map<String, dynamic>?;
          final imageUrl = data != null && data.containsKey('imageUrl') ? data['imageUrl'] : null;
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(documentSnapshot['tipo']),
                    subtitle: Text(documentSnapshot['preco'].toString()),
                    leading: imageUrl != null
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(imageUrl),
                          )
                        : null,
                    trailing: SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _createOrUpdate(documentSnapshot)),
                          IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteBolo(documentSnapshot.id)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primaryColor,
        onPressed: () => _createOrUpdate(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
