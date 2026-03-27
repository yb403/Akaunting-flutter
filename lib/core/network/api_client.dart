import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiClient {
  static String get baseUrl => dotenv.get('BASE_API', fallback: 'http://192.168.1.116/akaunting/api');

  static Future<Map<String, String>> _getAuthHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String email = prefs.getString('email') ?? '';
    String password = prefs.getString('password') ?? '';

    String basicAuth = 'Basic ${base64Encode(utf8.encode('$email:$password'))}';

    return {
      'Authorization': basicAuth,
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  static Future<http.Response> getRequest(String endpoint) async {
    var headers = await _getAuthHeaders();
    return await http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
  }

  static Future<http.Response> postRequest(String endpoint, Map<String, dynamic> body) async {
    var headers = await _getAuthHeaders();
    return await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> putRequest(String endpoint, Map<String, dynamic> body) async {
    var headers = await _getAuthHeaders();
    return await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> deleteRequest(String endpoint) async {
    var headers = await _getAuthHeaders();
    return await http.delete(Uri.parse('$baseUrl$endpoint'), headers: headers);
  }
  static Future<http.StreamedResponse> multipartPostRequest(String fullUrl, {String? filePath, String fileField = 'file'}) async {
    var headers = await _getAuthHeaders();
    // Akaunting specifically requires X-Company.
    headers['X-Company'] = 'akaunting_company_id';
    
    var request = http.MultipartRequest('POST', Uri.parse(fullUrl));
    request.headers.addAll(headers);
    
    if (filePath != null) {
      request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
    }
    
    return await request.send();
  }
}
