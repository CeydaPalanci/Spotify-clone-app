using System.Collections.Generic;

namespace spotify_clone_app.DTO
{
    public class LastPlayedSongDto
    {
        public string UserId { get; set; } = string.Empty;
        public string SongId { get; set; } = string.Empty;
        public Dictionary<string, object> SongData { get; set; } = new();
    }

    public class PlayHistoryDto
    {
        public string UserId { get; set; } = string.Empty;
        public List<Dictionary<string, object>> Songs { get; set; } = new();
    }

    public class SongPositionDto
    {
        public string UserId { get; set; } = string.Empty;
        public string SongId { get; set; } = string.Empty;
        public int Position { get; set; }
    }
} 