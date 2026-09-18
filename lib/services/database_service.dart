import 'package:mysql1/mysql1.dart';
import 'settings_service.dart';

class DatabaseService {
  final SettingsService _settingsService = SettingsService();
  MySqlConnection? _connection;

  Future<MySqlConnection> _getConnection() async {
    if (_connection != null && !_connection!.isClosed) {
      return _connection!;
    }

    final serverIP = await _settingsService.getServerIP();
    final port = await _settingsService.getPort();
    final dbName = await _settingsService.getDbName();
    final username = await _settingsService.getUsername();
    final password = await _settingsService.getPassword();

    if (serverIP == null || dbName == null || username == null || password == null) {
      throw Exception('Database connection settings are incomplete');
    }

    final settings = ConnectionSettings(
      host: serverIP,
      port: port,
      user: username,
      password: password,
      db: dbName,
      timeout: const Duration(seconds: 10),
    );

    _connection = await MySqlConnection.connect(settings);
    return _connection!;
  }

  Future<void> closeConnection() async {
    if (_connection != null && !_connection!.isClosed) {
      await _connection!.close();
      _connection = null;
    }
  }

  Future<String?> getUserIdByDeviceId(String deviceId) async {
    try {
      final conn = await _getConnection();

      // This would be the actual query based on your DB schema
      // Adjust the table/column names as needed
      final results = await conn.query(
        'SELECT user_id FROM user_devices WHERE device_id = ?',
        [deviceId]
      );

      if (results.isNotEmpty) {
        return results.first['user_id'].toString();
      }
      return null;
    } catch (e) {
      print('Error getting user ID by device ID: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    try {
      final conn = await _getConnection();

      // Query based on the extracted schema
      final results = await conn.query('''
        SELECT
          tbl_item.it_id as ItemID,
          tbl_item.it_un_price_sell_a as RetailPrice,
          tbl_item.it_un_price_sell_b as WholesalePrice,
          tbl_item.it_un_price_sell_c as HalfWholesalePrice,
          tbl_item.it_un_price_sell_d as ExportPrice,
          tbl_item.it_un_price_sell_e as ConsumerPrice,
          tbl_item.it_cost_per_unit as cost_price,
          func_get_item_cost2(tbl_item.it_id, tbl_item.it_unit_id, tbl_item.it_id_currency, tbl_item.it_cost_per_unit, tbl_item.it_unit_equal) as last_price
        FROM tbl_item_barcode
        INNER JOIN tbl_item ON tbl_item_barcode.it_item_id = tbl_item.it_id
        WHERE tbl_item_barcode.it_barcode_value = ?
      ''', [barcode]);

      if (results.isNotEmpty) {
        final row = results.first;
        return {
          'itemId': row['ItemID'],
          'retailPrice': row['RetailPrice'],
          'wholesalePrice': row['WholesalePrice'],
          'halfWholesalePrice': row['HalfWholesalePrice'],
          'exportPrice': row['ExportPrice'],
          'consumerPrice': row['ConsumerPrice'],
          'costPrice': row['cost_price'],
          'lastPrice': row['last_price'],
        };
      }
      return null;
    } catch (e) {
      print('Error getting product by barcode: $e');
      rethrow;
    }
  }

  Future<bool> testConnection() async {
    try {
      final conn = await _getConnection();
      await conn.query('SELECT 1');
      return true;
    } catch (e) {
      print('Database connection test failed: $e');
      return false;
    }
  }

  Future<int> getUserDuration(String userId) async {
    try {
      final conn = await _getConnection();

      // This would check the user's license duration
      // Adjust the query based on your actual schema
      final results = await conn.query(
        'SELECT DATEDIFF(expiry_date, NOW()) as days_remaining FROM user_licenses WHERE user_id = ?',
        [userId]
      );

      if (results.isNotEmpty) {
        return results.first['days_remaining'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error getting user duration: $e');
      return 0;
    }
  }
}