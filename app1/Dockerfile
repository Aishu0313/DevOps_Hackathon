FROM public.ecr.aws/lambda/nodejs:18

# Copy package.json first
COPY package*.json ./

# Install dependencies inside container
RUN npm install

# Copy application code
COPY . .

# Set Lambda handler file and function
# Example: index.js -> exports.handler
CMD ["index.handler"]
