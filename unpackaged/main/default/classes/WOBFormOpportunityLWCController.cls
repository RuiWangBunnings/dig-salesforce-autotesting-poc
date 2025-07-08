public with sharing class WOBFormOpportunityLWCController {
    
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getRelatedOpportunities(String projectId, String accountRecordId){
        System.debug('projectId '+projectId+' accountRecordId '+accountRecordId);
        try {
            return [SELECT Id, Name, AccountId, Project__c, StageName, CloseDate, 
            TECH_WOB_Close_Date_Formatted__c,
            TECH_WOB_Delivery_Date_Formatted__c,
            Site_Address__c, RecordTypeId, Amount, Estimated_Amount__c, Quote_Required_By__c,
            Builder_Type__c, Dwelling_Type__c, Current_Supplier__c, Quality__c,
            Take_off_Required__c, Bathroom_Floors__c, Bathroom_Walls__c, Kitchen_Floors__c,
            Kitchen_Walls__c, Laundry_Floors__c, Laundry_Walls__c, Living_Areas__c,
            External__c, Other__c, Schedule_of_Finishes__c, Tile_Spec__c, Plans_Including_Elevations__c,
            Additional_Notes__c, Delivery_Date__c, Type, Tender_or_Live__c, Tender_Approver__c,
            New_or_Existing_Customer__c, 
            Roof_Trusses__c,
            Roof_Material__c,
            Roof_Material_Other__c,
            Truss_Centres__c,
            Truss_Centres_Other__c,
            Replace_Rafters__c,
            Wind_Category__c,
            Rafters_Type__c,
            Rafters_Other__c,
            Valley_Boards__c,
            Box_Gutter_Boards__c,
            Parapets_Roof_Trusses__c,
            Roof_Truss_Comments__c,
            Prefab_Prenail_Wall_Frames__c,
            Frame_Specifications__c,
            Stud_Centres__c,
            GF_LB__c,
            FF_LB__c,
            GF_NLB__c,
            FF_NLB__c,
            Wet_Areas_Type__c,
            Roof_Beams__c,
            Posts_CB__c,
            Parapets_Prefab_Wall__c,
            Wall_Frame_Comments__c,
            Floor_Trusses__c,
            Wet_Area_Setdown_PL__c,
            Floor_Truss_Type__c,
            Floor_Truss_Centres__c,
            Floor_Truss_Depth__c,
            Floor_Truss_Comments__c,
            Floor_System__c,
            Supplier__c,
            Supplier_Other__c,
            Floor_Joist_Centres__c,
            Standard_Flooring_Type__c,
            Wet_Area_Flooring_Type__c,
            Wet_Area_Flooring_Type_Other__c,
            Balcony_Flooring_Type__c,
            Balcony_Flooring_Type_Other__c,
            Floor_Beams__c,
            Balcony_Joists_Solids__c,
            Standard_Flooring__c,
            Wet_Area_Flooring_CB__c,
            Balcony_Flooring__c,
            Floor_System_Comments__c,
            Floor_Truss_System_Loose_Materials__c, //newly added
            Engineering_Drawings_Required__c,
            Floor_Truss_Depth_Other__c,
            Floor_Comparison_Approver__c,
            TECH_WOB_Has_Beaumont_Quote_Requirements__c,
            TECH_WOB_Has_FandT_Quote_Requirements__c,
            Architectural_Drawings__c,
            Lot_No__c, Street_No__c, 
            Street_Name__c, Street_Type__c, Suburb__c, Postcode__c, State__c
            ,(SELECT 
            Id, Name,Opportunity__c, RecordType.Name, Project__c, Wall_Centres__c,
            Wall_Centres_Other__c,
            Additional_Notes__c,
            Walls__c,
            Board_Location__c,
            Framework_Studwork__c,
            Internal_Ceilings__c,
            Internal_Ceilings_Detail__c,
            Internal_Ceilings_Detail_Other__c,
            Specify_Batten_Location__c,
            Wet_Areas_Baths_Ensuites__c,
            Full_Height_Tiling__c,
            Alfresco__c,
            Alfresco_Board_Type__c,
            Alfresco_Board_Type_Other__c,
            Alfresco_Battens__c,
            Alfresco_Battens_Other__c,
            Trim__c,
            Balcony_Same_as_Alfresco__c,
            Balcony__c,
            Balcony_Board_Type__c,
            Balcony_Board_Type_Other__c,
            Balcony_Battens__c,
            Balcony_Battens_Other__c,
            Balcony_Trim__c,
            External_Ceilings_Notes__c,
            Garage_Walls__c,
            Garage_Walls_Other__c,
            Garage_Ceilings__c,
            Garage_Ceiling_Spec__c,
            Garage_Ceiling_Type__c,
            Trim_by_Builder__c,
            Cornice__c,
            Cornice_Sub_Selection__c,
            Cornice_Sub_Selection_Other__c,
            Other_Cornice_Type_Location__c,
            Cornice_Additional_Notes__c,
            Wall_Wrap__c,
            External_Wall_Insulation__c,
            Ceiling_Insulation__c,
            Acoustic__c,
            House_Plans__c,
            Building_Type__c,
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
            Supply_Install__c,
            Wall_Wrap_CB__c,
            External_Wall_Insulation_CB__c,
            Ceiling_Insulation_CB__c,
            Additional_Acoustic_Thermal_Insulation__c,
            Internal_Walls__c,
            Under_Floor__c,     
            Energy_Report__c,
            Architectural_Drawings__c,
            Product_Type__c,
            Return_Format__c,
            Wind_Zone__c,
            Dulux_Acratex_Details__c,
            Cladding_Dulux_Exsulite__c,
            General_description_of_works__c,
            Required_Render_Finishes__c,
            Estimated_Start_Date__c,
            Levels__c,
            Plans_Attached__c,
            Required_Render_Finishes_Other__c,
            Required_Render_Finishes_M2__c,
            Returns_format_Other__c,
            Notes__c,
            Window_Covering_Type__c,
            Window_Installation_Method__c,
            Material_Selected__c,
            Slab_Edge_Height__c,
            Slab_Rebate_Size__c,
            Top_Hat__c,
            Panel_size__c,
            Product_Specifications__c,
            Project_Finish_Schedule__c,
            Product_Selection__c,
            Tactile_Ground_Surface_Indicators_TGSI__c,
            Stair_Nosing__c,
            Car_Park_Fixtures__c,
            Asset_Protection__c,
            Braille_Signs__c,
            Quote_All_Relevant_Products__c,
            Technical_Information__c,
            Type__c,
            Staircase_Rail__c,
            Mount_Type__c,
            Hardware_Colour_Balustrading__c,
            Surface_Installing_into__c,
            Finishes_Schedule__c,
            Skirting__c,
            Flooring_Type__c,
            Underlay_Required__c,
            Trims__c,
            Subfloor_Material__c,
            Install_Method__c,
            Flooring_Direction__c,
            Upgrade_1_Timber_mono_stringer__c,
            Upgrade_2_Steel_mono_stringer__c,
            Upgrade_3_Steel_plate_stringers__c,
            Quick_options__c,
            Tread__c,
            Tread_Addition__c,
            Riser__c,
            Stringer__c,
            Timber_stringer__c,
            Steel_stringer__c,
            Newel_Post__c,
            Handrail__c,
            Baluster__c,
            Type_of_Windows__c,
            Floor_Plans__c,
            Elevations__c,
            Window_Schedule__c,
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
            Product_Selection_Cladding__c,
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
            Architectural_Plans_Engineering_Drawings__c,
            Project_Link_Passwords__c,
            Building_Type_Storey__c,
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
            Window_Schedule_Plans__c,
            Engineering_Plan__c
            FROM Opportunity_Offers__r),
            Offer__c,
            House_Type__c,
            New_Build_Only__c,
            Installation_Required__c,
            Building_Type__c	

            FROM Opportunity 
            WHERE Project__c = :projectId
            AND AccountId = :accountRecordId];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static Boolean checkExistingOpportunityContactRole(String oppId, String contactId){
        try {
            Boolean existingOppAndContactRole = false;
            OpportunityContactRole oppContactRole = [SELECT Id, OpportunityId, ContactId FROM OpportunityContactRole 
                                                         WHERE OpportunityId = :oppId 
                                                         AND ContactId = :contactId];
            System.debug('Sid oppContactRole' + oppContactRole);
            if(oppContactRole.Id != null){
                existingOppAndContactRole = true;
            }else{
                existingOppAndContactRole = false;
            }

            return existingOppAndContactRole;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
 


    //to be commented out first for F&T Deployment to prod

    @AuraEnabled(cacheable=true)
    public static String getLoggedInUserProfileName(){
        try {
            String profileName;
            Profile profileRecord = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
            profileName = profileRecord.Name;    
            return profileName;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static WoB_Opp_Offer_Visibility_Mapping__mdt getOpportunityOfferVisibilityByProjectState(String projectState, String profileName){
        try {
            WoB_Opp_Offer_Visibility_Mapping__mdt oppOfferToDisplay = new WoB_Opp_Offer_Visibility_Mapping__mdt();
            List<WoB_Opp_Offer_Visibility_Mapping__mdt> oppOfferList = [SELECT Id, 
                                                                        Project_State__c, 
                                                                        Profiles__c, 
                                                                        Plasterboard_Insulation__c, 
                                                                        AAC_Nasahi_Panel__c,
                                                                        Balustrading__c, 
                                                                        Cladding__c, 
                                                                        Flooring__c, 
                                                                        Garage_Door__c, 
                                                                        HVAC__c, 
                                                                        Insulation_Only__c, 
                                                                        Render_Texture__c,
                                                                        Residential_Lifts__c, 
                                                                        Shower_Screens__c, 
                                                                        Staircases__c, 
                                                                        Tactile__c, 
                                                                        Wardrobe__c, 
                                                                        Waterproofing_Sealing__c, 
                                                                        Window_Furnishing__c, 
                                                                        Windows__c, 
                                                                        Joinery__c
                                                                        FROM WoB_Opp_Offer_Visibility_Mapping__mdt WHERE Project_State__c = :projectState]; 

            for(WoB_Opp_Offer_Visibility_Mapping__mdt oppOfferRec : oppOfferList){
                if(oppOfferRec.Profiles__c.split(',').contains(profileName)){
                    oppOfferToDisplay = oppOfferRec;
                    System.debug('sid true ' + oppOfferToDisplay);
                }
            }         
            return oppOfferToDisplay;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static WoB_S_I_Opp_Offer_Estimate_Amount__mdt getEstimatedAmountOppOffer(String oppOffer){
        try {
            WoB_S_I_Opp_Offer_Estimate_Amount__mdt oppOfferEstimatedAmount = [SELECT Id, Offer__c, Estimated_Amount__c FROM WoB_S_I_Opp_Offer_Estimate_Amount__mdt WHERE Offer__c = :oppOffer];
            System.debug('sid opp Offer Amount ' + oppOfferEstimatedAmount);
            return oppOfferEstimatedAmount;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Initialisation__mdt getTactileOppOfferUrl(){
        try {
            Initialisation__mdt getTactileOppOfferUrl = [SELECT WOB_Opp_Offer_Tactile__c FROM Initialisation__mdt WHERE MasterLabel = 'CCRM Initialisation'];
            System.debug('sid opp Offer Tactiler Url ' + getTactileOppOfferUrl);
            return getTactileOppOfferUrl;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Initialisation__mdt getGarageDoorOfferUrls(){
        try {
            Initialisation__mdt garageDoorUrls = [SELECT WoB_Garage_Door_Colour_Chart__c, WoB_Garage_Door_Roller_Door_Brochure__c,
                                                    WoB_Garage_Door_Sectional_Door_Brochure__c, WoB_Garage_Door_Tilt_Door_Brochure__c, 
                                                    WoB_Garage_Door_Timber_Brochure__c, WoB_Garage_Door_WA_Website__c, WoB_Garage_Door_Website__c
                                                    FROM Initialisation__mdt WHERE MasterLabel = 'CCRM Initialisation'];
            return garageDoorUrls;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}