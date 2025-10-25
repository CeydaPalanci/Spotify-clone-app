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

    public async Task SetPlayHistoryAsync(string userId, string songsData)
    {
        await _db.StringSetAsync($"playHistory:{userId}", songsData, TimeSpan.FromDays(30));
    }

    public async Task<string?> GetPlayHistoryAsync(string userId)
    {
        return await _db.StringGetAsync($"playHistory:{userId}");
    }

    public async Task SetSongPositionAsync(string userId, string songId, int position)
    {
        await _db.StringSetAsync($"songPosition:{userId}:{songId}", position.ToString(), TimeSpan.FromDays(7));
    }

    public async Task<int?> GetSongPositionAsync(string userId, string songId)
    {
        var position = await _db.StringGetAsync($"songPosition:{userId}:{songId}");
        if (int.TryParse(position, out int result))
        {
            return result;
        }
        return null;
    }
}
