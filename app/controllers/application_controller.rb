class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :mailer_set_url_options

  def mailer_set_url_options
    ActionMailer::Base.default_url_options[:host] = request.host_with_port
  end

  def abstract_json_for_jqgrid records, columns = nil, options = {}

    if records.empty?
      return { :page => 1, :total => 1, :records => 0, :rows => nil }.to_json
    end

    columns ||= records.first.attributes.keys

    options[:id_column] ||= columns.first
    options[:page]      ||= records.current_page

    { :page => options[:page],
      :total => records.total_pages,
      :records => records.total_entries,
      :rows => records.map do |r| {
        :id => ( value = r
                 options[:id_column].each_line('.') do |n|
                   value = value.send(n.chomp('.'))
                 end
                 value),
        :cell => columns.map do |c|
                   value = r
                   c.each_line('.') do |n|
                     if(value != nil) then
                       m = n.chomp('.')
                       if !options[:params].nil? and !options[:params][m].nil?
                         value = value.send(m, options[:params][m])
                       else
                         value = value.send(m)
                       end
                     end
                   end
                   value
                 end}
      end
    }.to_json
    
  end

  def objects_order_by_from_params objects, params
    if params[:sord] == 'asc'
      objects.sort! { |a,b| a = ( v = a
                                  params[:sidx].each_line('.') do |n|
                                    if v.nil?
                                      v = ''
                                    else
                                      v = v.send(n.chomp('.'))
                                    end
                                  end
                                  v) <=> b = ( w = b
                                               params[:sidx].each_line('.') do |n|
                                                 if w.nil?
                                                   w = ''
                                                 else
                                                   w = w.send(n.chomp('.'))
                                                 end
                                               end
                                               w) }
    else if params[:sord] == 'desc'
      objects.sort! { |b,a| a = ( v = a
                                  params[:sidx].each_line('.') do |n|
                                    if v.nil?
                                      v = ''
                                    else
                                      v = v.send(n.chomp('.'))
                                    end
                                  end
                                  v) <=> b = ( w = b
                                               params[:sidx].each_line('.') do |n|
                                                 if w.nil?
                                                   w = ''
                                                 else
                                                   w = w.send(n.chomp('.'))
                                                 end
                                               end
                                               w) }
         end
    end
  end
  
  def set_current_user
    User.current = current_user.entity
  end

end
