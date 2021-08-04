class DummyJwtMiddleware
  def initialize(app, bearer:)
    @app = app
    @bearer = bearer
  end

  def call(env)
    env['HTTP_AUTHORIZATION']="Bearer #{@bearer}"
    @app.call(env)
  end
end
