FROM mcr.microsoft.com/dotnet/core/aspnet:3.1-buster-slim AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/core/sdk:3.1-buster AS build

ENV SSH_PASSWD "root:Docker!"

RUN apt-get update \
	&& apt-get install -y apt-utils \
          unzip \
          openssh-server \
          vim \
          curl \
          wget \
          tcptraceroute \
	&& echo "$SSH_PASSWD" | chpasswd 
COPY sshd_config /etc/ssh/

COPY init_container.sh /usr/local/bin/
RUN chmod u+x /usr/local/bin/init_container.sh \
     && chmod 777 /opt  \
     && echo "$SSH_PASSWD" | chpasswd \
     && echo "cd /home" >> /etc/bash.bashrc

WORKDIR /src
COPY ["WebApplication2.csproj", ""]
RUN dotnet restore "./WebApplication2.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "WebApplication2.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "WebApplication2.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

ENV SSH_PORT 2222
EXPOSE 2222
ENTRYPOINT ["dotnet", "WebApplication2.dll"]