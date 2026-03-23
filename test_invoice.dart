import 'package:http/http.dart' as http;

void main() async {
  var headers = {
    'X-Company': '1', // Often company ID is 1, let's see if the user meant a placeholder
    'Authorization': 'Basic YWRtaW5AY29tcGFueS5jb206cGFzc3dvcmQ='
  };
  
  // Also trying with the exact URL the user provided.
  var request = http.MultipartRequest('POST', Uri.parse('http://idaax.local/akaunting/api/documents?category_id=3&document_number=0000003&status=draft&issued_at=2022-04-23&due_at=2022-05-22&account_id=1&currency_code=USD&currency_rate=1&notes=This is note for invoice&contact_id=2&contact_name=Name&contact_email=mail@mail.com&contact_address=Client address&items[0][item_id]=1&items[0][name]=Service&items[0][quantity]=2&items[0][price]=1&items[0][total]=2&items[0][discount]=0&items[0][description]=This is custom item description&items[0][tax_ids][0]=1&items[0][tax_ids][1]=1&amount=2&type=invoice&search=type:invoice'));

  request.headers.addAll(headers);

  try {
    print('Sending request...');
    http.StreamedResponse response = await request.send();

    print('Status: ${response.statusCode}');
    print('Reason: ${response.reasonPhrase}');
    
    var responseBody = await response.stream.bytesToString();
    print('Response Body: $responseBody');
  } catch (e) {
    print('Exception: $e');
  }
}
