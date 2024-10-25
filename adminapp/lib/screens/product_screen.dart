
import 'package:adminapp/widgets/product_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductScreen extends StatelessWidget {
  const ProductScreen({super.key});

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
        
      ),
      body: Padding(
        padding: const EdgeInsets.all(0), // Adjust the overall padding
        child: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('product').snapshots(),
          builder: (context,
              AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 cards per row
                childAspectRatio: 0.75, // Adjust this value for height/width ratio
                crossAxisSpacing: 8.0, // Space between cards horizontally
                mainAxisSpacing: 8.0, // Space between cards vertically
              ),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) => ProductCard(
                snap: snapshot.data!.docs[index].data(),
                productId: snapshot.data!.docs[index].id,
              ),
            );
          },
        ),
      ),
    );
  }
}
