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
end
