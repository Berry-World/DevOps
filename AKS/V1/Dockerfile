FROM #{dockerImage}# AS base
EXPOSE 80
EXPOSE 443
WORKDIR /app
COPY . ./

ENV ASPNETCORE_FORWARDEDHEADERS_ENABLED=true
ENV ASPNETCORE_ENVIRONMENT=#{environment}#
#{ASPNETCORE_URLS}#
#{ASPNETCORE_HTTPS_PORT}#
#{BWG_SWAGGER_BASE_URL}#


#placeholder

RUN apt-get update
RUN apt-get install -y libgdiplus

ENTRYPOINT ["dotnet", "#{entrypoint}#"]
