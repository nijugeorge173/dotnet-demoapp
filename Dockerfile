# Learn about building .NET container images:
# https://github.com/dotnet/dotnet-docker/blob/main/samples/README.md
FROM  mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /source

# copy csproj and restore as distinct layers
COPY src/*.csproj .

RUN dotnet restore
ARG CACHEBUST=1
# copy and publish app and libraries
COPY src/. .
RUN dotnet publish -o /app

# final stage/image
FROM mcr.microsoft.com/dotnet/aspnet:6.0

ADD ./newrelic-dotnet-agent_amd64.tar.gz /app

# Enable the agent
ENV CORECLR_ENABLE_PROFILING=1 \
CORECLR_PROFILER={36032161-FFC0-4B61-B559-F6C5D41BAE5A} \
CORECLR_NEWRELIC_HOME=/app/newrelic-dotnet-agent \
CORECLR_PROFILER_PATH=/app/newrelic-dotnet-agent/libNewRelicProfiler.so \
NEW_RELIC_LICENSE_KEY=eu01xx2fca99a6cabde4af2e29a8919bFFFFNRAL \
NEW_RELIC_APP_NAME=DOTNET6.0

# Expose port 5000 from Kestrel webserver
EXPOSE 5000

# Tell Kestrel to listen on port 5000 and serve plain HTTP
ENV ASPNETCORE_URLS http://*:5000
ENV ASPNETCORE_ENVIRONMENT Production
# This is critical for the Azure AD signin flow to work in Kubernetes and App Service
ENV ASPNETCORE_FORWARDEDHEADERS_ENABLED=true

WORKDIR /app
COPY --from=build /app .
RUN ls -lrt /app
USER $APP_UID
ENTRYPOINT ["./dotnet-demoapp"]
