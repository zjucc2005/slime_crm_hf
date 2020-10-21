module CallRecordsHelper

  def call_record_operator_options
    query = User.where(role: %w[pm pa], status: 'active')
    users = user_channel_filter(query).order(:created_at => :asc)
    users.map{|user| ["#{user.uid} #{user.name_cn}, #{user.email}", user.id] }
  end

  def call_record_status_badge(category)
    dict = { :pending => 'secondary', :missed => 'warning', :accepted => 'success', :accept_and_add_to_candidate => 'success', :declined => 'danger' }.stringify_keys
    content_tag :span, CallRecord::STATUS[category] || t(category), :class => "badge badge-#{dict[category] || 'dark' }"
  end

end