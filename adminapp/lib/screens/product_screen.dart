import 'package:adminapp/widgets/product_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          'Sản phẩm',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim().toLowerCase(); // Cập nhật từ khóa tìm kiếm
                });
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(1.0), // Adjust the overall padding
        child: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('product').snapshots(),
          builder: (context,
              AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            // Lọc sản phẩm dựa trên từ khóa tìm kiếm
            final filteredDocs = snapshot.data!.docs.where((doc) {
              String productName =
                  (doc['name'] as String).toLowerCase().replaceAll(' ', '');
              String query = searchQuery.replaceAll(' ', '');
              return productName.contains(query);
            }).toList();

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 cards per row
                childAspectRatio: 0.75, // Adjust this value for height/width ratio
                crossAxisSpacing: 8.0, // Space between cards horizontally
                mainAxisSpacing: 8.0, // Space between cards vertically
              ),
              itemCount: filteredDocs.length,
              itemBuilder: (context, index) => ProductCard(
                snap: filteredDocs[index].data(),
                productId: filteredDocs[index].id,
              ),
            );
          },
        ),
      ),
    );
  }
}
