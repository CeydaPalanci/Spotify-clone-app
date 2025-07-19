using Microsoft.EntityFrameworkCore;
using spotify_clone_app.Models;


namespace spotify_clone_app.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options) { }
        public DbSet<Playlist> Playlists { get; set; }
        public DbSet<User> Users { get; set; }
        public DbSet<PlaylistSong> PlaylistSongs { get; set; }
        public DbSet<FavoriteSong> FavoriteSongs { get; set; }


    }
}
