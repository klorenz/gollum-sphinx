require 'rack'
require 'rubygems'
require 'gollum/app'
require 'json'


# require 'gollum'

Gollum::Page.send :remove_const, :FORMAT_NAMES if defined? Gollum::Page::FORMAT_NAMES

# limit to one format
Gollum::Page::FORMAT_NAMES = { :rest => "reStructuredText" }


require 'github/markup'
require "github/markup/command_implementation"
# we need only our sphinx rest2html


#GitHub::Markup.markups = []
#GitHub::Markup.markups << CommandImplementation.new(/\.re?st/, 
    #"python2 -S @rest2html_path@/rest2html")

module GitHub
    module Markup
        markups.clear
        cmd = "python2 -S @rest2html_path@/rest2html"
        puts "command #{cmd}"
        markups << CommandImplementation.new(/re?st(\.txt)?/, cmd)
        puts "markups #{markups}"
    end
end

=begin
Valid formats are:
{ :markdown  => "Markdown",
  :textile   => "Textile",
  :rdoc      => "RDoc",
  :org       => "Org-mode",
  :creole    => "Creole",
  :rest      => "reStructuredText",
  :asciidoc  => "AsciiDoc",
  :mediawiki => "MediaWiki",
  :pod       => "Pod" }
=end

# Add in commit user/email
class Precious::App
    before do
        session['gollum.author'] = {
            :name       => request.env['AUTHENTICATE_CN'],
            :email      => request.env['AUTHENTICATE_MAIL'],
        }
    end

    
end

Gollum::Hook::register(:post_commit, :hook_id) do |committer, sha1|
    # build pages here
    puts "git --git-dir #{ENV['GOLLUM_REPO']} --work-tree #{ENV['GOLLUM_WORK_DIR']} checkout -f"
    `git --git-dir #{ENV['GOLLUM_REPO']} --work-tree #{ENV['GOLLUM_WORK_DIR']} checkout -f`
    puts "cd #{ENV['GOLLUM_SPHINX_SRC_DIR']} && make html MWINT_DIR=#{ENV['GOLLUM_SPHINX_BUILD_DIR']} BUILD_HTML_DIR=#{ENV['GOLLUM_SPHINX_OUT_DIR']} SPHINXOPTS=\"-D wiki_enabled=1\""
    `cd #{ENV['GOLLUM_SPHINX_SRC_DIR']} && make html MWINT_DIR=#{ENV['GOLLUM_SPHINX_BUILD_DIR']} BUILD_HTML_DIR=#{ENV['GOLLUM_SPHINX_OUT_DIR']} SPHINXOPTS="-D wiki_enabled=1"`
    puts "cd #{ENV['GOLLUM_MWINT_SITE_DIR']} && make deploy-html"
    `cd #{ENV['GOLLUM_MWINT_SITE_DIR']} && make deploy-html`
end

module Gollum
    def Page.format_to_ext(format)
        if format.to_s == "rest"
            return "rst"
        elsif format == :markdown
            return "md"
        else
            return format.to_s
        end
    end
end

map "/preview-files" do
  run Rack::File.new("@sphinx_build_dir@")
end

map "/javascript/editor/langs" do
  run Rack::File.new("@rest2html_path@/langs")
end

gollum_path = File.expand_path( ENV['WIKI_REPO'] ) # CHANGE THIS TO POINT TO YOUR OWN WIKI REPO
Precious::App.set(:gollum_path, gollum_path)
Precious::App.set(:default_markup, :restructuredtext) # set your favorite markup language
Precious::App.set(:wiki_options, {
#    :mathjax => true, 
    :live_preview => false, 
    :universal_toc => false, 
#    :css => true, 
#    :template_dir => "@templates@"
})


module Precious
    class LocalApp < Precious::App
        def is_editable(request)
            wiki_editors = ''
            if request.env.has_key? 'WIKI_EDITORS'
                wiki_editors = request.env['WIKI_EDITORS']
            end
            puts "wiki_editors #{wiki_editors}"
            editors = wiki_editors.split(/\s*;\s*|\s+/)
            may_edit = 0
            request.env['AUTHENTICATE_OU'].split(/\s*;\s*/).each do |ou|
                puts "ou #{ou} of #{editors}?"
                if editors.include? ou
                    may_edit = 1
                end
            end
            puts "may_edit #{may_edit}"
            may_edit
        end

        before %r{^/(edit|create)/} do
            halt 403 unless is_editable(request)
        end

        def get_commit_info(page, v)
            { :id => v.id,
              :id7 => v.id[0..6],
              :selected  => page.version.id == v.id,
              :author    => v.author.name.respond_to?(:force_encoding) ? v.author.name.force_encoding('UTF-8') : v.author.name,
              :message   => v.message.respond_to?(:force_encoding) ? v.message.force_encoding('UTF-8') : v.message,
              :date      => v.authored_date.strftime("%B %d, %Y"),
              :gravatar  => Digest::MD5.hexdigest(v.author.email.strip.downcase),
              :date_full => v.authored_date,
            }
        end

        def versions(page, page_versions)
            i = page_versions.size + 1
            page_versions.map do |v|
                info = get_commit_info(page, v)
                info[:num] = i
                info
            end
        end
    
        # return true if editable.  WIKI_EDIT_ALLOWED is set in apache config
        get '/json/editable' do
	  content_type :json
          { :editable => is_editable(request) }.to_json
        end
        
        
        get '/json/history/*' do
          @page = wiki_page(params[:splat].first).page
          @page_num = [params[:page].to_i, 1].max
          unless @page.nil?
              @versions = versions(@page, @page.versions(:page => @page_num))
          else
              @versions = {}
          end

          content_type :json
        
          @versions.to_json
        end

        get '/json/latest_changes/*' do
          @page = wiki_page(params[:splat].first).page
        
          unless @page.nil?
              @versions = versions(@page, @page.versions(:page => @page_num))
          else
              @versions = []
          end
        
          content_type :json
          @versions.to_json
        end

        get '/json/data/*/:version' do
          page = wiki_page(params[:splat].first, params[:version]).page

          v = page.version 
          content_type :json
          info = get_commit_info(page, page.version)
          info[:data] = page.raw_data

          info.to_json
        end

        def sanitize(input, encoding)
          input.gsub("\r", '').force_encoding(encoding)
        end

        if defined?(POSIX::Spawn)
          def execute(command, target)
            spawn = POSIX::Spawn::Child.new(*command, :input => target)
            if spawn.status.success?
              sanitize(spawn.out, target.encoding)
            else
              sanitize("<html><body><pre>#{spawn.err.strip}</pre></body></html>", target.encoding)

              #raise GitHub::MarkUp::CommandError.new(spawn.err.strip)
            end
          end
        else
          def execute(command, target)
            output = Open3.popen3(*command) do |stdin, stdout, stderr, wait_thr|
              stdin.puts target
              stdin.close
              if wait_thr.value.success?
                stdout.readlines
              else
                #raise GitHub::MarkUp::CommandError.new(stderr.readlines.join('').strip)
                "<htmL><body><pre>#{stderr.readlines.join('').strip}</pre></body></html>"
              end
            end
            sanitize(output.join(''), target.encoding)
          end
        end
  
        post '/preview' do
           # page path format content
           puts "my preview"
           wiki = wiki_new
           @name = params[:page] || "Preview"
           cmd = "python2 -S @rest2html_path@/rest2html"
           content = params[:content]
           rendered = execute(cmd, content)
           rendered = rendered.to_s.empty? ? content : rendered
           #python2 -S #{Shellwords.escape(File.dirname(__FILE__))}/commands/rest2html", /re?st(\.txt)?/
           content_type :html
           rendered
        end

        post '/edit/*' do
          path      = '/' + clean_url(sanitize_empty_params(params[:path])).to_s
          page_name = CGI.unescape(params[:page])
          wiki      = wiki_new
          page      = wiki.paged(page_name, path, exact = true)
          return if page.nil?
          committer = Gollum::Committer.new(wiki, commit_message)
          commit    = { :committer => committer }
    
          update_wiki_page(wiki, page, params[:content], commit, page.name, params[:format])
          update_wiki_page(wiki, page.header, params[:header], commit) if params[:header]
          update_wiki_page(wiki, page.footer, params[:footer], commit) if params[:footer]
          update_wiki_page(wiki, page.sidebar, params[:sidebar], commit) if params[:sidebar]
          committer.commit

          nextpage = params[:redirect]

          puts "redirect #{nextpage}"

          if params[:redirect]
              redirect params[:redirect]
          else
              redirect to("/#{page.escaped_url_path}") unless page.nil?
          end
        end

        post '/create' do
          name   = params[:page].to_url
          path   = sanitize_empty_params(params[:path]) || ''
          format = params[:format].intern
          wiki   = wiki_new
    
          path.gsub!(/^\//, '')

          begin
            wiki.write_page(name, format, params[:content], commit_message, path)
    
            page_dir = settings.wiki_options[:page_file_dir].to_s

            if params[:redirect]
              redirect params[:redirect]
            else
              redirect to("/#{clean_url(::File.join(page_dir, path, encodeURIComponent(name)))}")
            end
          rescue Gollum::DuplicatePageError => e
            @message = "Duplicate page: #{e.message}"
            mustache :error
          end
        end


    end
end


run Precious::LocalApp
