import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(InventoryApp());
}

class InventoryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Management App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: InventoryHomePage(title: 'Inventory Home Page'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class InventoryHomePage extends StatefulWidget {
  InventoryHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _InventoryHomePageState createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends State<InventoryHomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _addItem() async {
    TextEditingController nameController = TextEditingController();
    TextEditingController quantityController = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add Inventory Item'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Item Name'),
                ),
                TextField(
                  controller: quantityController,
                  decoration: InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  String name = nameController.text.trim();
                  int? quantity = int.tryParse(quantityController.text.trim());
                  if (name.isNotEmpty && quantity != null) {
                    await _firestore.collection('inventory').add({
                      'name': name,
                      'quantity': quantity,
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text('Add'),
              ),
            ],
          ),
    );
  }

  void _updateItem(DocumentSnapshot doc) async {
    TextEditingController nameController = TextEditingController(
      text: doc['name'],
    );
    TextEditingController quantityController = TextEditingController(
      text: doc['quantity'].toString(),
    );

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit Inventory Item'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Item Name'),
                ),
                TextField(
                  controller: quantityController,
                  decoration: InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  String name = nameController.text.trim();
                  int? quantity = int.tryParse(quantityController.text.trim());
                  if (name.isNotEmpty && quantity != null) {
                    await _firestore.collection('inventory').doc(doc.id).update(
                      {'name': name, 'quantity': quantity},
                    );
                    Navigator.pop(context);
                  }
                },
                child: Text('Update'),
              ),
            ],
          ),
    );
  }

  void _deleteItem(String docId) async {
    await _firestore.collection('inventory').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _firestore
                .collection('inventory')
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text('Error loading items'));
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());

          final items = snapshot.data!.docs;

          if (items.isEmpty)
            return Center(child: Text('No items in inventory'));

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final doc = items[index];
              return ListTile(
                title: Text(doc['name']),
                subtitle: Text('Quantity: ${doc['quantity']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.orange),
                      onPressed: () => _updateItem(doc),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteItem(doc.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        tooltip: 'Add Item',
        child: Icon(Icons.add),
      ),
    );
  }
}