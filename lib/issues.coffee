
fs = require 'fs'
request = require 'request'

token = '207e2ec811c24123b8e483b784534d3c690084e5'
outFilePfx = 'data/comments-'

module.exports = 

  activate: -> 
      console.log 'start issues'
    # 
    # atom.workspace.open('issues.txt').then (editor) ->

      firstPage = 1
      lastPage  = 100
      
      page = firstPage - 1
      
      padChars = (num, len, chr = ' ') ->
        num = '' + num
        while num.length < len then num = chr + num
        num
      
      do oneIssuesPage = ->
        if ++page > lastPage
          console.log 'issues done'
          return
          
        filePath = outFilePfx + padChars(page, 4, '0') + '.txt'
        
        if fs.existsSync filePath then oneIssuesPage(); return
        
        url = "https://api.github.com/repos/atom/atom/issues" +
                "?filter=all" +
                "&page=" + page

        options =
          url: url
          method: 'GET'
          headers:
            "User-Agent": "mark-hahn-issue-stats-app"
            Authorization: 'token ' + token
          json: true

        request options, (err, res, body) =>
          
          if not body.length then oneIssuesPage(); return
          
          pageHdr = '\n# page: ' + page + 
                    ', date: ' + body[0].created_at[0...10] +
                    ', count: ' + body.length +
                    ', rateLimit: ' + res.headers['x-ratelimit-remaining'] +
                    ' of ' + res.headers['x-ratelimit-limit'] +
                    '\n\n'
                        
          console.log pageHdr
          fs.appendFileSync filePath, pageHdr
          
          do oneIssue = ->
            if not (issue = body.shift())
              process.nextTick oneIssuesPage
              return
            
            options.url = "https://api.github.com/repos/atom/atom/issues/#{issue.number}/comments"

            request options, (err, res, body) =>
              if body.message then console.log 'comment error:', body.message
              else
                for comment in body
                  fs.appendFileSync filePath, '   ' + padChars(comment.body.length, 4) + 
                                                '-' + comment.id + 
                                                '-' + issue.number +        
                                                ' ' + comment.body[0..100].replace(/\s+/g, ' ') + '\n'

              process.nextTick oneIssue
                              
          