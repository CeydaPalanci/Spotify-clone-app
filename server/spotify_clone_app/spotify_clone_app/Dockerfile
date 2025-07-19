FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["spotify_clone_app.csproj", "./"]
RUN dotnet restore "spotify_clone_app.csproj"
COPY . .
RUN dotnet build "spotify_clone_app.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "spotify_clone_app.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "spotify_clone_app.dll"]