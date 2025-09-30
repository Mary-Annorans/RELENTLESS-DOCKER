# Use the official Nginx image as base with latest stable version
FROM nginx:1.25-alpine

# Set maintainer information
LABEL maintainer="Mary-Ann Oranekwulu <greenmaryann57@gmail.com>"
LABEL description="Static Portfolio Website for Mary-Ann Oranekwulu - Cloud & DevOps Engineer"

# Copy the website files to the Nginx html directory
# We're copying from clark-master/clark-master because that's where the actual website files are
COPY clark-master/clark-master/ /usr/share/nginx/html/

# Copy any additional files from the root of clark-master
COPY clark-master/README.md /usr/share/nginx/html/
COPY clark-master/cert-details.json /usr/share/nginx/html/

# Create a custom Nginx configuration for better performance
RUN echo 'server { \
    listen 80; \
    server_name localhost; \
    root /usr/share/nginx/html; \
    index index.html index.htm; \
    \
    # Enable gzip compression \
    gzip on; \
    gzip_vary on; \
    gzip_min_length 1024; \
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json; \
    \
    # Cache static assets \
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ { \
        expires 1y; \
        add_header Cache-Control "public, immutable"; \
    } \
    \
    # Handle HTML files \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
    \
    # Security headers \
    add_header X-Frame-Options "SAMEORIGIN" always; \
    add_header X-Content-Type-Options "nosniff" always; \
    add_header X-XSS-Protection "1; mode=block" always; \
    \
    # Hide Nginx version \
    server_tokens off; \
}' > /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
