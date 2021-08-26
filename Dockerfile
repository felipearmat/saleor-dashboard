FROM node:10 as builder

# Instalando dependencias e copiando arquivos
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

# ARGs e ENVs
ARG APP_MOUNT_URI
ARG API_URI
ARG STATIC_URL
ENV API_URI ${API_URI:-http://localhost:8000/graphql/}
ENV APP_MOUNT_URI ${APP_MOUNT_URI:-/dashboard/}
ENV STATIC_URL ${STATIC_URL:-/dashboard/}

# Build do App
RUN STATIC_URL=${STATIC_URL} API_URI=${API_URI} APP_MOUNT_URI=${APP_MOUNT_URI} npm run build

###############################################
# Nginx docker image with pagespeed module
FROM nginx:alpine as deploy

# Upgrade libs for security
RUN apk upgrade

# Cópia do build
WORKDIR /app
COPY --from=builder /app/build/ .

# Configuração do nginx
COPY ./nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./nginx/server.conf /etc/nginx/sites-available/default
RUN mkdir /etc/nginx/sites-enabled && ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled
RUN ln -sf /dev/stdout /var/log/nginx/access.log && ln -sf /dev/stderr /var/log/nginx/error.log

# Portas a serem expostas
EXPOSE 80
USER nginx
