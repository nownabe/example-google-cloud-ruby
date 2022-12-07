# frozen_string_literal: true

require "google/cloud/spanner"
require "google/cloud/spanner/admin/instance"

class CloudSpannerAdmin
  DEFAULT_REGION = "asia-northeast1"

  def initialize(db_config)
    @project_id = db_config[:project]
    @instance_id = db_config[:instance]
    @emulator_host = db_config[:emulator_host]
  end

  def ensure_instance!
    return if instance_exists?

    instance_admin.create_instance(
      parent: project_path,
      instance_id: @instance_id,
      instance: {
        name: instance_path,
        config: instance_config_path,
        display_name: @instance_id,
        processing_units: 100
      }
    ).wait_until_done!
  end

  private

  def instance_admin
    @instance_admin ||= Google::Cloud::Spanner::Admin::Instance.instance_admin(
      project_id: @project_id,
      emulator_host: @emulator_host
    )
  end

  def instance_config_path
    @instance_config_path ||= instance_admin.instance_config_path(
      project: @project_id,
      instance_config: "regional-#{DEFAULT_REGION}"
    )
  end

  def instance_exists?
    instance_admin.list_instances(parent: project_path)
                  .any? { |instance| instance.name == instance_path }
  end

  def instance_path
    @instance_path ||= instance_admin.instance_path(
      project: @project_id,
      instance: @instance_id
    )
  end

  def project_path
    @project_path ||= instance_admin.project_path(project: @project_id)
  end
end
