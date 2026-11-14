FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY src/Metra.Api/Metra.Api.csproj src/Metra.Api/
RUN dotnet restore src/Metra.Api/Metra.Api.csproj

COPY src/Metra.Api/ src/Metra.Api/
RUN dotnet publish src/Metra.Api/Metra.Api.csproj \
    --configuration Release \
    --no-restore \
    --output /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

COPY --from=build --chown=app:app /app/publish .
USER app

ENTRYPOINT ["dotnet", "Metra.Api.dll"]
