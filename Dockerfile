FROM elixir

WORKDIR /app

RUN curl -sL https://deb.nodesource.com/setup_12.x  | bash -

RUN apt-get install -y nodejs

RUN mix local.hex --force && mix local.rebar --force

COPY package*.json ./

RUN npm install

COPY . .

RUN cd harbinger-server && mix deps.get && mix deps.compile

RUN npm run build

CMD cd harbinger-server && mix run --no-halt
