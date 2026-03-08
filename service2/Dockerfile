# Use a lightweight Node.js image
FROM node:18-alpine

# Create app directory
WORKDIR /usr/src/app

# Copy package files and install dependencies
# (If you don't have a package.json yet, this might error, 
# so let's keep it simple for a 'Smoke Test' app)
COPY . .

# Expose the port your app runs on (usually 3000 for ECS)
EXPOSE 3000

# Command to run your app
CMD [ "node", "index.js" ]