/*******************************************************************************************************
* Class Name        : DM_ProcessAutomation
* Description       : Data Layer - Selector for Custom Metadata Type Process Automation Control Panel
* Author            : Simplus - MS
* Created On        : 2021-05-31
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS            2021-05-31      1000                Initial version
* Simplus MS			06/08/2021		2000				Added getAll instead of soql
******************************************************************************************************/
public with sharing class DM_ProcessAutomation {

    /**
    * @description 
    * @author Simplus MS | 31/05/2021 
    * @return Process_Automation_Control_Panel__mdt 
    **/
    @AuraEnabled(cacheable=true)
    public static Process_Automation_Control_Panel__mdt getCCRMProcessAutomation() {
        
        Process_Automation_Control_Panel__mdt record = Process_Automation_Control_Panel__mdt.getAll().values();
        return record;
    }
    
    
    /**
    * @description 
    * @author Simplus MS | 31/05/2021 
    * @return Process_Automation_Control_Panel__mdt 
    **/   
    public static Process_Automation_Control_Panel__mdt ccrmProcessAutomation {
        get {
            if(ccrmProcessAutomation == null) {
                ccrmProcessAutomation = getCCRMProcessAutomation();
            }
            return ccrmProcessAutomation;
        } set;
    }
}