import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

import '../../utils/app_settings.dart';

class PaymentTestPage extends StatefulWidget {
  final String orderId;
  final int amount;

  const PaymentTestPage({
    Key? key,
    required this.orderId,
    required this.amount,
  }) : super(key: key);

  @override
  State<PaymentTestPage> createState() => _PaymentTestPageState();
}

class _PaymentTestPageState extends State<PaymentTestPage> {
  String? paymentUrl;
  late final WebViewController _controller;
  String statusMessage = "جاري بدء الدفع...";

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
    _initPayment();
  }

  Future<void> _initPayment() async {
    final url = Uri.parse('${AppSettings.serverurl}/payment/init');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "orderId": widget.orderId,
        "amount": widget.amount,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (!mounted) return;
      setState(() {
        paymentUrl = data["url"];
        _controller.loadRequest(Uri.parse(paymentUrl!));
      });
    } else {
      setState(() {
        statusMessage = "فشل بدء الدفع";
      });
    }
  }

  Future<void> _checkOrderStatus() async {
    final url = Uri.parse(
        "${AppSettings.serverurl}/payment/status/${widget.orderId}");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (!mounted) return;
      setState(() {
        statusMessage = "حالة الدفع: ${data["paymentStatus"]}";
      });
    } else {
      if (!mounted) return;
      setState(() {
        statusMessage = "تعذر جلب حالة الدفع";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تجربة الدفع")),
      body: Column(
        children: [
          Expanded(
            child: paymentUrl == null
                ? Center(child: Text(statusMessage))
                : WebViewWidget(controller: _controller),
          ),
          ElevatedButton(
            onPressed: _checkOrderStatus,
            child: const Text("تحديث حالة الطلب"),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(statusMessage),
          )
        ],
      ),
    );
  }
}
