/****************************************************************************************
* Class : PowerPassSignUp_Ctrl
* Created By : bob alicante
----------------------------------------------------------------------------------------
* Description : Controller for PowerPassSignUp_Ctrl web component.
----------------------------------------------------------------------------------------
* Utility Test Data : PowerPassSignUp_Ctrl_Test
----------------------------------------------------------------------------------------
* Version History:
* VERSION     DEVELOPER NAME        DATE            DETAIL FEATURES
  1.0         bob alicante          02.17.2020      Initial Development
  2.0         Simplus MS            11.11.2021      CCRM15-410   
***************************************************************************************/
public with sharing class PowerPassSignUp_Ctrl {

    @auraEnabled
    public static List<Account> getAccountDetails(Id accountId) {
        System.debug('*** getAccountDetails ***');
        return [
            SELECT
                Id,
                Name,
                Industry,
                Secondary_Segment__c,
                Business_Type__c,
                Assigned_Store__c,
                Home_Store__c,
                ABN__c,
                ACN__c,
                GST_Number__c,
                Business_Email_Address__c,
                RecordType.Name,
                billingcity,
                billingstreet,
                billingpostalcode,
                billingstate,
                Phone,
                (
                    SELECT
                        Id,
                        Title,
                        FirstName,
                        Lastname,
                        Email
                    FROM
                        Contacts
                )
            FROM
                Account
            WHERE
                Id = :accountId
        ];
    }

    @AuraEnabled
    public static String getEncodedAccountInfo(Id accountId) {
        List<String> selectAcctFields = new List<String>();
        List<String> selectContFields = new List<String>();
        
        Initialisation__mdt config = DM_Initialisation.ccrmInitialisation;
        String powerpassURL = '';
        String countryCode = 'NZ';
        
        for (PowerPass_Signup_Field_Mapping__mdt fieldMapping : [SELECT FieldName__c, Target_Field__c, TargetObject__c FROM PowerPass_Signup_Field_Mapping__mdt]) {
            if (fieldMapping.TargetObject__c == 'Account') {
                selectAcctFields.add(fieldMapping.Target_Field__c);
            }
            else if (fieldMapping.TargetObject__c == 'Contact') {
                selectContFields.add(fieldMapping.Target_Field__c);
            }
        }

        Account acc = Database.query('SELECT Id, RecordType.Name, ' 
                        + String.join(selectAcctFields, ',')
                        + ', (SELECT Id, '+ String.join(selectContFields, ',') + ' FROM Contacts)'
                        + ' FROM Account WHERE Id = \'' + accountId + '\''); //[SELECT Id, (SELECT Id FROM Contacts) FROM Account WHERE Id = :accountId];
        List<String> params = new List<String>();
        for (PowerPass_Signup_Field_Mapping__mdt fieldMapping : [SELECT FieldName__c, Target_Field__c, TargetObject__c FROM PowerPass_Signup_Field_Mapping__mdt]) {
            if (fieldMapping.TargetObject__c == 'Account') {
                if (acc.get(fieldMapping.Target_Field__c) == null) continue;
                if (fieldMapping.FieldName__c == 'busphone') {
                    params.add('busphoneareacode=' + String.valueOf(acc.Phone).substring(0,2));
                    params.add('busphone=' + String.valueOf(acc.Phone).substring(2));
                }
                else {
                    params.add(fieldMapping.FieldName__c + '=' + acc.get(fieldMapping.Target_Field__c));
                }
            }
            else if (fieldMapping.TargetObject__c == 'Contact') {
                if (acc.Contacts[0].get(fieldMapping.Target_Field__c) == null) continue;
                params.add(fieldMapping.FieldName__c + '=' + acc.Contacts[0].get(fieldMapping.Target_Field__c));
            }
        }
        System.debug('params: ' + String.join(params, '|'));
        //System.debug(Label.COS_Powerpass_URL + EncodingUtil.base64Encode(Blob.valueOf(String.join(params, '|'))));
        //return Label.COS_Powerpass_URL + EncodingUtil.base64Encode(Blob.valueOf(String.join(params, '|')));
        
        if (String.valueOf(acc.RecordType.Name).startsWith('AU')) {
            countryCode = 'AU';
        }
        
        powerpassURL = config.COS_Powerpass_SignUp_URL__c.replace('###COUNTRY_CODE###', countryCode).replace('###ACCT_NO###', acc.Id) + EncodingUtil.base64Encode(Blob.valueOf(String.join(params, '|')));
        
        System.debug('powerpassURL: ' + powerpassURL);
        return powerpassURL;
        
    }
}