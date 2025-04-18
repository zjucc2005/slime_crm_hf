# encoding: utf-8
class ProjectInvoice < ApplicationRecord
  belongs_to :project, class_name: 'Project'
  mount_uploader :file, FileUploader

  
end