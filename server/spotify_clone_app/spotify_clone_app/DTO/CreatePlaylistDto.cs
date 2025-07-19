using System.ComponentModel.DataAnnotations;

namespace spotify_clone_app.DTO
{
    public class CreatePlaylistDto
    {
        [Required]
        public string Name { get; set; } = string.Empty;

        [Required]
        public IFormFile ImageFile { get; set; } = null!;
    }
}
