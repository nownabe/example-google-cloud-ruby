# frozen_string_literal: true

require "redis"
require "sinatra"


set :bind, "0.0.0.0"
set :port, ENV.fetch("PORT", "8080")


# Plain Redis (no AUTH, no TLS)

redis_plain = Redis.new(
  host: ENV.fetch("REDIS_PLAIN_HOST")
)


# Redis with AUTH

redis_auth = Redis.new(
  host: ENV.fetch("REDIS_AUTH_HOST"),
  password: ENV.fetch("REDIS_AUTH_AUTHSTRING"),
)


# Redis with TLS

redis_tls = Redis.new(
  host: ENV.fetch("REDIS_TLS_HOST"),
  port: 6378,
  ssl: true,
  ssl_params: {
    ca_file: "/redis_tls_cert/ca.pem"
  }
)


# Redis with AUTH and TLS

redis_authtls = Redis.new(
  host: ENV.fetch("REDIS_AUTHTLS_HOST"),
  port: 6378,
  password: ENV.fetch("REDIS_AUTHTLS_AUTHSTRING"),
  ssl: true,
  ssl_params: {
    ca_file: "/redis_authtls_cert/ca.pem"
  }
)


# Define endpoints to set and get for each redis instance

{
  plain: redis_plain,
  auth: redis_auth,
  tls: redis_tls,
  authtls: redis_authtls,
}.each do |prefix, redis|
  get "/#{prefix}/set/:key/:value" do
    result = redis.set(params[:key], params[:value])
    "[#{prefix}] #{result}\n"
  rescue => e
    "[#{prefix}] #{e.class}: #{e.message}\n"
  end

  get "/#{prefix}/get/:key" do
    result = redis.get(params[:key])
    "[#{prefix}] #{result}\n"
  rescue => e
    "[#{prefix}] #{e.class}: #{e.message}\n"
  end
end

get "/" do
  "ok\n"
end
