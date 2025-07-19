using System.ComponentModel.DataAnnotations.Schema;

namespace spotify_clone_app.Models
{
    public class Playlist
    {
        public int Id { get; set; }
        public String Name { get; set; }//çalma listesi adı 
        public String? ImageUrl { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [Column("user_id")]  // ⬅️ Bu satır kritik
        public int UserId { get; set; }
        
        public User User { get; set; }
        public List<PlaylistSong> Songs { get; set; } = new List<PlaylistSong>();
    }
}
