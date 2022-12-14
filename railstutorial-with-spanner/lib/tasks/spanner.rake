# frozen_string_literal: true

require "cloud_spanner_admin"

namespace :spanner do
  namespace :instance do
    task create: :environment do
      config = ActiveRecord::Base.configurations
                                 .find_db_config(Rails.env)
                                 .configuration_hash
      admin = CloudSpannerAdmin.new(config)
      admin.ensure_instance!
    end
  end

  namespace :patch do
    task :schema_dump do
      module SchemaDumperPatch
        private

        def column_spec_for_primary_key(column)
          spec = super
          spec.except!(:limit) if default_primary_key?(column)
          spec
        end
      end

      require "active_record/schema_dumper"
      require "active_record/connection_adapters/abstract/schema_dumper"
      require "active_record/connection_adapters/spanner/schema_dumper"
      ActiveRecord::ConnectionAdapters::Spanner::SchemaDumper.prepend(SchemaDumperPatch)
    end

    task :schema_load do
      module SchemaStatementPatch
        def assume_migrated_upto_version(version)
          version = version.to_i
          sm_table = quote_table_name(schema_migration.table_name)

          migrated = migration_context.get_all_versions
          versions = migration_context.migrations.map(&:version)

          unless migrated.include?(version)
            execute "INSERT INTO #{sm_table} (version) VALUES (#{quote(version.to_s)})"
          end

          inserting = (versions - migrated).select { |v| v < version }
          if inserting.any?
            if (duplicate = inserting.detect { |v| inserting.count(v) > 1 })
              raise "Duplicate migration #{duplicate}. Please renumber your migrations to resolve the conflict."
            end
            execute insert_versions_sql(inserting)
          end
        end

        def insert_versions_sql(versions)
          sm_table = quote_table_name(schema_migration.table_name)

          if versions.is_a?(Array)
            sql = +"INSERT INTO #{sm_table} (version) VALUES\n"
            sql << versions.reverse.map { |v| "(#{quote(v.to_s)})" }.join(",\n")
            sql << ';'
            sql
          else
            "INSERT INTO #{sm_table} (version) VALUES (#{quote(versions.to_s)});"
          end
        end
      end

      require "active_record/connection_adapters/abstract/schema_statements"
      ActiveRecord::ConnectionAdapters::SchemaStatements.prepend(SchemaStatementPatch)
    end
  end
end

Rake::Task["db:create"].enhance(["spanner:instance:create"])

Rake::Task["db:schema:dump"].enhance(["spanner:patch:schema_dump"])
Rake::Task["db:schema:load"].enhance(["spanner:patch:schema_load"])
Rake::Task["db:test:load_schema"].enhance(["spanner:patch:schema_load"])
