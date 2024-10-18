import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> snap; // Order data
  final String productId; // Order ID

  OrderCard({required this.snap, required this.productId});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.all(10.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side: Order details
            Flexible(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Họ và tên: ${snap['recipientName'] ?? 'N/A'}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text("Địa chỉ: ${snap['recipientAddress'] ?? 'N/A'}",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 5),
                  Text("Số điện thoại: ${snap['recipientPhoneNum'] ?? 'N/A'}",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 5),
                  Text("Tổng cộng: ${snap['totalAmount']} VND",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 5),
                  Text("Trạng thái: ${snap['orderStatus'] ?? 'Chưa xác nhận'}",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            const SizedBox(width: 20), // Space between text and buttons
            // Right side: Action buttons
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () => _updateOrderStatus(context, 'Xác nhận'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Button color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Xác Nhận"),
                ),
                const SizedBox(height: 10), // Spacing between buttons
                ElevatedButton(
                  onPressed: () => _updateOrderStatus(context, 'Từ chối'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // Button color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Từ Chối"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateOrderStatus(BuildContext context, String status) async {
    await FirebaseFirestore.instance.collection('orders').doc(productId).update({
      'orderStatus': status,
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đơn hàng đã được $status")),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $error")),
      );
    });
  }
}
