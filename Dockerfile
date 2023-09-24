FROM node:18-alpine as build

WORKDIR /opt/app
COPY package.json package-lock.json tsconfig.json ./
COPY src/ src/
RUN npm install
RUN npm run build

FROM public.ecr.aws/lambda/nodejs:18

COPY --from=build /opt/app/dist ${LAMBDA_TASK_ROOT}/dist