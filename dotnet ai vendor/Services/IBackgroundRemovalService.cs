namespace VendorDashboard.Services
{
    public interface IBackgroundRemovalService
    {
        Task<string> RemoveBackgroundAndEnhanceAsync(string imagePath, string productName);
    }
}



