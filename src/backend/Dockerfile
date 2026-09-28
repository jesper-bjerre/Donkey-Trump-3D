# Build from repository root: docker build -f src/backend/Dockerfile -t dt3d-highscores .
FROM mcr.microsoft.com/dotnet/sdk:10.0.401 AS build
WORKDIR /source
COPY global.json ./
COPY infra/backend-environments.json infra/
RUN test "$(dotnet --version)" = "10.0.401"
COPY src/backend/DonkeyTrump.Highscores.Api.csproj src/backend/
RUN dotnet restore src/backend/DonkeyTrump.Highscores.Api.csproj
COPY src/backend/ src/backend/
RUN dotnet publish src/backend/DonkeyTrump.Highscores.Api.csproj -c Release --no-restore -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0.12 AS runtime
WORKDIR /app
ENV ASPNETCORE_HTTP_PORTS=8080
EXPOSE 8080
COPY --from=build /app/publish ./
USER $APP_UID
ENTRYPOINT ["dotnet", "DonkeyTrump.Highscores.Api.dll"]
