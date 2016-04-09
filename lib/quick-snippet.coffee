{CompositeDisposable} = require 'atom'

module.exports = QuickSnippet =
  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-text-editor',
      'quick-snippet:snippet': => @fromSelection()
      'quick-snippet:reload-snippets': => @reload()

  deactivate: ->
    @subscriptions.dispose()
    @subscriptions = null

  fromSelection: ->
    editor = atom.workspace.getActiveTextEditor()
    return unless editor?
    cursors = editor.getCursorsOrderedByBufferPosition()
    if cursors.length is 1
      if cursors[0].selection.getText() isnt ''
        new NamedView(editor.getRootScopeDescriptor().getScopeChain(), cursors[0].selection.getText(), @addSelection)
    else
      scope = editor.getRootScopeDescriptor().getScopeChain()
      selection = @getLargestSelection(editor, cursors)
      body = @getBodyFromCursors(editor, selection, cursors)
      prefix = @getPrefixFromCursors(cursors)
      console.log prefix
      console.log body
      return
      if prefix?
        @addSelection {scope, prefix, body}
      else
        new NamedView(scope, body, @addSelection)

  addSelection: ({scope, prefix, body}) ->

  getLargestSelection: (editor, cursors) ->
    editor.getTextInBufferRange([cursors[0].getBufferPosition(), cursors[cursors.length - 1].getBufferPosition()])

  getBodyFromCursors: (editor, selection, cursors) ->
    start = cursors[0].getBufferPosition()
    selection = selection.replace /\$/g, '\\$'
    lines = selection.split '\n'
    offsets = [[0, lines.shift().length + 1]]
    for line, index in lines
      begin = offsets[index][1]
      offsets.push [begin, begin + line.length + 1]
    body = ''
    wordsToReplace = {}
    defaultAt = {}
    currentIndex = 1
    offsetInSelection = 0
    currentOffset = 0
    for cursor, index in cursors.slice(1, cursors.length - 1)
      offsetInSelection = @getOffsetInSelection(start, offsets, cursor)
      if cursor.selection.isEmpty()
        if cursor.isInsideWord() and not cursor.isAtEndOfLine() # FIXME See atom/atom#5766
          currentWord = editor.getTextInBufferRange(cursor.getCurrentWordBufferRange())
          tabStop = "$#{currentIndex}"
          wordsToReplace[currentWord] = tabStop
        else
          tabStop = "$#{currentIndex}"
          body += selection.substring(currentOffset, offsetInSelection) + tabStop
          currentOffset = offsetInSelection
      else
        if atom.config.get('quick-snippet.reversePrefix') and cursor.selection.isReversed()
          continue
        currentSelection = cursor.selection.getText()
        tabStop = "${#{currentIndex}:\"\"}"
        defaultAt[currentIndex] = currentSelection
        wordsToReplace[currentSelection] = tabStop
      currentIndex = currentIndex + 1
    body += selection.substring(currentOffset)
    replace = (s, a, b) ->
      s.split(a).join(b)
    replaceWithoutEscaped = (s, a, b) ->
      s.split('\\' + a).map((e) -> e.split(a).join(b)).join('\\' + a)
    (body = replace(body, word, wordsToReplace[word])) for word in Object.keys(wordsToReplace)
    (body = replaceWithoutEscaped(body, "${#{index}:\"\"}", "${#{index}:\"#{defaultAt[index]}\"}")) for index in Object.keys(defaultAt)
    body

  getOffsetInSelection: (start, offsets, cursor) ->
    cursorPosition = null
    if cursor.selection.isEmpty()
      cursorPosition = cursor.getBufferPosition()
    else if cursor.selection.isReversed()
      cursorPosition = cursor.selection.getBufferRange().end
    else
      cursorPosition = cursor.selection.getBufferRange().start
    offset = offsets[cursorPosition.row - start.row]
    return offset[0] + cursorPosition.column

  getPrefixFromCursors: (cursors) ->
    return null unless atom.config.get('quick-snippet.reversePrefix')
    prefix = ''
    for cursor in cursors.slice(1, cursors.length - 1)
      continue if cursor.selection.isEmpty()
      if cursor.selection.isReversed()
        prefix += cursor.selection.getText()
    if prefix is ''
      return null
    return prefix
