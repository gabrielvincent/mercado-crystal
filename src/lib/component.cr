require "html"
require "json"
require "digest/sha1"

class Component
  alias AsyncComponent = Channel(Component)

  private struct RawHtml
    getter value : String

    def initialize(@value : String)
    end
  end

  class RenderContext
    getter io : IO
    getter async_children : Array(NamedTuple(id: String, channel: AsyncComponent))
    getter emitted_scopes : Set(String)
    getter css_buffer = [] of String

    def initialize(@io : IO, @async_children : Array(NamedTuple(id: String, channel: AsyncComponent)), @emitted_scopes : Set(String))
    end

    def <<(html : String) : self
      @io << html
      self
    end

    def <<(child : Component) : self
      child.render_into(self)
      self
    end

    def css(value : String) : Nil
      @css_buffer << value
    end

    def async(channel : AsyncComponent, fallback : Component, tag : String = "div") : Nil
      id = "component-async-#{channel.object_id}"

      @io << %(<#{tag} id="#{id}">)
      fallback.render_into(self)
      @io << %(</#{tag}>)

      @async_children << {id: id, channel: channel}
    end
  end

  private class AsyncPlaceholder < Component
    def initialize(@channel : AsyncComponent, @fallback : Component, @tag : String)
    end

    def render(io : RenderContext) : Nil
      io.async(@channel, fallback: @fallback, tag: @tag)
    end
  end

  def self.async(channel : AsyncComponent, fallback : Component, tag : String = "div") : Component
    AsyncPlaceholder.new(channel, fallback, tag)
  end

  macro props(*decls)
    {% for decl in decls %}
      getter {{decl.var}} : {{decl.type}}
    {% end %}

    def initialize(
      {% for decl in decls %}
        @{{decl.var}} : {{decl.type}}{% unless decl == decls.last %},{% end %}
      {% end %}
    )
    end
  end

  macro view(&block)
    def render(io : Component::RenderContext) : Nil
      __with_render_context(io) do
        {{block.body}}
      end
    end
  end

  def render(io : RenderContext) : Nil
  end

  def render(io : IO) : Nil
    async_children = [] of NamedTuple(id: String, channel: AsyncComponent)
    emitted_scopes = Set(String).new

    render_into_io(io, async_children, emitted_scopes)
    io.flush
    drain_async(io, async_children, emitted_scopes)
  end

  def to_s(io : IO) : Nil
    async_children = [] of NamedTuple(id: String, channel: AsyncComponent)
    emitted_scopes = Set(String).new

    render_into_io(io, async_children, emitted_scopes)
  end

  protected def render_into(parent : RenderContext) : Nil
    render_into_io(parent.io, parent.async_children, parent.emitted_scopes)
  end

  private def __with_render_context(ctx : RenderContext, &) : Nil
    previous = @__component_render_context
    @__component_render_context = ctx
    yield
  ensure
    @__component_render_context = previous
  end

  private def __render_tag(element_name : String, *children, **attrs) : Nil
    __component_render_context << "<" << element_name
    __render_attrs(attrs)

    if __void_tag?(element_name)
      __component_render_context << ">"
      return
    end

    __component_render_context << ">"
    children.each { |child| __render_node(child) }
    __component_render_context << "</" << element_name << ">"
  end

  private def __render_tag(element_name : String, *children, **attrs, &) : Nil
    __component_render_context << "<" << element_name
    __render_attrs(attrs)
    __component_render_context << ">"

    children.each { |child| __render_node(child) }
    yield
    __component_render_context << "</" << element_name << ">"
  end

  private def text(value) : Nil
    __component_render_context << HTML.escape(value.to_s)
  end

  private def raw(value : String) : Nil
    __render_node(RawHtml.new(value))
  end

  private def child(component : Component) : Nil
    __component_render_context << component
  end

  private def css(value : String) : Nil
    __component_render_context.css(value)
  end

  private def tag(element_name : String, *children, **attrs) : Nil
    __render_tag(element_name, *children, **attrs)
  end

  private def tag(element_name : String, *children, **attrs, &) : Nil
    __render_tag(element_name, *children, **attrs) { yield }
  end

  {% for name in %w(a abbr address area article aside audio b base bdi bdo blockquote body br button canvas caption cite code col colgroup data datalist dd del details dfn dialog div dl dt em embed fieldset figcaption figure footer form h1 h2 h3 h4 h5 h6 head header hgroup hr html i iframe img input ins kbd label legend li link main map mark menu meta meter nav noscript object ol optgroup option output p param picture pre progress q rp rt ruby s samp script section small source span strong style sub summary sup table tbody td template textarea tfoot th thead time title tr track u ul video wbr svg g defs symbol use path circle ellipse line polyline polygon rect text tspan) %}
    private def {{name.id}}(*children, **attrs) : Nil
      __render_tag({{name}}, *children, **attrs)
    end

    private def {{name.id}}(*children, **attrs, &) : Nil
      __render_tag({{name}}, *children, **attrs) { yield }
    end
  {% end %}

  private def __render_node(value : Nil) : Nil
  end

  private def __render_node(value : RawHtml) : Nil
    __component_render_context << value.value
  end

  private def __render_node(value : Component) : Nil
    __component_render_context << value
  end

  private def __render_node(value) : Nil
    __component_render_context << HTML.escape(value.to_s)
  end

  private def __render_attrs(attrs : NamedTuple) : Nil
    attrs.each do |name, value|
      __render_attr(name.to_s, value)
    end
  end

  private def __render_attr(name : String, value : Nil) : Nil
  end

  private def __render_attr(name : String, value : Bool) : Nil
    __component_render_context << " " << __html_attr_name(name) if value
  end

  private def __render_attr(name : String, value) : Nil
    attr_name = __html_attr_name(name)
    __component_render_context << " " << attr_name << %(=") << HTML.escape(value.to_s) << %(")
  end

  private def __html_attr_name(name : String) : String
    name.tr("_", "-")
  end

  private def __void_tag?(name : String) : Bool
    case name
    when "area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "param", "source", "track", "wbr"
      true
    else
      false
    end
  end

  private def __component_render_context : RenderContext
    @__component_render_context || raise "Component DSL helpers can only be used inside view blocks"
  end

  private def render_into_io(io : IO, async_children : Array(NamedTuple(id: String, channel: AsyncComponent)), emitted_scopes : Set(String)) : Nil
    rendered_css = nil

    body = String.build do |buf|
      ctx = RenderContext.new(buf, async_children, emitted_scopes)
      render(ctx)
      rendered_css = ctx.css_buffer.empty? ? nil : ctx.css_buffer.join("\n")
    end

    if css = rendered_css
      id = "c-#{Digest::SHA1.hexdigest(css)[0, 8]}"

      unless emitted_scopes.includes?(id)
        io << %(<style>[data-#{id}] { #{css} }</style>)
        emitted_scopes << id
      end

      io << %(<div data-#{id}>) << body << "</div>"
    else
      io << body
    end
  end

  private def drain_async(io : IO, async_children : Array(NamedTuple(id: String, channel: AsyncComponent)), emitted_scopes : Set(String)) : Nil
    async_children.each do |entry|
      component = entry[:channel].receive
      child_html = String.build { |b| component.to_s(b) }

      io << <<-HTML
        <script>
          document.getElementById(#{entry[:id].to_json}).outerHTML = #{child_html.to_json};
        </script>
      HTML

      io.flush
    end
  end
end
