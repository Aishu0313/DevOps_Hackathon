FROM public.ecr.aws/lambda/nodejs:18

# Copy package.json first
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy app code
COPY patient-service.js .  

# Set Lambda handler
CMD [ "patient-service.handler" ]
