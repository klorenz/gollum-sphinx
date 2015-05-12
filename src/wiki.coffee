###
This file targets _static/ folder


build with coffee ...
###

$ ->
  edit_url = document.location.pathname.replace(
    /^\/intranet([^\/]*\/[^\/]*)\/(.*)\.html$/,
    "/wiki$1/(edit|create)/$2"
    )
  html_base_url = document.location.pathname.match /^\/intranet[^\/]*/
  base_url = edit_url.replace /\/(edit|create)\/.*/, ""
  [pagePath, pageName] = edit_url.match(/\/(edit|create)((?=\/).*)\/([^\/]*)$/)[2..]

  window.baseUrl = base_url

  loadingPreview = null
  preview = "#gollum-preview"
  loading = false
  previewDelay = 500

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

  installEditor = (data) ->
    $data = $ data
    # header = data.match(/<head>([\s\S]*)<\/head>/)[1]

    $('div.sphinxsidebar').remove()

    $('div.body')
      .replaceWith $data.find('#gollum-editor')

    $('#gollum-editor form').submit (event) ->
      $form = $(this)
      $.post $form.attr('action'), $form.serialize(), ->
        document.location.href = document.location.pathname
      event.preventDefault()

    $('div.bodywrapper')
        .append """<div id="gollum-preview"></div>"""

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

        div.bodywrapper > div {
          display: inline-block;
          vertical-align: top;
          width: 48%;
        }

        div.markdown-body div.document {
          text-align: left;
        }
        /* copied from gollum's editor.css */
        #gollum-preview {
            overflow: auto;
        }
        #gollum-editor {
        }
        .ff #gollum-preview, .ie #gollum-preview {
            padding-bottom: 1em;
        }

        #gollum-preview {
        /*    border: 1px solid #E4E4E4;
            background: none repeat scroll 0% 0% #F9F9F9;
            border-radius: 1em;
        */
            margin: 1em 0px 5em;
        }
        #gollum-preview {
            padding: 0em 1em 0.4em;
        }

        /* now own ones */


        #wiki-wrapper.edit {
            width: 95%;
            /* position: relative; */
            max-width: none;
        }

        #wiki-wrapper.edit #wiki-content > div {
            display: inline-block;
            width: 47%;
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
        $('textarea').height(height*2/3);
        $('#gollum-preview').height($('#gollum-editor').height());

      $(window).resize()

      $('textarea').scroll ->
        previewScrollHeight = $('#gollum-preview').get(0).scrollHeight;
        textareaScrollHeight = $('#gollum-editor-body').get(0).scrollHeight;
        $('#gollum-preview').scrollTop( $('textarea').scrollTop() * previewScrollHeight / textareaScrollHeight );

      loadPreview()


  loadPreview = ->
    page = $('#gollum-editor-page-title').val()
    path = $('#gollum-editor-page-path').val()
    body = $('#gollum-editor-body').val()

    $.post "#{base_url}/preview", {
      page   : page
      path   : path
      format : $('#wiki_format').val() or "rest"
      content : """
        page: #{page}
        path: #{path}

        #{body}
        """
      }, displayPreview

  displayPreview = (data) ->
    $preview = $ data
    $html = $preview.find('#wiki-body')
    title = $preview.find('#head h1').eq(0).html()

    $preview.find('img').each ->
      ref = $(this).attr 'src'
      $(this).attr('src', "#{base_url}/preview-files/#{ref}")

    $(preview)
      .html('')
      .append($html)

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
    """

  $.getScript "#{base_url}/javascript/gollum.dialog.js", ->

    $("ul.this-page-menu").append("""
      <li><a href="?edit" id="edit-this-page">Edit</a></li>
      <li><a href="#" id="create-new-page">Create Page</a></li>
      """)

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
        htmlEscape('/'+pagePath) + """</span>
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
