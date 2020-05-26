#FROM nginx:latest

#ENV SSH_PASSWD "root:Docker!"

#RUN mkdir -p /usr/local/nginx  \
#    && chmod 755 /usr/local/nginx \
#     && echo "$SSH_PASSWD" | chpasswd \
#     && echo "cd /home" >> /etc/bash.bashrc

#COPY nginx.conf /usr/local/nginx/nginx.conf

FROM mcr.microsoft.com/dotnet/core/aspnet:3.1-buster-slim AS base
WORKDIR /app
ENV SSH_PASSWD "root:Docker!"

FROM mcr.microsoft.com/dotnet/core/sdk:3.1-buster AS build



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
EXPOSE  2222
ENTRYPOINT ["dotnet", "WebApplication2.dll"]