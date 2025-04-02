// Import Flutter package
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

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
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: InventoryHomePage(title: 'Inventory Home Page'),
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
  final CollectionReference _inventoryCollection =
      FirebaseFirestore.instance.collection('inventory');

  Future<void> _deleteItem(String itemId) async {
    await _inventoryCollection.doc(itemId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Item deleted successfully!')),
    );
  }

  void _navigateToEditItemScreen(String itemId, Map<String, dynamic> itemData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditItemScreen(itemId: itemId, itemData: itemData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _inventoryCollection.snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Your inventory is empty. Click the "+" button to add items.'));
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(data['name'] ?? 'No Name'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quantity: ${data['quantity'] ?? 0}'),
                      Text('Description: ${data['description'] ?? 'N/A'}'),
                      Text('Price: \$${(data['price'] ?? 0.0).toStringAsFixed(2)}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _navigateToEditItemScreen(document.id, data),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteItem(document.id),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddItemScreen()),
          );
        },
        tooltip: 'Add Item',
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddItemScreen extends StatefulWidget {
  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  final CollectionReference _inventoryCollection =
      FirebaseFirestore.instance.collection('inventory');

  Future<void> _addItem() async {
    if (_formKey.currentState!.validate()) {
      await _inventoryCollection.add({
        'name': _nameController.text.trim(),
        'quantity': int.tryParse(_quantityController.text.trim()) ?? 0,
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
      });
      Navigator.pop(context); // Go back to the inventory list screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item added successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Item Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the item name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Quantity'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the quantity';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description (Optional)'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Price (Optional)'),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty && double.tryParse(value.trim()) == null) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addItem,
                child: Text('Add Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditItemScreen extends StatefulWidget {
  final String itemId;
  final Map<String, dynamic> itemData;

  EditItemScreen({required this.itemId, required this.itemData});

  @override
  _EditItemScreenState createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  final CollectionReference _inventoryCollection =
      FirebaseFirestore.instance.collection('inventory');

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.itemData['name'] ?? '';
    _quantityController.text = widget.itemData['quantity']?.toString() ?? '';
    _descriptionController.text = widget.itemData['description'] ?? '';
    _priceController.text = widget.itemData['price']?.toString() ?? '';
  }

  Future<void> _updateItem() async {
    if (_formKey.currentState!.validate()) {
      await _inventoryCollection.doc(widget.itemId).update({
        'name': _nameController.text.trim(),
        'quantity': int.tryParse(_quantityController.text.trim()) ?? 0,
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
      });
      Navigator.pop(context); // Go back to the inventory list screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item updated successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Item Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the item name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Quantity'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the quantity';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description (Optional)'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Price (Optional)'),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty && double.tryParse(value.trim()) == null) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateItem,
                child: Text('Update Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}