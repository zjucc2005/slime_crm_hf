# frozen_literal: true

class UtilsController < ApplicationController
  before_action :authenticate_user!

  # GET /utils/loading_modal?op=newCallRecord&reference_id=1
  def loading_modal
    @op = params[:op] # operation
    case @op
    when 'newCallRecord' then set_new_call_record
    when 'editCallRecord' then set_edit_call_record
    else nil
    end
    respond_to { |f| f.js }
  end

  private

  def set_new_call_record
    @project = Project.find(params[:project_id])
    @call_record = @project.call_records.new
    @modal_title = t('action.new_model', model: t('activerecord.models.call_record'))
    @modal_body_form = 'call_records/loading_modal/new'
  end

  def set_edit_call_record
    @call_record = CallRecord.find(params[:id])
    @project = @call_record.project
    @modal_title = t('action.update_model', model: t('activerecord.models.call_record'))
    @modal_body_form = 'call_records/loading_modal/edit'
  end
end