using System.ComponentModel.DataAnnotations.Schema;

namespace spotify_clone_app.Models
{
    public class PlaylistSong
    {
        public int Id { get; set; }
        
        [ForeignKey("Playlist")]
        public int PlaylistId { get; set; }
        
        public string Title { get; set; }
        public string Artist { get; set; }
        public string Album { get; set; }
        public string StreamUrl { get; set; }
        public string DeezerId { get; set; }
        public string ImageUrl { get; set; }
        public int Duration { get; set; }
        public DateTime AddedAt { get; set; }
        
        public Playlist Playlist { get; set; }
    }
}
