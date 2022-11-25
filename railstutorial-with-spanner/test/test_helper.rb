ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/reporters"
Minitest::Reporters.use!

module FixturePatch
  def insert_fixtures_set(fixture_set, tables_to_delete = [])
    fixture_inserts = build_fixture_statements(fixture_set)
    table_deletes = tables_to_delete.map { |table| "DELETE FROM #{quote_table_name(table)} WHERE true" }
    statements = [table_deletes + fixture_inserts].flatten.compact

    with_multi_statements do
      disable_referential_integrity do
        transaction(requires_new: true) do
          execute_batch(statements, "Fixtures Load")
        end
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::DatabaseStatements.prepend(FixturePatch)

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # self.use_transactional_tests = false

  # Add more helper methods to be used by all tests here...

  include ApplicationHelper
end
