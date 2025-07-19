using StackExchange.Redis; // Redis'in IDatabase'ini kullanıyoruz
using System.Threading.Tasks;

// Burada EF Core’un IDatabase'ini **KULLANMAYACAĞIZ**,  
// Eğer varsa `using Microsoft.EntityFrameworkCore.Storage;` satırını kaldır.


public class RedisHelper
{
    private readonly ConnectionMultiplexer _redis;
    private readonly IDatabase _db;

    public RedisHelper(string connectionString)
    {
        _redis = ConnectionMultiplexer.Connect(connectionString);
        _db = _redis.GetDatabase();
    }

    public async Task SetLastPlayedSongAsync(string userId, string songId)
    {
        await _db.StringSetAsync($"lastPlayed:{userId}", songId);
    }

    public async Task<string?> GetLastPlayedSongAsync(string userId)
    {
        return await _db.StringGetAsync($"lastPlayed:{userId}");
    }
}
