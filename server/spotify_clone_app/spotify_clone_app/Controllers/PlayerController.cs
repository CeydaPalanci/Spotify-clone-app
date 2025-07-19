using Microsoft.AspNetCore.Mvc;

namespace spotify_clone_app.Controllers
{
    public class PlayerController : ControllerBase
    {
        private readonly RedisHelper _redisHelper;

        public PlayerController()
        {
            // Docker’da Redis localhost'ta 6379 portunda çalışıyor
            _redisHelper = new RedisHelper("localhost:6379");
        }

        [HttpPost("play/{userId}/{songId}")]
        public async Task<IActionResult> PlaySong(string userId, string songId)
        {
            await _redisHelper.SetLastPlayedSongAsync(userId, songId);
            return Ok($"User {userId} is now playing song {songId}");
        }

        [HttpGet("last-played/{userId}")]
        public async Task<IActionResult> GetLastPlayed(string userId)
        {
            var songId = await _redisHelper.GetLastPlayedSongAsync(userId);
            if (songId == null)
                return NotFound("No last played song found.");
            return Ok(new { songId });
        }
    }
}
