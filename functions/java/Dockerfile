FROM public.ecr.aws/lambda/java:11
#COPY target/classes/*        ${LAMBDA_TASK_ROOT}
#RUN mkdir ${LAMBDA_TASK_ROOT}/example
COPY target/classes/example/  ${LAMBDA_TASK_ROOT}/example/
COPY target/myfunc-0.1.0.jar  ${LAMBDA_TASK_ROOT}/lib/
#RUN ls -la ${LAMBDA_TASK_ROOT}/*
CMD [ "example.Handler::handleRequest" ]
