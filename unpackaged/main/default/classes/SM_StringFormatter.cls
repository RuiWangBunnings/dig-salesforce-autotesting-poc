/*******************************************************************************************************
* Class Name      	: SM_StringFormatter
* Description		: Utility class for string formatting
* Author          	: Simplus - Philip Clark
* Created On      	: 06/07/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Philip Clark          06/07/2020		1000				Initial version
******************************************************************************************************/
public without sharing class SM_StringFormatter {

    /**
    * @description 
    * @author Philip Clark | 06/07/2020 
    * @param String 
    **/
    public static String abnFormat(String abn) {
        if(abn.replaceAll('[^0-9]','').length()==11) {
            abn = abn.replaceAll('[^0-9]','');
            abn = abn.substring(0,2)+' '+abn.substring(2,5)+' '+abn.substring(5,8)+' '+abn.substring(8,11);
        }
        return abn;
    }

    /**
    * @description 
    * @author Philip Clark | 06/07/2020 
    * @param String 
    **/
    public static String acnFormat(String acn) {
        if(acn.replaceAll('[^0-9]','').length()==9) {
            acn = acn.replaceAll('[^0-9]','');
            acn = acn.substring(0,3)+' '+acn.substring(3,6)+' '+acn.substring(6,9);
        }
        return acn;
    }

    /**
    * @description 
    * @author Philip Clark | 08/07/2020 
    * @param String 
    **/
    public static String gstFormat(String num) {
        if(num.replaceAll('[^0-9]', '').length()==8 || num.replaceAll('[^0-9]', '').length()==9) {
            num = num.replaceAll('[^0-9]', '');
        }
        return num;
    }

}