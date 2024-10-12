import 'dart:io';
import 'package:adminapp/screens/main_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class EditProductScreen extends StatefulWidget {
  final String productId;

  EditProductScreen({super.key, required this.productId});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  XFile? _image;
  final picker = ImagePicker();
  bool isDiscounted = false;

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController typeController = TextEditingController();
  final TextEditingController productionPlaceController =
      TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController discountedPriceController =
      TextEditingController();

  bool isLoading = true;
  String? existingImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProductData();
  }

  Future<void> _deleteProduct() async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa sản phẩm'),
          content: const Text('Bạn có chắc chắn muốn xóa sản phẩm này không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Không xóa
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Xác nhận xóa
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      await FirebaseFirestore.instance
          .collection('product')
          .doc(widget.productId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sản phẩm đã được xóa thành công!')),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    }
  }

  Future<void> _loadProductData() async {
    DocumentSnapshot productDoc = await FirebaseFirestore.instance
        .collection('product')
        .doc(widget.productId)
        .get();
    if (productDoc.exists) {
      var productData = productDoc.data() as Map<String, dynamic>;
      nameController.text = productData['name'];
      descriptionController.text = productData['description'];
      typeController.text = productData['category'];
      productionPlaceController.text = productData['origin'];
      quantityController.text = productData['stockQuantity'].toString();
      priceController.text = productData['price'].toString();
      if (productData['isSale']) {
        discountedPriceController.text = productData['newPrice'].toString();
        isDiscounted = true;
      }
      existingImageUrl = productData['imageUrl'];
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String> uploadImageToFirebase(File imageFile) async {
    String fileName = Uuid().v4(); // Generate a unique filename
    Reference storageRef =
        FirebaseStorage.instance.ref().child('images/$fileName.jpg');
    UploadTask uploadTask = storageRef.putFile(imageFile);
    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  Future<void> _updateProduct() async {
    String name = nameController.text;
    String description = descriptionController.text;
    String type = typeController.text;
    String productionPlace = productionPlaceController.text;

    // Nếu người dùng không nhập lại giá, giữ nguyên giá hiện tại
    double? price = double.tryParse(priceController.text);
    double? discountedPrice =
        isDiscounted ? double.tryParse(discountedPriceController.text) : null;

    // Nếu price là null và người dùng không sửa, giữ nguyên giá cũ
    DocumentSnapshot productDoc = await FirebaseFirestore.instance
        .collection('product')
        .doc(widget.productId)
        .get();
    double existingPrice = productDoc['price'];
    double? existingDiscountedPrice = productDoc['newPrice'];

    if (price == null) {
      price = existingPrice; // giữ nguyên giá cũ
    }

    if (isDiscounted && discountedPrice == null) {
      discountedPrice = existingDiscountedPrice; // giữ nguyên giá giảm cũ
    }

    String? imageUrl;
    if (_image != null) {
      imageUrl = await uploadImageToFirebase(File(_image!.path));
    } else {
      imageUrl = existingImageUrl; // Sử dụng ảnh cũ nếu không có ảnh mới
    }

    Map<String, dynamic> updatedData = {
      'name': name,
      'description': description,
      'category': type,
      'origin': productionPlace,
      'stockQuantity': int.tryParse(quantityController.text) ?? 0,
      'price': price,
      'newPrice': isDiscounted ? discountedPrice : null,
      'isSale': isDiscounted,
      'imageUrl': imageUrl,
    };

    await FirebaseFirestore.instance
        .collection('product')
        .doc(widget.productId)
        .update(updatedData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sản phẩm đã được cập nhật thành công!')),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa sản phẩm',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_sharp, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => MainScreen()),
            );
          },
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
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
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Chọn hoặc chụp ảnh',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: _image == null
                          ? existingImageUrl != null
                              ? Image.network(
                                  existingImageUrl!,
                                  height: 200,
                                )
                              : const Text('Chưa có ảnh sản phẩm.')
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
                    _buildTextField(quantityController, 'Số lượng',
                        isNumber: true),
                    const SizedBox(height: 16),
                    _buildTextField(priceController, 'Giá sản phẩm',
                        isNumber: true),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sản phẩm có giảm giá không?',
                            style: TextStyle(fontSize: 16)),
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
                      _buildTextField(discountedPriceController, 'Giá sau giảm',
                          isNumber: true),
                    ],
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton(
                        onPressed: _updateProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Cập nhật sản phẩm',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(
                        height: 16), // Thêm khoảng trống giữa các nút
                    Center(
                      child: ElevatedButton(
                        onPressed: _deleteProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.red, // Màu đỏ để biểu thị nút xóa
                        ),
                        child: const Text('Xóa sản phẩm',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isNumber = false}) {
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

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
      });
    }
  }
}
