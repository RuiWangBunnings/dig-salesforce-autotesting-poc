/*******************************************************************************************************
* Class Name      	: SM_ContactPointAddressBuilder
* @description		: Service layer - To create ContactPointAddress records easily
* @author          	: Deloitte - Juan Cutrera
* Created On      	: 04/04/2025
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer				Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* Juan Cutrera          04/04/2025		1000				Initial Version
******************************************************************************************************/
public class SM_ContactPointAddressBuilder implements Builder {

    private ContactPointAddress newContactPointAddress = new ContactPointAddress();

    /**
    * @description  setAddress - Sets the address fields of the ContactPointAddress
    * @author Juan Cutrera | 04/04/2025
    * @param street The street address
    * @param city The city
    * @param state The state
    * @param postalCode The postal code
    * @param country The country
    * @return ContactPointAddress
    **/
    public SM_ContactPointAddressBuilder setAddress(String street, String city, String state, String postalCode, String country) {
        newContactPointAddress.Street = street;
        newContactPointAddress.City = city;
        newContactPointAddress.State = state;
        newContactPointAddress.PostalCode = postalCode;
        newContactPointAddress.Country = country;
        return this;
    }


    /**
    * @description  setAddressType - Sets the address type of the ContactPointAddress and validates it
    * @author Juan Cutrera | 04/04/2025
    * @param addressType The address type to set
    * @return ContactPointAddress
    * @throws IllegalArgumentException if the address type is invalid
    **/
    public SM_ContactPointAddressBuilder setAddressType(String addressType) {
        Set<String> validAddressType = getPicklistValues('AddressType');

        if (validAddressType.contains(addressType)) {
            newContactPointAddress.AddressType = addressType;
        } else {
            throw new IllegalArgumentException('Invalid Address Type: ' + addressType);
        }
        return this;
    }

    /**
    * @description  setName - Sets the name of the ContactPointAddress
    * @author Juan Cutrera | 04/04/2025
    * @param name The name to set
    * @return ContactPointAddress
    **/
    public SM_ContactPointAddressBuilder setName(String name) {
        newContactPointAddress.Name = name;
        return this;
    }

    /**
    * @description  setParentId - Sets the parent ID of the ContactPointAddress
    * @author Juan Cutrera | 04/04/2025
    * @param parentId The parent ID to set
    * @return ContactPointAddress
    **/
    public SM_ContactPointAddressBuilder setParentId(String parentId) {
        newContactPointAddress.ParentId = parentId;
        return this;
    }

    /**
    * @description  setOwnerId - Sets the owner ID of the ContactPointAddress
    * @author Juan Cutrera | 04/04/2025
    * @param ownerId The owner ID to set
    * @return ContactPointAddress
    **/
    public SM_ContactPointAddressBuilder setOwnerId(String ownerId) {
        newContactPointAddress.OwnerId = ownerId;
        return this;
    }

    /**
    * @description  getPicklistValues - Get valid picklist values dynamically for a given field
    * @author Juan Cutrera | 04/04/2025
    * @param fieldName The API name of the field
    * @return Set<String>
    **/
    private static Set<String> getPicklistValues(String fieldName) {
        Set<String> validValues = new Set<String>();
        Schema.DescribeFieldResult fieldResult = Schema.SObjectType.ContactPointAddress.fields.getMap().get(fieldName).getDescribe();

        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            validValues.add(entry.getValue());
        }
        return validValues;
    }

    /**
    * @description  build - Builds and returns the configured ContactPointAddress instance
    * @author Juan Cutrera | 04/04/2025
    * @return ContactPointAddress
    **/
    public ContactPointAddress build() {
        return newContactPointAddress;
    }
}