import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smart_track/utils/colors.dart';

class ShimmerHelper {
  static Widget buildHomePageShimmer(BuildContext context) {
    return Container(
      color: ColorStyle.BlueStatic,
      child: Shimmer.fromColors(
        baseColor: Colors.white.withOpacity(0.2),
        highlightColor: Colors.white.withOpacity(0.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar Shimmer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),

            // Header Section with Image
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height / 3.5,
              decoration: const BoxDecoration(
                color: Color(0xFF80A7D5),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Class Info Shimmer
                    Container(width: 250, height: 120, color: Colors.white),
                  ],
                ),
              ),
            ),

            // Class List Shimmer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(height: 24, width: 150, color: Colors.white),
            ),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: 4,
                itemBuilder:
                    (_, __) => Container(
                      width: 120,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
              ),
            ),

            // Class Details Shimmer
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 28, width: 150, color: Colors.white),
                      const SizedBox(height: 15),
                      ...List.generate(
                        7,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                height: 16,
                                width: 80,
                                color: Colors.white,
                              ),
                              Container(
                                height: 16,
                                width: 120,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildTodayShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 200,
              height: 24,
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.symmetric(horizontal: 10.0),
            ),
            Container(
              width: double.infinity,
              height: 18,
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 16),
            ),
            ...List.generate(4, (index) => buildShimmerClassItem()),
          ],
        ),
      ),
    );
  }

  static Widget buildShimmerClassItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(12.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 20,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 8),
                ),
                Container(
                  width: 150,
                  height: 16,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 8),
                ),
                Container(
                  width: double.infinity,
                  height: 16,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget _buildShimmerLoading() {
//   return Shimmer.fromColors(
//     baseColor: Colors.grey[300]!,
//     highlightColor: Colors.grey[100]!,
//     child: ListView.builder(
//       scrollDirection: Axis.horizontal,
//       itemCount: 4,
//       itemBuilder:
//           (context, index) => Container(
//             margin: const EdgeInsets.symmetric(horizontal: 4.0),
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
//             decoration: BoxDecoration(
//               border: Border.all(color: Colors.transparent),
//               borderRadius: BorderRadius.circular(50),
//               color: Colors.white,
//             ),
//             width: 150,
//           ),
//     ),
//   );
// }
