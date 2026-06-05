import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import Screens (Placeholder imports - we will create these files shortly)
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/product/presentation/product_list_screen.dart';
import '../features/product/presentation/product_detail_screen.dart';
import '../features/inquiry/presentation/inquiry_form_screen.dart';
import '../features/inquiry/presentation/my_inquiries_screen.dart';
import '../features/supplier/presentation/supplier_dashboard_screen.dart';
import '../features/supplier/presentation/lead_management_screen.dart';
import '../features/supplier/presentation/product_management_screen.dart';
import '../features/supplier/presentation/supplier_profile_screen.dart';
import '../features/news/presentation/news_screen.dart';
import '../features/auth/presentation/pending_approval_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/pending-approval',
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OtpScreen(phone: phone);
        },
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) {
          final categoryId = state.uri.queryParameters['categoryId'];
          return ProductListScreen(categoryId: categoryId);
        },
      ),
      GoRoute(
        path: '/products/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductDetailScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/inquiry-form',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return InquiryFormScreen(
            supplierId: extra['supplierId'] ?? '',
            productId: extra['productId'],
            productName: extra['productName'],
            productImage: extra['productImage'],
            serviceId: extra['serviceId'],
            serviceName: extra['serviceName'],
          );
        },
      ),
      GoRoute(
        path: '/my-inquiries',
        builder: (context, state) => const MyInquiriesScreen(),
      ),
      GoRoute(
        path: '/supplier-dashboard',
        builder: (context, state) => const SupplierDashboardScreen(),
      ),
      GoRoute(
        path: '/supplier-leads',
        builder: (context, state) => const LeadManagementScreen(),
      ),
      GoRoute(
        path: '/supplier-add-product',
        builder: (context, state) => const ProductManagementScreen(),
      ),
      GoRoute(
        path: '/supplier-profile',
        builder: (context, state) => const SupplierProfileScreen(),
      ),
      GoRoute(
        path: '/news',
        builder: (context, state) => const NewsScreen(),
      ),
    ],
  );
});
