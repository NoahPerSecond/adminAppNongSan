import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime startDate =
      DateTime.now().subtract(Duration(days: 30)); // Mặc định 30 ngày trước
  DateTime endDate = DateTime.now(); // Mặc định ngày hiện tại

  // Hàm chọn ngày bắt đầu
  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != startDate) {
      setState(() {
        startDate = picked;
      });
    }
  }

  // Hàm chọn ngày kết thúc
  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: startDate, // Đảm bảo ngày kết thúc không nhỏ hơn ngày bắt đầu
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != endDate) {
      setState(() {
        endDate = picked;
      });
    }
  }

  Future<int> fetchCustomerCount() async {
    QuerySnapshot users =
        await FirebaseFirestore.instance.collection('users').get();
    return users.size;
  }

  Future<int> fetchNewUsersCount() async {
    DateTime oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));

    QuerySnapshot newUsers = await FirebaseFirestore.instance
        .collection('users')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(oneWeekAgo))
        .get();

    return newUsers.size;
  }

  Future<int> fetchNewProductsCount() async {
    DateTime oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));

    QuerySnapshot newProducts = await FirebaseFirestore.instance
        .collection('product')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(oneWeekAgo))
        .get();

    return newProducts.size;
  }

  Future<Map<String, Map<String, dynamic>>> fetchProductRatings() async {
    // Lấy danh sách sản phẩm
    QuerySnapshot productsSnapshot =
        await FirebaseFirestore.instance.collection('product').get();

    // Map để lưu trữ tên sản phẩm, trung bình đánh giá và số lượng đánh giá
    Map<String, Map<String, dynamic>> productRatings = {};

    for (var product in productsSnapshot.docs) {
      String productId = product.id;
      String productName = product['name']; // Lấy tên sản phẩm từ document

      // Lấy collection 'ratings' của từng sản phẩm
      QuerySnapshot ratingsSnapshot = await FirebaseFirestore.instance
          .collection('product')
          .doc(productId)
          .collection('ratings')
          .get();

      // Tính trung bình đánh giá và số lượng đánh giá
      double totalRating = 0;
      int ratingCount = ratingsSnapshot.docs.length;

      for (var ratingDoc in ratingsSnapshot.docs) {
        ProductRating rating = ProductRating.fromFirestore(
            ratingDoc.data() as Map<String, dynamic>);
        totalRating += rating.rating;
      }

      double averageRating = ratingCount > 0 ? totalRating / ratingCount : 0.0;

      // Lưu tên sản phẩm, trung bình đánh giá, và số lượng đánh giá
      productRatings[productName] = {
        'averageRating': averageRating,
        'ratingCount': ratingCount,
      };
    }

    return productRatings;
  }

  Future<List<ProductSales>> fetchProductSalesByDate() async {
    QuerySnapshot orders = await FirebaseFirestore.instance
        .collection('orders')
        .orderBy('timestamp')
        .get();

    Map<String, Map<DateTime, int>> groupedData = {};

    for (var order in orders.docs) {
      String productName = order['productName'];
      int quantity = order['quantity'];
      Timestamp timestamp = order['timestamp'];
      DateTime date = DateTime(timestamp.toDate().year,
          timestamp.toDate().month, timestamp.toDate().day);

      if (!groupedData.containsKey(productName)) {
        groupedData[productName] = {};
      }

      groupedData[productName]!
          .update(date, (value) => value + quantity, ifAbsent: () => quantity);
    }

    List<ProductSales> salesData = [];
    groupedData.forEach((productName, salesByDate) {
      salesByDate.forEach((date, quantity) {
        salesData.add(ProductSales(productName, date, quantity));
      });
    });

    return salesData;
  }

  Future<double> calculateRevenue(DateTime startDate, DateTime endDate) async {
    QuerySnapshot orders = await FirebaseFirestore.instance
        .collection('orders')
        .where('timestamp', isGreaterThanOrEqualTo: startDate)
        .where('timestamp', isLessThanOrEqualTo: endDate)
        .get();

    double totalRevenue = 0;

    for (var order in orders.docs) {
      double totalAmount =
          (order['totalAmount'] as num).toDouble(); // Convert to double
      String orderStatus = order['orderStatus']; // Assuming the field exists

      // Subtract the totalAmount for refunded orders
      if (orderStatus == 'Đã hoàn trả') {
        totalRevenue -= totalAmount;
      } else {
        totalRevenue += totalAmount;
      }
    }
    return totalRevenue;
  }

  Future<int> calculateTotalProductsSold() async {
    QuerySnapshot orders =
        await FirebaseFirestore.instance.collection('orders').get();

    int totalProductsSold = 0;
    for (var order in orders.docs) {
      totalProductsSold += order['quantity'] as int;
    }
    return totalProductsSold;
  }

  Future<Map<String, Map<String, dynamic>>> calculateRevenueByProduct() async {
    QuerySnapshot orders =
        await FirebaseFirestore.instance.collection('orders').get();

    Map<String, Map<String, dynamic>> revenueAndQuantityByProduct = {};

    for (var order in orders.docs) {
      String productName = order['productName'];
      double totalAmount =
          (order['totalAmount'] as num).toDouble(); // Convert to double
      int quantity = (order['quantity'] as num).toInt(); // Get quantity as int

      if (revenueAndQuantityByProduct.containsKey(productName)) {
        revenueAndQuantityByProduct[productName]!['revenue'] += totalAmount;
        revenueAndQuantityByProduct[productName]!['quantity'] += quantity;
      } else {
        revenueAndQuantityByProduct[productName] = {
          'revenue': totalAmount,
          'quantity': quantity,
        };
      }
    }
    return revenueAndQuantityByProduct;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê doanh thu'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card chọn ngày
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chọn khoảng thời gian',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Ngày bắt đầu: ${DateFormat('dd/MM/yyyy').format(startDate)}'),
                            TextButton(
                              onPressed: () => _selectStartDate(context),
                              child: const Text('Chọn ngày bắt đầu'),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Ngày kết thúc: ${DateFormat('dd/MM/yyyy').format(endDate)}'),
                            TextButton(
                              onPressed: () => _selectEndDate(context),
                              child: const Text('Chọn ngày kết thúc'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Card doanh thu
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FutureBuilder<double>(
                  future: calculateRevenue(startDate, endDate),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    } else if (snapshot.hasError) {
                      return Text('Lỗi: ${snapshot.error}');
                    } else {
                      return Text(
                        'Doanh thu: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ').format(snapshot.data)}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      );
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Revenue by product
            const Text(
              'Doanh thu theo sản phẩm:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            FutureBuilder<Map<String, Map<String, dynamic>>>(
              future: calculateRevenueByProduct(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Sản phẩm')),
                        DataColumn(label: Text('Doanh thu')),
                        DataColumn(label: Text('Số lượng bán')),
                      ],
                      rows: snapshot.data!.entries.map((entry) {
                        final productName = entry.key;
                        final revenue = entry.value['revenue'] as double;
                        final quantity = entry.value['quantity'] as int;

                        return DataRow(cells: [
                          DataCell(Text(productName)),
                          DataCell(Text(
                              '${NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ').format(revenue)}')),
                          DataCell(Text(quantity.toString())),
                        ]);
                      }).toList(),
                    ),
                  );
                } else {
                  return const Center(child: Text('Không có dữ liệu.'));
                }
              },
            ),

            // const SizedBox(height: 16),
            // FutureBuilder<Map<String, double>>(
            //   future: fetchProductRatings(),
            //   builder: (context, snapshot) {
            //     if (snapshot.connectionState == ConnectionState.waiting) {
            //       return const Center(child: CircularProgressIndicator());
            //     } else if (snapshot.hasError) {
            //       return Center(child: Text('Lỗi: ${snapshot.error}'));
            //     } else {
            //       Map<String, double> productRatings = snapshot.data!;

            //       return SingleChildScrollView(
            //         scrollDirection: Axis.horizontal,
            //         child: DataTable(
            //           columns: const [
            //             DataColumn(label: Text('Sản phẩm')),
            //             DataColumn(label: Text('Đánh giá trung bình')),
            //           ],
            //           rows: productRatings.entries.map((entry) {
            //             return DataRow(cells: [
            //               DataCell(Text(entry
            //                   .key)), // Tên sản phẩm (productId hoặc tên sản phẩm nếu muốn)
            //               DataCell(Text(entry.value
            //                   .toStringAsFixed(2))), // Đánh giá trung bình
            //             ]);
            //           }).toList(),
            //         ),
            //       );
            //     }
            //   },
            // ),

            const SizedBox(height: 16),
            // Bảng đánh giá sản phẩm
            const Text(
              'Đánh giá sản phẩm',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: FutureBuilder<Map<String, Map<String, dynamic>>>(
                future:
                    fetchProductRatings(), // Gọi hàm trả về cả averageRating và ratingCount
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('Lỗi: ${snapshot.error}'),
                      ),
                    );
                  } else {
                    Map<String, Map<String, dynamic>> productRatings =
                        snapshot.data!;

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Sản phẩm')),
                          DataColumn(label: Text('Đánh giá trung bình')),
                          DataColumn(label: Text('Số lượng đánh giá')),
                        ],
                        rows: productRatings.entries.map((entry) {
                          final productName = entry.key;
                          final averageRating =
                              entry.value['averageRating'] as double;
                          final ratingCount = entry.value['ratingCount'] as int;

                          return DataRow(cells: [
                            DataCell(Text(productName)),
                            DataCell(Text(averageRating.toStringAsFixed(2))),
                            DataCell(Text(ratingCount.toString())),
                          ]);
                        }).toList(),
                      ),
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: 8),
            const Text(
              'Các sản phẩm hoàn trả',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('orderStatus', isEqualTo: 'Đã hoàn trả')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                } else {
                  var returnedOrders = snapshot.data!.docs;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Mã đơn hàng')),
                        DataColumn(label: Text('Tên sản phẩm')),
                        DataColumn(label: Text('Số tiền hoàn trả')),
                        DataColumn(label: Text('Lý do hoàn trả')),
                        DataColumn(label: Text('Thời gian hoàn trả')),
                      ],
                      rows: returnedOrders.map((order) {
                        return DataRow(cells: [
                          DataCell(Text(order['orderId'] ?? 'N/A')),
                          DataCell(Text(order['productName'] ?? 'N/A')),
                          DataCell(Text(
                              order['totalAmount']?.toStringAsFixed(0) ?? '0')),
                          DataCell(Text(order['returnReason'] ?? 'N/A')),
                          DataCell(Text(
                              order['returnTimestamp']?.toDate().toString() ??
                                  'N/A')),
                        ]);
                      }).toList(),
                    ),
                  );
                }
              },
            ),
            Card(
              child: FutureBuilder<int>(
                future: fetchCustomerCount(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                        title: Text('Đang tải số lượng khách hàng...'));
                  } else if (snapshot.hasError) {
                    return ListTile(title: Text('Lỗi: ${snapshot.error}'));
                  } else {
                    return ListTile(
                      leading: const Icon(Icons.people, color: Colors.blue),
                      title: const Text('Số lượng khách hàng'),
                      trailing: Text(
                        snapshot.data.toString(),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            // Số lượng người dùng mới đăng ký
            Card(
              child: FutureBuilder<int>(
                future: fetchNewUsersCount(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                        title: Text(
                            'Đang tải số lượng người dùng mới đăng ký...'));
                  } else if (snapshot.hasError) {
                    return ListTile(title: Text('Lỗi: ${snapshot.error}'));
                  } else {
                    return ListTile(
                      leading:
                          const Icon(Icons.person_add, color: Colors.green),
                      title: const Text('Số lượng người dùng mới đăng ký'),
                      trailing: Text(
                        snapshot.data.toString(),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductSales {
  final String productName;
  final DateTime date;
  final int quantity;

  ProductSales(this.productName, this.date, this.quantity);
}

class ProductRating {
  final String userId;
  final int rating;

  ProductRating({required this.userId, required this.rating});

  factory ProductRating.fromFirestore(Map<String, dynamic> data) {
    return ProductRating(
      userId: data['userId'],
      rating: data['rating'],
    );
  }
}
