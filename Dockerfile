FROM node:20-slim

RUN apt-get update && apt-get install -y sudo curl git && rm -rf /var/lib/apt/lists/*

COPY openclaw /home/openclaw/openclaw

WORKDIR /home/openclaw
ENV PATH="/home/openclaw/node_modules/.bin:/usr/local/bin:$PATH"

CMD ["node", "dist/index.js", "gateway", "--bind", "0.0.0.0", "--port", "29789"]
