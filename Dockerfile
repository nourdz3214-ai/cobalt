FROM node:24-alpine AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

FROM base AS build
WORKDIR /app
COPY . /app

RUN corepack enable
RUN apk add --no-cache python3 alpine-sdk git

RUN pnpm install --prod --frozen-lockfile
RUN pnpm deploy --filter=@imput/cobalt-api --prod /prod/api

# تهيئة مستودع Git الوهمي كما هو
RUN cd /prod/api && \
    git init && \
    git config user.email "railway@deploy.com" && \
    git config user.name "Railway" && \
    git remote add origin https://github.com/imput/cobalt.git && \
    git add . && \
    git commit -m "init" || true

FROM base AS api
WORKDIR /app

RUN apk add --no-cache git

COPY --from=build --chown=node:node /prod/api /app

# إنشاء ملف cookies.txt تلقائياً داخل الحاوية من متغير البيئة في Railway لضمان الأمان وعدم رفعه لـ GitHub
RUN mkdir -p /app/cookies && \
    echo "$YT_DLP_COOKIES" > /app/cookies/cookies.txt

# إخبار النظام وأداة التحميل بمسار ملف الكوكيز صراحة
ENV YT_DLP_COOKIES="/app/cookies/cookies.txt"
ENV YTDL_OPTIONS_COOKIES="/app/cookies/cookies.txt"

USER node

EXPOSE 9000
CMD [ "node", "src/cobalt" ]
