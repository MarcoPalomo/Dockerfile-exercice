# Installation des requirements de base de l'app.
FROM python:alpine AS base
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

FROM node:12-alpine AS app-base
WORKDIR /app
COPY app/package.json app/yarn.lock ./
COPY app/spec ./spec
COPY app/src ./src

# Batterie de tests pour valider l'app
FROM app-base AS test
RUN apk add --no-cache python3 g++ make
RUN yarn install
RUN yarn test

# Copy des node_modules et generation du zip 
FROM app-base AS app-zip-creator
COPY app/package.json app/yarn.lock ./
COPY app/spec ./spec
COPY app/src ./src
RUN apk add zip && \
    zip -r /app.zip /app

# site wiki mkdocs pour environement DEV
FROM base AS dev
CMD ["mkdocs", "serve", "-a", "0.0.0.0:8000"]

# nous buildons le mkdocs site
FROM base AS build
COPY . .
RUN mkdocs build

# Extraction du contenu statique present dans le zip
FROM nginx:alpine
COPY --from=app-zip-creator /app.zip /usr/share/nginx/html/assets/app.zip
COPY --from=build /app/site /usr/share/nginx/html
