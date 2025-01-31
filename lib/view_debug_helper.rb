# Add something like the following to get debug output in separate popup
#  <botton onclick="show_debug_popup(); return false;">Show debug popup</button>
#  <%= debug_popup %>
#
# Alternatively if you want to render the table inline you can use <%= debug_inline %>
module ViewDebugHelper

  def debug_popup
    @raw = false
    popup_create do |script|
      script << add("<html><head><title>Rails Debug Console_#{controller.class.name}</title>")
      script << add("<style type='text/css'> body {background-color:#FFFFFF;} </style>" )
      render_style(script)
      script << add('</head><body>' )
      render_table(script)
      script << add('</body></html>')
    end
  end

  def debug_inline
    @raw = true
    script = ""
    render_style(script)
    render_table(script)
    script
  end

  private

  def render_style(script)
    script << add("<style type='text/css'> table.debug {width:100%;border: 0;} table.debug th {text-align: left; background-color:#CCCCCC;font-weight: bold;} table.debug td {background-color:#EEEEEE; vertical-align: top;} table.debug td.key {color: blue;} table.debug td {color: green;}</style>" )
  end

  def render_table(script)
    script << add("<table class='debug'><colgroup id='key-column'/>" )
    popup_header(script, 'Rails Debug Console')

    if ! controller.params.nil?
      popup_header(script, 'Request Parameters:')
      controller.params.each do |key, value|
        popup_data(script, h(key), h(value.inspect).gsub(/,/, ',<br/>'))
      end
    end

    dump_vars(script, 'Session Variables:', controller.session.to_hash)
    dump_vars(script, 'Flash Variables:', controller.send(:flash))
    assigns = controller.instance_variables.reject { |v| controller.protected_instance_variables.include?(v) }
    if view_debug_display_assigns and not assigns.nil?
      popup_header(script, 'Assigned Template Variables:')
      assigns.each do |k|
        unless k =~ /^@?_/
          v = controller.instance_variable_get(k)
          popup_data(script, h(k), dump_obj(v))
        end
      end
    end

    script << add('</table>')
  end

  def dump_vars(script, header, vars)
    return if vars.nil?
    popup_header(script, header)
    vars.each do |k, v|
      unless k =~ /^@?_/
        popup_data(script, h(k), dump_obj(v))
      end
    end
  end

  def popup_header(script, heading)
    ; script << add( "<tr><th colspan='2'>#{heading}</th></tr>" );
  end

  def popup_data(script, key, value)
    ; script << add( "<tr><td class='key'>#{key}</td><td>#{value.gsub(/\r|\n/, '<br/>')}</td></tr>" );
  end

  def popup_create
    script = "<script language='javascript'>\n<!--\n"
    script << "function show_debug_popup() {\n"
    script << "_rails_console = window.open(\"\",\"#{controller.class.name.tr(':','')}\",\"width=680,height=600,resizable,scrollbars=yes\");\n"
    yield script
    script << "_rails_console.document.close();\n"
    script << "}\n"
    script << "-->\n</script>"
  end

  def add(msg)
    if @raw
      msg
    else
      "_rails_console.document.write(\"#{msg}\")\n"
    end
  end

  def dump_obj(object)
    return '...' if object.class.name == 'ActionController::Pagination::Paginator'
    begin
      Marshal::dump(object)
      "<pre>#{h(object.to_yaml).gsub("  ", "&nbsp; ").gsub("\n", "<br/>" )}</pre>"
    rescue Object => e
      # Object couldn't be dumped, perhaps because of singleton methods -- this is the fallback
      "<pre>#{h(object.inspect)}</pre>"
    end
  end
end

class ActionController::Base
  @@view_debug_display_assigns = true
  cattr_accessor :view_debug_display_assigns
  helper_method :view_debug_display_assigns
end

ActionView::Base.send :include, ViewDebugHelper
