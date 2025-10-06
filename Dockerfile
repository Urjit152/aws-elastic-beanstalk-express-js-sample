# --------------------------------------------------------
# Base image for building the Node.js app
# --------------------------------------------------------
FROM node:16

# Set working directory inside the container
WORKDIR /app

# Copy dependency definitions first (for caching)
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy remaining app files
COPY . .

# Expose the port the app listens on
EXPOSE 8080

# Start the app
CMD ["npm", "start"]
