# Use Node.js 16 as base image
FROM node:16

# Set working directory inside container
WORKDIR /app

# Copy all files into container
COPY . .

# Install dependencies
RUN npm install

# Expose port (if your app uses it)
EXPOSE 3000

# Start the app
CMD ["node", "app.js"]
