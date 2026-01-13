# Build stage
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src

# Copy csproj and restore dependencies
COPY ["ZavaStorefront.csproj", "./"]
RUN dotnet restore "ZavaStorefront.csproj"

# Copy the rest of the source code
COPY . .

# Build the application
RUN dotnet build "ZavaStorefront.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "ZavaStorefront.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Final stage - runtime
FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS final
WORKDIR /app

# Set environment variables
ENV ASPNETCORE_URLS=http://+:80
ENV ASPNETCORE_ENVIRONMENT=Production

# Expose port 80
EXPOSE 80

# Copy published files from publish stage
COPY --from=publish /app/publish .

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:80/health || exit 1

# Set the entry point
ENTRYPOINT ["dotnet", "ZavaStorefront.dll"]
