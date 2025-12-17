# Dùng nginx alpine để test
FROM nginx:alpine

# Copy file HTML đơn giản để test
RUN mkdir -p /usr/share/nginx/html
COPY index.html /usr/share/nginx/html/index.html

# Expose port
EXPOSE 80

# CMD mặc định nginx
CMD ["nginx", "-g", "daemon off;"]
