###
*  RestructuredText Language Definition
*
*  A language definition for string manipulation operations, in this case
*  for the Markdown, uh, markup language. Uses regexes for various functions
*  by default. If regexes won't do and you need to do some serious
*  manipulation, you can declare a function in the object instead.
*
*  Code example:
*  'functionbar-id'  :   {
*                          exec: function(text, selectedText) {
*                                   functionStuffHere();
*                                },
*                          search: /somesearchregex/gi,
*                          replace: 'replace text for RegExp.replace',
*                          append: "just add this where the cursor is"
*                         }
*
###

(($) ->
    # console.log "start rest"

    makeHeadline = (text, headlineChar) ->
        lines = text.split "\n"
        repText = ''
        for line in lines
          if m = line.match /(.+)([\n]?)/
            repText += "#{line}\n"+headlineChar.repeat(line.length)+"\n\n"
        repText

    # console.log "makeHeadline defined"

    $.GollumDialog.createFieldMarkup = (fieldArray) ->
        fieldMarkup = '<fieldset>';
        for field in fieldArray
            # console.log "createFieldMarkup", field
            fieldMarkup += '<div class="field">'
            if typeof field is 'object'
                switch field.type
                    when 'text'
                        fieldMarkup += $.GollumDialog.createFieldText field
                    when 'file'
                        fieldMarkup += $.GollumDialog.createFieldFile field
                    when 'select'
                        fieldMarkup += $.GollumDialog.createFieldSelect field
            fieldMarkup += '</div>'
        fieldMarkup += '</fieldset>'
        # console.log "fieldMarkup: ", fieldMarkup
        fieldMarkup

    # console.log "createFieldMarkup overridden"

    escapeHtml = (s) ->
        s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")

    $.GollumDialog.createFieldSelect = (field) ->
        {name, id, defaultValue, type, context, options, size} = field

        # console.log "createFieldSelect"

        html = ''
        if name?
            html += '<label'
            if id?
                html += " for=\"gollum-dialog-dialog-generated-field-#{id}\""
            html += ">#{name}</label>"

        # console.log "html1", html

        html += '<select '

        if id?
            html += " name=\"#{id}\" id=\"gollum-dialog-dialog-generated-field-#{id}\" style=\"width: 100%\""

            if size?
                html += " size=\"#{size}\""
            if type == 'code'
                html += ' class="code"'

            html += ">"

        # console.log "html2", html

        for option in options
            # console.log "option", option

            if typeof option is 'string'
                option = {name: option, value: option}

            {name, value} = option
            if name?
               value ?= name

            if value?
               name ?= value

            name = escapeHtml(name)
            value = escapeHtml(value)
            
            html += "<option value=\"#{value}\">#{name}</option>"

        html += "</select>"

        if context?
            html += """<span class="context">#{context}</span>"""

        html

    # console.log "createFieldSelect created"
           
    thisProject = document.location.toString().match(/\/intranet[^\/]*\/([^\/]*)/)[1]

    # console.log "thisProject: ", thisProject

    options = []
    for entry in DOCUMENTATION_OPTIONS.FIND_ANYTHING_ENTRIES
        # console.log entry

        continue if entry.href.match /#/

        {info, name, path, project, href} = entry
        page = href.match(/\/([^\/]*)\.html$/)[1]

        # console.log "page: ", page

        if project == thisProject
           role = 'doc'
        else
           role = project

        # console.log "role: ", role

        options.push {
        #    name:  "#{info}: #{name} <#{path}#{page}>"
            name:  "#{info}: #{name}"
            value: ":#{role}:`#{path}#{page}`"
        }

    # console.log "options: ", options

    RestructuredText =
      'function-bold' :
          search: /([^\n]+)([\n\s]*)/g,
          replace: "**$1**$2"

      'function-italic' :
          search: /([^\n]+)([\n\s]*)/g,
          replace: "*$1*$2"

      'function-code'   :
          search: /([^\n]+)([\n\s]*)/g,
          replace: "``$1``$2"

      'function-hr'     :
          append: "\n----------\n"

      'function-ul'     :
          search: /(.+)([\n]?)/g,
          replace: "* $1$2"

      # based on rdoc.js
      'function-ol'   :
          exec: ( txt, selText, $field ) ->
            count = 1
            # split into lines
            repText = ''
            lines = selText.split("\n")
            hasContent = /[\w]+/
            for line in lines
              if line.match hasContent
                repText += (i + 1).toString() + '. ' + line + "\n"

            $.GollumEditor.replaceSelection( repText )

      'function-blockquote' :
            search: /(.+)([\n]?)/g,
            replace: "| $1$2"

      'function-h1'         :
            exec: ( txt, selText, $field ) ->
              $.GollumEditor.replaceSelection( makeHeadline(selText, "=") )

      'function-h2'         :
            exec: ( txt, selText, $field ) ->
              $.GollumEditor.replaceSelection( makeHeadline(selText, "-") )

      'function-h3'         :
            exec: ( txt, selText, $field ) ->
                $.GollumEditor.replaceSelection( makeHeadline(selText, '"') );

      'function-link'       :
            exec: ( txt, selText, $field ) ->
              results = null;
              
              $.GollumEditor.Dialog.init({
                title: 'Insert Link',
                fields: [
                  {
                    id:   'doc',
                    name: 'Select Page',
                    type: 'select',
                    options: options,
                    context: """
                    Default of displayed text is the title of the page.  You can specify a custom
                    anchor for the link in "Link Text"
                    """
                  }
                  {
                    id:   'text',
                    name: 'Link Text',
                    type: 'text',
                    defaultValue: selText
                  },
                  {
                    id:   'href',
                    name: 'URL',
                    type: 'text',
                    context: """
                    Specify a URL, if you want to specify a custom link rather than a page.  
                    """
                  },
                ],
                OK: ( res ) ->
                  rep = ''
                  console.log res

                  $('#gollum-dialog-dialog-body select').each ->
                      res[$(this).attr('name')] = $(this).val()

                  if res['href']
                      if  res['text'] && res['href']
                          rep = '`' + res['text'] + ' <' + res['href'] + '>`_'
                  else
                      rep = res['doc']
                      if text = res['text']
                          rep = rep.replace /:`(.*)`/, ":`#{text} <$1>`"
                      console.log rep

                  $.GollumEditor.replaceSelection( rep )
              })
    ###
    ,

      'function-image'      :   {
                                  exec: function( txt, selText, $field ) {
                                    var results = null;
                                    $.GollumEditor.Dialog.init({
                                      title: 'Insert Image',
                                      fields: [
                                        {
                                          id: 'url',
                                          name: 'Image URL',
                                          type: 'text'
                                        },
                                        {
                                          id: 'alt',
                                          name: 'Alt Text',
                                          type: 'text'
                                        }
                                      ],
                                      OK: function( res ) {
                                        var rep = '';
                                        if ( res['url'] && res['alt'] ) {
                                          rep = '![' + res['alt'] + ']' +
                                                '(' + res['url'] + ')';
                                        }
                                        $.GollumEditor.replaceSelection( rep );
                                      }
                                    });
                                  }
                                }
    ###

    RestHelp = [
        {
            menuName: 'Block Elements',
            content: [
                {
                  menuName: 'Paragraphs &amp; Breaks',
                  data: """<p>
                      To create a paragraph, simply create a block of text
                      that is not separated by one or more blank lines.
                      Blocks of text separated by one or more blank lines
                      will be parsed as paragraphs.
                    </p>
                    """
                },
                {
                  menuName: 'Headers',
                  data: """<p>
                      To create a header underline a single line with
                      characters like "=", "-", "\'", , '~', etc.  Same
                      character underlining mean same header level.
                    </p><p>
                      Example:
                      <pre>
                      This is a Heading
                      =================
                      </pre>
                    </p>
                    """
                },

                # {
                #   menuName: 'Blockquotes',
                #   data: """<p><!-- Markdown creates blockquotes
                #      email-style by prefixing each line with the
                #      <code>&gt;</code>. This looks best if you
                #      decide to hard-wrap text and prefix each line
                #      with a <code>&gt;</code> character, but
                #      Markdown supports just putting
                #      <code>&gt;</code> before your paragraph.
                #      --></p>
                #      """
                # },

                {
                  menuName: 'Lists',
                  data: """<p>
                      To create an ordered list, simply prefix each line
                      with a number followed by a "." (any number will do
                      &mdash; this is why the editor only uses one number.)
                      To create an unordered list, you can prefix each line
                      with <code>*</code>, <code>+</code> or
                      <code>-</code>.
                    </p><p>
                      List items can contain multiple paragraphs, however
                      each paragraph must be indented like first line in list
                      (after listitem character)
                    </p><p>
                      Example:
                      <pre>
                      - first item
                      - second item
                        with more lines

                        Another Paragraph

                      - third item
                      </pre>
                    </p>
                    """
                },
                {
                  menuName: 'Code Blocks',
                  data: """<p>
                      There are basically ways of
                      <a href="http://sphinx-doc.org/markup/code.html">creating
                      codeblocks</a>, explicit or implicit.
                    </p><p>
                      You can create an explicit codeblock with
                      <code>code-block</code> directive followed by type of code
                      for highlighting:
                      <pre>
                      .. code-block:: python

                          def foo():
                              return "bar"
                      </pre>
                    </p><p>
                      You can create an implicit codeblock using the current
                      highlighting by simply ending a line with a double colon
                      followed by an empty line.  Following code must be indented
                      like in following example:
                      <pre>
                      Here is some code::

                          def foo():
                              return "bar"
                      </pre>
                    </p><p>
                      You can change highlighting with highlight directive:
                      <pre>
                      .. highlight:: cpp
                      </pre><
                    </p>
                    """
                },
                {
                  menuName: 'Horizontal Rules',
                  data: """
                      Horizontal rules are created by placing four or more
                      punctuation characters like hyphens or dots in one line
                      and nothing else.
                      """
                }
            ]
        },

        {
          menuName: 'Span Elements',
          content: [
            {
              menuName: 'Links',
              data: '<p>Markdown has two types of links: <strong>inline</strong> and <strong>reference</strong>. For both types of links, the text you want to display to the user is placed in square brackets. For example, if you want your link to display the text &ldquo;GitHub&rdquo;, you write <code>[GitHub]</code>.</p><p>To create an inline link, create a set of parentheses immediately after the brackets and write your URL within the parentheses. (e.g., <code>[GitHub](http://github.com/)</code>). Relative paths are allowed in inline links.</p><p>To create a reference link, use two sets of square brackets. <code>[my internal link][internal-ref]</code> will link to the internal reference <code>internal-ref</code>.</p>'
            },

            {
              menuName: 'Emphasis',
              data: '<p>Asterisks (<code>*</code>) and underscores (<code>_</code>) are treated as emphasis and are wrapped with an <code>&lt;em&gt;</code> tag, which usually displays as italics in most browsers. Double asterisks (<code>**</code>) or double underscores (<code>__</code>) are treated as bold using the <code>&lt;strong&gt;</code> tag. To create italic or bold text, simply wrap your words in single/double asterisks/underscores. For example, <code>**My double emphasis text**</code> becomes <strong>My double emphasis text</strong>, and <code>*My single emphasis text*</code> becomes <em>My single emphasis text</em>.</p>'
            },

            {
              menuName: 'Code',
              data: '<p>To create inline spans of code, simply wrap the code in backticks (<code>`</code>). Markdown will turn <code>`myFunction`</code> into <code>myFunction</code>.</p>'
            },

            {
              menuName: 'Images',
              data: '<p>Markdown image syntax looks a lot like the syntax for links; it is essentially the same syntax preceded by an exclamation point (<code>!</code>). For example, if you want to link to an image at <code>http://github.com/unicorn.png</code> with the alternate text <code>My Unicorn</code>, you would write <code>![My Unicorn](http://github.com/unicorn.png)</code>.</p>'
            }
          ]
        },

        {
          menuName: 'Miscellaneous',
          content: [
            {
              menuName: 'Automatic Links',
              data: '<p>If you want to create a link that displays the actual URL, markdown allows you to quickly wrap the URL in <code>&lt;</code> and <code>&gt;</code> to do so. For example, the link <a href="javascript:void(0);">http://github.com/</a> is easily produced by writing <code>&lt;http://github.com/&gt;</code>.</p>'
            },

            {
              menuName: 'Escaping',
              data: '<p>If you want to use a special Markdown character in your document (such as displaying literal asterisks), you can escape the character with the backslash (<code>\\</code>). Markdown will ignore the character directly after a backslash.'
            }
          ]
        }
    ]

    # console.log "define language"


    $.GollumEditor.defineLanguage('rest', RestructuredText)
    $.GollumEditor.defineHelp('rest', RestHelp)

    # console.log "defined help"

)(jQuery)
