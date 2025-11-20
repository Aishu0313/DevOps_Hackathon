# Dockerfile
FROM public.ecr.aws/lambda/nodejs:18

# Copy app files
COPY patient-service.js .  

# Set the Lambda function handler
CMD [ "patient-service.handler" ]
