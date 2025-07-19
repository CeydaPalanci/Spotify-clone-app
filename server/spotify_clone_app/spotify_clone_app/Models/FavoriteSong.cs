using System.ComponentModel.DataAnnotations.Schema;

namespace spotify_clone_app.Models
{
    public class FavoriteSong
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string Title { get; set; }
        public string Artist { get; set; }
        public string Album { get; set; }
        public string StreamUrl { get; set; }
        public string DeezerId { get; set;}
        public string ImageUrl { get; set; }
        public int Duration { get; set; }
        public DateTime FavoriteAddedAt { get; set; }

        // Kullanıcı ile ilişki (NAVIGATION PROPERTY)
        [ForeignKey("UserId")]
        public virtual User User { get; set; }
    }
}
