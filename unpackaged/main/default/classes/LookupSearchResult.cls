/*******************************************************************************************************
* Class Name      	: LookupSearchResult
* Description		: Class used to serialize a single Lookup search result item
*                     The Lookup controller returns a List<LookupSearchResult> when sending search result back to Lightning
* Author          	: Simplus - Yi Zhang
* Created On      	: 07/08/2020
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Yi Zhang              07/08/2020		1000				Initial version
******************************************************************************************************/
public class LookupSearchResult implements Comparable {
    private Id id;
    private String sObjectType;
    private String icon;
    private String title;
    private String subtitle;

    public LookupSearchResult(Id id, String sObjectType, String icon, String title, String subtitle) {
        this.id = id;
        this.sObjectType = sObjectType;
        this.icon = icon;
        this.title = title;
        this.subtitle = subtitle;
    }

    @AuraEnabled
    public Id getId() {
        return id;
    }

    @AuraEnabled
    public String getSObjectType() {
        return sObjectType;
    }

    @AuraEnabled
    public String getIcon() {
        return icon;
    }

    @AuraEnabled
    public String getTitle() {
        return title;
    }

    @AuraEnabled
    public String getSubtitle() {
        return subtitle;
    }

    /**
     * Allow to sort search results based on title
     */
    public Integer compareTo(Object compareTo) {
        LookupSearchResult other = (LookupSearchResult) compareTo;
        if (this.getTitle() == null) {
            return (other.getTitle() == null) ? 0 : 1;
        }
        if (other.getTitle() == null) {
            return -1;
        }
        return this.getTitle().compareTo(other.getTitle());
    }
}