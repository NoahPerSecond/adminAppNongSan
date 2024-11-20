import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OrderCard extends StatefulWidget {
  final Map<String, dynamic> snap; // Order data
  final String ordertId; // Order ID

  OrderCard({required this.snap, required this.ordertId});

  @override
  _OrderCardState createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool isProcessed = false; // Track if the order has been processed

  @override
  void initState() {
    super.initState();
    // Check if the order has been processed or if it is in the pending state
    isProcessed = widget.snap['orderStatus'] == 'Xác nhận' ||
        widget.snap['orderStatus'] == 'Từ chối';
  }

  void _updateOrderStatus(BuildContext context, String status) async {
    // Get product information to adjust the stock quantity
    DocumentSnapshot productSnapshot = await FirebaseFirestore.instance
        .collection('product')
        .doc(widget.snap['productId']) // Get productId from order
        .get();

    if (productSnapshot.exists) {
      int currentStock = productSnapshot['stockQuantity'] ?? 0;
      int orderQuantity = widget.snap['quantity'] ?? 0;

      // Check stock quantity
      if (currentStock >= orderQuantity && status == 'Xác nhận') {
        // Deduct the product quantity
        await FirebaseFirestore.instance
            .collection('product')
            .doc(widget.snap['productId'])
            .update({
          'stockQuantity': currentStock - orderQuantity,
        });
      } else if (status == 'Xác nhận') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text("Số lượng sản phẩm không đủ để xác nhận đơn hàng.")),
        );
        return; // Do not update order status
      }
    }

    // Update order status to 'Xác nhận'
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.ordertId)
        .update({
      'orderStatus': status,
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đơn hàng đã được $status")),
      );
      setState(() {
        isProcessed = true; // Update status after processing
      });

      // After 10 seconds, update the status to 'Đang giao'
      if (status == 'Xác nhận') {
        Future.delayed(const Duration(seconds: 10), () async {
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(widget.ordertId)
              .update({
            'orderStatus': 'Đang giao',
          }).then((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      "Đơn hàng đã được chuyển sang trạng thái Đang giao.")),
            );
          }).catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Lỗi: $error")),
            );
          });
        });
      }

      if (status == 'Xác nhận') {
        // After 1 hour, update the status to 'Hoàn thành'
        Future.delayed(const Duration(seconds: 20), () async {
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(widget.ordertId)
              .update({
            'orderStatus': 'Hoàn thành',
          }).then((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Đơn hàng đã hoàn thành.")),
            );
          }).catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Lỗi: $error")),
            );
          });
        });
      }
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $error")),
      );
    });
  }

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
                    "Họ và tên: ${widget.snap['recipientName'] ?? 'N/A'}",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text("Địa chỉ: ${widget.snap['recipientAddress'] ?? 'N/A'}",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 5),
                  Text(
                      "Số điện thoại: ${widget.snap['recipientPhoneNum'] ?? 'N/A'}",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 5),
                  Text("Tên sản phẩm: ${widget.snap['productName'] ?? 'N/A'}",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 5),
                  Text("Tổng cộng: ${widget.snap['totalAmount']} VND",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 5),
                  Text(
                      "Trạng thái: ${widget.snap['orderStatus'] ?? 'Chưa xác nhận'}",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 5),
                  Text("Số lượng: ${widget.snap['quantity'] ?? 1}",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 5),
                  Text(
                    "Thời gian mua: ${_formatTimestamp(widget.snap['timestamp'])}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            const SizedBox(width: 20), // Space between text and buttons
            // Right side: Action buttons
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Show buttons only if the order is pending
                if (widget.snap['orderStatus'] == 'Chờ xác nhận') ...[
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTimestamp(dynamic timestamp) {
  if (timestamp == null) return "N/A";

  try {
    // Convert Firestore Timestamp or milliseconds to DateTime
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is int) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      return "Invalid timestamp";
    }

    // Format the DateTime to a readable format
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime);
  } catch (e) {
    return "Error formatting date";
  }
}
