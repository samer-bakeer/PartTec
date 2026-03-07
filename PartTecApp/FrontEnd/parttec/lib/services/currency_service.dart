import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  static Future<double> getUsdToSypRate() async {
    try {
      final url = Uri.parse(
        "https://open.er-api.com/v6/latest/USD",
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["rates"]["SYP"] * 1.0;
      }
    } catch (e) {
      print("Currency API error: $e");
    }

    return 15000; // fallback إذا فشل الاتصال
  }
}
