using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using spotify_clone_app.Data;
using spotify_clone_app.DTO;
using spotify_clone_app.DTOs;
using spotify_clone_app.Models;
using System;
using System.Security.Claims;

[ApiController]
[Route("api/[controller]")]
public class PlaylistsController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public PlaylistsController(ApplicationDbContext context)
    {
        _context = context;
    }


    [HttpPost("upload")]
    [Consumes("multipart/form-data")]
    [Authorize]
    public async Task<IActionResult> CreatePlaylistWithImage([FromForm] CreatePlaylistDto request)
    {
        try
        {
            if (request.ImageFile == null || request.ImageFile.Length == 0)
                return BadRequest("Image is required.");

            var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "images", "playlists");
            if (!Directory.Exists(uploadsFolder))
                Directory.CreateDirectory(uploadsFolder);

            var fileName = Guid.NewGuid().ToString() + Path.GetExtension(request.ImageFile.FileName);
            var filePath = Path.Combine(uploadsFolder, fileName);

            // kullanıcı ıd sini token dan al.
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value!);

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await request.ImageFile.CopyToAsync(stream);
            }

            var playlist = new Playlist
            {
                Name = request.Name,
                ImageUrl = "/images/playlists/" + fileName,
                UserId = userId
            };

            _context.Playlists.Add(playlist);
            await _context.SaveChangesAsync();

            return Ok(playlist);
        }
        catch (Exception ex)
        {
            var fullMessage = ex.InnerException?.Message ?? ex.Message;
            Console.WriteLine("❌ Hata Detayı: " + fullMessage);
            return StatusCode(500, $"Internal server error: {fullMessage}");
        }

    }



    [HttpDelete("{id}")]
    [Authorize]
    public async Task<IActionResult> DeletePlaylist(int id)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value);

        var playlist = await _context.Playlists.FindAsync(id);

        if (playlist == null)
            return NotFound($"Playlist with ID {id} not found.");

        if (playlist.UserId != userId)
            return Forbid("You are not authorized to delete this playlist.");

        // Sunucuda kayıtlı resim varsa onu da silelim (opsiyonel)
        if (!string.IsNullOrWhiteSpace(playlist.ImageUrl))
        {
            var imagePath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", playlist.ImageUrl.TrimStart('/'));
            if (System.IO.File.Exists(imagePath))
                System.IO.File.Delete(imagePath);
        }

        _context.Playlists.Remove(playlist);
        await _context.SaveChangesAsync();

        return NoContent(); // 204: Başarılı ama içerik yok
    }

    [Authorize]
    [HttpGet]
    public async Task<IActionResult> GetAllPlaylists()
    {
        try
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdStr))
            {
                Console.WriteLine("❌ userId claim bulunamadı!");
                return Unauthorized("Kullanıcı doğrulanamadı.");
            }

            var userId = int.Parse(userIdStr);
            Console.WriteLine("✅ userId: " + userId);

            var playlists = await _context.Playlists
                .Where(p => p.UserId == userId)
                .OrderByDescending(p => p.CreatedAt)
                .ToListAsync();

            return Ok(playlists);
        }
        catch (Exception ex)
        {
            Console.WriteLine("🔥 HATA: " + ex.Message);
            Console.WriteLine("💥 Inner: " + ex.InnerException?.Message);
            return StatusCode(500, $"Internal server error: {ex.InnerException?.Message ?? ex.Message}");
        }
    }


    [HttpGet("{id}")]
    [Authorize]
    public async Task<IActionResult> GetPlaylistById(int id)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value);

        var playlist = await _context.Playlists
        .FirstOrDefaultAsync(p => p.Id == id && p.UserId == userId);

        if (playlist == null)
            return NotFound($"Playlist with ID {id} not found.");

        return Ok(playlist);
    }

    [HttpPut("{id}")]
    [Consumes("multipart/form-data")]
    [Authorize]
    public async Task<IActionResult> UpdatePlaylist(int id, [FromForm] UpdatePlaylistDto request)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value);

        var playlist = await _context.Playlists.FindAsync(id);
        if (playlist == null)
            return NotFound($"Playlist with ID {id} not found.");

        if (playlist.UserId != userId)
            return Forbid("You are not authorized to update this playlist.");

        playlist.Name = request.Name;

        if (request.ImageFile != null && request.ImageFile.Length > 0)
        {
            // Eski resmi sil
            if (!string.IsNullOrWhiteSpace(playlist.ImageUrl))
            {
                var oldImagePath = Path.Combine("wwwroot", playlist.ImageUrl.TrimStart('/'));
                if (System.IO.File.Exists(oldImagePath))
                    System.IO.File.Delete(oldImagePath);
            }

            // Yeni resmi kaydet
            var fileName = Guid.NewGuid().ToString() + Path.GetExtension(request.ImageFile.FileName);
            var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "images", "playlists");
            if (!Directory.Exists(uploadsFolder))
                Directory.CreateDirectory(uploadsFolder);

            var filePath = Path.Combine(uploadsFolder, fileName);
            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await request.ImageFile.CopyToAsync(stream);
            }

            playlist.ImageUrl = "/images/playlists/" + fileName;
        }

        await _context.SaveChangesAsync();

        return Ok(playlist);
    }

    [HttpPost("add-song")]
    public async Task<IActionResult> AddSongToPlaylist([FromBody] PlaylistSongAddDto dto)
    {
        var playlistSong = new PlaylistSong
        {
            PlaylistId = dto.PlaylistId,
            Title = dto.Title,
            Artist = dto.Artist,
            Album = dto.Album,
            DeezerId = dto.DeezerId,
            StreamUrl = dto.StreamUrl,
            ImageUrl = dto.ImageUrl,
            Duration = dto.Duration,
            AddedAt = DateTime.Now
        };

        _context.PlaylistSongs.Add(playlistSong);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Şarkı başarıyla eklendi", songId = playlistSong.Id });
    }

    [HttpGet("{playlistId}/songs")]
    public async Task<IActionResult> GetSongsForPlaylist(int playlistId)
    {
        var songs = await _context.PlaylistSongs
            .Where(ps => ps.PlaylistId == playlistId)
            .ToListAsync();

        return Ok(songs);
    }

    [HttpDelete("delete-song/{songId}")]
    public async Task<IActionResult> DeleteSongFromPlaylist(int songId)
    {
        try
        {
            var playlistSong = await _context.PlaylistSongs
                .FirstOrDefaultAsync(ps => ps.Id == songId);

            if (playlistSong == null)
            {
                return NotFound(new { message = "Şarkı bulunamadı" });
            }

            _context.PlaylistSongs.Remove(playlistSong);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Şarkı başarıyla silindi" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Şarkı silinirken bir hata oluştu", error = ex.Message });
        }
    }

    // 1. Favori ekle (Token'dan userId alınıyor)
    [HttpPost("favorite-add")]
    [Authorize]
    public async Task<IActionResult> AddFavorite([FromBody] FavoriteSongDto dto)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (userIdClaim == null) return Unauthorized();

        int userId = int.Parse(userIdClaim.Value);

        var exists = await _context.FavoriteSongs
            .AnyAsync(f => f.UserId == userId && f.StreamUrl == dto.StreamUrl);

        if (exists)
            return Conflict("Bu şarkı zaten favorilere eklenmiş.");

        var favorite = new FavoriteSong
        {
            UserId = userId,
            Title = dto.Title,
            Artist = dto.Artist,
            Album = dto.Album,
            DeezerId = dto.DeezerId,
            StreamUrl=dto.StreamUrl,
            ImageUrl = dto.ImageUrl,
            Duration = dto.Duration,
        };

        _context.FavoriteSongs.Add(favorite);
        await _context.SaveChangesAsync();

        return Ok("Şarkı favorilere eklendi.");
    }

    // 2. Favorilerden çıkar (Token'dan userId alınıyor)
    [HttpDelete("remove-favorite")]
    public async Task<IActionResult> RemoveFavorite(string streamUrl)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (userIdClaim == null) return Unauthorized();

        int userId = int.Parse(userIdClaim.Value);

        var song = await _context.FavoriteSongs
            .FirstOrDefaultAsync(f => f.UserId == userId && f.StreamUrl == streamUrl);

        if (song == null)
            return NotFound("Bu şarkı favorilerde bulunamadı.");

        _context.FavoriteSongs.Remove(song);
        await _context.SaveChangesAsync();

        return Ok("Şarkı favorilerden çıkarıldı.");
    }

    // 3. Kullanıcının tüm favori şarkılarını getir (Token'dan userId alınıyor)
    [HttpGet("get-favorite")]
    public async Task<IActionResult> GetUserFavorites()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (userIdClaim == null) return Unauthorized();

        int userId = int.Parse(userIdClaim.Value);

        var favorites = await _context.FavoriteSongs
            .Where(f => f.UserId == userId)
            .ToListAsync();

        return Ok(favorites);
    }
}
