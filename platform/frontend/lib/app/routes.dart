/// Route paths. Kept apart from `router.dart` so pages can navigate without
/// importing the router (which imports the pages).
abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const completeProfile = '/complete-profile';
  static const editProfile = '/profile/edit';
  static const profileSuccess = '/profile/success';
  static const dashboard = '/dashboard';
  static const dashboardNewTransaction = '/dashboard/new-transaction';
  static const transactions = '/transactions';
  static const newTransaction = '/transactions/new';
  static String editTransaction(int id) => '/transactions/$id/edit';
  static const newCategory = '/categories/new';
  static const goals = '/goals';
  static const forecast = '/forecast';
  static const notifications = '/notifications';
}
