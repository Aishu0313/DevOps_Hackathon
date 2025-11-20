FROM public.ecr.aws/lambda/nodejs:18

# Copy package.json BEFORE installing dependencies
COPY package*.json ./

# Install NPM dependencies (express, aws-lambda-ric)
RUN npm install

# Copy your service code
COPY appointment-service.js .  

# Set handler
CMD [ "appointment-service.handler" ]
