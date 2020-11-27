FROM elixir

WORKDIR /app

ENV MIX_HOME=/opt/mix
ENV MIX_ENV=prod

RUN curl -sL https://deb.nodesource.com/setup_12.x  | bash -

RUN apt-get install -y nodejs

RUN mix local.hex --force && mix local.rebar --force

COPY package*.json ./

RUN npm install

COPY . .

RUN cd harbinger-server && mix deps.get && mix deps.compile

RUN npm run build

CMD cd harbinger-server && mix run --no-halt
