


2.  const response = await helpers.apiClient.post(tcUrl + '/JsonRestServices/Core-2007-01-DataManagement/setProperties',
        {
          'header': {
            'state': {
              'locale': sessionLocale,
            },
            'policy': {},
          },
          'body': {
            'objects': [objectUid], // Just the UID string as required
            'attributes': attributesObj
          },
        },
        {
          'headers': {
            'Cookie': JSESSIONIDcookie,
          },
        });
Payload:
{
"objectUid": "hAthiiNXppgr6D",
    "attributes": [
    { "name": "att1Value", "values": "8814" }
}


4.  const response = await helpers.apiClient.post(tcUrl + '/JsonRestServices/Core-2013-05-LOV/getInitialLOVValues',
        {
          'header': {
            'state': {
              'locale': sessionLocale,
            },
            'policy': {},
          },
          'body': {
            'initialData': {
              'propertyName': 'awp0AdvancedQueryName',
              'filterData': {
                'filterString': '',
                'maxResults': 0,
                'numberToReturn': numberToReturnQuery,
                'order': 1,
                'sortPropertyName': '',
              },
              'lov': {
                'uid': 'AAAAAAAAAAAAAA',
                'type': 'unknownType',
              },
              'lovInput': {
                'owningObject': {
                  'uid': 'AAAAAAAAAAAAAA',
                  'type': 'Awp0AdvancedSearchInput',
                },
                'operationName': 'Specialedit',
                'boName': 'Awp0AdvancedSearchInput',
                'propertyValues': {},
              },
            },
          },
        },
        {
          'headers': {
            'Cookie': JSESSIONIDcookie,
          },
        });
Payload:{
 "numberToReturnQuery": 10
}

5. const response = await helpers.apiClient.post(tcUrl + '/JsonRestServices/Query-2006-03-SavedQuery/describeSavedQueries',
        {
          'header': {
            'state': {
              'locale': sessionLocale,
            },
            'policy': {},
          },
          'body': {
            'queries': [
              queryUid,
            ],
          },
        },
        {
          'headers': {
            'Cookie': JSESSIONIDcookie,
          },
        });
Payload:{
"queryUid": "QwhF92$rppgr6D"
}