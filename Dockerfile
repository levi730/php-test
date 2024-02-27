#/usr/share/nginx/html

FROM nginx

# Copy in custom code from the host machine.
WORKDIR /app
COPY . ./
