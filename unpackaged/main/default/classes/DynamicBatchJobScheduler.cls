/*******************************************************************************************************
* Class Name      	: DynamicBatchJobScheduler 
* Description		: Dynamic Scheduler class for Batch class for CCRM15-247 migration
* Author          	: Simplus MS
* Created On      	: 18/10/2021
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer			  		Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Sidney Garcia             18/10/2021		1000				Initial version
******************************************************************************************************/
global class DynamicBatchJobScheduler implements Schedulable{
    public String CLASSNAME;
    public Integer BATCHSIZE;
    public String QUERYFILTER;
    public DynamicBatchJobScheduler(String batchClassName, Integer count, String queryFilter){
        this.CLASSNAME = batchClassName;
        this.BATCHSIZE = count;
        this.QUERYFILTER = queryFilter;
    }

    public class ClassNameException extends Exception {}
    public Object createInstance(String className) {
        Type typ = Type.forName(className);
        Object instance = null;
        if (typ != null) {
            instance = typ.newInstance();
        }
    
        if (instance == null) {
            throw new ClassNameException('Couldn\'t successfully instantiate an object for class ' + className + '. Please check if Class Name is correct, is compilable and current user has access.');
        }
    
        return instance;
    }

    public void execute(SchedulableContext sc) { 
        System.debug('QUERYFILTER ' + QUERYFILTER);
        if(QUERYFILTER != null){
            String batchParameters = '{"queryFilter": "'+QUERYFILTER+'"}';
            Database.Batchable<SObject> b = (Database.Batchable<SObject>) JSON.deserialize(batchParameters, Type.forName(CLASSNAME));
            Database.executeBatch(b, BATCHSIZE);
        }else{
            Database.executeBatch((Database.Batchable<sObject>)createInstance(CLASSNAME), BATCHSIZE);
        }
        
   }
}