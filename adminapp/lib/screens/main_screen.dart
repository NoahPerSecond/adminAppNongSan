import 'dart:io';
import 'dart:math';

import 'package:adminapp/screens/add_product_screen.dart';
import 'package:adminapp/screens/dashboard_screen.dart';
import 'package:adminapp/screens/order_screen.dart';
import 'package:adminapp/screens/product_screen.dart';
import 'package:adminapp/widgets/order_card.dart';
import 'package:adminapp/widgets/product_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<String> _bannerUrls = [];

  Future<void> _refreshScreen() async {
    try {
      // Gọi hàm tải dữ liệu cần thiết
      await _loadBanners();

      // Hiển thị thông báo thành công (nếu cần)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Screen refreshed successfully!')),
      );
    } catch (e) {
      // Xử lý lỗi nếu có
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refreshing screen: $e')),
      );
    }
  }

  Future<void> _loadBanners() async {
    final urls = await fetchLatestBannerUrls();
    setState(() {
      _bannerUrls = urls;
    });
  }

  Future<List<String>> fetchLatestBannerUrls() async {
    try {
      final ListResult result =
          await FirebaseStorage.instance.ref('banners').listAll();

      // Lấy danh sách các file
      final List<Reference> allFiles = result.items;

      // Sắp xếp file theo tên (giả sử tên file chứa timestamp)
      allFiles.sort((a, b) => b.name.compareTo(a.name)); // Descending order

      // Lấy 3 file mới nhất
      final List<Reference> latestFiles = allFiles.take(3).toList();

      // Lấy URL tải xuống cho từng file
      List<String> urls = [];
      for (Reference file in latestFiles) {
        final String url = await file.getDownloadURL();
        urls.add(url);
      }

      return urls;
    } catch (e) {
      print("Error fetching banners: $e");
      return [];
    }
  }

// //   Future<void> addCreatedAtToAllProducts() async {
//   Future<void> calculateAndUpdateSaleCount() async {
//     try {
//       // Get a reference to the 'orders' collection
//       CollectionReference ordersCollection =
//           FirebaseFirestore.instance.collection('orders');

//       // Fetch all orders
//       QuerySnapshot ordersSnapshot = await ordersCollection.get();

//       // Map to store the sale count for each product
//       Map<String, int> salesCountMap = {};

//       // Iterate through each order
//       for (var orderDoc in ordersSnapshot.docs) {
//         String productId = orderDoc['productId'];
//         int quantity = orderDoc['quantity'];

//         // Aggregate the sale count for each product
//         if (salesCountMap.containsKey(productId)) {
//           salesCountMap[productId] = salesCountMap[productId]! + quantity;
//         } else {
//           salesCountMap[productId] = quantity;
//         }
//       }

//       // Update each product with the calculated sale count
//       CollectionReference productsCollection =
//           FirebaseFirestore.instance.collection('product');

//       for (String productId in salesCountMap.keys) {
//         await productsCollection.doc(productId).update({
//           'saleCount': salesCountMap[productId],
//         });
//       }

//       // Show a confirmation message
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Sale counts updated successfully!')),
//       );
//     } catch (e) {
//       // Show error message
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   Future<void> resetSaleCountToZero() async {
//     try {
//       // Get a reference to the 'product' collection
//       CollectionReference productsCollection =
//           FirebaseFirestore.instance.collection('product');

//       // Fetch all products
//       QuerySnapshot productsSnapshot = await productsCollection.get();

//       // Iterate through each product and reset the saleCount to 0
//       for (var productDoc in productsSnapshot.docs) {
//         await productsCollection.doc(productDoc.id).update({
//           'saleCount': 0, // Reset saleCount to 0
//         });
//       }

//       // Show a confirmation message
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Sale counts reset to 0 for all products!')),
//       );
//     } catch (e) {
//       // Show error message
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<File?> _imageFiles = [null, null, null]; // To store selected images

  // // Function to pick an image
  // Future<void> _pickImage(int index) async {
  //   final XFile? pickedFile =
  //       await _picker.pickImage(source: ImageSource.gallery);
  //   if (pickedFile != null) {
  //     setState(() {
  //       _imageFiles[index] = File(pickedFile.path);
  //     });
  //   }
  // }
  Future<void> _pickImage(int index) async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFiles[index] = File(pickedFile.path);
      });

      // Tự động tải ảnh lên sau khi chọn
      await _uploadImage(index);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image uploaded successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No image selected!')),
      );
    }
  }

//   Future<void> _pickImage(int index) async {
//   final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
//   if (pickedFile != null) {
//     setState(() {
//       _imageFiles[index] = File(pickedFile.path); // Cập nhật hình ảnh được chọn
//     });
//   } else {
//     // Thông báo nếu người dùng hủy chọn
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('No image selected!')),
//     );
//   }
// }

  // Function to upload the image to Firebase Storage
  Future<void> _uploadImage(int index) async {
    if (_imageFiles[index] != null) {
      try {
        String fileName =
            'banners/${DateTime.now().millisecondsSinceEpoch}.jpg';
        TaskSnapshot snapshot =
            await _storage.ref(fileName).putFile(_imageFiles[index]!);
        String downloadUrl = await snapshot.ref.getDownloadURL();
        print("Image uploaded successfully: $downloadUrl");
      } catch (e) {
        print("Error uploading image: $e");
      }
    }
  }

  

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadBanners();
  }

  final ScrollController _scrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Main Screen',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          InkWell(
            child: Icon(Icons.menu),
            onTap: ()=>Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => DashboardScreen())),
          )
        ],
        backgroundColor: Colors.green, // Set AppBar color
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: RefreshIndicator(
          onRefresh: _refreshScreen,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Align items to the start
              children: [
                // Row to align the Add Product button and Products text
                Row(
                  mainAxisAlignment: MainAxisAlignment
                      .spaceBetween, // Space between button and text
                  children: [
                    Text(
                      'Products',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800], // Darker green for text
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AddProductScreen(),
                          ),
                        );
                        // calculateAndUpdateSaleCount();
                        // resetSaleCountToZero();
                        // addCreatedAtToAllProducts();
                        // addSaleCountToAllProducts();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.green, // Button text color
                        padding: const EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 20.0), // Padding
                      ),
                      child: Text('Add Product',
                          style: TextStyle(fontSize: 16)), // Button text style
                    ),
                  ],
                ),
                const SizedBox(
                    height: 20), // Space between row and product list
                Container(
                  height: 230,
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('product')
                        .orderBy('createdAt')
                        .snapshots(),
                    builder: (context,
                        AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                            snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) => ProductCard(
                          snap: snapshot.data!.docs[index].data(),
                          productId: snapshot.data!.docs[index].id,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Spacer(), // Đẩy Text ra cuối dòng
                    InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ProductScreen(),
                        ),
                      ),
                      child: Text(
                        'See all products',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20), // Space before orders section
                Text(
                  'Orders',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800], // Darker green for text
                  ),
                ),
                StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context,
                      AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                          snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return Container(
                      height: 600,
                      child: Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: ListView.builder(
                          controller: _scrollController,
                          shrinkWrap: true,
                          scrollDirection: Axis.vertical,
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) => OrderCard(
                            snap: snapshot.data!.docs[index].data(),
                            ordertId: snapshot.data!.docs[index].id,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Row(
                  children: [
                    Spacer(), // Đẩy Text ra cuối dòng
                    InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => OrderScreen(),
                        ),
                      ),
                      child: Text(
                        'See all orders',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20), // Space before orders section
                Text(
                  'Banners',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800], // Darker green for text
                  ),
                ),
                SizedBox(
                  height: 200, // Adjust the height as necessary
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _bannerUrls.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _pickImage(index),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _bannerUrls[index] == null
                              ? Center(
                                  child: Icon(Icons.add, size: 50),
                                )
                              : Image.network(
                                  _bannerUrls[index], // Hiển thị banner từ URL
                                  fit: BoxFit.cover,
                                ),
                        ),
                      );
                    },
                  ),
                ),
                // Add this button below the GridView.builder
                const SizedBox(height: 20), // Space before the button
                // Align(
                //   alignment: Alignment.center,
                //   child: ElevatedButton(
                //     onPressed: () async {
                //       for (int i = 0; i < _imageFiles.length; i++) {
                //         if (_imageFiles[i] != null) {
                //           await _uploadImage(i); // Upload each selected image
                //         }
                //       }
                //       ScaffoldMessenger.of(context).showSnackBar(
                //         SnackBar(
                //             content: Text(
                //                 'All selected images uploaded successfully!')),
                //       );
                //     },
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: Colors.green,
                //       padding: const EdgeInsets.symmetric(
                //           vertical: 12.0, horizontal: 24.0),
                //     ),
                //     child: const Text(
                //       'Upload Banners',
                //       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
