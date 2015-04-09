// Generated by CoffeeScript 1.9.1

/*
This file targets _static/ folder


build with coffee ...
 */

(function() {
  $(function() {
    var base_url, displayPreview, edit_url, installEditor, installEditorJavascript, loadPreview, loading, loadingPreview, onEditorKeyDown, preview, previewDelay, ref1;
    edit_url = document.location.pathname.replace(/^\/intranet([^\/]*\/[^\/]*)\/(.*)\.html$/, "/wiki$1/edit/$2");
    base_url = edit_url.replace(/\/edit\/.*/, "");
    window.baseUrl = base_url;
    loadingPreview = null;
    preview = "#gollum-preview";
    loading = false;
    previewDelay = 500;
    installEditorJavascript = function(callback) {
      return $.getScript(base_url + "/javascript/mousetrap.min.js", function() {
        return $.getScript(base_url + "/javascript/gollum.js", function() {
          return $.getScript(base_url + "/javascript/gollum.dialog.js", function() {
            return $.getScript(base_url + "/javascript/gollum.placeholder.js", function() {
              return $.getScript(base_url + "/javascript/editor/gollum.editor.js", function(data) {
                return callback();
              });
            });
          });
        });
      });
    };
    installEditor = function(data) {
      var $data;
      $data = $(data);
      $('div.sphinxsidebar').remove();
      $('div.body').replaceWith($data.find('#gollum-editor'));
      $('#gollum-editor form').submit(function(event) {
        var $form;
        $form = $(this);
        $.post($form.attr('action'), $form.serialize(), function() {
          return document.location.href = document.location.pathname;
        });
        return event.preventDefault();
      });
      $('div.bodywrapper').append("<div id=\"gollum-preview\"></div>");
      $('div.bodywrapper').prepend("<ul class=\"actions\"><li class=\"minibutton\"><a href=\"" + document.location.pathname + "\">View Page</a></li>");
      $('head').append("<link rel=\"stylesheet\" type=\"text/css\" href=\"" + base_url + "/css/gollum.css\" media=\"all\">\n<link rel=\"stylesheet\" type=\"text/css\" href=\"" + base_url + "/css/editor.css\" media=\"all\">\n<link rel=\"stylesheet\" type=\"text/css\" href=\"" + base_url + "/css/dialog.css\" media=\"all\">\n<link rel=\"stylesheet\" type=\"text/css\" href=\"" + base_url + "/css/template.css\" media=\"all\">\n\n<style>\ndiv.documentwrapper {\n  position: absolute;\n  top: 3em;\n  bottom: 3em;\n  width: 95%;\n  left: 2.5%;\n}\n\ndiv.bodywrapper > div {\n  display: inline-block;\n  vertical-align: top;\n  width: 48%;\n}\n\ndiv.markdown-body div.document {\n  text-align: left;\n}\n\n/* copied from gollum's editor.css */\n#gollum-preview {\n    overflow: auto;\n}\n#gollum-editor {\n}\n.ff #gollum-preview, .ie #gollum-preview {\n    padding-bottom: 1em;\n}\n\n#gollum-preview {\n/*    border: 1px solid #E4E4E4;\n    background: none repeat scroll 0% 0% #F9F9F9;\n    border-radius: 1em;\n*/\n    margin: 1em 0px 5em;\n}\n#gollum-preview {\n    padding: 0em 1em 0.4em;\n}\n\n/* now own ones */\n\n\n#wiki-wrapper.edit {\n    width: 95%;\n    /* position: relative; */\n    max-width: none;\n}\n\n#wiki-wrapper.edit #wiki-content > div {\n    display: inline-block;\n    width: 47%;\n    max-width: 980px;\n    vertical-align: top;\n}\n\n#gollum-editor-format-selector {\n    display: none;\n}\n\n#gollum-editor-body + div {\n    font-size: 1em;\n}\n\n#gollum-editor #gollum-editor-preview {\n    display: none;\n}\n/* move button to right\n#gollum-editor input#gollum-editor-submit {\n    float: right;\n}\n*/\n\np.gollum-error {\n    font-family: monospace;\n    white-space: pre;\n    color: red;\n}\n\n#gollum-preview div.toctree {\n    border: 1px solid rgba(0,0,0,0.7);\n    background: rgba(0,0,0,0.3);\n}\n\n#gollum-preview div.toctree:before {\n  content: \"TOCTREE\";\n}\n</style>");
      $('#gollum-editor-body').keydown(onEditorKeyDown);
      return installEditorJavascript(function() {
        $(window).resize(function() {
          var height;
          height = $('div.documentwrapper').height();
          $('textarea').height(height * 2 / 3);
          return $('#gollum-preview').height($('#gollum-editor').height());
        });
        $(window).resize();
        $('textarea').scroll(function() {
          var previewScrollHeight, textareaScrollHeight;
          previewScrollHeight = $('#gollum-preview').get(0).scrollHeight;
          textareaScrollHeight = $('#gollum-editor-body').get(0).scrollHeight;
          return $('#gollum-preview').scrollTop($('textarea').scrollTop() * previewScrollHeight / textareaScrollHeight);
        });
        return loadPreview();
      });
    };
    loadPreview = function() {
      var body, page, path;
      page = $('#gollum-editor-page-title').val();
      path = $('#gollum-editor-page-path').val();
      body = $('#gollum-editor-body').val();
      return $.post(base_url + "/preview", {
        page: page,
        path: path,
        format: $('#wiki_format').val(),
        content: "page: " + page + "\npath: " + path + "\n\n" + body
      }, displayPreview);
    };
    displayPreview = function(data) {
      var $html, $preview, title;
      $preview = $(data);
      $html = $preview.find('#wiki-body');
      title = $preview.find('#head h1').eq(0).html();
      $preview.find('img').each(function() {
        var ref;
        ref = $(this).attr('src');
        return $(this).attr('src', base_url + "/preview-files/" + ref);
      });
      $(preview).html('').append($html);
      if (loadingPreview) {
        loadingPreview = null;
        loading = false;
        return loadPreview();
      } else {
        return loading = false;
      }
    };
    onEditorKeyDown = function() {
      if (!loading) {
        if (loadingPreview) {
          clearTimeout(loadingPreview);
          loadingPreview = void 0;
        }
        return loadingPreview = setTimeout(loadPreview, previewDelay);
      } else {
        return loadingPreview = true;
      }
    };
    $("ul.this-page-menu").append("<li><a href=\"?edit\" id=\"edit-this-page\">Edit</a></li>");
    if ((ref1 = document.location.search) != null ? ref1.match(/[?&]edit(&|$)/) : void 0) {
      return $.get(edit_url, installEditor);
    }
  });

}).call(this);
