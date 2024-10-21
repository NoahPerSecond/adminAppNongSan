import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderCard extends StatefulWidget {
  final Map<String, dynamic> snap; // Order data
  final String ordertId; // Order ID

  OrderCard({required this.snap, required this.ordertId});

  @override
  _OrderCardState createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool isProcessed = false; // Biến trạng thái để theo dõi xem đơn hàng đã được xử lý chưa

  @override
  void initState() {
    super.initState();
    // Kiểm tra xem đơn hàng đã được xử lý chưa
    isProcessed = widget.snap['orderStatus'] == 'Xác nhận' || widget.snap['orderStatus'] == 'Từ chối';
  }

  void _updateOrderStatus(BuildContext context, String status) async {
    // Lấy thông tin sản phẩm để trừ số lượng
    DocumentSnapshot productSnapshot = await FirebaseFirestore.instance
        .collection('product')
        .doc(widget.snap['productId']) // Lấy productId từ đơn hàng
        .get();

    if (productSnapshot.exists) {
      int currentStock = productSnapshot['stockQuantity'] ?? 0;
      int orderQuantity = widget.snap['quantity'] ?? 0;

      // Kiểm tra số lượng tồn kho
      if (currentStock >= orderQuantity && status == 'Xác nhận') {
        // Trừ số lượng sản phẩm
        await FirebaseFirestore.instance
            .collection('product')
            .doc(widget.snap['productId'])
            .update({
          'stockQuantity': currentStock - orderQuantity,
        });
      } else if (status == 'Xác nhận') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Số lượng sản phẩm không đủ để xác nhận đơn hàng.")),
        );
        return; // Không thực hiện cập nhật trạng thái đơn hàng
      }
    }

    // Cập nhật trạng thái đơn hàng
    await FirebaseFirestore.instance.collection('orders').doc(widget.ordertId).update({
      'orderStatus': status,
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đơn hàng đã được $status")),
      );
      setState(() {
        isProcessed = true; // Cập nhật trạng thái sau khi xử lý
      });
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
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text("Địa chỉ: ${widget.snap['recipientAddress'] ?? 'N/A'}",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 5),
                  Text("Số điện thoại: ${widget.snap['recipientPhoneNum'] ?? 'N/A'}",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 5),
                  Text("Tên sản phẩm: ${widget.snap['productName'] ?? 'N/A'}", // Hiển thị tên sản phẩm
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 5),
                  Text("Tổng cộng: ${widget.snap['totalAmount']} VND",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 5),
                  Text("Trạng thái: ${widget.snap['orderStatus'] ?? 'Chưa xác nhận'}",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 5),
                  Text("Số lượng: ${widget.snap['quantity'] ?? 1}",
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
                // Ẩn nút nếu đơn hàng đã được xử lý
                if (!isProcessed) ...[
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
