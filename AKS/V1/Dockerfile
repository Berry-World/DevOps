FROM #{dockerImage}# AS base
EXPOSE 80
EXPOSE 443
WORKDIR /app
COPY . ./

ENV ASPNETCORE_ENVIRONMENT=#{environment}#
#ENV ASPNETCORE_HTTPS_PORT=443
#ENV ASPNETCORE_URLS="https://+443;http://+80"
ENV ASPNETCORE_URLS="http://+80"


ENTRYPOINT ["dotnet", "#{entrypoint}#"]
