import 'package:adminapp/widgets/order_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';



class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  String searchQuery = ""; // Query cho tìm kiếm

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Quản lý đơn hàng",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim().toLowerCase(); // Cập nhật query
                });
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên, trạng thái...',
                prefixIcon: const Icon(Icons.search),
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
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('orders').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Lọc dữ liệu dựa trên từ khóa tìm kiếm
          final filteredOrders = snapshot.data!.docs.where((doc) {
            final data = doc.data();
            final recipientName = (data['recipientName'] as String? ?? '').toLowerCase();
            final orderStatus = (data['orderStatus'] as String? ?? '').toLowerCase();

            // Tìm kiếm theo tên người nhận hoặc trạng thái đơn hàng
            return recipientName.contains(searchQuery) || orderStatus.contains(searchQuery);
          }).toList();

          // Hiển thị danh sách đơn hàng
          return ListView.builder(
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) {
              final orderData = filteredOrders[index].data();
              final orderId = filteredOrders[index].id;

              return OrderCard(
                snap: orderData,
                ordertId: orderId,
              );
            },
          );
        },
      ),
    );
  }
}
