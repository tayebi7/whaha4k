import 'package:flutter/foundation.dart';

import 'store.dart';

/// يُقرأ من Store عند أول استخدام (بعد Store.init)
final ValueNotifier<String> langNotifier = ValueNotifier<String>(Store.lang);

/// ترجمة بسيطة: المفتاح هو النص الإنجليزي.
String tr(String en) =>
    langNotifier.value == 'ar' ? (_ar[en] ?? en) : en;

const Map<String, String> _ar = {
  'Home': 'الرئيسية',
  'Live': 'مباشر',
  'Movies': 'أفلام',
  'Series': 'مسلسلات',
  'Account': 'الحساب',
  'Change Playlist': 'تغيير القائمة',
  'Settings': 'الإعدادات',
  'Reload': 'إعادة تحميل',
  'Exit': 'خروج',
  'Reloaded': 'تمت إعادة التحميل',
  'Current playlist expires': 'ينتهي الاشتراك',
  'unlimited': 'غير محدود',
  'Recently Viewed': 'شوهد مؤخراً',
  'All': 'الكل',
  'Favorite': 'المفضلة',
  'Add to Favorite': 'إضافة للمفضلة',
  'Remove from Favorite': 'إزالة من المفضلة',
  'Full screen': 'ملء الشاشة',
  'Search': 'بحث',
  'No items': 'لا توجد عناصر',
  'No episodes': 'لا توجد حلقات',
  'Season': 'الموسم',
  'Retry': 'إعادة المحاولة',
  'Add Playlist': 'إضافة قائمة',
  'Playlists': 'القوائم',
  'Change Language': 'تغيير اللغة',
  'Live Stream Format': 'صيغة البث المباشر',
  'Clear History Channels': 'مسح سجل القنوات',
  'Clear History Movies': 'مسح سجل الأفلام',
  'Clear Favorites': 'مسح المفضلة',
  'About': 'حول التطبيق',
  'Done': 'تم',
  'Playlist name': 'اسم القائمة',
  'Server URL (http://host:port)': 'رابط السيرفر (http://host:port)',
  'M3U URL': 'رابط M3U',
  'Username': 'اسم المستخدم',
  'Password': 'كلمة المرور',
  'Pick M3U file': 'اختيار ملف M3U',
  'File loaded': 'تم تحميل الملف',
  'Save': 'حفظ',
  'Login failed': 'فشل تسجيل الدخول',
  'Please fill all fields': 'يرجى ملء كل الحقول',
  'Status': 'الحالة',
  'Expires': 'تاريخ الانتهاء',
  'Connections': 'الاتصالات',
  'Playlist': 'القائمة',
  'Type': 'النوع',
  'Fit': 'ملاءمة الصورة',
  'Cancel': 'إلغاء',
  'Delete': 'حذف',
  'No playlist yet': 'لا توجد قوائم بعد',
  'Close': 'إغلاق',
};
