# frozen_string_literal: true

class KpiSummariesController < ApplicationController
  load_and_authorize_resource
  before_action :authenticate_user!

  
end