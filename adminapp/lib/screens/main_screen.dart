import 'package:adminapp/screens/add_product_screen.dart';
import 'package:adminapp/widgets/order_card.dart';
import 'package:adminapp/widgets/product_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Main Screen',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green, // Set AppBar color
      ),
      body: Container(
        color: Colors.green[50], // Light green background
        padding: const EdgeInsets.all(16.0), // Add some padding
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
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => AddProductScreen(),
                      ),
                    );
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
            const SizedBox(height: 20), // Space between row and product list
            Container(
              height: 230,
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('product')
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
                Text(
                  'See all products',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              stream:
                  FirebaseFirestore.instance.collection('orders').snapshots(),
              builder: (context,
                  AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                      snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) => OrderCard(
                      snap: snapshot.data!.docs[index].data(),
                      ordertId: snapshot.data!.docs[index].id,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
