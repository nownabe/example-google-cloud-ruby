ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

Google::Cloud::Spanner::V1::Spanner::Client.configure do |c|
  timeout_sec = 10 * 365 * 24 * 60 * 60 # ten years

  c.rpcs.create_session.timeout = timeout_sec
  c.rpcs.batch_create_sessions.timeout = timeout_sec
  c.rpcs.get_session.timeout = timeout_sec
  c.rpcs.list_sessions.timeout = timeout_sec
  c.rpcs.delete_session.timeout = timeout_sec
  c.rpcs.execute_sql.timeout = timeout_sec
  c.rpcs.execute_streaming_sql.timeout = timeout_sec
  c.rpcs.read.timeout = timeout_sec
  c.rpcs.streaming_read.timeout = timeout_sec
  c.rpcs.begin_transaction.timeout = timeout_sec
  c.rpcs.commit.timeout = timeout_sec
  c.rpcs.rollback.timeout = timeout_sec
  c.rpcs.partition_query.timeout = timeout_sec
  c.rpcs.partition_read.timeout = timeout_sec
end

module FixturesPatch
  def insert_fixtures_set(fixture_set, tables_to_delete = [])
    fixture_inserts = build_fixture_statements(fixture_set)
    table_deletes = build_truncate_statements(tables_to_delete)
    statements = table_deletes + fixture_inserts

    with_multi_statements do
      disable_referential_integrity do
        transaction(requires_new: true) do
          execute_batch(statements, "Fixtures Load")
        end
      end
    end
  end
end

module FixturesPatchSpanner
  def build_truncate_statement(table_name)
    "DELETE FROM #{quote_table_name(table_name)} WHERE TRUE"
  end

  def build_fixture_statements(*args)
    super.flatten.compact
  end
end

ActiveRecord::ConnectionAdapters::DatabaseStatements.prepend(FixturesPatch)
ActiveRecord::ConnectionAdapters::Spanner::DatabaseStatements.prepend(FixturesPatchSpanner)

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end
