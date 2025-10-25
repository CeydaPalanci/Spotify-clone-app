using System.ComponentModel.DataAnnotations;

namespace spotify_clone_app.Models
{
    public class User
    {
        public int Id { get; set; }
        public string Username { get; set; }
        public string Email { get; set; }
        public byte[] PasswordHash { get; set; }
        public byte[] PasswordSalt { get; set; }
        
        public virtual ICollection<FavoriteSong> FavoriteSongs { get; set; } = new List<FavoriteSong>();
        public virtual ICollection<Playlist> Playlists { get; set; } = new List<Playlist>();
    }
}
