FROM #{dockerImage}# AS base
EXPOSE 80
EXPOSE 443
WORKDIR /app
COPY . ./

ENV ASPNETCORE_ENVIRONMENT=#{environment}#
#{ASPNETCORE_URLS}#
#{ASPNETCORE_HTTPS_PORT}#

ENTRYPOINT ["dotnet", "#{entrypoint}#"]
