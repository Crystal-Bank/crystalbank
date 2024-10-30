class ProjectionDB
  def initialize(@db : DB::Database); end

  def prepare
    skip = @db.query_one %(SELECT EXISTS (SELECT FROM pg_catalog.pg_namespace WHERE nspname = 'projections');), as: Bool
    return true if skip

    m = Array(String).new
    m << %( CREATE SCHEMA IF NOT EXISTS "projections"; )
    m << %( GRANT USAGE ON SCHEMA "projections" TO pg_monitor; )
    m << %( GRANT SELECT ON ALL TABLES IN SCHEMA "projections" TO pg_monitor; )
    m << %( GRANT SELECT ON ALL SEQUENCES IN SCHEMA "projections" TO pg_monitor; )
    m << %( ALTER DEFAULT PRIVILEGES IN SCHEMA "projections" GRANT SELECT ON TABLES TO pg_monitor; )
    m << %( ALTER DEFAULT PRIVILEGES IN SCHEMA "projections" GRANT SELECT ON SEQUENCES TO pg_monitor; )

    m.each { |s| @db.exec s }
  end
end

# Initializing projection database schema
ES::Config.projection_database = DB.open(CrystalBank::Env.projection_database_uri)
ProjectionDB.new(ES::Config.projection_database).prepare
