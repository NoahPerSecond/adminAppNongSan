import 'package:adminapp/screens/edit_product_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProductCard extends StatefulWidget {
  final Map<String, dynamic> snap;
  final String? productId;

  ProductCard({super.key, required this.snap, this.productId});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: '');
  double _averageRating = 0.0;
  int _totalRatings = 0; // Count of total ratings

  @override
  void initState() {
    super.initState();
    calculateAverageRating();
    print(_averageRating);
  }

  Future<void> calculateAverageRating() async {
    try {
      QuerySnapshot ratingSnapshot = await FirebaseFirestore.instance
          .collection('product')
          .doc(widget.productId)
          .collection('ratings')
          .get();

      if (ratingSnapshot.docs.isNotEmpty) {
        int totalRating = 0;
        ratingSnapshot.docs.forEach((doc) {
          totalRating += doc['rating'] as int;
        });
        setState(() {
          _averageRating = totalRating / ratingSnapshot.docs.length;
          _totalRatings = ratingSnapshot.docs.length;
        });
      }
    } catch (e) {
      print('Error calculating average rating: $e');
    }
  }

  @override
Widget build(BuildContext context) {
  return InkWell(
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditProductScreen(
          productId: widget.productId!,
        ),
      ),
    ),
    child: Stack(
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20)),
                child: Image.network(
                  widget.snap['imageUrl'],
                  width: 200,
                  height: 110,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.snap['name'],
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              Icons.star,
                              size: 15,
                              color: index < _averageRating
                                  ? Colors.yellow
                                  : Colors.grey,
                            );
                          }),
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Text(
                          _averageRating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        Text(
                          ' (' + _totalRatings.toString() + ' đánh giá)',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    widget.snap['isSale']
                        ? Column(
                            children: [
                              Text(
                                '${formatCurrency.format(widget.snap['newPrice'])} VND',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${formatCurrency.format(widget.snap['price'])} VND',
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            '${formatCurrency.format(widget.snap['price'])} VND',
                            style: const TextStyle(fontSize: 16),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            
            child: Text(
              '${widget.snap['saleCount']} lượt bán',
              style: const TextStyle(
                
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

}
