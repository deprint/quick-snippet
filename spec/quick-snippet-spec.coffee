Snippets = require '../lib/quick-snippet'

describe 'Quick Snippet', ->
  editor = null

  beforeEach ->
    waitsForPromise -> atom.workspace.open('test.coffee')
    waitsForPromise -> atom.packages.activatePackage('language-coffee-script')
    runs ->
      editor = atom.workspace.getActiveTextEditor()

  describe '::getLargestSelection', ->
    ret = null

    beforeEach ->
      editor.setCursorBufferPosition([0, 0])
      editor.addCursorAtBufferPosition([1, 5])
      editor.addCursorAtBufferPosition([1, 0])
      ret = Snippets.getLargestSelection(editor, editor.getCursorsOrderedByBufferPosition())

    it 'returns the largest selection', ->
      expect(ret).toBe 'module.exports = QuickSnippet =\n  act'

  describe '::getBodyFromCursors', ->
    describe 'to generate a static snippet', ->
      ret = null

      beforeEach ->
        editor.setCursorBufferPosition([0, 0])
        editor.addCursorAtBufferPosition([1, 5])
        selection = Snippets.getLargestSelection(editor, editor.getCursorsOrderedByBufferPosition())
        ret = Snippets.getBodyFromCursors(editor, selection, editor.getCursorsOrderedByBufferPosition())

      it 'returns the snippet', ->
        expect(ret).toBe 'module.exports = QuickSnippet =\n  act'

    describe 'to generate a snippet with one tab stop', ->
      ret = null

      beforeEach ->
        editor.setCursorBufferPosition([0, 0])
        editor.addCursorAtBufferPosition([2, 0])
        editor.addCursorAtBufferPosition([1, 12])
        selection = Snippets.getLargestSelection(editor, editor.getCursorsOrderedByBufferPosition())
        ret = Snippets.getBodyFromCursors(editor, selection, editor.getCursorsOrderedByBufferPosition())

      it 'returns the snippet', ->
        expect(ret.replace /\n/g, '\\n').toBe 'module.exports = QuickSnippet =\\n  activate: $1 ->\\n'

    describe 'to generate a snippet with two tab stops', ->
      ret = null

      beforeEach ->
        editor.setCursorBufferPosition([0, 0])
        editor.addCursorAtBufferPosition([4, 0])
        editor.addCursorAtBufferPosition([1, 12])
        editor.addCursorAtBufferPosition([3, 4])
        selection = Snippets.getLargestSelection(editor, editor.getCursorsOrderedByBufferPosition())
        ret = Snippets.getBodyFromCursors(editor, selection, editor.getCursorsOrderedByBufferPosition())

      it 'returns the snippet', ->
        expect(ret.replace /\n/g, '\\n').toBe 'module.exports = QuickSnippet =\\n  activate: $1 ->\\n    console.log \'Activated \\${2:""} QuickSnippet\'\\n    $2\\n'

    describe 'to generate a snippet with two tab stops (one of them from word)', ->
      ret = null

      beforeEach ->
        editor.setCursorBufferPosition([0, 0])
        editor.addCursorAtBufferPosition([4, 0])
        editor.addCursorAtBufferPosition([1, 12])
        editor.addCursorAtBufferPosition([0, 20])
        selection = Snippets.getLargestSelection(editor, editor.getCursorsOrderedByBufferPosition())
        ret = Snippets.getBodyFromCursors(editor, selection, editor.getCursorsOrderedByBufferPosition())

      it 'returns the snippet', ->
        expect(ret.replace /\n/g, '\\n').toBe 'module.exports = $1 =\\n  activate: $2 ->\\n    console.log \'Activated \\${2:""} $1\'\\n    \\n'

    describe 'to generate a snippet with three tab stops (one of them with default)', ->
      ret = null

      beforeEach ->
        editor.setCursorBufferPosition([0, 0])
        editor.addCursorAtBufferPosition([4, 0])
        editor.addCursorAtBufferPosition([1, 12])
        editor.addCursorAtBufferPosition([0, 20])
        editor.addCursorAtBufferPosition([1, 5]).selection.selectWord()
        selection = Snippets.getLargestSelection(editor, editor.getCursorsOrderedByBufferPosition())
        ret = Snippets.getBodyFromCursors(editor, selection, editor.getCursorsOrderedByBufferPosition())

      it 'returns the snippet', ->
        expect(ret.replace /\n/g, '\\n').toBe 'module.exports = $1 =\\n  ${2:"activate"}: $3 ->\\n    console.log \'Activated \\${2:""} $1\'\\n    \\n'

    describe 'to generate a snippet with two tab stops + 2 prefix selections', ->
      ret = null

      beforeEach ->
        atom.config.set('quick-snippet.reversePrefix', true)
        editor.setCursorBufferPosition([0, 0])
        editor.addCursorAtBufferPosition([4, 0])
        editor.addCursorAtBufferPosition([1, 12])
        editor.addCursorAtBufferPosition([0, 20])
        editor.addSelectionForBufferRange([[0, 17], [0, 18]], reversed: true)
        editor.addSelectionForBufferRange([[0, 22], [0, 23]], reversed: true)
        selection = Snippets.getLargestSelection(editor, editor.getCursorsOrderedByBufferPosition())
        ret = Snippets.getBodyFromCursors(editor, selection, editor.getCursorsOrderedByBufferPosition())

      it 'returns the snippet', ->
        expect(ret.replace /\n/g, '\\n').toBe 'module.exports = $1 =\\n  activate: $2 ->\\n    console.log \'Activated \\${2:""} $1\'\\n    \\n'
