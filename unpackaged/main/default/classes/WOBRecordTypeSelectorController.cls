/*******************************************************************************************************
* Class Name      	: WOBRecordTypeSelectorController
* Description		: Controller class of SelectedRecordTypeId lightning component
* Author          	: Simplus MS
* Created On      	: 03/02/2022
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer					Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS             	03/02/2022		1000				Initial version
******************************************************************************************************/
public class WOBRecordTypeSelectorController {
    
    /**
    * @description Used to get opportunity record type list 
    * @author Simplus MS | 03/02/2022
    **/
    @AuraEnabled
    public static List<RecordTypeListWrapper> getListOfRecordType(){
        try{ 
            List<RecordTypeListWrapper> recordTypeList= new List<RecordTypeListWrapper>();
            Schema.SObjectType  objType = Opportunity.SObjectType;        
            for(RecordTypeInfo rt : objType.getDescribe().getRecordTypeInfos()){
                if (rt.isAvailable()){
                    if(rt.getName() != 'Master'){
                        recordTypeList.add(new RecordTypeListWrapper(rt.getName(), rt.getRecordTypeId()));
                    }
                }
            }
            return recordTypeList;    
        }catch(Exception e){
            system.debug('ERROR: ' + e.getMessage());
            return null; 
        }    
    }

    public class RecordTypeListWrapper {
        @AuraEnabled public String label;
        @AuraEnabled public String value;

        public RecordTypeListWrapper(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
}