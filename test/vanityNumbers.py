import sys
sys.path.insert(1, '../functions/vanityNumbers')

from index import lambda_handler
class TestVanityNumbers():

  def test_sample_phone(self):
    caller = {
      'Details': {
        'ContactData': {
          'Attributes': {},
          'Channel': 'VOICE',
          'ContactId': 'beca59d6-7305-4254-9039-3ea8ff095535',
          'CustomerEndpoint': {
            'Address': '+15714846978',
            'Type': 'TELEPHONE_NUMBER'
          },
          'CustomerId': None,
          'Description': None,
          'InitialContactId': 'beca59d6-7305-4254-9039-3ea8ff095535',
          'InitiationMethod': 'INBOUND',
          'InstanceARN': 'arn:aws:connect:us-east-1:859530432683:instance/42108984-e820-43c2-821c-c55e47931bf7',
          'LanguageCode': 'en-US',
          'MediaStreams': {
            'Customer': {
              'Audio': None
            }
          },
          'Name': None,
          'PreviousContactId': 'beca59d6-7305-4254-9039-3ea8ff095535',
          'Queue': None,
          'References': {},
          'SystemEndpoint': {
            'Address': '+13239246194',
            'Type': 'TELEPHONE_NUMBER'
          }
        },
        'Parameters': {}
      },
      'Name': 'ContactFlowEvent'
    }
    
    print(lambda_handler(caller, ''))