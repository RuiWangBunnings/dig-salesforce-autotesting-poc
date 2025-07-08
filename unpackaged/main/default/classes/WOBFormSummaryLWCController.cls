public with sharing class WOBFormSummaryLWCController {
    //todo - add parameter to include recordtype for email template use
    @AuraEnabled
    public static string updateWobOppStagesAndSendEmail(List<String> oppIdList, String projectRecordId){
        try {

            
            List<Messaging.SingleEmailMessage> masterListMails = new List<Messaging.SingleEmailMessage>();
            List<Opportunity> beaumontOppListFiltered = [SELECT Id, StageName, Created_From_WOB__c, Quote_Email_Sent__c 
                                                FROM Opportunity WHERE Id IN :oppIdList 
                                                AND StageName = 'New' 
                                                AND Created_From_WOB__c = true
                                                AND Quote_Email_Sent__c = false
                                                AND RecordType.Name = 'Beaumont Tiles Opportunity'];

            List<Opportunity> frameAndTrussOppListFiltered = [SELECT Id, Name, StageName, Created_From_WOB__c, Account.Name, Project__c, AccountId
                                                FROM Opportunity WHERE Id IN :oppIdList 
                                                AND StageName = 'New' 
                                                AND Created_From_WOB__c = true
                                                AND RecordType.Name = 'Frame & Truss Opportunity'];

            List<Opportunity> supplyInstallOppListFiltered = [SELECT Id, StageName, Created_From_WOB__c, Account.Name, Account.AccountNumber, 
                                                Lot_No__c, Offer__c, 
                                                Originating_Store__r.Name, Create_COS__c, Account.Phone, Project__r.Construction_Start__c, Account.Power_Pass_Account_Number__c, CreatedDate,
                                                State__c, Suburb__c, Postcode__c, Street_Name__c, Street_Type__c, Contract_Start__c, Build_Type__c,
                                                Number_of_Buildings_Units__c, Email_Address__c, PowerPass_Account_Number__c, Account.Powerpass_Account_Manager__c,
                                                TECH_WOB_Create_COS__c, Amount, Estimated_Amount__c
                                                FROM Opportunity WHERE Id IN :oppIdList 
                                                AND StageName = 'New' 
                                                AND Created_From_WOB__c = true
                                                AND RecordType.Name = 'Supply & Install Opportunity'];
            System.debug('sid supplyInstallOppListFiltered '+ supplyInstallOppListFiltered);
           
            if(beaumontOppListFiltered.size() > 0){
                List<Opportunity> oppListToUpdate = new List<Opportunity>();
                EmailTemplate beaumontEmailTemplate = [SELECT Id, Subject, Description, HtmlValue, DeveloperName, Body FROM EmailTemplate WHERE Name = 'Beaumont Tiles Quote Request' AND Description = 'Email Template for Sending Quote Request'];
                List<ContentDocumentLink> files = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :projectRecordId];
                

                WoB_Opp_Quote_Email_Address__mdt wobRecipientBCCList = [SELECT Id, MasterLabel, Recipient__c, BCC__c FROM WoB_Opp_Quote_Email_Address__mdt WHERE MasterLabel = 'Recipient and BCC' LIMIT 1];
                
                List<String> recipientList = wobRecipientBCCList.Recipient__c.split(',');
                List<String> bccList = wobRecipientBCCList.BCC__c.split(',');
                List<ID> fileIDs = new List<ID>();
                for (ContentDocumentLink docLink : files) {
                    fileIDs.add(docLink.ContentDocumentId);
                }

                List<ContentVersion> contentVersionFile = [SELECT Id, ContentDocumentId, FileExtension, Title, VersionData, FileType
                    FROM ContentVersion WHERE ContentDocumentId IN : fileIDs AND IsLatest = true];


                List<Messaging.EmailFileAttachment> emailFileAttachments = new List<Messaging.EmailFileAttachment>(); 
                List<String> contentVersionFileIdList = new List<String>();

                for(ContentVersion cv : contentVersionFile){
                    Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment(); 

                    efa.setFileName(cv.Title + '.' + cv.FileType); 

                    efa.setBody(cv.VersionData); 

                    emailFileAttachments.add(efa); 
                    contentVersionFileIdList.add(cv.Id);
                }

                for(Opportunity opp : beaumontOppListFiltered)
                {
                    if(opp.StageName == 'New'){
                        opp.StageName = 'Qualifying';
                    
                        Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(beaumontEmailTemplate.Id, null, opp.Id);

                        String emailSubject = email.getSubject();
                        String emailTextBody = email.getPlainTextBody();
                        email.setToAddresses(recipientList);
                        email.setBccAddresses(bccList);
                        email.setSubject(emailSubject);
                        email.setPlainTextBody(emailTextBody);
                        email.saveAsActivity = true;
                        
                        // if (!emailFileAttachments.isEmpty()) { 
                        //     email.setFileAttachments(emailFileAttachments);
                        // } 

                        if (!contentVersionFileIdList.isEmpty()) { 
                            email.setEntityAttachments(contentVersionFileIdList);
                        } 
                        

                        masterListMails.add(email);
                        oppListToUpdate.add(opp);
                    }
                }
                
                if(masterListMails.size() > 0){
                    List<Messaging.SendEmailResult> sendEmailResults = Messaging.sendEmail(masterListMails);

                    for(Messaging.SendEmailResult sendEmailResult: sendEmailResults){
                        if(sendEmailResult.isSuccess()){
                            System.debug('success ' + sendEmailResult);
                        }else{
                            System.debug('failed ' + sendEmailResult);
                        }
                    }

                    if(oppListToUpdate.size() > 0){
                        for(Opportunity opp : oppListToUpdate){
                            opp.Quote_Email_Sent__c = true;
                        }
                        update oppListToUpdate;
                    }
                }
            }
            if(frameAndTrussOppListFiltered.size() > 0){
                List<Opportunity> oppListToUpdate = new List<Opportunity>();
                List<Case> frameAndTrussCaseList = new List<Case>();
                for(Opportunity opp : frameAndTrussOppListFiltered){
                    if(opp.StageName == 'New'){
                        opp.StageName = 'Qualifying';
                    }
                    Case newFandTRequestCase = new Case();
                    newFandTRequestCase.AccountId = opp.AccountId;
                    newFandTRequestCase.Opportunity__c = opp.Id;
                    newFandTRequestCase.Project__c = opp.Project__c;
                    newFandTRequestCase.Priority = 'Medium';
                    newFandTRequestCase.Subject = 'F&T Quote Request';
                    newFandTRequestCase.Status = 'New';
                    //to replace with F&T Team Queue 
                    //newFandTRequestCase.OwnerId = UserInfo.getUserId();
                    newFandTRequestCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('F_T_Request').getRecordTypeId();
                    frameAndTrussCaseList.add(newFandTRequestCase);
                }
                update frameAndTrussOppListFiltered;
                insert frameAndTrussCaseList;
            }
            if(supplyInstallOppListFiltered.size() > 0){
                List<Opportunity> oppListToUpdate = new List<Opportunity>();
                EmailTemplate supplyInstallEmailTemplate = [SELECT Id, Subject, Description, HtmlValue, DeveloperName, Body FROM EmailTemplate WHERE Name = 'Supply & Install Quote Request'];
                List<ContentDocumentLink> files = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :projectRecordId];
                User senderRecord = [SELECT Id, FirstName, LastName, Title, Address, Phone, MobilePhone, Email FROM User WHERE Id = :UserInfo.getUserId()];
                List<Double> oppOffersEstimatedAmountList = new List<Double>();
                List<String> oppOfferList = new List<String>();
                List<String> oppCreateCOSList = new List<String>();
                Map<Id, Opportunity> opportunityAndOppOfferMap = new Map<Id, Opportunity>();
                Map<Id, Map<String, Object>> oppIdAndFieldsMap = new Map<Id, Map<String, Object>>();
                Map<String, List<Opportunity>> offerNameOppListMap = new Map<String, List<Opportunity>>();

                

                
                Set<Id> oppIdSet = new Set<Id>();
                for(Opportunity opp : supplyInstallOppListFiltered){
                    oppIdSet.add(opp.Id);
                    if(opp.StageName == 'New'){
                        opp.StageName = 'Submitted to S&I';
                        // if(!oppOfferList.contains(opp.Offer__c)){
                        //     oppOfferList.add(opp.Offer__c);
                        // }
                        
                        // oppCreateCOSList.add(opp.TECH_WOB_Create_COS__c);
                        oppListToUpdate.add(opp);
                        oppOffersEstimatedAmountList.add(opp.Estimated_Amount__c);
                    }
                }

                
                System.debug('sid oppOffersEstimatedAmountList ' + oppOffersEstimatedAmountList);
                Double totalOppOfferEstimatedAmount = 0;
                for(Integer i = 0;i<oppOffersEstimatedAmountList.size();i++){
                    if(oppOffersEstimatedAmountList[i] != null){
                        totalOppOfferEstimatedAmount = totalOppOfferEstimatedAmount + oppOffersEstimatedAmountList[i];
                    }
                    
                }

               
                System.debug('sid totalOppOfferEstimatedAmount '+ totalOppOfferEstimatedAmount);
        
                

                String phoneNumber = senderRecord.Phone != null ? senderRecord.Phone : '';
                String emailAddress = senderRecord.Email != null ? senderRecord.Email : '';
                String userTitle = senderRecord.Title != null ? senderRecord.Title : '';
                String mobilePhone = senderRecord.MobilePhone != null ? senderRecord.MobilePhone : '';
                String userAddress = String.valueOf(senderRecord.Address) != null ? String.valueOf(senderRecord.Address) : '';

                
                WoB_Opp_Quote_Email_Address__mdt wobRecipientBCCList = [SELECT Id, MasterLabel, Recipient__c, BCC__c FROM WoB_Opp_Quote_Email_Address__mdt WHERE DeveloperName = 'Supply_Install_Recipient_List' LIMIT 1];
                
                List<String> recipientList = wobRecipientBCCList.Recipient__c.split(',');
                List<String> bccList = wobRecipientBCCList.BCC__c.split(',');
                List<ID> fileIDs = new List<ID>();
                for (ContentDocumentLink docLink : files) {
                    fileIDs.add(docLink.ContentDocumentId);
                }

                // List<ContentVersion> contentVersionFile = [SELECT Id, ContentDocumentId, FileExtension, Title, VersionData, FileType
                //     FROM ContentVersion WHERE ContentDocumentId IN : fileIDs AND IsLatest = true];


                List<Messaging.EmailFileAttachment> emailFileAttachments = new List<Messaging.EmailFileAttachment>(); 
                List<String> contentVersionFileIdList = new List<String>();

                for(ContentVersion cv : [SELECT Id, ContentDocumentId, FileExtension, Title, VersionData, FileType
                FROM ContentVersion WHERE ContentDocumentId IN : fileIDs AND IsLatest = true]){
                    Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment(); 

                    efa.setFileName(cv.Title + '.' + cv.FileType); 

                    efa.setBody(cv.VersionData); 

                    emailFileAttachments.add(efa); 
                    contentVersionFileIdList.add(cv.Id);
                }

                

                List<Opportunity> plasterboardOppOfferList = [SELECT Id, Name,  StageName, Offer__c, Created_From_WOB__c, Site_Address__c, CloseDate,   Installation_Required__c,
                                                            Amount, Estimated_Amount__c, TECH_WOB_Create_COS__c,
                                                            (SELECT Id, Wall_Centres__c, 
                                                            Wall_Centres_Other__c, Walls__c, Board_Location__c, Framework_Studwork__c, Internal_Ceilings__c, Internal_Ceilings_Detail__c, 
                                                            Internal_Ceilings_Detail_Other__c, Specify_Batten_Location__c, Wet_Areas_Baths_Ensuites__c, Full_Height_Tiling__c, Alfresco__c, 
                                                            Alfresco_Board_Type__c, Alfresco_Board_Type_Other__c, 
                                                            Alfresco_Battens__c, Alfresco_Battens_Other__c, Trim__c, Balcony_Same_as_Alfresco__c, Balcony__c, Balcony_Board_Type__c, Balcony_Board_Type_Other__c, Balcony_Battens__c, 
                                                            Balcony_Battens_Other__c, Balcony_Trim__c, External_Ceilings_Notes__c, Garage_Walls__c, Garage_Walls_Other__c , Garage_Ceilings__c, 
                                                            Garage_Ceiling_Spec__c, Garage_Ceiling_Type__c, Trim_by_Builder__c, Cornice__c, Cornice_Sub_Selection__c, Cornice_Sub_Selection_Other__c,
                                                            Other_Cornice_Type_Location__c, 
                                                            Cornice_Additional_Notes__c, 
                                                            Wall_Wrap__c, External_Wall_Insulation__c, Ceiling_Insulation__c, Acoustic__c, 
                                                            Additional_Notes__c, 
                                                            Energy_Report__c, House_Plans__c 
                                                            FROM Opportunity_Offers__r)
                                                            FROM Opportunity WHERE Id IN :oppIdSet 
                                                            AND StageName = 'New' 
                                                            AND Created_From_WOB__c = true
                                                            AND RecordType.Name = 'Supply & Install Opportunity'
                                                            AND Offer__c = 'Plasterboard & Insulation'];
                if(plasterboardOppOfferList.size() > 0){
                    for(Opportunity plasterboardOpp : plasterboardOppOfferList){
                        Map<String, Object> fieldsToValue = plasterboardOpp.getPopulatedFieldsAsMap();
                        
                        Map<String, Object> oppOfferFieldsToValue = plasterboardOpp.Opportunity_Offers__r[0].getPopulatedFieldsAsMap();
                        Map<String, Object> oppAndOppOfferFieldMap = new Map<String, Object>();
    
                        oppAndOppOfferFieldMap.putAll(fieldsToValue);
                        oppAndOppOfferFieldMap.putAll(oppOfferFieldsToValue);
    
                        oppAndOppOfferFieldMap = formatOppOfferMap(oppAndOppOfferFieldMap);
                        
    
                        oppIdAndFieldsMap.put(plasterboardOpp.Id, oppAndOppOfferFieldMap);
                        
                    }
                }
                

                List<Opportunity> insulationOppOfferList = [SELECT Id, Name,  StageName, Offer__c, Created_From_WOB__c, Site_Address__c, CloseDate,   Installation_Required__c,
                                                            Amount, Estimated_Amount__c, TECH_WOB_Create_COS__c,
                                                            (SELECT ID, Opportunity__c, Wall_Wrap_CB__c, 
                                                            External_Wall_Insulation_CB__c, Ceiling_Insulation_CB__c, Additional_Acoustic_Thermal_Insulation__c, Internal_Walls__c, Under_Floor__c, 
                                                            Additional_Notes__c, Energy_Report__c, Architectural_Drawings__c 
                                                            FROM Opportunity_Offers__r)
                                                            FROM Opportunity WHERE Id IN :oppIdSet 
                                                            AND StageName = 'New' 
                                                            AND Created_From_WOB__c = true
                                                            AND RecordType.Name = 'Supply & Install Opportunity'
                                                            AND Offer__c = 'Insulation Only'];

                
                if(insulationOppOfferList.size() > 0){
                    for(Opportunity insulationOpp : insulationOppOfferList){
                        Map<String, Object> fieldsToValue = insulationOpp.getPopulatedFieldsAsMap();
                        Map<String, Object> oppOfferFieldsToValue = insulationOpp.Opportunity_Offers__r[0].getPopulatedFieldsAsMap();
                        Map<String, Object> oppAndOppOfferFieldMap = new Map<String, Object>();
    
                        oppAndOppOfferFieldMap.putAll(fieldsToValue);
                        oppAndOppOfferFieldMap.putAll(oppOfferFieldsToValue);
                        oppAndOppOfferFieldMap.put('Wall_Wrap__c', oppAndOppOfferFieldMap.get('Wall_Wrap_CB__c'));
                        oppAndOppOfferFieldMap.remove('Wall_Wrap_CB__c');
    
                        oppAndOppOfferFieldMap.put('Ceiling_Insulation__c', oppAndOppOfferFieldMap.get('Ceiling_Insulation_CB__c'));
                        oppAndOppOfferFieldMap.remove('Ceiling_Insulation_CB__c');
    
                        oppAndOppOfferFieldMap.put('External_Wall_Insulation__c', oppAndOppOfferFieldMap.get('External_Wall_Insulation_CB__c'));
    
                        oppAndOppOfferFieldMap = formatOppOfferMap(oppAndOppOfferFieldMap);
    
    
                        
                        oppAndOppOfferFieldMap.remove('External_Wall_Insulation_CB__c');
    
                        oppIdAndFieldsMap.put(insulationOpp.Id, oppAndOppOfferFieldMap);
                    }
                }
                


                List<Opportunity> staircaseOppOfferList = [SELECT Id, Name,  StageName, Offer__c, Created_From_WOB__c, Site_Address__c, CloseDate,   Installation_Required__c,
                                                            Amount, Estimated_Amount__c, TECH_WOB_Create_COS__c,
                                                            (SELECT Id, Opportunity__c, RecordTypeId, Quick_options__c, 
                                                            Tread__c, Tread_Addition__c, Riser__c, Stringer__c, 
                                                            Timber_stringer__c, Steel_stringer__c, Newel_Post__c, Handrail__c, 
                                                            Baluster__c, 
                                                            Upgrade_1_Timber_mono_stringer__c,
                                                            Upgrade_2_Steel_mono_stringer__c,
                                                            Upgrade_3_Steel_plate_stringers__c,
                                                            Additional_Notes__c,
                                                            Architectural_Drawings__c,
                                                            Finishes_Schedule__c
                                                            FROM Opportunity_Offers__r)
                                                            FROM Opportunity WHERE Id IN :oppIdSet 
                                                            AND StageName = 'New' 
                                                            AND Created_From_WOB__c = true
                                                            AND RecordType.Name = 'Supply & Install Opportunity'
                                                            AND Offer__c = 'Staircases'];
                
                
                if(staircaseOppOfferList.size() > 0){
                    for(Opportunity staircaseOpp : staircaseOppOfferList){
                        Map<String, Object> fieldsToValue = staircaseOpp.getPopulatedFieldsAsMap();
                        Map<String, Object> oppOfferFieldsToValue = staircaseOpp.Opportunity_Offers__r[0].getPopulatedFieldsAsMap();
                        Map<String, Object> oppAndOppOfferFieldMap = new Map<String, Object>();
    
                        oppAndOppOfferFieldMap.putAll(fieldsToValue);
                        oppAndOppOfferFieldMap.putAll(oppOfferFieldsToValue);
    
                        oppAndOppOfferFieldMap = formatOppOfferMap(oppAndOppOfferFieldMap);
    
                        oppIdAndFieldsMap.put(staircaseOpp.Id, oppAndOppOfferFieldMap);
                    }
                }
                

                List<Opportunity> hvacOppOfferList = [SELECT Id, Name,  StageName, Offer__c, Created_From_WOB__c, Site_Address__c, CloseDate,  
                                                            Amount, Estimated_Amount__c, TECH_WOB_Create_COS__c,
                                                            (SELECT Id, Opportunity__c, RecordTypeId, Building_Type__c,
                                                            Ceiling_Heights_d_stairs__c,
                                                            Ceiling_Heights_d_stairs_Other__c,
                                                            Ceiling_Heights_u_stairs__c,
                                                            Ceiling_Heights_u_stairs_Other__c,
                                                            Roof_Type__c,
                                                            Roof_Type_Other__c,
                                                            Fuel_Type__c,
                                                            Power_Supply_available__c,
                                                            System_Type__c,
                                                            System_Detail__c,
                                                            Unit_Location__c,
                                                            Efficiency_of_Gas_Furnace__c,
                                                            Number_of_GDH_Ducted_RC_outlets__c,
                                                            Zoning_Requirements__c,
                                                            Return_Air_position__c,
                                                            Return_Air_Grill_Type__c,
                                                            Type_of_EAC_unit__c,
                                                            Colour_of_EAC_unit__c,
                                                            Optima_High_Wall_Split__c,
                                                            Additional_Notes__c,
                                                            Building_Type_Storey__c
                                                            FROM Opportunity_Offers__r)
                                                            FROM Opportunity WHERE Id IN :oppIdSet 
                                                            AND StageName = 'New' 
                                                            AND Created_From_WOB__c = true
                                                            AND RecordType.Name = 'Supply & Install Opportunity'
                                                            AND Offer__c = 'HVAC'];
                
                
                if(hvacOppOfferList.size() > 0){
                    for(Opportunity hvacOpp : hvacOppOfferList){
                        Map<String, Object> fieldsToValue = hvacOpp.getPopulatedFieldsAsMap();
                        Map<String, Object> oppOfferFieldsToValue = hvacOpp.Opportunity_Offers__r[0].getPopulatedFieldsAsMap();
                        Map<String, Object> oppAndOppOfferFieldMap = new Map<String, Object>();
    
                        oppAndOppOfferFieldMap.putAll(fieldsToValue);
                        oppAndOppOfferFieldMap.putAll(oppOfferFieldsToValue);
    
                        oppAndOppOfferFieldMap = formatOppOfferMap(oppAndOppOfferFieldMap);
    
                        oppIdAndFieldsMap.put(hvacOpp.Id, oppAndOppOfferFieldMap);
                    }
                }
                

                List<Opportunity> balustradingOppOfferList = [SELECT Id, Name,  StageName, Offer__c, Created_From_WOB__c, Site_Address__c, CloseDate,   Installation_Required__c,
                                                            Amount, Estimated_Amount__c, TECH_WOB_Create_COS__c,
                                                            (SELECT Id, Opportunity__c, RecordTypeId, 
                                                            Technical_Information__c,
                                                            Type__c,
                                                            Staircase_Rail__c,
                                                            Mount_Type__c,
                                                            Hardware_Colour_Balustrading__c,
                                                            Surface_Installing_into__c,
                                                            Additional_Notes__c,
                                                            Architectural_Drawings__c,
                                                            Finishes_Schedule__c
                                                            FROM Opportunity_Offers__r)
                                                            FROM Opportunity WHERE Id IN :oppIdSet 
                                                            AND StageName = 'New' 
                                                            AND Created_From_WOB__c = true
                                                            AND RecordType.Name = 'Supply & Install Opportunity'
                                                            AND Offer__c = 'Balustrading'];
                
                
                if(balustradingOppOfferList.size() > 0){
                    for(Opportunity balOpp : balustradingOppOfferList){
                        Map<String, Object> fieldsToValue = balOpp.getPopulatedFieldsAsMap();
                        Map<String, Object> oppOfferFieldsToValue = balOpp.Opportunity_Offers__r[0].getPopulatedFieldsAsMap();
                        Map<String, Object> oppAndOppOfferFieldMap = new Map<String, Object>();
    
                        oppAndOppOfferFieldMap.putAll(fieldsToValue);
                        oppAndOppOfferFieldMap.putAll(oppOfferFieldsToValue);

                        oppAndOppOfferFieldMap = formatOppOfferMap(oppAndOppOfferFieldMap);
    
                        oppIdAndFieldsMap.put(balOpp.Id, oppAndOppOfferFieldMap);
                    }
                }
                

                List<Opportunity> claddingOppOfferList = [SELECT Id, Name,  StageName, Offer__c, Created_From_WOB__c, Site_Address__c, CloseDate,   Installation_Required__c,
                                                            Amount, Estimated_Amount__c, TECH_WOB_Create_COS__c,
                                                            (SELECT Id, Opportunity__c, RecordTypeId, 
                                                            Product_Selection_Cladding__c,
                                                            Return_Format__c,
                                                            Wall_Centres__c,
                                                            Wall_Centres_Other__c,
                                                            Wall_Wrap__c,
                                                            Cladding__c,
                                                            Cladding_Comment__c,
                                                            Partiwalls__c,
                                                            Partiwalls_Comment__c,
                                                            Number_of_Levels_Combination__c,
                                                            Render_M2__c,
                                                            Eaves_Soffits__c,
                                                            Building_Substrate_s_for_rendering__c,
                                                            BAL_requirements__c,
                                                            Additional_Comments__c,
                                                            Hardies_Boundary_Wall_Systems__c,
                                                            Hardies_ZeroLot_Wall_Systems__c,
                                                            Hardies_InterTenancy_Wall_Systems__c,
                                                            Architectural_Drawings__c,
                                                            Architectural_Plans_Engineering_Drawings__c,
                                                            Product_Specifications__c,
                                                            Project_Finish_Schedule__c,
                                                            Project_Link_Passwords__c,
                                                            Additional_Notes__c,
                                                            Finishes_Schedule__c
                                                            FROM Opportunity_Offers__r)
                                                            FROM Opportunity WHERE Id IN :oppIdSet 
                                                            AND StageName = 'New' 
                                                            AND Created_From_WOB__c = true
                                                            AND RecordType.Name = 'Supply & Install Opportunity'
                                                            AND Offer__c = 'Cladding'];
                
                
                if(claddingOppOfferList.size() > 0){
                    for(Opportunity claddingOpp : claddingOppOfferList){
                        Map<String, Object> fieldsToValue = claddingOpp.getPopulatedFieldsAsMap();
                        Map<String, Object> oppOfferFieldsToValue = claddingOpp.Opportunity_Offers__r[0].getPopulatedFieldsAsMap();
                        Map<String, Object> oppAndOppOfferFieldMap = new Map<String, Object>();
    
                        oppAndOppOfferFieldMap.putAll(fieldsToValue);
                        oppAndOppOfferFieldMap.putAll(oppOfferFieldsToValue);

                        oppAndOppOfferFieldMap = formatOppOfferMap(oppAndOppOfferFieldMap);
    
                        oppIdAndFieldsMap.put(claddingOpp.Id, oppAndOppOfferFieldMap);
                    }
                }
                

                List<Opportunity> flooringOppOfferList = [SELECT Id, Name,  StageName, Offer__c, Created_From_WOB__c, Site_Address__c, CloseDate,   Installation_Required__c,
                                                            Amount, Estimated_Amount__c, TECH_WOB_Create_COS__c,
                                                            (SELECT Id, Opportunity__c, RecordTypeId, 
                                                            Skirting__c,
                                                            Flooring_Type__c,
                                                            Underlay_Required__c,
                                                            Trims__c,
                                                            Subfloor_Material__c,
                                                            Install_Method__c,
                                                            Flooring_Direction__c,
                                                            Additional_Notes__c,
                                                            Finishes_Schedule__c
                                                            FROM Opportunity_Offers__r)
                                                            FROM Opportunity WHERE Id IN :oppIdSet 
                                                            AND StageName = 'New' 
                                                            AND Created_From_WOB__c = true
                                                            AND RecordType.Name = 'Supply & Install Opportunity'
                                                            AND Offer__c = 'Flooring'];
                
                
                if(flooringOppOfferList.size() > 0){
                    for(Opportunity flooringOpp : flooringOppOfferList){
                        Map<String, Object> fieldsToValue = flooringOpp.getPopulatedFieldsAsMap();
                        Map<String, Object> oppOfferFieldsToValue = flooringOpp.Opportunity_Offers__r[0].getPopulatedFieldsAsMap();
                        Map<String, Object> oppAndOppOfferFieldMap = new Map<String, Object>();
    
                        oppAndOppOfferFieldMap.putAll(fieldsToValue);
                        oppAndOppOfferFieldMap.putAll(oppOfferFieldsToValue);

                        oppAndOppOfferFieldMap = formatOppOfferMap(oppAndOppOfferFieldMap);
    
                        oppIdAndFieldsMap.put(flooringOpp.Id, oppAndOppOfferFieldMap);
                    }
                }
                

                List<Opportunity> garageOppOfferList = [SELECT Id, Name,  StageName, Offer__c, Created_From_WOB__c, Site_Address__c, CloseDate,  
                                                            Amount, Estimated_Amount__c, TECH_WOB_Create_COS__c,
                                                            (SELECT Id, Opportunity__c, RecordTypeId, 
                                                                Garage_Door_Type__c,
                                                                Door_Type__c,
                                                                Quantity_Garage_Door__c,
                                                                Profile__c,
                                                                Colour__c,
                                                                Colour_Other__c,
                                                                Colour_Finish_Specific__c,
                                                                Brush_Seals__c,
                                                                Window_Intergration__c,
                                                                Motor_Upgrade__c,
                                                                Zimi_Power_Mesh_System_Home_Automation__c,
                                                                Additional_Remotes__c,
                                                                Windrated_Upgrade__c,
                                                                Quantity_Additional_Remotes__c,
                                                                Additional_Notes__c
                                                            FROM Opportunity_Offers__r)
                                                            FROM Opportunity WHERE Id IN :oppIdSet 
                                                            AND StageName = 'New' 
                                                            AND Created_From_WOB__c = true
                                                            AND RecordType.Name = 'Supply & Install Opportunity'
                                                            AND Offer__c = 'Garage Door'];
                
                
                if(garageOppOfferList.size() > 0){
                    for(Opportunity garageOpp : garageOppOfferList){
                        Map<String, Object> fieldsToValue = garageOpp.getPopulatedFieldsAsMap();
                        Map<String, Object> oppOfferFieldsToValue = garageOpp.Opportunity_Offers__r[0].getPopulatedFieldsAsMap();
                        Map<String, Object> oppAndOppOfferFieldMap = new Map<String, Object>();
    
                        oppAndOppOfferFieldMap.putAll(fieldsToValue);
                        oppAndOppOfferFieldMap.putAll(oppOfferFieldsToValue);

                        oppAndOppOfferFieldMap = formatOppOfferMap(oppAndOppOfferFieldMap);
    
                        oppIdAndFieldsMap.put(garageOpp.Id, oppAndOppOfferFieldMap);
                    }
                }
                

                List<Opportunity> joineryOppOfferList = [SELECT Id, Name,  StageName, Offer__c, Created_From_WOB__c, Site_Address__c, CloseDate,  Installation_Required__c,
                                                            Amount, Estimated_Amount__c, TECH_WOB_Create_COS__c,
                                                            (SELECT Id, Opportunity__c, RecordTypeId, 
                                                            Elevations__c,
                                                            Floor_Plans__c,
                                                            Finishes_Schedule__c,
                                                            Additional_Notes__c
                                                            FROM Opportunity_Offers__r)
                                                            FROM Opportunity WHERE Id IN :oppIdSet 
                                                            AND StageName = 'New' 
                                                            AND Created_From_WOB__c = true
                                                            AND RecordType.Name = 'Supply & Install Opportunity'
                                                            AND Offer__c = 'Joinery'];
                
                
                if(joineryOppOfferList.size() > 0){
                    for(Opportunity joineryOpp : joineryOppOfferList){
                        Map<String, Object> fieldsToValue = joineryOpp.getPopulatedFieldsAsMap();
                        Map<String, Object> oppOfferFieldsToValue = joineryOpp.Opportunity_Offers__r[0].getPopulatedFieldsAsMap();
                        Map<String, Object> oppAndOppOfferFieldMap = new Map<String, Object>();
    
                        oppAndOppOfferFieldMap.putAll(fieldsToValue);
                        oppAndOppOfferFieldMap.putAll(oppOfferFieldsToValue);

                        oppAndOppOfferFieldMap = formatOppOfferMap(oppAndOppOfferFieldMap);
    
                        oppIdAndFieldsMap.put(joineryOpp.Id, oppAndOppOfferFieldMap);
                    }
                }
                

                List<Opportunity> renderOppOfferList = [SELECT Id, Name,  StageName, Offer__c, Created_From_WOB__c, Site_Address__c, CloseDate,  
                                                            Amount, Estimated_Amount__c, TECH_WOB_Create_COS__c, Installation_Required__c,
                                                            (SELECT Id, Opportunity__c, RecordTypeId, 
                                                                Product_Type__c,
                                                                Return_Format__c,
                                                                Returns_format_Other__c,
                                                                Wind_Zone__c,
                                                                Dulux_Acratex_Details__c,
                                                                Cladding_Dulux_Exsulite__c,
                                                                Required_Render_Finishes_Other__c,	
                                                                Required_Render_Finishes_M2__c,
                                                                Additional_Notes__c ,
                                                                Architectural_Drawings__c,
                                                                Finishes_Schedule__c
                                                            FROM Opportunity_Offers__r)
                                                            FROM Opportunity WHERE Id IN :oppIdSet 
                                                            AND StageName = 'New' 
                                                            AND Created_From_WOB__c = true
                                                            AND RecordType.Name = 'Supply & Install Opportunity'
                                                            AND Offer__c = 'Render & Texture'];
                
                
                if(renderOppOfferList.size() > 0){
                    for(Opportunity renderOpp : renderOppOfferList){
                        Map<String, Object> fieldsToValue = renderOpp.getPopulatedFieldsAsMap();
                        Map<String, Object> oppOfferFieldsToValue = renderOpp.Opportunity_Offers__r[0].getPopulatedFieldsAsMap();
                        Map<String, Object> oppAndOppOfferFieldMap = new Map<String, Object>();
    
                        oppAndOppOfferFieldMap.putAll(fieldsToValue);
                        oppAndOppOfferFieldMap.putAll(oppOfferFieldsToValue);

                        oppAndOppOfferFieldMap = formatOppOfferMap(oppAndOppOfferFieldMap);
    
                        oppIdAndFieldsMap.put(renderOpp.Id, oppAndOppOfferFieldMap);
                    }
                }
                

                List<Opportunity> residentialOppOfferList = [SELECT Id, Name,  StageName, Offer__c, Created_From_WOB__c, Site_Address__c, CloseDate,  
                                                            Amount, Estimated_Amount__c, TECH_WOB_Create_COS__c, Installation_Required__c,
                                                            (SELECT Id, Opportunity__c, RecordTypeId, 
                                                                Estimated_Start_Date__c,
                                                                Levels__c,
                                                                Plans_Attached__c,
                                                                Additional_Notes__c,
                                                                Architectural_Drawings__c,
                                                                Engineering_Plan__c
                                                            FROM Opportunity_Offers__r)
                                                            FROM Opportunity WHERE Id IN :oppIdSet 
                                                            AND StageName = 'New' 
                                                            AND Created_From_WOB__c = true
                                                            AND RecordType.Name = 'Supply & Install Opportunity'
                                                            AND Offer__c = 'Residential Lifts'];
                
                
                if(residentialOppOfferList.size() > 0){
                    for(Opportunity residentialOpp : residentialOppOfferList){
                        Map<String, Object> fieldsToValue = residentialOpp.getPopulatedFieldsAsMap();
                        Map<String, Object> oppOfferFieldsToValue = residentialOpp.Opportunity_Offers__r[0].getPopulatedFieldsAsMap();
                        Map<String, Object> oppAndOppOfferFieldMap = new Map<String, Object>();
    
                        oppAndOppOfferFieldMap.putAll(fieldsToValue);
                        oppAndOppOfferFieldMap.putAll(oppOfferFieldsToValue);
    
                        oppAndOppOfferFieldMap = formatOppOfferMap(oppAndOppOfferFieldMap);

                        DateTime estimatedStartDate = (DateTime) oppAndOppOfferFieldMap.get('Estimated_Start_Date__c');
        
                        oppAndOppOfferFieldMap.put('Estimated_Start_Date__c', estimatedStartDate.day() + '-' + estimatedStartDate.month() + '-' + estimatedStartDate.year());
    
                        oppIdAndFieldsMap.put(residentialOpp.Id, oppAndOppOfferFieldMap);
                    }
                }
                

                List<Opportunity> showerOppOfferList = [SELECT Id, Name,  StageName, Offer__c, Created_From_WOB__c, Site_Address__c, CloseDate,  
                                                            Amount, Estimated_Amount__c, TECH_WOB_Create_COS__c, Installation_Required__c,
                                                            (SELECT Id, Opportunity__c, RecordTypeId, 
                                                            Elevations__c,
                                                            Floor_Plans__c,
                                                            Finishes_Schedule__c,
                                                            Additional_Notes__c
                                                            FROM Opportunity_Offers__r)
                                                            FROM Opportunity WHERE Id IN :oppIdSet 
                                                            AND StageName = 'New' 
                                                            AND Created_From_WOB__c = true
                                                            AND RecordType.Name = 'Supply & Install Opportunity'
                                                            AND Offer__c = 'Shower Screens'];
                
                
                if(showerOppOfferList.size() > 0){
                    for(Opportunity showerOpp : showerOppOfferList){
                        Map<String, Object> fieldsToValue = showerOpp.getPopulatedFieldsAsMap();
                        Map<String, Object> oppOfferFieldsToValue = showerOpp.Opportunity_Offers__r[0].getPopulatedFieldsAsMap();
                        Map<String, Object> oppAndOppOfferFieldMap = new Map<String, Object>();
    
                        oppAndOppOfferFieldMap.putAll(fieldsToValue);
                        oppAndOppOfferFieldMap.putAll(oppOfferFieldsToValue);
    
                        oppAndOppOfferFieldMap = formatOppOfferMap(oppAndOppOfferFieldMap);
    
                        oppIdAndFieldsMap.put(showerOpp.Id, oppAndOppOfferFieldMap);
                    }
                }
                

                List<Opportunity> tactileOppOfferList = [SELECT Id, Name,  StageName, Offer__c, Created_From_WOB__c, Site_Address__c, CloseDate,  
                                                            Amount, Estimated_Amount__c, TECH_WOB_Create_COS__c, Installation_Required__c,
                                                            (SELECT Id, Opportunity__c, RecordTypeId, 
                                                            Tactile_Ground_Surface_Indicators_TGSI__c,
                                                            Stair_Nosing__c,
                                                            Car_Park_Fixtures__c,
                                                            Asset_Protection__c,
                                                            Braille_Signs__c,
                                                            Quote_All_Relevant_Products__c,
                                                            Additional_Notes__c,
                                                            Architectural_Drawings__c
                                                            FROM Opportunity_Offers__r)
                                                            FROM Opportunity WHERE Id IN :oppIdSet 
                                                            AND StageName = 'New' 
                                                            AND Created_From_WOB__c = true
                                                            AND RecordType.Name = 'Supply & Install Opportunity'
                                                            AND Offer__c = 'Tactile'];
                
                
                if(tactileOppOfferList.size() > 0){
                    for(Opportunity tactileOpp : tactileOppOfferList){
                        Map<String, Object> fieldsToValue = tactileOpp.getPopulatedFieldsAsMap();
                        Map<String, Object> oppOfferFieldsToValue = tactileOpp.Opportunity_Offers__r[0].getPopulatedFieldsAsMap();
                        Map<String, Object> oppAndOppOfferFieldMap = new Map<String, Object>();
    
                        oppAndOppOfferFieldMap.putAll(fieldsToValue);
                        oppAndOppOfferFieldMap.putAll(oppOfferFieldsToValue);
    
                        oppAndOppOfferFieldMap = formatOppOfferMap(oppAndOppOfferFieldMap);
    
                        oppIdAndFieldsMap.put(tactileOpp.Id, oppAndOppOfferFieldMap);
                    }
                }
                

                List<Opportunity> wardrobeOppOfferList = [SELECT Id, Name,  StageName, Offer__c, Created_From_WOB__c, Site_Address__c, CloseDate,  
                                                            Amount, Estimated_Amount__c, TECH_WOB_Create_COS__c,
                                                            (SELECT Id, Opportunity__c, RecordTypeId, 
                                                            Elevations__c,
                                                            Floor_Plans__c,
                                                            Finishes_Schedule__c,
                                                            Additional_Notes__c
                                                            FROM Opportunity_Offers__r)
                                                            FROM Opportunity WHERE Id IN :oppIdSet 
                                                            AND StageName = 'New' 
                                                            AND Created_From_WOB__c = true
                                                            AND RecordType.Name = 'Supply & Install Opportunity'
                                                            AND Offer__c = 'Wardrobe'];
                
                
                if(wardrobeOppOfferList.size() > 0){
                    for(Opportunity wardrobeOpp : wardrobeOppOfferList){
                        Map<String, Object> fieldsToValue = wardrobeOpp.getPopulatedFieldsAsMap();
                        Map<String, Object> oppOfferFieldsToValue = wardrobeOpp.Opportunity_Offers__r[0].getPopulatedFieldsAsMap();
                        Map<String, Object> oppAndOppOfferFieldMap = new Map<String, Object>();
    
                        oppAndOppOfferFieldMap.putAll(fieldsToValue);
                        oppAndOppOfferFieldMap.putAll(oppOfferFieldsToValue);
    
                        oppAndOppOfferFieldMap = formatOppOfferMap(oppAndOppOfferFieldMap);
    
                        oppIdAndFieldsMap.put(wardrobeOpp.Id, oppAndOppOfferFieldMap);
                    }
                }
                

                List<Opportunity> waterproofingOppOfferList = [SELECT Id, Name,  StageName, Offer__c, Created_From_WOB__c, Site_Address__c, CloseDate,  
                                                            Amount, Estimated_Amount__c, TECH_WOB_Create_COS__c, Installation_Required__c,
                                                            (SELECT Id, Opportunity__c, RecordTypeId, 
                                                            Requirement_Type__c,
                                                            Venue_Type__c,
                                                            Exposed_Roof_tops__c,
                                                            Green_Roofs_Vertical_Gardens__c,
                                                            Plant_Rooms__c,
                                                            Balconies__c,
                                                            Wet_Areas_bathrooms_toilets_laundries__c,
                                                            Lift_Pits__c,
                                                            Fire_Tanks__c,
                                                            Planter_Boxes__c,
                                                            Podium_Plaza_Decks_and_Terraces__c,
                                                            Slab_Edge_Parging__c,
                                                            Window_Door_Reveals__c,
                                                            Concrete_Decks_Multi_level_Carparks__c,
                                                            Facades__c,
                                                            Retaining_Walls__c,
                                                            Pool_Decks__c,
                                                            Walkways__c,
                                                            Ponds_Water_Features__c,
                                                            Car_parks__c,
                                                            Garages__c,
                                                            Wash_Down_Bays__c,
                                                            Walkways_paths__c,
                                                            Stair_Wells__c,
                                                            Warehouses__c,
                                                            Showrooms__c,
                                                            Storage_Areas__c,
                                                            Plant_Rooms_Waste_Rooms_Mail_Rooms__c,
                                                            Factories_Workshops__c,
                                                            Anti_Graffiti__c,
                                                            Patios_Alfresco_Areas__c,
                                                            Driveways__c,
                                                            Industrial_Kitchens__c,
                                                            Building_Entrances_Lobbies__c,
                                                            Kennels__c,
                                                            Additional_Notes__c
                                                            FROM Opportunity_Offers__r)
                                                            FROM Opportunity WHERE Id IN :oppIdSet 
                                                            AND StageName = 'New' 
                                                            AND Created_From_WOB__c = true
                                                            AND RecordType.Name = 'Supply & Install Opportunity'
                                                            AND Offer__c = 'Waterproofing/Sealing'];
                
                
                if(waterproofingOppOfferList.size() > 0){
                    for(Opportunity waterproofingOpp : waterproofingOppOfferList){
                        Map<String, Object> fieldsToValue = waterproofingOpp.getPopulatedFieldsAsMap();
                        Map<String, Object> oppOfferFieldsToValue = waterproofingOpp.Opportunity_Offers__r[0].getPopulatedFieldsAsMap();
                        Map<String, Object> oppAndOppOfferFieldMap = new Map<String, Object>();
    
                        oppAndOppOfferFieldMap.putAll(fieldsToValue);
                        oppAndOppOfferFieldMap.putAll(oppOfferFieldsToValue);
    
                        oppAndOppOfferFieldMap = formatOppOfferMap(oppAndOppOfferFieldMap);
    
                        oppIdAndFieldsMap.put(waterproofingOpp.Id, oppAndOppOfferFieldMap);
                    }
                }
                

                List<Opportunity> windowFurnishingOppOfferList = [SELECT Id, Name,  StageName, Offer__c, Created_From_WOB__c, Site_Address__c, CloseDate,  
                                                            Amount, Estimated_Amount__c, TECH_WOB_Create_COS__c, Installation_Required__c,
                                                            (SELECT Id, Opportunity__c, RecordTypeId, 
                                                            Window_Covering_Type__c,
                                                            Window_Installation_Method__c,
                                                            Material_Selected__c,
                                                            Notes__c
                                                            FROM Opportunity_Offers__r)
                                                            FROM Opportunity WHERE Id IN :oppIdSet 
                                                            AND StageName = 'New' 
                                                            AND Created_From_WOB__c = true
                                                            AND RecordType.Name = 'Supply & Install Opportunity'
                                                            AND Offer__c = 'Window Furnishing'];
                
                
                if(windowFurnishingOppOfferList.size() > 0){
                    for(Opportunity windowFurnishingOpp : windowFurnishingOppOfferList){
                        Map<String, Object> fieldsToValue = windowFurnishingOpp.getPopulatedFieldsAsMap();
                        Map<String, Object> oppOfferFieldsToValue = windowFurnishingOpp.Opportunity_Offers__r[0].getPopulatedFieldsAsMap();
                        Map<String, Object> oppAndOppOfferFieldMap = new Map<String, Object>();
    
                        oppAndOppOfferFieldMap.putAll(fieldsToValue);
                        oppAndOppOfferFieldMap.putAll(oppOfferFieldsToValue);
    
                        oppAndOppOfferFieldMap = formatOppOfferMap(oppAndOppOfferFieldMap);
    
                        oppIdAndFieldsMap.put(windowFurnishingOpp.Id, oppAndOppOfferFieldMap);
                    }
                }
                

                List<Opportunity> windowsOppOfferList = [SELECT Id, Name,  StageName, Offer__c, Created_From_WOB__c, Site_Address__c, CloseDate,  
                                                            Amount, Estimated_Amount__c, TECH_WOB_Create_COS__c, Installation_Required__c,
                                                            (SELECT Id, Opportunity__c, RecordTypeId, 
                                                            Type_of_Windows__c,
                                                            Floor_Plans__c,
                                                            Elevations__c,
                                                            Window_Schedule__c,
                                                            Energy_Report__c,
                                                            Fire_Engineers_Report__c,
                                                            Finishing_H_Ware_Schedule__c,
                                                            Acoustic_Report__c,
                                                            Bal_Rating__c,
                                                            Wind_Ratings__c,
                                                            General_Service__c,
                                                            Polywrap_to_Frames__c,
                                                            Reveals__c,
                                                            Flyscreens__c,
                                                            Flydoors__c,
                                                            Flydoor_Options__c,
                                                            Windows_Doors__c,
                                                            Additional_Notes__c,
                                                            Architectural_Drawings__c,
                                                            Engineering_Plan__c
                                                            FROM Opportunity_Offers__r)
                                                            FROM Opportunity WHERE Id IN :oppIdSet 
                                                            AND StageName = 'New' 
                                                            AND Created_From_WOB__c = true
                                                            AND RecordType.Name = 'Supply & Install Opportunity'
                                                            AND Offer__c = 'Windows'];
                
                
                if(windowsOppOfferList.size() > 0){
                    for(Opportunity windowsOpp : windowsOppOfferList){
                        Map<String, Object> fieldsToValue = windowsOpp.getPopulatedFieldsAsMap();
                        Map<String, Object> oppOfferFieldsToValue = windowsOpp.Opportunity_Offers__r[0].getPopulatedFieldsAsMap();
                        Map<String, Object> oppAndOppOfferFieldMap = new Map<String, Object>();
    
                        oppAndOppOfferFieldMap.putAll(fieldsToValue);
                        oppAndOppOfferFieldMap.putAll(oppOfferFieldsToValue);
    
                        oppAndOppOfferFieldMap = formatOppOfferMap(oppAndOppOfferFieldMap);
    
                        oppIdAndFieldsMap.put(windowsOpp.Id, oppAndOppOfferFieldMap);
                    }
                }
                


                List<Opportunity> nasahiOppOfferList = [SELECT Id, Name,  StageName, Offer__c, Created_From_WOB__c, Site_Address__c, CloseDate,  
                                                            Amount, Estimated_Amount__c, TECH_WOB_Create_COS__c, Installation_Required__c,
                                                            (SELECT Id, Opportunity__c, RecordTypeId, 
                                                            Return_Format__c,
                                                            Panel_size__c,
                                                            Top_Hat__c,
                                                            Slab_Edge_Height__c,
                                                            Slab_Rebate_Size__c,
                                                            General_description_of_works__c,
                                                            Architectural_Drawings__c,
                                                            Product_Specifications__c,
                                                            Project_Finish_Schedule__c,
                                                            Product_Selection__c
                                                            FROM Opportunity_Offers__r)
                                                            FROM Opportunity WHERE Id IN :oppIdSet 
                                                            AND StageName = 'New' 
                                                            AND Created_From_WOB__c = true
                                                            AND RecordType.Name = 'Supply & Install Opportunity'
                                                            AND Offer__c = 'AAC - Nasahi Panel'];
                
                
                if(nasahiOppOfferList.size() > 0){
                    for(Opportunity nasahiOpp : nasahiOppOfferList){
                        Map<String, Object> fieldsToValue = nasahiOpp.getPopulatedFieldsAsMap();
                        Map<String, Object> oppOfferFieldsToValue = nasahiOpp.Opportunity_Offers__r[0].getPopulatedFieldsAsMap();
                        Map<String, Object> oppAndOppOfferFieldMap = new Map<String, Object>();
    
                        oppAndOppOfferFieldMap.putAll(fieldsToValue);
                        oppAndOppOfferFieldMap.putAll(oppOfferFieldsToValue);
    
                        oppAndOppOfferFieldMap = formatOppOfferMap(oppAndOppOfferFieldMap);
    
                        oppIdAndFieldsMap.put(nasahiOpp.Id, oppAndOppOfferFieldMap);
                    }
                }

                for(Id key  : oppIdAndFieldsMap.keySet()){
                    Object convertedOfferName = oppIdAndFieldsMap.get(key).get('Offer__c');
                    Object oppCosIDLink = oppIdAndFieldsMap.get(key).get('TECH_WOB_Create_COS__c');
                    if(convertedOfferName == 'Insulation Only'){
                        convertedOfferName = 'Insulation';
                    }else if(convertedOfferName == 'Render & Texture'){
                        convertedOfferName = 'Render';
                    }else if(convertedOfferName == 'Residential Lifts'){
                        convertedOfferName = 'Lifts';
                    }else if(convertedOfferName == 'Garage Door'){
                        convertedOfferName = 'Garage';
                    }else if(convertedOfferName == 'Waterproofing/Sealing'){
                        convertedOfferName = 'Waterproofing';
                    }else if(convertedOfferName == 'Wardrobe'){
                        convertedOfferName = 'Wardrobes';
                    }else if(convertedOfferName == 'Joinery'){
                        convertedOfferName = 'Kitchen Joinery';
                    }else if(convertedOfferName == 'Plasterboard & Insulation'){
                        convertedOfferName = 'Plasterboard / Insulation';
                    }

                    if(!oppOfferList.contains((String)convertedOfferName)){
                        oppOfferList.add((String)convertedOfferName);
                    }
                    //oppOfferList.add((String)convertedOfferName);
                    oppCreateCOSList.add((String)oppCosIDLink);
                }

                System.debug('sid oppOfferList ' + oppOfferList);

                String oppIDLinks = String.join(oppCreateCOSList, '||'); 
                String oppOffers = String.join(oppOfferList,'||');

                Project__c projectRecord = [SELECT Id, Name, Project_Address__c, Build_Stage__c, Development_Type__c, Status__c,
                                            Project_Type__c, Project_Value__c,Floors__c, Number_of_Units_Buildings__c, 
                                            Tender_Due_Date__c, Town__c, State__c, Postcode__c, Main_Account__c, Selected_Account_Lookup__c, CreatedDate,
                                            Concatenated_Address__c,OwnerId, House_Type__c, Selected_Account_Lookup__r.Power_Pass_Account_Number__c, Selected_Account_Lookup__r.Name, 
                                            Selected_Contact_Lookup__r.Phone,Selected_Account_Lookup__r.Account_Owner__c, Selected_Contact_Lookup__r.Email,
                                            Construction_Start__c, Construction_End__c , Selected_Contact_Lookup__c, Document_Library_URL__c, Shared_Document_Password__c, Selected_Account__c,
                                            TECH_WOB_Construction_End_Formatted__c, TECH_WOB_Construction_Start_Formatted__c, TECH_WOB_Lot_No__c, TECH_WOB_Street_No__c,
                                            TECH_WOB_Street_Name__c,TECH_WOB_Street_Type__c 
                                            FROM Project__c 
                                            WHERE Id =:projectRecordId];
                
                Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(supplyInstallEmailTemplate.Id, null, projectRecordId);

                email.setToAddresses(recipientList);
                email.setBccAddresses(bccList);


                String emailSubject = 'BOT Supply and Install Lead Form - '+ projectRecord.State__c +' - '+ projectRecord.Selected_Account_Lookup__r.Name +' - '+ projectRecord.Town__c +' - ' + oppOffers;
                email.setSubject(emailSubject);
                String htmlTextBody = '<html style="overflow-y: hidden;">';
                htmlTextBody += '<head><title></title></head>';
                htmlTextBody += '<body style="height: auto; min-height: auto;">';
                htmlTextBody += '<p><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;">Hi, S&amp;I Team:</span></p>';
                htmlTextBody += '<p><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;">I am submitting S&amp;I quote request.</span></p>';
                
                //SFSUP-74 - Determine if credit check required
                if(totalOppOfferEstimatedAmount >= 50000){
                    Decimal oppOfferDecimal = totalOppOfferEstimatedAmount;
                    String formattedAmount = oppOfferDecimal.format().contains('.') ? oppOfferDecimal.format() : (oppOfferDecimal.format()+'.00');
                    htmlTextBody += '<p><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;">Attn Credit:</span></p>';
                    htmlTextBody += '<p><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;">Please review credit limitations of a proposed job estimated value $'+ formattedAmount +'</span></p>';
                }

                DateTime expectedStartDate = (DateTime) projectRecord.Construction_Start__c;
                String expectedStartDateFormatted = expectedStartDate.day() + '-' + expectedStartDate.month() + '-' + expectedStartDate.year();
                
                DateTime leadDate = (DateTime) projectRecord.CreatedDate;
                String leadDateFormatted = leadDate.day() + '-' + leadDate.month() + '-' + leadDate.year();

                htmlTextBody += '<p><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;">---------------------------------------------For Supply And Install Use Only-------------------------------------------------------,</span></p>&nbsp;';
                htmlTextBody += '<table><tbody>';
                htmlTextBody += '<col width="40%"><col width="60%">';
                htmlTextBody += '<tr><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;"><strong>CustomerAccountNumber: </strong></span></td><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;">'+projectRecord.Selected_Account_Lookup__r.Power_Pass_Account_Number__c+' ;</span></td></tr>';
                htmlTextBody += '<tr><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;"><strong>CustomerName: </strong></span></td><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;">'+ projectRecord.Selected_Account_Lookup__r.Name +' ;</span></td></tr>';
                htmlTextBody += '<tr><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;"><strong>PhoneNo: </strong></span></td><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;">'+ projectRecord.Selected_Contact_Lookup__r.Phone + ' ;</span></td></tr>';
                htmlTextBody += '<tr><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;"><strong>LotNo: </strong></span></td><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;">'+ projectRecord.TECH_WOB_Lot_No__c + ' ;</span></td></tr>';
                htmlTextBody += '<tr><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;"><strong>StreetNo: </strong></span></td><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;">'+ projectRecord.TECH_WOB_Street_No__c + ' ;</span></td></tr>';
                htmlTextBody += '<tr><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;"><strong>StreetName: </strong></span></td><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;">'+ projectRecord.TECH_WOB_Street_Name__c +' ;</span></td></tr>';
                htmlTextBody += '<tr><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;"><strong>StreetType: </strong></span></td><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;">'+ projectRecord.TECH_WOB_Street_Type__c +' ;</span></td></tr>';
                htmlTextBody += '<tr><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;"><strong>Suburb: </strong></span></td><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;">'+ projectRecord.Town__c +' ;</span></td></tr>';
                htmlTextBody += '<tr><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;"><strong>State: </strong></span></td><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;">'+ projectRecord.State__c +' ;</span></td></tr>';
                htmlTextBody += '<tr><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;"><strong>Postcode: </strong></span></td><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;">'+ projectRecord.Postcode__c +' ;</span></td></tr>';
                htmlTextBody += '<tr><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;"><strong>ExpectedStartDate: </strong></span></td><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;">'+ expectedStartDateFormatted +' ;</span></td></tr>';
                htmlTextBody += '<tr><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;"><strong>ContractDate: </strong></span></td><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;">'+ supplyInstallOppListFiltered[0].Contract_Start__c +' ;</span></td></tr>';
                htmlTextBody += '<tr><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;"><strong>Units/DwellingQty: </strong></span></td><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;">'+ projectRecord.Number_of_Units_Buildings__c +' ;</span></td></tr>';
                htmlTextBody += '<tr><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;"><strong>BuildType: </strong></span></td><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;">'+ projectRecord.Project_Type__c +' ;</span></td></tr>';
                htmlTextBody += '<tr><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;"><strong>CommercialAccountManager: </strong></span></td><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;">'+ projectRecord.Selected_Account_Lookup__r.Account_Owner__c +' ;</span></td></tr>';
                htmlTextBody += '<tr><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;"><strong>Categories: </strong></span></td><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;">'+ oppOffers +' ;</span></td></tr>';
                htmlTextBody += '<tr><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;"><strong>LeadDate: </strong></span></td><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;">'+ leadDateFormatted +'</span></td></tr>';
                htmlTextBody += '<tr><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;"><strong>Store Name: </strong></span></td><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;">'+ supplyInstallOppListFiltered[0].Originating_Store__r.Name +' ;</span></td></tr>';
                htmlTextBody += '<tr><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;"><strong>Email: </strong></span></td><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;">'+ projectRecord.Selected_Contact_Lookup__r.Email +' ;</span></td></tr>';
                htmlTextBody += '<tr><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;"><strong>OpportunityIDLinks: </strong></span></td><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;">'+ oppIDLinks +' ;</span></td></tr>';
                htmlTextBody += '<tr><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;"><strong>SharedDocumentLink: </strong></span></td><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;"><a href="'+ projectRecord.Document_Library_URL__c +'">'+ projectRecord.Document_Library_URL__c +'</a> ;</span></td></tr>';
                htmlTextBody += '<tr><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;"><strong>SharedDocumentPassword: </strong></span></td><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;">'+ projectRecord.Shared_Document_Password__c +' ;</span></td></tr>';
                htmlTextBody += '</tbody></table>';

                htmlTextBody += '<tr><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;"><strong>LeadInfo: </strong></span></td><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;"></span></td></tr>';
                for(Id key  : oppIdAndFieldsMap.keySet()){
                    Object convertedOfferName = oppIdAndFieldsMap.get(key).get('Offer__c');
                    if(convertedOfferName == 'Insulation Only'){
                        convertedOfferName = 'Insulation';
                    }else if(convertedOfferName == 'Render & Texture'){
                        convertedOfferName = 'Render';
                    }else if(convertedOfferName == 'Residential Lifts'){
                        convertedOfferName = 'Lifts';
                    }else if(convertedOfferName == 'AAC - Nasahi Panel'){
                        convertedOfferName = 'Roofing';
                    }else if(convertedOfferName == 'Garage Door'){
                        convertedOfferName = 'Garage';
                    }else if(convertedOfferName == 'Waterproofing/Sealing'){
                        convertedOfferName = 'Waterproofing';
                    }else if(convertedOfferName == 'Wardrobe'){
                        convertedOfferName = 'Wardrobes';
                    }else if(convertedOfferName == 'Joinery'){
                        convertedOfferName = 'Kitchen Joinery';
                    }else if(convertedOfferName == 'Plasterboard & Insulation'){
                        convertedOfferName = 'Plasterboard / Insulation';
                    }
                    
                    htmlTextBody += '<h3><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;"><strong>--'+ convertedOfferName  +'--</strong></span></h3>';
                    htmlTextBody += '<table><tbody>';
                    htmlTextBody += '<col width="40%"><col width="60%">';
                    for(String fieldName : oppIdAndFieldsMap.get(key).keySet()){
                        String convertedFieldName = fieldName;
                        if(convertedFieldName.contains('__c')){
                            convertedFieldName = convertedFieldName.removeEnd('__c');
                            convertedFieldName = convertedFieldName.replaceAll('\\_', ' ');
                        }
                        Object convertedFieldValue = oppIdAndFieldsMap.get(key).get(fieldName);
                        if(convertedFieldValue == true){
                            convertedFieldValue = 'Yes';
                        }
                        if(convertedFieldValue == false){
                            convertedFieldValue = 'No';
                        }
                        if(convertedFieldName == 'CloseDate'){
                            convertedFieldName = 'Close Date';
                        }
                        if(convertedFieldName == 'Hardware Colour Balustrading'){
                            convertedFieldName = 'Hardware Colour';
                        }
                        if(convertedFieldName != 'TECH WOB Create COS'){
                            htmlTextBody += '<tr><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;"><strong>'+ convertedFieldName +': </strong></span></td><td><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;">'+ convertedFieldValue +' ;</span></td></tr>';
                        }
                        
                    }
                    htmlTextBody += '</tbody></table>';
                }

                htmlTextBody += '<p><span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;">Please reach out to me should you require any clarification.</span></p><br />';
                htmlTextBody += '<span style="font-family:Segoe UI,Arial,Helvetica,sans-serif;"><meta><b style="color: rgb(0, 0, 0); font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; letter-spacing: normal; orphans: 2; text-align: start; text-indent: 0px; text-transform: none; white-space: normal; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; text-decoration-style: initial; text-decoration-color: initial; font-family: Calibri, sans-serif; font-size: 14.6667px;"><b><span style="font-size: 10.5pt; color: rgb(0, 61, 66);">'+ senderRecord.FirstName +' '+ senderRecord.LastName +'</span>';
                htmlTextBody += '</b><br />'+ userTitle +'</b><br /><img alt="Email signature footer" src="https://bunnings--c.documentforce.com/file-asset-public/Email_signature_footer1?oid=00D2v0000026nq0" style="max-width: 2348.4957885742188px" title="Email signature footer" /><br />';
                htmlTextBody += '<b style="color: rgb(0, 0, 0); font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; letter-spacing: normal; orphans: 2; text-align: start; text-indent: 0px; text-transform: none; white-space: normal; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; text-decoration-style: initial; text-decoration-color: initial; font-family: Calibri, sans-serif; font-size: 14.6667px;"><span style="font-size: 7.5pt; color: rgb(20, 20, 19);">Bunnings Group Limited<br />'+ userAddress +'<br />';
                htmlTextBody += ''+ phoneNumber + '&nbsp; |&nbsp; '+ mobilePhone +'&nbsp; |&nbsp;'+ emailAddress +'</span></b></span>';
                htmlTextBody += '</body></html>';

                email.setHTMLBody(htmlTextBody);
                email.saveAsActivity = true;
                
                if (!contentVersionFileIdList.isEmpty()) { 
                    email.setEntityAttachments(contentVersionFileIdList);
                } 
                
                masterListMails.add(email);

                System.debug('sid email ' + masterListMails);
                if(masterListMails.size() > 0){
                    List<Messaging.SendEmailResult> sendEmailResults = Messaging.sendEmail(masterListMails);

                    for(Messaging.SendEmailResult sendEmailResult: sendEmailResults){
                        if(sendEmailResult.isSuccess()){
                            System.debug('success ' + sendEmailResult);
                        }else{
                            System.debug('failed ' + sendEmailResult);
                        }
                    }

                    //SFSUP-107 - Submit Form - Create S&I case
                    List<Case> supplyInstallCaseList = new List<Case>();
                    for(Opportunity opp : supplyInstallOppListFiltered){
                        if(opp.StageName == 'New'){
                            opp.StageName = 'Qualifying';
                        }
                        Case newSandIRequestCase = new Case();
                        newSandIRequestCase.AccountId = opp.AccountId;
                        newSandIRequestCase.Opportunity__c = opp.Id;
                        newSandIRequestCase.Project__c = opp.Project__c;
                        newSandIRequestCase.Priority = 'Medium';
                        newSandIRequestCase.Subject = 'S&I Request';
                        newSandIRequestCase.Status = 'New';
                        //to replace with F&T Team Queue 
                        //newSandIRequestCase.OwnerId = UserInfo.getUserId();
                        newSandIRequestCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('S_I_Request').getRecordTypeId();
                        supplyInstallCaseList.add(newSandIRequestCase);
                    }
                    update supplyInstallOppListFiltered;
                    insert supplyInstallCaseList;
                }

                
            }

            
            
            return 'Opportunities updated and emails sent';
        } catch (Exception e) {
            System.debug('sid error '+  e.getMessage());
            AuraHandledException ex = new AuraHandledException(String.valueOf(e));
            //ex.setMessage('An Error Occured While Updating stages of Opportunities related to Project');
            throw ex; 
        }
    }

    public static Map<String, Object> formatOppOfferMap(Map<String, Object> oppOfferMapToFormat){
        Map<String, Object> formattedOppOfferMap = new Map<String, Object>();
        DateTime closeDateTime = (DateTime) oppOfferMapToFormat.get('CloseDate');
        
        oppOfferMapToFormat.put('CloseDate', closeDateTime.day() + '-' + closeDateTime.month() + '-' + closeDateTime.year());

        

        oppOfferMapToFormat.remove('Opportunity_Offers__r');
        oppOfferMapToFormat.remove('Id');
        oppOfferMapToFormat.remove('StageName');
        oppOfferMapToFormat.remove('Opportunity__c');
        oppOfferMapToFormat.remove('Created_from_WOB__c');
        oppOfferMapToFormat.remove('RecordTypeId');
        //oppOfferMapToFormat.remove('CloseDate');

        formattedOppOfferMap = oppOfferMapToFormat;

        return formattedOppOfferMap;
    }

}