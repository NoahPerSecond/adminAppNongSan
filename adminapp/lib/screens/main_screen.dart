import 'dart:math';

import 'package:adminapp/screens/add_product_screen.dart';
import 'package:adminapp/screens/product_screen.dart';
import 'package:adminapp/widgets/order_card.dart';
import 'package:adminapp/widgets/product_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
//   Future<void> addCreatedAtToAllProducts() async {
 Future<void> calculateAndUpdateSaleCount() async {
    try {
      

      // Get a reference to the 'orders' collection
      CollectionReference ordersCollection = FirebaseFirestore.instance.collection('orders');

      // Fetch all orders
      QuerySnapshot ordersSnapshot = await ordersCollection.get();

      // Map to store the sale count for each product
      Map<String, int> salesCountMap = {};

      // Iterate through each order
      for (var orderDoc in ordersSnapshot.docs) {
        String productId = orderDoc['productId'];
        int quantity = orderDoc['quantity'];

        // Aggregate the sale count for each product
        if (salesCountMap.containsKey(productId)) {
          salesCountMap[productId] = salesCountMap[productId]! + quantity;
        } else {
          salesCountMap[productId] = quantity;
        }
      }

      // Update each product with the calculated sale count
      CollectionReference productsCollection = FirebaseFirestore.instance.collection('product');

      for (String productId in salesCountMap.keys) {
        await productsCollection.doc(productId).update({
          'saleCount': salesCountMap[productId],
        });
      }

      
      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sale counts updated successfully!')),
      );
    } catch (e) {
      

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> resetSaleCountToZero() async {
    try {
      

      // Get a reference to the 'product' collection
      CollectionReference productsCollection = FirebaseFirestore.instance.collection('product');

      // Fetch all products
      QuerySnapshot productsSnapshot = await productsCollection.get();

      // Iterate through each product and reset the saleCount to 0
      for (var productDoc in productsSnapshot.docs) {
        await productsCollection.doc(productDoc.id).update({
          'saleCount': 0, // Reset saleCount to 0
        });
      }

      

      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sale counts reset to 0 for all products!')),
      );
    } catch (e) {
      

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

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
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AddProductScreen(),
                      ),
                    );
                    calculateAndUpdateSaleCount();
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
            const SizedBox(height: 20), // Space between row and product list
            Container(
              height: 230,
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('product').orderBy('createdAt')
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
                  onTap: ()=>Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProductScreen(),
                      ),
                    ),
                  child: Text(
                    'See all products',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              stream:
                  FirebaseFirestore.instance.collection('orders').orderBy('timestamp', descending: true).snapshots(),
              builder: (context,
                  AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                      snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Flexible(
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: ListView.builder(
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
            const SizedBox(height: 20), // Space before orders section
            Text(
              'Banners',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green[800], // Darker green for text
              ),
            ),
          ],
        ),
      ),
    );
  }
}
