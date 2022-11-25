# frozen_string_literal: true

require "google/cloud/spanner"
require "google/cloud/spanner/admin/instance"

namespace :spanner do
  namespace :instance do
    task create: :environment do
      config = ActiveRecord::Base.configurations
                                 .find_db_config(Rails.env)
                                 .configuration_hash
      admin = Google::Cloud::Spanner::Admin::Instance
              .instance_admin(project_id: config[:project])

      project = config[:project]
      instance = config[:instance]

      project_path = admin.project_path(project:)
      instance_path = admin.instance_path(project:, instance:)
      instance_config = ENV.fetch("SPANNER_INSTANCE_CONFIG", "regional-asia-northeast1")
      instance_config_path = admin.instance_config_path(project:, instance_config:)

      instance = {
        name: instance_path,
        config: instance_config_path,
        display_name: config[:instance]
      }

      if ENV["SPANNER_INSTANCE_NODE_COUNT"]
        instance[:node] = ENV["SPANNER_INSTANCE_NODE_COUNT"].to_i
      else
        instance[:processing_units] = 100
      end

      admin.create_instance(
        parent: project_path,
        instance_id: config[:instance],
        instance:
      ).wait_until_done!
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
      end

      require "active_record/connection_adapters/abstract/schema_statements"
      ActiveRecord::ConnectionAdapters::SchemaStatements.prepend(SchemaStatementPatch)
    end
  end
end

Rake::Task["db:schema:dump"].enhance(["spanner:patch:schema_dump"])
Rake::Task["db:schema:load"].enhance(["spanner:patch:schema_load"])
