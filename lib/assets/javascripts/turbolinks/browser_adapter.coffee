#= require ./progress_bar

class Turbolinks.BrowserAdapter
  PROGRESS_BAR_DELAY = 500

  ANNOTATION_CLASS_NAMES =
    snapshot: "turbolinks-snapshot"
    loading: "turbolinks-loading"

  constructor: (@controller) ->
    @progressBar = new Turbolinks.ProgressBar

  visitProposedToLocationWithAction: (location, action) ->
    @controller.startVisitToLocationWithAction(location, action)

  visitStarted: (visit) ->
    visit.changeHistory()
    visit.issueRequest()
    if visit.restoreSnapshot()
      @annotateDocument("snapshot")

  visitRequestStarted: (visit) ->
    @annotateDocument("loading")
    @progressBar.setValue(0)
    unless visit.snapshotRestored
      if visit.hasSnapshot() or visit.action isnt "restore"
        @showProgressBarAfterDelay()
      else
        @showProgressBar()

  visitRequestProgressed: (visit) ->
    @progressBar.setValue(visit.progress)

  visitRequestCompleted: (visit) ->
    visit.loadResponse()

  visitRequestFailedWithStatusCode: (visit, statusCode) ->
    switch statusCode
      when Turbolinks.HttpRequest.NETWORK_FAILURE, Turbolinks.HttpRequest.TIMEOUT_FAILURE
        @reload()
      else
        visit.loadResponse()

  visitRequestFinished: (visit) ->
    @removeDocumentAnnotations()
    @hideProgressBar()

  visitResponseLoaded: (visit) ->
    visit.followRedirect()

  pageInvalidated: ->
    @reload()

  # Private

  showProgressBarAfterDelay: ->
    @progressBarTimeout = setTimeout(@showProgressBar, PROGRESS_BAR_DELAY)

  showProgressBar: =>
    @progressBar.show()

  hideProgressBar: ->
    @progressBar.hide()
    clearTimeout(@progressBarTimeout)

  annotateDocument: (annotation) ->
    className = ANNOTATION_CLASS_NAMES[annotation]
    document.documentElement.classList.add(className)

  removeDocumentAnnotations: ->
    for key, className of ANNOTATION_CLASS_NAMES
      document.documentElement.classList.remove(className)
    return

  reload: ->
    window.location.reload()
