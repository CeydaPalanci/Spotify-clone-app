namespace spotify_clone_app.Controllers
{
    using Microsoft.AspNetCore.Mvc;
    using Microsoft.EntityFrameworkCore;
    using System.Security.Cryptography;
    using System.Text;
    using Microsoft.IdentityModel.Tokens;
    using System.IdentityModel.Tokens.Jwt;
    using System.Security.Claims;
    using spotify_clone_app.Models;
    using System;
    using spotify_clone_app.Data;
    using spotify_clone_app.DTO;

    namespace SpotifyAPI.Controllers
    {
        [Route("api/[controller]")]
        [ApiController]
        public class AuthController : ControllerBase  // Constructor
        {
            private readonly ApplicationDbContext _context;  //veritabanı işlemleri için
            private readonly IConfiguration _configuration;  //appsettings.json’daki JWT key’e ulaşmak için.

            public AuthController(ApplicationDbContext context, IConfiguration configuration)
            {
                _context = context;
                _configuration = configuration;
            }

            [HttpPost("register")]
            public async Task<IActionResult> Register(RegisterDto request)
            {
                if (await _context.Users.AnyAsync(u => u.Email == request.Email))
                    return BadRequest("Email zaten kullanılıyor.");

                CreatePasswordHash(request.Password, out byte[] passwordHash, out byte[] passwordSalt);

                var user = new User
                {
                    Username = request.Username,
                    Email = request.Email,
                    PasswordHash = passwordHash,
                    PasswordSalt = passwordSalt,
                    PlainPassword = request.Password // test amaçlı
                };

                _context.Users.Add(user);
                await _context.SaveChangesAsync();


                return Ok("Kayıt başarılı.");
            }

            [HttpPost("login")]
            public async Task<IActionResult> Login(LoginDto request)
            {

                try
                {
                    var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
                    if (user == null)
                        return BadRequest("Kullanıcı bulunamadı.");

                    if (!VerifyPasswordHash(request.Password, user.PasswordHash, user.PasswordSalt))
                        return BadRequest("Şifre yanlış.");

                    string token = CreateToken(user);

                    return Ok(new { token });
                }
                catch (Exception ex)
                {
                    // Hata detayını logla (console, dosya, vs.)
                    Console.WriteLine(ex.Message);
                    return StatusCode(500, "Sunucu hatası: " + ex.Message);
                }
            }

            // Şifre hash’leme
            private void CreatePasswordHash(string password, out byte[] hash, out byte[] salt)
            {
                using var hmac = new HMACSHA512();
                salt = hmac.Key;
                hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(password));
            }

            // Şifre doğrulama
            private bool VerifyPasswordHash(string password, byte[] hash, byte[] salt)
            {
                using var hmac = new HMACSHA512(salt);
                var computedHash = hmac.ComputeHash(Encoding.UTF8.GetBytes(password));
                return computedHash.SequenceEqual(hash);
            }

            // JWT oluşturma
            private string CreateToken(User user)
            {
                var claims = new[]
                {
                    new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                    new Claim(ClaimTypes.Name, user.Username),
                    new Claim(ClaimTypes.Email, user.Email)
                };

                var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(
                    _configuration.GetSection("Jwt:Key").Value!));

                var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha512);

                var token = new JwtSecurityToken(
                    claims: claims,
                    expires: DateTime.Now.AddHours(3),
                    signingCredentials: creds);

                return new JwtSecurityTokenHandler().WriteToken(token);
            }
        }
    }

}
