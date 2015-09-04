###
This file targets _static/ folder


build with coffee ...
###

$ ->
  edit_url = document.location.pathname.replace(
    /^\/intranet([^\/]*\/[^\/]*)\/(.*)\.html$/,
    "/wiki$1/edit/$2"
    )
  html_base_url = document.location.pathname.match /^\/intranet[^\/]*/
  base_url = edit_url.replace /\/edit\/.*/, ""
  [pagePath, pageName] = edit_url.match(/\/edit((?=\/).*)\/([^\/]*)$/)[1..]

  window.baseUrl = base_url

  loadingPreview = null
  preview = "#gollum-preview"
  loading = false
  previewDelay = 1000

  # from gollum.js
  htmlEscape = (str) ->
    String(str)
      .replace /&/g, '&amp;'
      .replace /"/g, '&quot;'
      .replace /'/g, '&#39;'
      .replace /</g, '&lt;'
      .replace />/g, '&gt;'

  # from gollum.js
  abspath = (path, name) ->
    if name[0] != '/'
      name = "/#{name}"
      if path
        name = "/#{path}#{name}"
    name_parts = name.split('/')
    newPath = name_parts.slice(0, -1).join('/')
    newName = name_parts.pop()
    return [newPath, newName]

  # $.ajaxSetup cache: true

  # make sure, that each script is loaded after the other
  installEditorJavascript = (callback) ->
    $.getScript "#{base_url}/javascript/mousetrap.min.js", ->
      $.getScript "#{base_url}/javascript/gollum.js", ->
          $.getScript "#{base_url}/javascript/gollum.placeholder.js", ->
            $.getScript "#{base_url}/javascript/editor/gollum.editor.js", (data) ->
              $.GollumEditor MarkupType: "rest"
              callback()

  # install the editor in current page
  installEditor = (data) ->
    $data = $ data
    # header = data.match(/<head>([\s\S]*)<\/head>/)[1]

    $('div.sphinxsidebar').remove()

#    $('div.body')
#      .replaceWith $data.find('#gollum-editor')

    $('div.body')
      .replaceWith '<div><div id="gollum-sphinx-wrapper"></div></div>'

    $('#gollum-sphinx-wrapper').append $data.find('#gollum-editor')

    $('#gollum-sphinx-wrapper')
        .append """<div id="gollum-preview" class="markdown-body"></div>"""

    $('div.bodywrapper')
        .prepend """<ul class="actions"><li class="minibutton"><a href="#{document.location.pathname}">View Page</a></li>"""

    $('head').append """
        <link rel="stylesheet" type="text/css" href="#{base_url}/css/gollum.css" media="all">
        <link rel="stylesheet" type="text/css" href="#{base_url}/css/editor.css" media="all">
        <link rel="stylesheet" type="text/css" href="#{base_url}/css/template.css" media="all">

        <style>
        div.documentwrapper {
          position: absolute;
          top: 3em;
          bottom: 3em;
          width: 95%;
          left: 2.5%;
        }

        div.markdown-body div.document {
          text-align: left;
          padding: 0em 1em 0.4em;
        }

        #gollum-sphinx-wrapper {
          text-align: center;
        }

        #gollum-sphinx-wrapper > div {
          text-align: left;
          display: inline-block;
          vertical-align: top;
          width: 45%;
        }

        /* copied from gollum's editor.css */
        #gollum-preview > .document {
            overflow: auto;
            background-color: white;
            border: 1px solid #DDD;
        }
        #gollum-editor {
        }
        .ff #gollum-preview, .ie #gollum-preview {
            padding-bottom: 1em;
        }

        #gollum-preview {
            margin: 1em 0px 5em;
            border: 1px solid #E4E4E4;
            background: #F9F9F9 none repeat scroll 0% 0%;
            margin: 1em 0px 5em;
            border-radius: 1em;
            /* padding: 0em 1em 0.4em; */
            padding: 1em;
        }

        /* now own ones */


        #wiki-wrapper.edit {
            width: 95%;
            /* position: relative; */
            max-width: none;
        }

        #wiki-wrapper.edit #wiki-content > div {
            display: inline-block;
            width: 45%;
            max-width: 980px;
            vertical-align: top;
        }

        #gollum-editor-format-selector {
            display: none;
        }

        #gollum-editor-body + div {
            font-size: 1em;
        }

        #gollum-editor #gollum-editor-preview {
            display: none;
        }
        /* move button to right
        #gollum-editor input#gollum-editor-submit {
            float: right;
        }
        */

        p.gollum-error {
            font-family: monospace;
            white-space: pre;
            color: red;
        }

        #gollum-preview div.toctree {
            border: 1px solid rgba(0,0,0,0.7);
            background: rgba(0,0,0,0.3);
        }

        #gollum-preview div.toctree:before {
          content: "TOCTREE";
        }
        </style>
      """

    $('#gollum-editor-body').keydown onEditorKeyDown


    installEditorJavascript ->
      $('div.related a[href=#]').each ->
        $(@).attr('href', document.location.pathname)

      $(window).resize ->
        height = $('div.documentwrapper').height()
        width = $('div.documentwrapper').width()
        marginLeft = Math.ceil(width/100)
        
        $('textarea').height(height*2/3);
        $('#gollum-preview').outerHeight($('#gollum-editor').outerHeight())
        $('#gollum-preview').css('borderTopLeftRadius', $('#gollum-editor').css('borderTopLeftRadius'))
        $('#gollum-preview').css('borderTopRightRadius', $('#gollum-editor').css('borderTopRightRadius'))
        $('#gollum-preview').css('borderBottomLeftRadius', $('#gollum-editor').css('borderBottomLeftRadius'))
        $('#gollum-preview').css('borderBottomRightRadius', $('#gollum-editor').css('borderBottomRightRadius'))
        $('#gollum-preview > .document').outerHeight($('#gollum-preview').height())

        $('#gollum-preview').css('marginLeft', marginLeft)

        halfWidth = Math.floor((width - marginLeft)/2) - 2

        $('#gollum-preview, #gollum-editor').outerWidth( halfWidth )
        console.log "width #{width}, halfWidth #{halfWidth}, marginLeft #{marginLeft}"

      $('textarea').scroll ->
        previewScrollHeight = $('#gollum-preview > .document')[0].scrollHeight;
        textareaScrollHeight = $('#gollum-editor-body')[0].scrollHeight;
        $('#gollum-preview > .document').scrollTop( $('textarea').scrollTop() * previewScrollHeight / textareaScrollHeight );

      $form = $('#gollum-editor form[name="gollum-editor"]')

      $form.append("""<input type="hidden" name="redirect" value="">""")

      updateRedirect = ->
        if $form.attr('action').match /create$/
          path = $form.find('input[name="path"]').val()
          name = $form.find('input[name="page"]').val()
  
          redirect = "#{html_base_url}#{path}/#{name}".replace(/\/\/+/, "/")
        else
          redirect = document.location.pathname

        $form.find('input[name="redirect"]').val(redirect)

      updateRedirect()

      $form.find('input[name="page"]').change updateRedirect

      $form.submit ->
        updateRedirect()
        true

      loadPreview()


  # load preview of given page, path, body in format
  # format defaults to restructured text
  # if nothing given data is taken from editor form
  loadPreview = (page, path, body, format)->
    page ?= $('#gollum-editor-page-title').val()
    path ?= $('#gollum-editor-page-path').val()
    body ?= $('#gollum-editor-body').val()
    format ?= $('#wiki_format').val() or "rest"

    loading = true

    $.post "#{base_url}/preview", {
      page   : page
      path   : path
      format : format
      content : """
        page: #{page}
        path: #{path}

        #{body}
        """
      }, displayPreview

  showPreview = (selector, data) ->
    $preview = $ data
    $html  = $preview

    #$html = $preview.find('#wiki-body')
    #title = $preview.find('#head h1').eq(0).html()

    $preview.find('img').each ->
      ref = $(this).attr 'src'
      $(this).attr('src', "#{base_url}/preview-files/#{ref}")

    $preview.find('object').each ->
      data = $(this).attr 'data'
      if data.match /^_images/
         $(this).attr('data', "#{base_url}/preview-files/#{data}")

    $(selector)
      .html('')
      .append($html)

  # diesplay a preview in
  displayPreview = (data) ->
    showPreview(preview, data)

    $(window).resize()

    if loadingPreview
      # in the meantime there was another preview requested
      loadingPreview = null
      loading = false
      loadPreview()
    else
      loading = false

  onEditorKeyDown = ->
    if not loading
      if loadingPreview
        clearTimeout loadingPreview
        loadingPreview = undefined

      # three seconds is max delay
      loadingPreview = setTimeout loadPreview, previewDelay
    else
      loadingPreview = true

  $('head').append """
    <link rel="stylesheet" type="text/css" href="#{base_url}/css/dialog.css" media="all">
    <style>
        #gollum-dialog-dialog-inner {
           max-width: 700px;
        }
    </style>
    """

  $('div.related a[href=#]').each ->
    $(this).attr('href', document.location)

  ###
  If editable is accessible, wiki is accessible, if it returns {editable: true}, wiki
  is also editable.
  ###
  $.getJSON "#{base_url}/json/editable", (data) ->

    # if editable, display Edit and Create Page links
    if data.editable
      $("ul.this-page-menu").append("""
        <li><a href="?edit" id="edit-this-page">Edit</a></li>
        <li><a href="#" id="create-new-page">Create Page</a></li>
        """)

      $.getScript "#{base_url}/javascript/gollum.dialog.js", ->

        if document.location.search?.match /[?&]edit(&|$)/
          $.get edit_url, installEditor

        if document.location.search?.match /[?&]create(&|$)/
          $('#create-new-page').click()

        # TODO
        # after save, get source of index and check if current page is in
        # toc or toc contains globs (which will become default)

        $('#create-new-page').click ->
          context_blurb = """
            Page will be created under <span class="path">"""+
            htmlEscape('/'+pagePath).replace('//+', '/') + """</span>
            unless an absolute path is given.
            """

          $.GollumDialog.init(
            title: "Create New Page",
            fields: [
              {
                id: 'name',
                name: "Page Name",
                type: "text",
                defaultValue: "",
                context: context_blurb
              }
            ]
            OK: (res) ->
              name = "New Page"
              if res.name
                name = res.name

              name_encoded = []
              name_parts = abspath(pagePath, name).join("/").split("/")
              for n in name_parts
                name_encoded.push encodeURIComponent n

              $.get "#{base_url}/"+name_encoded.join("/"), installEditor

          )

    renderCommitInfo = (entry) ->
      {id, id7, message, author} = entry
      """
        <div class="commit">
          <div class="commit-row-title">
            <a href="?rev=#{id}" class="id_short">#{id7}</a>
            <a href="?rev=#{id}" class="message">#{message}</a>
          </div>
          <div class="commit-row-info">
            <span class="author">#{author}</span>
          </div>
        </div>
      """

    # display history link
    $('ul.this-page-menu').append('''
      <li><a href="?history" id="this-page-history">History</a></li>
    ''')

    # handle history link
    last = (array) -> array[array.length-1]
    if document.location.search?.match /[?&]history(&|$)/
      $.getJSON "#{base_url}/json/history#{pagePath}/#{pageName}", (data) ->
        title = $('h1').eq(0).text().replace /.$/, ''   # remove paragraph endline char
        $('div.documentwrapper > div.bodywrapper > div.body').html("""
          <h1>History for <b>#{pageName}</b></h1>
          <div id="history"></div>
          """);

        changes_per_date = []

        for rec in data
          {date} = rec

          if changes_per_date.length
            last_entry = last(changes_per_date)
            if last_entry.date == date
              last_entry.entries.push rec
            else
              changes_per_date.push { date, entries: [ rec ]}
          else
            changes_per_date.push { date, entries: [ rec ]}

        for date_rec in changes_per_date
           {date, entries} = date_rec
           $('#history').append("<h2>#{date}</h2><ul></ul>")

           $ul = $('#history > ul').last()
           for entry in entries
             $ul.append "<li>" + renderCommitInfo(entry) + "</li>"


    if m = document.location.search?.match /\?rev=([^&]*)/
      version = m[1]
      $('div.documentwrapper > div.bodywrapper > div.body')
      .html """
          <div class="loading">
            <img src="#{DOCUMENTATION_OPTIONS.URL_ROOT}_static/mw-48x48-transparent-bg-white-loadinfo.net.gif">
            <div class="loading-text">loading ...</div>
          </div>
      """
      $.getJSON "#{base_url}/json/data#{pagePath}/#{pageName}/#{version}", (versionInfo) ->

        $.post "#{base_url}/preview", {
          page   : pageName
          path   : pagePath
          format : 'rest'
          content : """
            page: #{pageName}
            path: #{pagePath}

            #{versionInfo.data}
            """
          }, (data) ->
              {id, id7, message, author, date} = versionInfo
              orig = document.location.pathname

              $('div.documentwrapper > div.bodywrapper > div.body')
              .html('')
              .append("""
                <h1>#{pageName} as of #{date} (#{id7})</h1>

                <div id="wiki-page-info">
                  <table class="page-info"><tbody>
                    <tr> <th>Date</th> <td>#{date}</td> </tr>
                    <tr> <th>Author</th> <td>#{author}</td> </tr>
                    <tr> <th>ID</th> <td>#{id}</td> </tr>
                    <tr> <th>Message</th> <td>#{message}</td> </tr>
                  </tbody></table>
                </div>

                <div><a href="#{orig}">Back to current version</a></div>

                <div id="wiki-review"></div>
                """)

              showPreview '#wiki-review', data
