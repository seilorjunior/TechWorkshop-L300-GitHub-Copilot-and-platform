# Use the official .NET 8 SDK image for building
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj and restore dependencies
COPY src/*.csproj ./
RUN dotnet restore

# Copy the rest of the source code
COPY src/. ./
RUN dotnet publish -c Release -o /app/publish

# Use the official .NET 8 runtime image for running
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

# Copy the published app from the build stage
COPY --from=build /app/publish .

# Expose port 8080 (Azure App Service default)
EXPOSE 8080

# Set environment variables
ENV ASPNETCORE_URLS=http://+:8080

# Run the application
ENTRYPOINT ["dotnet", "ZavaStorefront.dll"]
