/*******************************************************************************************************
* Class Name      	: SM_UpdateAccountsSalesRepQueueable
* Description		: Queueable class for CCRM15-259
					  using Queueable since the process is initiated in a future method: SM_SalesRep.updateUsersAsync
					  Future method cannot be called from a future or batch method
* Author          	: Simplus - MS
* Created On      	: 04/11/2021
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Simplus MS            04/11/2021		1000				Initial version
******************************************************************************************************/
public class SM_UpdateAccountsSalesRepQueueable implements Queueable {
    private list<Account> lAccounts = new list<Account>(); 
    
    public SM_UpdateAccountsSalesRepQueueable(List<Account> lAccounts) {
        this.lAccounts = lAccounts;
    }
    
    public void execute(System.QueueableContext qc) {
        try {
            system.debug('lAccounts' + this.lAccounts);
            update lAccounts;
        } catch(Exception e) {
            ApplicationLogger.log('SM_UpdateAccountsSalesRepQueueable', 'Account', 'Queueable', e);
        }  
    }
    
}