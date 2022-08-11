# encoding: utf-8
class CallRecord < ApplicationRecord

  # ENUM
  STATUS = {
    :pending  => '待定',
    :missed   => '未接',
    :accepted => '接受',
    :declined => '拒绝'
  }.stringify_keys

  # Associations
  belongs_to :creator, :class_name => 'User', :foreign_key => :created_by, :optional => true
  belongs_to :operator, :class_name => 'User', :foreign_key => :operator_id
  belongs_to :project, :class_name => 'Project', :optional => true
  belongs_to :candidate, :class_name => 'Candidate', :optional => true

  # Validations
  validates_presence_of :name
  validates_inclusion_of :status, :in => STATUS
  validates_numericality_of :number_of_calls, :greater_than_or_equal_to => 0

  before_validation :setup, :on => [:create, :update]

  def project_candidate
    if project_id && candidate_id
      ProjectCandidate.where(project_id: project_id, candidate_id: candidate_id).first
    else
      nil
    end
  end

  def can_add_to_candidate?
    candidate_id.blank?
  end

  def can_be_edited_by(user)
    user.admin? || self.operator_id == user.id
  end

  private
  def setup
    self.status          ||= 'pending'
    self.number_of_calls ||= 1
    self.operator_id     ||= self.created_by
    self.user_channel_id ||= self.creator.user_channel_id
  end

end
