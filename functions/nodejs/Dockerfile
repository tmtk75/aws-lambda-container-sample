FROM public.ecr.aws/lambda/nodejs:14
COPY app.js package.json  /var/task/
RUN npm install
CMD ["app.handler"]
