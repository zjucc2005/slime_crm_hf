# encoding :utf-8
class ProjectRequirement < ApplicationRecord
  # ENUM
  STATUS = {
    :ongoing     => '进展中',
    :finished    => '已完成',
    # :unfinished  => '未完成',
    :cancelled   => '已取消'
  }.stringify_keys

  # Associations
  belongs_to :creator, :class_name => 'User', :foreign_key => :created_by
  belongs_to :operator, :class_name => 'User', :optional => true
  belongs_to :project, :class_name => 'Project'

  # Validations
  validates_inclusion_of :status, :in => STATUS.keys

  mount_uploader :file, FileUploader

  before_validation :setup, :on => :create

  after_save do
    project.last_update
  end

  def can_edit?
    status == 'ongoing'
  end

  def content_abstract
    max_length = 120
    first_line = content.split[0]
    first_line.length <= max_length ? first_line : "#{first_line[0,120]}..."
  end

  private
  def setup
    self.status ||= 'ongoing'
  end

end
