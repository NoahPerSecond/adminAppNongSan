import 'dart:io';
import 'package:adminapp/screens/main_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class AddProductScreen extends StatefulWidget {
  AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  XFile? _image;
  final picker = ImagePicker();

  // Trạng thái cho phần giảm giá
  bool isDiscounted = false;

  // TextEditingControllers để lấy giá trị từ TextField
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController typeController = TextEditingController();
  final TextEditingController productionPlaceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController discountedPriceController = TextEditingController();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
      });
    }
  }

  Future<String> uploadImageToFirebase(File imageFile) async {
    String fileName = Uuid().v4(); // Generate a unique filename
    Reference storageRef = FirebaseStorage.instance.ref().child('images/$fileName.jpg');
    UploadTask uploadTask = storageRef.putFile(imageFile);
    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  Future<void> _saveProduct() async {
    String name = nameController.text;
    String description = descriptionController.text;
    String type = typeController.text;
    String productionPlace = productionPlaceController.text;
    int quantity = int.tryParse(quantityController.text) ?? 0; // Default to 0 if parsing fails
    double price = double.tryParse(priceController.text) ?? 0.0; // Default to 0.0 if parsing fails
    double? discountedPrice = isDiscounted ? (double.tryParse(discountedPriceController.text) ?? 0.0) : null;

    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn hình ảnh sản phẩm!')),
      );
      return;
    }

    // Kiểm tra đầu vào
    if (name.isEmpty || description.isEmpty || type.isEmpty || productionPlace.isEmpty || quantity <= 0 || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin sản phẩm!')),
      );
      return;
    }

    String imageUrl = await uploadImageToFirebase(File(_image!.path));
    var uuid = Uuid();
    String productId = uuid.v4();

    await FirebaseFirestore.instance.collection('product').doc(productId).set({
      'id': productId,
      'name': name,
      'description': description,
      'category': type,
      'origin': productionPlace,
      'stockQuantity': quantity,
      'price': price, // Lưu giá dưới dạng số
      'newPrice': isDiscounted ? discountedPrice : null, // Lưu giá giảm cũng dưới dạng số hoặc null
      'isSale': isDiscounted,
      'imageUrl': imageUrl,
      'rating': 0,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sản phẩm đã được lưu thành công!')),
    );

    // Reset các trường sau khi lưu
    _resetFields();
  }

  void _resetFields() {
    nameController.clear();
    descriptionController.clear();
    typeController.clear();
    productionPlaceController.clear();
    quantityController.clear();
    priceController.clear();
    discountedPriceController.clear();
    setState(() {
      _image = null;
      isDiscounted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm sản phẩm', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green, // Màu xanh lá cây cho AppBar
        leading: IconButton(
          icon: Icon(Icons.arrow_back_sharp, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => MainScreen()),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => BottomSheet(
                        onClosing: () {},
                        builder: (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.camera),
                              title: const Text('Chụp ảnh'),
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage(ImageSource.camera);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo),
                              title: const Text('Chọn ảnh từ thư viện'),
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage(ImageSource.gallery);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Màu xanh lá cây cho nút
                  ),
                  child: const Text('Chọn hoặc chụp ảnh', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: _image == null
                    ? const Text('Chưa chọn ảnh.')
                    : Image.file(
                        File(_image!.path),
                        height: 200,
                      ),
              ),
              const SizedBox(height: 16),
              _buildTextField(nameController, 'Tên sản phẩm'),
              const SizedBox(height: 16),
              _buildTextField(descriptionController, 'Miêu tả'),
              const SizedBox(height: 16),
              _buildTextField(typeController, 'Loại sản phẩm'),
              const SizedBox(height: 16),
              _buildTextField(productionPlaceController, 'Nơi sản xuất'),
              const SizedBox(height: 16),
              _buildTextField(quantityController, 'Số lượng', isNumber: true),
              const SizedBox(height: 16),
              _buildTextField(priceController, 'Giá sản phẩm', isNumber: true),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sản phẩm có giảm giá không?', style: TextStyle(fontSize: 16)),
                  Switch(
                    value: isDiscounted,
                    onChanged: (value) {
                      setState(() {
                        isDiscounted = value;
                      });
                    },
                    activeColor: Colors.green,
                  ),
                ],
              ),
              if (isDiscounted) ...[
                const SizedBox(height: 16),
                _buildTextField(discountedPriceController, 'Giá sau giảm', isNumber: true),
              ],
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Lưu sản phẩm', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.green),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.green),
            ),
          ),
        ),
      ],
    );
  }
}
