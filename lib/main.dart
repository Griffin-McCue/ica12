// Import Flutter package
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(InventoryApp());
}

class InventoryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Management App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: InventoryHomePage(title: 'Inventory Home Page'),
    );
  }
}

class InventoryHomePage extends StatefulWidget {
  InventoryHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _InventoryHomePageState createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends State<InventoryHomePage> {
  final CollectionReference _inventoryItems =
      FirebaseFirestore.instance.collection('products'); // Using 'products' collection

  Future<void> _addItem() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddItemScreen()),
    );
  }

  Future<void> _updateItem(DocumentSnapshot snapshot) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => UpdateItemScreen(item: snapshot)),
    );
  }

  Future<void> _deleteItem(String itemId) async {
    await _inventoryItems.doc(itemId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Successfully deleted the item')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _inventoryItems.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final inventoryData = snapshot.data!.docs;

          if (inventoryData.isEmpty) {
            return const Center(child: Text('Your inventory is empty.'));
          }

          return ListView.builder(
            itemCount: inventoryData.length,
            itemBuilder: (context, index) {
              final DocumentSnapshot documentSnapshot = inventoryData[index];
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(documentSnapshot['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quantity: ${documentSnapshot['quantity']}'),
                      Text('Price: \$${documentSnapshot['price'].toStringAsFixed(2)}'),
                    ],
                  ),
                  trailing: SizedBox(
                    width: 100,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _updateItem(documentSnapshot),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteItem(documentSnapshot.id),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddItemScreen extends StatefulWidget {
  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  final CollectionReference _inventoryItems =
      FirebaseFirestore.instance.collection('products'); // Using 'products' collection

  Future<void> _create() async {
    final String name = _nameController.text;
    final int? quantity = int.tryParse(_quantityController.text);
    final double? price = double.tryParse(_priceController.text);

    if (name.isNotEmpty && quantity != null && price != null) {
      await _inventoryItems.add({
        "name": name,
        "quantity": quantity,
        "price": price,
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully added an item')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields correctly')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _create,
              child: const Text('Add Item'),
            ),
          ],
        ),
      ),
    );
  }
}

class UpdateItemScreen extends StatefulWidget {
  final DocumentSnapshot? item;

  UpdateItemScreen({Key? key, this.item}) : super(key: key);

  @override
  _UpdateItemScreenState createState() => _UpdateItemScreenState();
}

class _UpdateItemScreenState extends State<UpdateItemScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  final CollectionReference _inventoryItems =
      FirebaseFirestore.instance.collection('products'); // Using 'products' collection

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!['name'];
      _quantityController.text = widget.item!['quantity'].toString();
      _priceController.text = widget.item!['price'].toString();
    }
  }

  Future<void> _update() async {
    final String name = _nameController.text;
    final int? quantity = int.tryParse(_quantityController.text);
    final double? price = double.tryParse(_priceController.text);

    if (name.isNotEmpty && quantity != null && price != null) {
      await _inventoryItems.doc(widget.item!.id).update({
        "name": name,
        "quantity": quantity,
        "price": price,
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully updated the item')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields correctly')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _update,
              child: const Text('Update Item'),
            ),
          ],
        ),
      ),
    );
  }
}