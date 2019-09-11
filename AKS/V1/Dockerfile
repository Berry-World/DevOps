FROM #{dockerImage}# AS base
EXPOSE 80
EXPOSE 443
WORKDIR /app
COPY . ./

ENV ASPNETCORE_ENVIRONMENT=#{environment}#
ENV ASPNETCORE_HTTPS_PORT=443

ENTRYPOINT ["dotnet", "#{entrypoint}#"]
