using spotify_clone_app.Models;

namespace spotify_clone_app.DTO
{
    public class PlaylistSongAddDto
    {
        public int PlaylistId { get; set; }
        public string DeezerId { get; set; }
        public string Title { get; set; }
        public string Artist { get; set; }
        public string Album { get; set; }
        public string StreamUrl { get; set; }
        public string ImageUrl { get; set; }
        public int Duration { get; set; } // Saniye cinsinden 

    }
}
