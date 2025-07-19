using System.ComponentModel.DataAnnotations;

namespace spotify_clone_app.DTOs
{
    public class UpdatePlaylistDto
    {
        [Required]
        public string Name { get; set; }

        public IFormFile? ImageFile { get; set; } // yeni resim opsiyonel
    }
}

