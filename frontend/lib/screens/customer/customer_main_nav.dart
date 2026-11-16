import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../utils/constants.dart';
import 'customer_home_screen.dart';
import 'medicine_search_screen.dart';
import 'customer_orders_screen.dart';
import 'customer_profile_screen.dart';
import 'cart_screen.dart';

class CustomerMainNav extends StatefulWidget {
  final int initialIndex;
  const CustomerMainNav({super.key, this.initialIndex = 0});

  @override
  State<CustomerMainNav> createState() => _CustomerMainNavState();
}

class _CustomerMainNavState extends State<CustomerMainNav> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _pages = const [
    CustomerHomeScreen(),
    MedicineSearchScreen(),
    CustomerOrdersScreen(),
    CustomerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              activeIcon: Icon(Icons.search),
              label: 'Search',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'Orders',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
      floatingActionButton: cart.totalItemCount > 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                );
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: Badge(
                label: Text('${cart.totalItemCount}'),
                backgroundColor: AppColors.secondary,
                child: const Icon(Icons.shopping_bag_outlined),
              ),
              label: Text(
                'View Cart (${cart.totalItemCount})',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
    );
  }
}
