using Microsoft.AspNetCore.Mvc;
using System.Text.Json;
using System.Threading.Tasks;
using spotify_clone_app.DTO;

[ApiController]
[Route("api/[controller]")]
public class RedisController : ControllerBase
{
    private readonly RedisHelper _redisHelper;

    public RedisController(RedisHelper redisHelper)
    {
        _redisHelper = redisHelper;
    }

    // Son çalınan şarkıyı kaydet
    [HttpPost("last-played")]
    public async Task<IActionResult> SaveLastPlayedSong([FromBody] LastPlayedSongDto dto)
    {
        try
        {
            var songData = JsonSerializer.Serialize(dto.SongData);
            await _redisHelper.SetLastPlayedSongAsync(dto.UserId, songData);
            return Ok(new { message = "Son çalınan şarkı kaydedildi" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    // Son çalınan şarkıyı getir
    [HttpGet("last-played/{userId}")]
    public async Task<IActionResult> GetLastPlayedSong(string userId)
    {
        try
        {
            var songData = await _redisHelper.GetLastPlayedSongAsync(userId);
            if (string.IsNullOrEmpty(songData))
            {
                return NotFound(new { message = "Son çalınan şarkı bulunamadı" });
            }

            var song = JsonSerializer.Deserialize<Dictionary<string, object>>(songData);
            return Ok(new { songData = song });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    // Çalma geçmişini kaydet
    [HttpPost("play-history")]
    public async Task<IActionResult> SavePlayHistory([FromBody] PlayHistoryDto dto)
    {
        try
        {
            var songsData = JsonSerializer.Serialize(dto.Songs);
            await _redisHelper.SetPlayHistoryAsync(dto.UserId, songsData);
            return Ok(new { message = "Çalma geçmişi kaydedildi" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    // Çalma geçmişini getir
    [HttpGet("play-history/{userId}")]
    public async Task<IActionResult> GetPlayHistory(string userId)
    {
        try
        {
            var songsData = await _redisHelper.GetPlayHistoryAsync(userId);
            if (string.IsNullOrEmpty(songsData))
            {
                return Ok(new { songs = new List<object>() });
            }

            var songs = JsonSerializer.Deserialize<List<Dictionary<string, object>>>(songsData);
            return Ok(new { songs = songs });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    // Şarkı pozisyonunu kaydet
    [HttpPost("song-position")]
    public async Task<IActionResult> SaveSongPosition([FromBody] SongPositionDto dto)
    {
        try
        {
            await _redisHelper.SetSongPositionAsync(dto.UserId, dto.SongId, dto.Position);
            return Ok(new { message = "Şarkı pozisyonu kaydedildi" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    // Şarkı pozisyonunu getir
    [HttpGet("song-position/{userId}/{songId}")]
    public async Task<IActionResult> GetSongPosition(string userId, string songId)
    {
        try
        {
            var position = await _redisHelper.GetSongPositionAsync(userId, songId);
            if (position == null)
            {
                return NotFound(new { message = "Şarkı pozisyonu bulunamadı" });
            }

            return Ok(new { position = position });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
} 