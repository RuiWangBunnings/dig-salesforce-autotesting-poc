public class DriveAndCollectRequestBody 
{
	public Integer NumberOfFutureDays;
    public String LastUpdated;
    
    public static DriveAndCollectRequestBody parse(String json)
    {
        return (DriveAndCollectRequestBody) System.JSON.deserialize(json, DriveAndCollectRequestBody.class);
    }
}