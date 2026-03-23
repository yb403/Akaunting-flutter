import requests

url = "http://192.168.1.116/akaunting/api/documents?category_id=3&document_number=00000041&status=paid&issued_at=2022-04-23&due_at=2022-05-22&account_id=1&currency_code=USD&currency_rate=1&notes=This is note for invoice&contact_id=2&contact_name=Name&contact_email=mail@mail.com&contact_address=Client address&items[0][item_id]=1&items[0][name]=Service&items[0][quantity]=2&items[0][price]=1&items[0][total]=2&items[0][discount]=0&items[0][description]=This is custom item description&items[0][tax_ids][0]=1&items[0][tax_ids][1]=1&amount=2&type=invoice&search=type:invoice"

payload = {}
files={}
headers = {
  'X-Company': 'akaunting_company_id',
        'Authorization': 'Basic YWRtaW5AY29tcGFueS5jb206cGFzc3dvcmQ=',
}

response = requests.request("POST", url, headers=headers, data=payload, files=files)

print(response.text)
